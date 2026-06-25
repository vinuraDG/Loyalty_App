import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/core/errors/app_exception.dart';
import 'package:loyalty_app/models/transaction_model.dart';
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
    try {
      final res = await _dio.get('Mobile/GetAllCustomerLedgers',
          data: {
            'TransactionCompanyId': AppConstants.transactionCompanyId,
            'CustomerPhoneNo': phone,
          });
      final list = _asList(res.data);
      return list.map((m) => _txFromMap(m as Map<String, dynamic>, userId)).toList();
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
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
        'TransactionCompanyId': AppConstants.transactionCompanyId,
        'CustomerPhoneNo': phone,
        'EmployeePhoneNo': '',
        'DocumentNo': '',
        'Amount': points.toDouble(),
      });
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  TransactionModel _txFromMap(Map<String, dynamic> m, String userId) {
    final points = int.tryParse((m['Points'] ?? m['points'] ?? 0).toString()) ?? 0;
    final type = points >= 0 ? TransactionType.earned : TransactionType.redeemed;
    return TransactionModel(
      id: (m['Id'] ?? m['id'] ?? '').toString(),
      userId: userId,
      business: (m['CompanyName'] ?? m['business'] ?? '').toString(),
      points: points.abs(),
      type: type,
      date: m['Date'] != null
          ? DateTime.tryParse(m['Date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: (m['Note'] ?? m['note'])?.toString(),
      billNo: (m['DocumentNo'] ?? m['billNo'])?.toString(),
    );
  }
}

// Backend wraps lists in {"Value": [...], "StatusCode": 200}
List _asList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final inner = data['Value'] ?? data['value'] ?? data['data'] ?? data['items'];
    if (inner is List) return inner;
  }
  return [];
}

// ── Service factory ───────────────────────────────────────────────────────────

IPointsService get pointsService => AppConstants.useMockServices
    ? PointsMockService.instance
    : PointsApiService.instance;