import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/core/errors/app_exception.dart';
import 'emp_home_api_service.dart';
import 'emp_home_mock_service.dart';

class EmpHomeRealService implements IEmpHomeService {
  EmpHomeRealService._();
  static final EmpHomeRealService instance = EmpHomeRealService._();

  final Dio _dio = ApiClient.instance.dio;

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String> get _empPhone async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefUserPhone) ?? '';
  }

  String? _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['Message'] ?? data['error'])?.toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }

  // ── getMemberByQr ─────────────────────────────────────────────────────────
  // QR payload contains phone number — use GetCustomerByPhoneNo

  @override
  Future<ScannedMember> getMemberByQr(String userId) async {
    try {
      // userId from QR is the customer's phone number
      final res = await _dio.get('Common/GetCustomerByPhoneNo',
          queryParameters: {'CustomerPhoneNo': userId});
      final data = (res.data['customer'] ?? res.data['data'] ?? res.data)
          as Map<String, dynamic>;

      final points =
          int.tryParse((data['TotalPoints'] ?? data['totalPoints'] ?? 0).toString()) ?? 0;

      return ScannedMember(
        userId: (data['PhoneNo'] ?? data['phoneNo'] ?? userId).toString(),
        name:
            '${data['FirstName'] ?? ''} ${data['LastName'] ?? ''}'.trim(),
        memberId: (data['Id'] ?? data['CustomerId'] ?? '').toString(),
        tier: _tierFromPoints(points),
        currentPoints: points,
        phone: (data['PhoneNo'] ?? data['phoneNo'] ?? userId).toString(),
      );
    } on DioException catch (e) {
      throw Exception(_msg(e) ?? 'Member not found.');
    }
  }

  // ── recordFuelSale — POST /Common/EarnPoints ──────────────────────────────
  // PointsCalculationRequestDTO: TransactionCompanyId, CustomerPhoneNo,
  //   EmployeePhoneNo, DocumentNo, Amount

  @override
  Future<void> recordFuelSale({
    required String employeeId,
    required String customerId,
    required double saleAmount,
    required int pointsAwarded,
  }) async {
    final phone = await _empPhone;
    try {
      await _dio.post('Common/EarnPoints', data: {
        'TransactionCompanyId': AppConstants.transactionCompanyId,
        'CustomerPhoneNo': customerId,
        'EmployeePhoneNo': phone,
        'DocumentNo': '',
        'Amount': saleAmount,
      });
    } on DioException catch (e) {
      throw Exception(_msg(e) ?? 'Failed to record sale.');
    }
  }

  // ── getTodayScans — GET /Mobile/GetAllEmployeeLedgers ─────────────────────
  // EmployeeLedgerRequestDTO: TransactionCompanyId, CompanyId,
  //   EmployeePhoneNo, DateFrom, DateTo

  @override
  Future<List<ScanEntry>> getTodayScans(String employeeId) async {
    final phone = await _empPhone;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    try {
      final res = await _dio.get('Mobile/GetAllEmployeeLedgers',
          data: {
            'TransactionCompanyId': AppConstants.transactionCompanyId,
            'CompanyId': AppConstants.transactionCompanyId,
            'EmployeePhoneNo': phone,
            'DateFrom': dateStr,
            'DateTo': dateStr,
          });
      final list = res.data as List? ?? [];
      return list
          .map((m) => ScanEntry.fromJson(m as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  // ── getWeeklyCommission — GET /Common/CalculateCommission ─────────────────

  @override
  Future<List<int>> getWeeklyCommission(String employeeId) async {
    final phone = await _empPhone;
    final now = DateTime.now();
    // Build Mon–Sun of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final List<int> result = [];

    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      try {
        final res = await _dio.get('Common/CalculateCommission',
            data: {
              'TransactionCompanyId': AppConstants.transactionCompanyId,
              'EmployeePhoneNo': phone,
              'DateFrom': dateStr,
              'DateTo': dateStr,
            });
        final data = res.data;
        final val = data is Map
            ? int.tryParse(
                    (data['commission'] ?? data['Commission'] ?? 0).toString()) ??
                0
            : 0;
        result.add(val);
      } on DioException catch (_) {
        result.add(0);
      }
    }
    return result;
  }

  // ── getRedeemableOffers — GET /Mobile/GetAllCustomerLedgers ──────────────

  @override
  Future<List<RedeemableOffer>> getRedeemableOffers(String customerId) async {
    try {
      final res = await _dio.get('Mobile/GetAllCustomerLedgers',
          data: {
            'TransactionCompanyId': AppConstants.transactionCompanyId,
            'CustomerPhoneNo': customerId,
          });
      final list = res.data as List? ?? [];
      // Map ledger entries → RedeemableOffer shape
      return list.map((m) {
        final map = m as Map<String, dynamic>;
        return RedeemableOffer(
          id: (map['Id'] ?? map['id'] ?? '').toString(),
          title: (map['CompanyName'] ?? map['Title'] ?? 'Offer').toString(),
          description:
              (map['Description'] ?? map['Note'] ?? '').toString(),
          business: (map['CompanyName'] ?? map['Business'] ?? '').toString(),
          pointsCost:
              int.tryParse((map['Points'] ?? map['points'] ?? 0).toString()) ??
                  0,
          isExpired: map['IsExpired'] as bool? ?? false,
        );
      }).toList();
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  // ── sendRedemptionOtp — POST /Common/ForgotPassword (OTP channel) ─────────
  // Sends OTP to customer's registered phone

  @override
  Future<String> sendRedemptionOtp({
    required String customerId,
    required String offerId,
  }) async {
    try {
      await _dio.post('Common/ForgotPassword', data: {
        'UserName': customerId, // customerId = phone number
      });
      return ''; // OTP delivered via SMS — not returned to client
    } on DioException catch (e) {
      throw Exception(_msg(e) ?? 'Failed to send OTP.');
    }
  }

  // ── confirmRedemption — POST /Common/RedeemPoints ─────────────────────────
  // PointsRedeemRequestDTO: TransactionCompanyId, CustomerPhoneNo,
  //   EmployeePhoneNo, PointsRedeemCompany, DocumentNo, Amount, Points

  @override
  Future<RedemptionResult> confirmRedemption({
    required String customerId,
    required String offerId,
    required String otp,
    required String employeeId,
  }) async {
    final phone = await _empPhone;
    try {
      final res = await _dio.post('Common/RedeemPoints', data: {
        'TransactionCompanyId': AppConstants.transactionCompanyId,
        'CustomerPhoneNo': customerId,
        'EmployeePhoneNo': phone,
        'PointsRedeemCompany': '',
        'DocumentNo': offerId,
        'Amount': 0,
        'Points': 0,
        'OTP': otp,
      });
      final data = res.data is Map ? res.data as Map<String, dynamic> : {};
      final deducted =
          int.tryParse((data['PointsDeducted'] ?? data['points'] ?? 0).toString()) ?? 0;
      final remaining =
          int.tryParse((data['RemainingPoints'] ?? data['remaining'] ?? 0).toString()) ?? 0;
      final code = (data['ConfirmationCode'] ?? data['code'] ??
              'RDM-${DateTime.now().millisecondsSinceEpoch % 100000}')
          .toString();
      return RedemptionResult(
        pointsDeducted: deducted,
        remainingPoints: remaining,
        confirmationCode: code,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = _msg(e);
      if (status == 400) throw InvalidOtpException();
      if (status == 422) throw InsufficientPointsException();
      throw Exception(msg ?? 'Redemption failed. Please try again.');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _tierFromPoints(int p) {
    if (p >= 5000) return 'Platinum';
    if (p >= 2000) return 'Gold';
    if (p >= 500) return 'Silver';
    return 'Bronze';
  }
}

// ── Service factory ───────────────────────────────────────────────────────────

IEmpHomeService get empHomeService => AppConstants.useMockServices
    ? EmpHomeMockService.instance
    : EmpHomeRealService.instance;