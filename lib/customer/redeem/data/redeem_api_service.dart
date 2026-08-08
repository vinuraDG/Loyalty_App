import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/data/companies_api_service.dart';
import 'package:loyalty_app/data/customer_ledger_service.dart';
import 'package:loyalty_app/models/offer_models.dart';
import 'package:loyalty_app/customer/redeem/data/redeem_mock_service.dart';

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IRedeemService {
  Future<List<OfferModel>> getOffers();
  Future<int> getRedeemableBalance(String phone, int transactionCompanyId);
  Future<String> redeemOffer(String userId, OfferModel offer, {int points = 0});
}

// ── Real API service ──────────────────────────────────────────────────────────

class RedeemApiService implements IRedeemService {
  RedeemApiService._();
  static final RedeemApiService instance = RedeemApiService._();

  final Dio _dio = ApiClient.instance.dio;

  @override
  Future<List<OfferModel>> getOffers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';

      // Step 1: wallet (TC=0) → get TransactionCompanyId(s).
      // Step 2: ledger with that TC ID → collect PointsRedeemCompanyId (= c.Id).
      // Step 3: filter companies by those IDs.
      final companiesFuture = CompaniesApiService.instance.getCompanies();
      final walletsFuture   = _fetchAllWallets(phone);
      final companies = await companiesFuture;
      final wallets   = await walletsFuture;
      if (companies.isEmpty) return [];

      final redeemCompanyIds = <int>{};
      for (final w in wallets) {
        final tcId = int.tryParse(
                (w['TransactionCompanyId'] ?? w['transactionCompanyId'] ?? 0).toString()) ?? 0;
        if (tcId <= 0) continue;
        try {
          final ledgerRes = await _dio.get(
            'Mobile/GetAllCustomerLedgers',
            data: {'TransactionCompanyId': tcId, 'CustomerPhoneNo': phone},
          );
          final raw = ledgerRes.data;
          List items = raw is List ? raw : (raw is Map
              ? (raw['Value'] ?? raw['value'] ?? raw['Data'] ?? raw['data'] ?? [])
              : []);
          for (final entry in items) {
            if (entry is! Map) continue;
            final redeemId = int.tryParse(
                (entry['PointsRedeemCompanyId'] ?? 0).toString()) ?? 0;
            if (redeemId > 0) redeemCompanyIds.add(redeemId);
          }
        } catch (_) {}
      }

      // Filter by PointsRedeemCompanyId (matches c.Id).
      // Fall back to !isEarnOnly if ledger returned no redeem IDs.
      final redeemable = redeemCompanyIds.isNotEmpty
          ? companies.where((c) => redeemCompanyIds.contains(c.Id)).toList()
          : companies.where((c) => !c.isEarnOnly).toList();

      return redeemable
          .map((c) => OfferModel(
                id: 'redeem-${c.Id}',
                title: c.displayName,
                description: 'Redeem at ${c.name}',
                business: c.displayName,
                pointsCost: 0,
                companyPhoneNo: c.phoneNo,
                companyId: c.Id,
                companyTransactionId: c.transactionCompanyId,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllWallets(String phone) async {
    try {
      final res = await _dio.get(
        'Common/GetAllCustomerWallets',
        data: {
          'TransactionCompanyId': 0,
          'CustomerPhoneNo': phone,
        },
      );
      final raw = res.data;
      List items = [];
      if (raw is List) {
        items = raw;
      } else if (raw is Map) {
        final inner = raw['Value'] ?? raw['value'] ?? raw['Data'] ?? raw['data'];
        if (inner is List) {
          items = inner;
        } else if (inner == null) {
          items = [raw];
        }
      }
      return items.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<int> getRedeemableBalance(String phone, int transactionCompanyId) async {
    try {
      // Step 1: wallet (TC=0) → get TransactionCompanyId(s).
      // Step 2: ledger with that TC ID → sum PointBalance from Earn entries.
      final wallets = await _fetchAllWallets(phone);
      int balance = 0;
      for (final w in wallets) {
        final tcId = int.tryParse(
            (w['TransactionCompanyId'] ?? w['transactionCompanyId'] ?? 0).toString()) ?? 0;
        if (tcId <= 0) continue;
        try {
          final ledgerRes = await _dio.get(
            'Mobile/GetAllCustomerLedgers',
            data: {'TransactionCompanyId': tcId, 'CustomerPhoneNo': phone},
          );
          final raw = ledgerRes.data;
          List items = raw is List ? raw : (raw is Map
              ? (raw['Value'] ?? raw['value'] ?? raw['Data'] ?? raw['data'] ?? [])
              : []);
          for (final entry in items) {
            if (entry is! Map) continue;
            final type = (entry['PointsTransactionType'] ?? '').toString().toLowerCase();
            if (type != 'earn') continue;
            final b = entry['PointBalance'] ?? entry['PointsBalance'] ?? 0;
            balance += (double.tryParse(b.toString()) ?? 0).round();
          }
        } catch (_) {}
      }
      return balance;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<String> redeemOffer(String userId, OfferModel offer, {int points = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    final redeemPhone =
        offer.companyPhoneNo.isNotEmpty ? offer.companyPhoneNo : '0112948777';
    // Use the caller-supplied points (user's full balance); fall back to
    // pointsCost only when explicitly set (mock data / future API-driven offers).
    final pointsToSend = points > 0 ? points : offer.pointsCost;
    try {
      final res = await _dio.post(
        'Common/RedeemPoints',
        options: Options(responseType: ResponseType.plain),
        data: {
          'TransactionCompanyId': offer.companyTransactionId,
          'CustomerPhoneNo': phone,
          'EmployeePhoneNo': '',
          'Points': pointsToSend,
          'PointsRedeemCompanyPhoneNo': redeemPhone,
        },
      );

      // Invalidate the ledger cache so the next balance fetch reflects
      // the just-completed redemption.
      CustomerLedgerService.instance.clearCache();

      // Parse plain-text response as JSON if non-empty.
      Map<String, dynamic> data = {};
      final body = (res.data as String? ?? '').trim();
      if (body.isNotEmpty) {
        try {
          final parsed = jsonDecode(body);
          if (parsed is Map<String, dynamic>) data = parsed;
        } catch (_) {}
      }

      return (data['ConfirmationCode'] ??
              data['code'] ??
              'RDM-${DateTime.now().millisecondsSinceEpoch % 100000}')
          .toString();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message'] ?? e.response!.data['Message'])
          : null;
      throw Exception(msg ?? 'Redeem failed. Please try again.');
    }
  }
}

// ── Service factory ───────────────────────────────────────────────────────────

IRedeemService get redeemService => AppConstants.useMockServices
    ? RedeemMockService.instance
    : RedeemApiService.instance;
