import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/core/errors/app_exception.dart';
import 'package:loyalty_app/models/transaction_model.dart';
import 'package:loyalty_app/models/company_model.dart';
import 'package:loyalty_app/data/companies_api_service.dart';
import 'package:loyalty_app/customer/points/data/points_mock_service.dart';
import 'package:loyalty_app/data/customer_ledger_service.dart';

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IPointsService {
  Future<List<TransactionModel>> getTransactions(String userId);
  Future<List<TransactionModel>> getTransactionsByBusiness(
      String userId, String business);
  Future<void> awardPoints(String userId, String business, int points);
}

// ── Real API service ──────────────────────────────────────────────────────────

class PointsApiService implements IPointsService {
  PointsApiService._();
  static final PointsApiService instance = PointsApiService._();

  final Dio _dio = ApiClient.instance.dio;

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';

    // Fetch companies and ledgers in parallel
    final results = await Future.wait([
      _fetchCompanies(),
      _fetchLedgers(phone),
    ]);

    final companies = results[0] as List<CompanyModel>;
    final rawList   = results[1] as List<dynamic>? ?? <dynamic>[];

    // Build Id → CompanyModel map directly from backend data.
    // GetAllCompanies returns each company with its real Id field.
    final companyMap = <int, CompanyModel>{};
    for (final c in companies) {
      if (c.Id > 0) companyMap[c.Id] = c;
    }

    final txs = rawList
        .map((m) => _txFromMap(m as Map<String, dynamic>, userId, companyMap, companies))
        .toList();

    txs.sort((a, b) => b.date.compareTo(a.date));
    return txs;
  }

  @override
  Future<List<TransactionModel>> getTransactionsByBusiness(
      String userId, String business) async {
    final all = await getTransactions(userId);
    return all.where((t) => t.business == business).toList();
  }

  @override
  Future<void> awardPoints(String userId, String business, int points) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    try {
      await _dio.post('Common/EarnPoints', data: {
        'TransactionCompanyId': AppConstants.activeCompanyId,
        'CustomerPhoneNo': phone,
        'EmployeePhoneNo': '',
        'DocumentNo': '',
        'Amount': points.toDouble(),
      });
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<List<CompanyModel>> _fetchCompanies() async {
    try {
      return await CompaniesApiService.instance.getCompanies();
    } catch (e) {
      return [];
    }
  }

  // Delegates to the shared CustomerLedgerService so HomeApiService and
  // PointsApiService share one in-flight request + TTL cache.
  Future<List<dynamic>> _fetchLedgers(String phone) =>
      CustomerLedgerService.instance.fetchLedger(phone);

  TransactionModel _txFromMap(
  Map<String, dynamic> m,
  String userId,
  Map<int, CompanyModel> companyMap,
  List<CompanyModel> companies,
) {
  final points = int.tryParse(
          (m['PointsValue'] ?? m['Points'] ?? m['points'] ?? 0).toString()) ??
      0;

  final typeStr =
      (m['PointsTransactionType'] ?? m['transactionType'] ?? '').toString();
  final type = switch (typeStr.toLowerCase()) {
  'redeem'                        => TransactionType.redeemed,
  'expired' || 'expire' ||
  'expiring' || 'pointsexpired'   => TransactionType.expired,
  _                               => TransactionType.earned,
};

  final ownId    = int.tryParse((m['PointsOwnCompanyId']    ?? 0).toString()) ?? 0;
  final redeemId = int.tryParse((m['PointsRedeemCompanyId'] ?? 0).toString()) ?? 0;

  // Resolve company names purely from backend data (companyMap built from GetAllCompanies).
  // The earn company (PointsOwnCompanyId) may not be in GetAllCompanies — show empty if so.
  // The redeem company (PointsRedeemCompanyId) is always in GetAllCompanies.
  final ownCompany    = companyMap[ownId];
  final redeemCompany = (type == TransactionType.redeemed && redeemId > 0)
      ? companyMap[redeemId]
      : null;

  final businessName     = ownCompany?.displayName    ?? '';
  final businessFullName = ownCompany?.name.isNotEmpty == true ? ownCompany!.name : null;

  final redeemCompanyName     = redeemCompany?.displayName;
  final redeemCompanyFullName = redeemCompany?.name.isNotEmpty == true ? redeemCompany!.name : null;

  // ── Always use DateCreated — it is the actual transaction timestamp ──────
  final dateStr = (m['DateCreated'] ?? m['DateLastModified'] ?? '').toString();
  final parsed  = DateTime.tryParse(dateStr);
  final date    = (parsed != null && parsed.year >= 2000)
      ? DateTime(parsed.year, parsed.month, parsed.day, parsed.hour, parsed.minute, parsed.second)
      : DateTime.now();

  // ── Expiry info — Earn entries only ────────────────────────────────────
  // Backend never returns a separate "Expired" transaction type; instead
  // each Earn entry carries DateExpire and PointBalance (remaining points
  // from that batch after any redeems applied against it).
  int?      expiringBalance;
  DateTime? expiryDate;
  if (type == TransactionType.earned) {
    final expRaw    = (m['DateExpire'] ?? '').toString();
    final expParsed = DateTime.tryParse(expRaw);
    if (expParsed != null &&
        expParsed.year > 2000 &&
        expParsed.isAfter(DateTime.now())) {
      expiryDate      = expParsed;
      expiringBalance = int.tryParse(
              (m['PointBalance'] ?? 0).toString()) ??
          0;
    }
  }

  return TransactionModel(
    id:                    (m['Id'] ?? m['id'] ?? '').toString(),
    userId:                userId,
    business:              businessName,
    points:                points.abs(),
    type:                  type,
    date:                  date,
    note:                  (m['Note']       ?? m['note'])?.toString(),
    billNo:                (m['DocumentNo'] ?? m['billNo'])?.toString(),
    redeemCompanyName:     redeemCompanyName,
    businessFullName:      businessFullName,
    redeemCompanyFullName: redeemCompanyFullName,
    expiringBalance:       expiringBalance,
    expiryDate:            expiryDate,
  );
}
}

// ── Service factory ───────────────────────────────────────────────────────────

IPointsService get pointsService => AppConstants.useMockServices
    ? PointsMockService.instance
    : PointsApiService.instance;