import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/core/errors/app_exception.dart';
import 'package:loyalty_app/models/transaction_model.dart';
import 'package:loyalty_app/models/company_model.dart';
import 'package:loyalty_app/data/companies_api_service.dart';
import 'package:loyalty_app/customer/points/data/points_mock_service.dart';

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
    final rawList   = results[1] as List<dynamic>;

    // Build  PointsOwnCompanyId / PointsRedeemCompanyId → CompanyName  map.
    // GetAllCompanies order: [Laundry(idx0), Gold House(idx1), Fuel(idx2)].
    // Backend IDs confirmed from live ledger data (NOT the list order):
    //   Gold House = 1  (PointsRedeemCompanyId in redeem entries)
    //   Fuel       = 3  (PointsOwnCompanyId in earn entries = transactionCompanyId)
    //   Laundry    = 2  (assumed — only remaining company between IDs 1 and 3)
    final companyMap = <int, String>{};
    if (companies.length == 3) {
      companyMap[AppConstants.companyIdGoldHouse]   = companies[1].displayName;
      companyMap[AppConstants.companyIdLaundry]     = companies[0].displayName;
      companyMap[AppConstants.transactionCompanyId] = companies[2].displayName;
    } else {
      for (int i = 0; i < companies.length; i++) {
        companyMap[i + 1] = companies[i].displayName;
      }
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

  Future<List<dynamic>> _fetchLedgers(String phone) async {
    try {
      final res = await _dio.get(
        'Mobile/GetAllCustomerLedgers',
        data: {
          'TransactionCompanyId': AppConstants.activeCompanyId,
          'CustomerPhoneNo': phone,
        },
      );
      return _asList(res.data);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  TransactionModel _txFromMap(
  Map<String, dynamic> m,
  String userId,
  Map<int, String> companyMap,
  List<CompanyModel> companies,
) {
  final points = int.tryParse(
          (m['PointsValue'] ?? m['Points'] ?? m['points'] ?? 0).toString()) ??
      0;

  final typeStr =
      (m['PointsTransactionType'] ?? m['transactionType'] ?? '').toString();
  final type = typeStr.toLowerCase() == 'redeem'
      ? TransactionType.redeemed
      : TransactionType.earned;

  final ownId    = int.tryParse((m['PointsOwnCompanyId']    ?? 0).toString()) ?? 0;
  final redeemId = int.tryParse((m['PointsRedeemCompanyId'] ?? 0).toString()) ?? 0;

  // Business always shows the EARN company (where points were originally earned).
  String businessName = companyMap[ownId] ?? '';
  if (businessName.isEmpty && companies.isNotEmpty) {
    businessName = companies.last.displayName; // fallback to earn company (last = Fuel)
  }
  if (businessName.isEmpty && ownId > 0) {
    businessName = 'Company $ownId';
  }

  // Redeem company: only present on Redeem transactions; shown as extra row in UI.
  final redeemCompanyName = (type == TransactionType.redeemed && redeemId > 0)
      ? (companyMap[redeemId] ?? 'Company $redeemId')
      : null;

  // ── Always use DateCreated — it is the actual transaction timestamp ────────
  // DateExpire is irrelevant for display; it's 1 year ahead for Earn entries.
  final dateStr = (m['DateCreated'] ?? m['DateLastModified'] ?? '').toString();
  final parsed  = DateTime.tryParse(dateStr);
  final date    = (parsed != null && parsed.year >= 2000) ? parsed : DateTime.now();

  return TransactionModel(
    id:                (m['Id'] ?? m['id'] ?? '').toString(),
    userId:            userId,
    business:          businessName,
    points:            points.abs(),
    type:              type,
    date:              date,
    note:              (m['Note']       ?? m['note'])?.toString(),
    billNo:            (m['DocumentNo'] ?? m['billNo'])?.toString(),
    redeemCompanyName: redeemCompanyName,
  );
}
}

DateTime _resolveDate(DateTime? parsed, TransactionType type) {
  if (parsed == null || parsed.year < 2000) return DateTime.now();
  if (type == TransactionType.earned && parsed.isAfter(DateTime.now())) {
    return DateTime(
      parsed.year - 1,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    );
  }
  return parsed;
}

List _asList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final inner =
        data['Value'] ?? data['value'] ?? data['data'] ?? data['items'];
    if (inner is List) return inner;
  }
  return [];
}

// ── Service factory ───────────────────────────────────────────────────────────

IPointsService get pointsService => AppConstants.useMockServices
    ? PointsMockService.instance
    : PointsApiService.instance;