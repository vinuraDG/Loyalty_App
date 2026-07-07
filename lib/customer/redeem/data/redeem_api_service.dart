import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/data/companies_api_service.dart';
import 'package:loyalty_app/models/offer_models.dart';
import 'package:loyalty_app/customer/redeem/data/redeem_mock_service.dart';

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IRedeemService {
  Future<List<OfferModel>> getOffers();
  Future<String> redeemOffer(String userId, OfferModel offer);
}

// ── Real API service ──────────────────────────────────────────────────────────

class RedeemApiService implements IRedeemService {
  RedeemApiService._();
  static final RedeemApiService instance = RedeemApiService._();

  final Dio _dio = ApiClient.instance.dio;

  static const _fallbackOffer = OfferModel(
    id: 'gold-house-redeem',
    title: 'Gold House',
    description: 'Redeem at Gold House',
    business: 'Gold House',
    pointsCost: 0,
    companyPhoneNo: '0112948777',
  );

  @override
  Future<List<OfferModel>> getOffers() async {
    try {
      final companies = await CompaniesApiService.instance.getCompanies();
      final redeemable = companies
          .where((c) => c.id != AppConstants.transactionCompanyId)
          .toList();
      if (redeemable.isEmpty) return [_fallbackOffer];
      return redeemable
          .map((c) => OfferModel(
                id: 'redeem-${c.id}',
                title: c.displayName,
                description: 'Redeem at ${c.name}',
                business: c.displayName,
                pointsCost: 0,
                companyPhoneNo: c.phoneNo,
              ))
          .toList();
    } catch (_) {
      return [_fallbackOffer];
    }
  }

  @override
  Future<String> redeemOffer(String userId, OfferModel offer) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    final redeemPhone =
        offer.companyPhoneNo.isNotEmpty ? offer.companyPhoneNo : '0112948777';
    try {
      final res = await _dio.post(
        'Common/RedeemPoints',
        options: Options(responseType: ResponseType.plain),
        data: {
          'TransactionCompanyId': AppConstants.activeCompanyId,
          'CustomerPhoneNo': phone,
          'EmployeePhoneNo': '',
          'Points': offer.pointsCost,
          'PointsRedeemCompanyPhoneNo': redeemPhone,
        },
      );

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
