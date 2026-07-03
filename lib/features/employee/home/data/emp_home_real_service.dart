// lib/features/employee/home/data/emp_home_real_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  /// Logs a backend failure without surfacing it to the user.
  ///
  /// NOTE (2026-06-30): GetAllEmployeeWallets is now confirmed (via
  /// successive 405/400 responses during live debugging) to require:
  ///   1. HTTP verb GET (POST returns 405 Method Not Allowed).
  ///   2. A non-empty JSON request body (an empty/missing body returns 400
  ///      with a generic "Request field is required" — "Request" there is
  ///      just the action's parameter name, not a JSON wrapper key).
  ///   3. The body's fields FLAT at the top level, not nested under a
  ///      "Request" key — wrapping them caused the binder to report
  ///      EmployeePhoneNo (and presumably the others) as missing, since it
  ///      couldn't see past the extra nesting.
  /// In short: `[HttpGet] ... ([FromBody] WalletsRequestDto)`, an
  /// unconventional GET-with-flat-body action. Implemented below as
  /// `_dio.get(..., data: {...flat fields...})`.
  /// GetAllEmployeeLedgers has the same 500/empty-body symptom but is
  /// already sent as GET + flat `data:`, so if it's still failing the
  /// cause is likely something endpoint-specific (different/extra required
  /// fields, a genuine server bug, etc.) rather than this same shape issue
  /// — worth testing in isolation. This try/catch fallback is kept
  /// defensively either way.
  void _logBackendFailure(String endpoint, DioException e) {
    assert(() {
      debugPrint(
        '[EmpHome] $endpoint failed (treated as empty/degraded): '
        'status=${e.response?.statusCode} body=${e.response?.data}',
      );
      return true;
    }());
  }

  // ── getMemberByQr ─────────────────────────────────────────────────────────

  @override
  Future<ScannedMember> getMemberByQr(String userId) async {
    try {
      final res = await _dio.get(
        'Common/GetCustomerByPhoneNo',
        queryParameters: {'CustomerPhoneNo': userId},
      );
      if (res.data == null || res.data is! Map) {
        throw Exception('Member not found.');
      }
      final data = res.data as Map<String, dynamic>;
      final phone = (data['PhoneNo'] ?? data['phoneNo'] ?? userId).toString();

      int points = 0;
      try {
        final ledgerRes = await _dio.get(
          'Mobile/GetAllCustomerLedgers',
          data: {
            'TransactionCompanyId': AppConstants.transactionCompanyId,
            'CustomerPhoneNo': phone,
          },
        );
        final entries = _asList(ledgerRes.data);
        int earned = 0, redeemed = 0;
        for (final e in entries) {
          if (e is! Map<String, dynamic>) continue;
          final pts = int.tryParse((e['PointsValue'] ?? 0).toString()) ?? 0;
          final type =
              (e['PointsTransactionType'] ?? '').toString().toLowerCase();
          if (type == 'earn') {
            earned += pts;
          } else {
            redeemed += pts;
          }
        }
        points = earned - redeemed;
      } catch (_) {
        // Points fetch is best-effort; proceed without it
      }

      return ScannedMember(
        userId: phone,
        name: '${data['FirstName'] ?? ''} ${data['LastName'] ?? ''}'.trim(),
        memberId: phone,
        tier: _tierFromPoints(points),
        currentPoints: points,
        phone: phone,
      );
    } on DioException catch (e) {
      throw Exception(_msg(e) ?? 'Member not found.');
    }
  }

  // ── recordFuelSale — POST /Common/EarnPoints ──────────────────────────────

  @override
  Future<void> recordFuelSale({
    required String employeeId,
    required String customerId,
    required double saleAmount,
    required int pointsAwarded,
  }) async {
    final phone = await _empPhone;
    try {
      await _dio.post(
        'Common/EarnPoints',
        data: {
          'TransactionCompanyId': AppConstants.transactionCompanyId,
          'CustomerPhoneNo': customerId,
          'EmployeePhoneNo': phone,
          'DocumentNo': '',
          'Amount': saleAmount,
        },
      );
    } on DioException catch (e) {
      throw Exception(_msg(e) ?? 'Failed to record sale.');
    }
  }

  // ── getTodayScans — GET /Mobile/GetAllEmployeeWallets (body required) ──────
  // fallback to an empty list is kept defensively so a genuine transient/
  // server failure still degrades gracefully instead of crashing the
  // dashboard.

  @override
  Future<List<ScanEntry>> getTodayScans(String employeeId) async {
    final phone = await _empPhone;
    final now = DateTime.now();
    try {
      final res = await _dio.get(
        'Mobile/GetAllEmployeeWallets',
        data: {
          'TransactionCompanyId': AppConstants.transactionCompanyId,
          'CompanyId': AppConstants.transactionCompanyId,
          'EmployeePhoneNo': phone,
          'Year': now.year,
          'Month': now.month,
        },
      );
      final list = _asList(res.data);
      final entries = list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      bool isToday(Map<String, dynamic> j) {
        final raw =
            j['DateCreated'] ?? j['dateCreated'] ?? j['CreatedAt'] ?? j['Date'];
        final d = raw != null ? DateTime.tryParse(raw.toString()) : null;
        if (d == null) return false;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }

      return entries
          .where(isToday)
          .map((m) => ScanEntry.fromJson(m))
          .toList();
    } on DioException catch (e) {
      _logBackendFailure('GetAllEmployeeWallets (getTodayScans)', e);
      return const [];
    }
  }

  // ── getWeeklyCommission — derived from GET /Mobile/GetAllEmployeeWallets ──
  // FIX (2026-06-30): same GET + "Request"-wrapped body fix as
  // getTodayScans. CalculateCommission is confirmed to be a single-document
  // endpoint (requires CustomerPhoneNo + DocumentNo), not a date-range
  // rollup, so it's intentionally not called here at all.

  @override
  Future<List<int>> getWeeklyCommission(String employeeId) async {
    final phone = await _empPhone;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final result = List<int>.filled(7, 0);

    try {
      final res = await _dio.get(
        'Mobile/GetAllEmployeeWallets',
        data: {
          'TransactionCompanyId': AppConstants.transactionCompanyId,
          'CompanyId': AppConstants.transactionCompanyId,
          'EmployeePhoneNo': phone,
          'Year': now.year,
          'Month': now.month,
        },
      );
      final list = _asList(res.data);
      for (final raw in list) {
        if (raw is! Map) continue;
        final j = Map<String, dynamic>.from(raw);
        final dateRaw =
            j['DateCreated'] ?? j['dateCreated'] ?? j['CreatedAt'] ?? j['Date'];
        final d = dateRaw != null ? DateTime.tryParse(dateRaw.toString()) : null;
        if (d == null) continue;

        final dayIndex = d.difference(monday).inDays;
        if (dayIndex < 0 || dayIndex > 6) continue;

        final commissionRaw =
            j['Commission'] ?? j['commission'] ?? j['CommissionAmount'] ?? 0;
        final commission =
            (double.tryParse(commissionRaw.toString()) ?? 0.0).round();
        result[dayIndex] += commission;
      }
    } on DioException catch (e) {
      _logBackendFailure('GetAllEmployeeWallets (getWeeklyCommission)', e);
      // leave result as zeros
    }
    return result;
  }

  // ── getRedeemableOffers ───────────────────────────────────────────────────
  // The backend has no dedicated offers endpoint. Return a single synthetic
  // Gold Shop offer so the redemption UI can proceed; the actual points
  // amount is entered manually by the employee.

  @override
  Future<List<RedeemableOffer>> getRedeemableOffers(String customerId) async {
    return const [
      RedeemableOffer(
        id: 'gold-shop-redeem',
        title: 'Gold Shop',
        description: 'Redeem at Gold Shop',
        business: 'Gold Shop',
        pointsCost: 0,
      ),
    ];
  }

  // ── sendRedemptionOtp — POST /Common/ForgotPassword (OTP channel) ─────────

  @override
  Future<String> sendRedemptionOtp({
    required String customerId,
    required String offerId,
  }) async {
    try {
      await _dio.post(
        'Common/ForgotPassword',
        data: {'UserName': customerId},
      );
      return '';
    } on DioException catch (e) {
      throw Exception(_msg(e) ?? 'Failed to send OTP.');
    }
  }

  // ── confirmRedemption — POST /Common/RedeemPoints ─────────────────────────

  @override
  Future<RedemptionResult> confirmRedemption({
    required String customerId,
    required String offerId,
    required String otp,
    required String employeeId,
    int pointsToRedeem = 0,
  }) async {
    final phone = await _empPhone;
    try {
      final res = await _dio.post(
        'Common/RedeemPoints',
        data: {
          'TransactionCompanyId': AppConstants.transactionCompanyId,
          'CustomerPhoneNo': customerId,
          'EmployeePhoneNo': phone,
          'PointsRedeemCompany': 'Gold Shop',
          'DocumentNo': offerId == 'gold-shop-redeem' ? '' : offerId,
          'Amount': pointsToRedeem.toDouble(),
          'Points': pointsToRedeem,
          'OTP': otp,
        },
      );
      final data = res.data is Map
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      final deducted = int.tryParse(
              (data['PointsDeducted'] ?? data['points'] ?? 0).toString()) ??
          0;
      final remaining = int.tryParse(
              (data['RemainingPoints'] ?? data['remaining'] ?? 0).toString()) ??
          0;
      final code = (data['ConfirmationCode'] ??
              data['code'] ??
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
      if (status == 400) throw const InvalidOtpException();
      if (status == 422) throw const InsufficientPointsException();
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

List _asList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final inner =
        data['Value'] ?? data['value'] ?? data['data'] ?? data['items'];
    if (inner is List) return inner;
  }
  return [];
}

IEmpHomeService get empHomeService => AppConstants.useMockServices
    ? EmpHomeMockService.instance
    : EmpHomeRealService.instance;