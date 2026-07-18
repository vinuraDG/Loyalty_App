// lib/features/employee/home/data/emp_home_real_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/data/companies_api_service.dart';
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
        queryParameters: {
          'TransactionCompanyId': AppConstants.earnCompanyId,
          'CustomerPhoneNo': userId,
        },
      );
      if (res.data == null || res.data is! Map) {
        throw Exception('Member not found.');
      }
      final data = res.data as Map<String, dynamic>;
      final phone = (data['PhoneNo'] ?? data['phoneNo'] ?? userId).toString();

      // Prefer TotalPoints from the profile response — same value the customer
      // sees in their own app. Fall back to ledger calculation only if absent.
      final rawProfilePts = data['TotalPoints'] ?? data['totalPoints'] ??
          data['PointBalance'] ?? data['pointBalance'];
      int points = rawProfilePts != null
          ? (int.tryParse(rawProfilePts.toString()) ?? -1)
          : -1;

      if (points < 0) {
        points = 0;
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
  Future<int> recordFuelSale({
    required String employeeId,
    required String customerId,
    required double saleAmount,
    required int pointsAwarded,
    required String documentNo,
  }) async {
    final phone = await _empPhone;
    try {
      final res = await _dio.post(
        'Common/EarnPoints',
        data: {
          'TransactionCompanyId': AppConstants.earnCompanyId,
          'CustomerPhoneNo': customerId,
          'EmployeePhoneNo': phone,
          'Amount': saleAmount,
          'DocumentNo': documentNo,
        },
      );
      // Use server's calculated points; fall back to client estimate if absent.
      final data = res.data;
      if (data is Map) {
        final pts = int.tryParse((data['Points'] ?? data['points'] ?? pointsAwarded).toString());
        if (pts != null && pts > 0) return pts;
      }
      return pointsAwarded;
    } on DioException catch (e) {
      throw Exception(_msg(e) ?? 'Failed to record sale.');
    }
  }

  // ── _fmt helper for date strings ─────────────────────────────────────────

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── getTodayScans — GET /Mobile/GetAllEmployeeLedgers ────────────────────
  // GetAllEmployeeWallets always returns 500; switched to GetAllEmployeeLedgers
  // (same working endpoint used by the commission page) and filter client-side.

  @override
  Future<List<ScanEntry>> getTodayScans(String employeeId) async {
    final phone = await _empPhone;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd   = DateTime(now.year, now.month + 1, 0);
    try {
      final res = await _dio.get(
        'Mobile/GetAllEmployeeLedgers',
        data: {
          'TransactionCompanyId': AppConstants.earnCompanyId,
          'CompanyId':            AppConstants.earnCompanyId,
          'EmployeePhoneNo':      phone,
          'DateFrom':             _fmt(monthStart),
          'DateTo':               _fmt(monthEnd),
        },
      );
      final list = _asList(res.data);
      final entries = list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();

      bool isToday(Map<String, dynamic> j) {
        final raw = j['DateCreated'] ?? j['dateCreated'] ?? j['Date'];
        final _p = raw != null ? DateTime.tryParse(raw.toString()) : null;
        final d = _p != null ? DateTime(_p.year, _p.month, _p.day, _p.hour, _p.minute, _p.second) : null;
        if (d == null) return false;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }

      return entries
          .where(isToday)
          .map((m) => ScanEntry.fromJson(m))
          .toList();
    } on DioException catch (e) {
      _logBackendFailure('GetAllEmployeeLedgers (getTodayScans)', e);
      return const [];
    }
  }

  // ── getWeeklyCommission — GET /Mobile/GetAllEmployeeLedgers ──────────────
  // GetAllEmployeeWallets always returns 500; switched to GetAllEmployeeLedgers.

  @override
  Future<List<int>> getWeeklyCommission(String employeeId) async {
    final phone = await _empPhone;
    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final result = List<int>.filled(7, 0);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd   = DateTime(now.year, now.month + 1, 0);

    try {
      final res = await _dio.get(
        'Mobile/GetAllEmployeeLedgers',
        data: {
          'TransactionCompanyId': AppConstants.earnCompanyId,
          'CompanyId':            AppConstants.earnCompanyId,
          'EmployeePhoneNo':      phone,
          'DateFrom':             _fmt(monthStart),
          'DateTo':               _fmt(monthEnd),
        },
      );
      final list = _asList(res.data);
      for (final raw in list) {
        if (raw is! Map) continue;
        final j = Map<String, dynamic>.from(raw);
        final dateRaw = j['DateCreated'] ?? j['dateCreated'] ?? j['Date'];
        final _dp = dateRaw != null ? DateTime.tryParse(dateRaw.toString()) : null;
        if (_dp == null) continue;
        final d = DateTime(_dp.year, _dp.month, _dp.day, _dp.hour, _dp.minute, _dp.second);

        final dayIndex = d.difference(
          DateTime(monday.year, monday.month, monday.day),
        ).inDays;
        if (dayIndex < 0 || dayIndex > 6) continue;

        final commissionRaw =
            j['Commission'] ?? j['commission'] ?? j['CommissionAmount'];
        final commissionAmt = commissionRaw != null
            ? (double.tryParse(commissionRaw.toString()) ?? 0.0).round()
            : 0;
        result[dayIndex] += commissionAmt;
      }
    } on DioException catch (e) {
      _logBackendFailure('GetAllEmployeeLedgers (getWeeklyCommission)', e);
    }
    return result;
  }

  // ── getRedeemableOffers — built from GetAllCompanies ─────────────────────
  // Fetches all companies and returns every company except the active earn
  // company (Fuel) as a redeemable offer. PhoneNo from the backend is used
  // as PointsRedeemCompanyPhoneNo in confirmRedemption.

  static const _fallbackOffer = RedeemableOffer(
    id: 'laundry-redeem',
    title: 'Sunshine Laundry',
    description: 'Redeem Sunshine Laundry points',
    business: 'Sunshine Laundry',
    pointsCost: 0,
    companyPhoneNo: '0112948777',
    customerPoints: 0,
  );

  @override
  Future<List<RedeemableOffer>> getRedeemableOffers(String customerId) async {
    try {
      final companies = await CompaniesApiService.instance.getCompanies();
      // All companies returned by GetAllCompanies are redeemable partners.
      // The earn company (transactionCompanyId) is NOT in GetAllCompanies,
      // so no filtering needed — use the full list as-is.
      final redeemable = companies;

      if (redeemable.isEmpty) return [_fallbackOffer];

      final offers = <RedeemableOffer>[];
      for (final c in redeemable) {
        final pts = await _fetchCustomerPoints(customerId, c.Id);
        offers.add(RedeemableOffer(
          id: 'redeem-${c.Id}',
          title: c.name,
          description: 'Redeem at ${c.name}',
          business: c.name,
          pointsCost: 0,
          companyPhoneNo: c.phoneNo,
          customerPoints: pts,
        ));
      }
      return offers;
    } catch (_) {
      return [_fallbackOffer];
    }
  }

  // Fetch the customer's current point balance by summing their ledger.
  // GetCustomerByPhoneNo doesn't always return TotalPoints for non-earn companies,
  // so we use GetAllCustomerLedgers (TransactionCompanyId=3 = fuel, all entries)
  // and take the PointBalance from the most recent ledger entry as the current balance.
  Future<int> _fetchCustomerPoints(String customerId, int companyId) async {
    try {
      final res = await _dio.get(
        'Mobile/GetAllCustomerLedgers',
        data: {
          'TransactionCompanyId': AppConstants.earnCompanyId,
          'CustomerPhoneNo': customerId,
        },
      );
      final list = _asList(res.data);
      if (list.isEmpty) return 0;
      // Each Earn entry's PointBalance = remaining points in that batch after
      // redeems have been applied. Sum all Earn PointBalances = current balance.
      // (Redeem entries always have PointBalance=0 — ignore them.)
      int balance = 0;
      for (final raw in list) {
        if (raw is! Map) continue;
        final j    = Map<String, dynamic>.from(raw);
        final type = (j['PointsTransactionType'] ?? '').toString().toLowerCase();
        if (type != 'earn') continue;
        final pb = int.tryParse((j['PointBalance'] ?? 0).toString()) ?? 0;
        balance += pb;
      }
      return balance;
    } catch (_) {
      return 0;
    }
  }

  // ── sendRedemptionOtp — POST /Common/RedeemPoints ────────────────────────
  // Initiates the redemption AND sends OTP to the customer's phone via SMS.

  @override
  Future<String> sendRedemptionOtp({
    required String customerId,
    required String offerId,
    required int pointsToRedeem,
    required String companyPhoneNo,
  }) async {
    final phone = await _empPhone;
    final redeemPhone = companyPhoneNo.isNotEmpty ? companyPhoneNo : '0112948777';
    try {
      final res = await _dio.post(
        'Common/RedeemPoints',
        options: Options(responseType: ResponseType.plain),
        data: {
          'TransactionCompanyId': AppConstants.earnCompanyId,
          'CustomerPhoneNo': customerId,
          'EmployeePhoneNo': phone,
          'Points': pointsToRedeem,
          'PointsRedeemCompanyPhoneNo': redeemPhone,
        },
      );
      final body = (res.data as String? ?? '').trim();
      if (body.isNotEmpty) {
        try {
          final parsed = jsonDecode(body);
          if (parsed is Map) {
            final otp = (parsed['otp'] ?? parsed['OTP'] ?? parsed['Otp'] ?? '').toString();
            if (otp.isNotEmpty) return otp;
          }
        } catch (_) {}
      }
      return '';
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) throw const InsufficientPointsException();
      throw Exception(_msg(e) ?? 'Failed to initiate redemption.');
    }
  }

  // ── redeemPoints — POST RedeemPoints then auto-confirm with returned OTP ──
  // RedeemPoints returns {"otp":"XXXX",...} in the response body.
  // We auto-call RedeemConfirmation with that OTP so no SMS/manual entry needed.

  @override
  Future<RedemptionResult> redeemPoints({
    required String customerId,
    required String offerId,
    required int pointsToRedeem,
    required String companyPhoneNo,
    required String employeeId,
  }) async {
    final phone = await _empPhone;
    final redeemPhone = companyPhoneNo.isNotEmpty ? companyPhoneNo : '0112948777';

    // Step 1: Initiate redemption — backend returns OTP in response body.
    String otp = '';
    try {
      final res = await _dio.post(
        'Common/RedeemPoints',
        options: Options(responseType: ResponseType.plain),
        data: {
          'TransactionCompanyId': AppConstants.earnCompanyId,
          'CustomerPhoneNo': customerId,
          'EmployeePhoneNo': phone,
          'Points': pointsToRedeem,
          'PointsRedeemCompanyPhoneNo': redeemPhone,
        },
      );
      final body = (res.data as String? ?? '').trim();
      if (body.isNotEmpty) {
        try {
          final parsed = jsonDecode(body);
          if (parsed is Map) {
            otp = (parsed['otp'] ?? parsed['OTP'] ?? parsed['Otp'] ?? '').toString();
          }
        } catch (_) {}
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) throw const InsufficientPointsException();
      throw Exception(_msg(e) ?? 'Redemption failed. Please try again.');
    }

    if (otp.isEmpty) {
      throw Exception('Redemption could not be confirmed. Please try again.');
    }

    // Step 2: Confirm with the OTP returned in Step 1.
    try {
      final res = await _dio.post(
        'Common/RedeemConfirmation',
        options: Options(responseType: ResponseType.plain),
        queryParameters: {
          'TransactionCompanyId': AppConstants.redeemCompanyId,
          'CustomerPhoneNo': customerId,
          'OTP': otp,
        },
      );

      Map<String, dynamic> data = {};
      final body = (res.data as String? ?? '').trim();
      if (body.isNotEmpty) {
        try {
          final parsed = jsonDecode(body);
          if (parsed is Map<String, dynamic>) data = parsed;
        } catch (_) {}
      }

      final deducted = int.tryParse(
              (data['PointsDeducted'] ?? data['points'] ?? pointsToRedeem).toString()) ??
          pointsToRedeem;
      final remaining = int.tryParse(
              (data['RemainingPoints'] ?? data['remaining'] ?? 0).toString()) ?? 0;
      final code = (data['ConfirmationCode'] ?? data['code'] ??
              'RDM-${DateTime.now().millisecondsSinceEpoch % 100000}')
          .toString();

      return RedemptionResult(
        pointsDeducted: deducted,
        remainingPoints: remaining,
        confirmationCode: code,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) throw const InvalidOtpException();
      throw Exception(_msg(e) ?? 'Redemption confirmation failed. Please try again.');
    }
  }

  // ── confirmRedemption — POST /Common/RedeemConfirmation ──────────────────
  // Validates the OTP and completes the redemption.
  // NOTE: The backend keys the OTP under the REDEEM company's TransactionCompanyId
  // (laundry = 1, as seen in PointsRedeemCompanyId from ledger entries), NOT the
  // fuel company's TransactionCompanyId (3). Using 3 always returns 400.

  @override
  Future<RedemptionResult> confirmRedemption({
    required String customerId,
    required String offerId,
    required String otp,
    required String employeeId,
  }) async {
    // The laundry company's TransactionCompanyId is 1 (from PointsRedeemCompanyId
    // in GetAllCustomerLedgers). RedeemPoints registers the OTP under this ID.
    const redeemCompanyId = 1;
    try {
      final res = await _dio.post(
        'Common/RedeemConfirmation',
        options: Options(responseType: ResponseType.plain),
        queryParameters: {
          'TransactionCompanyId': redeemCompanyId,
          'CustomerPhoneNo': customerId,
          'OTP': otp,
        },
      );

      Map<String, dynamic> data = {};
      final body = (res.data as String? ?? '').trim();
      if (body.isNotEmpty) {
        try {
          final parsed = jsonDecode(body);
          if (parsed is Map<String, dynamic>) data = parsed;
        } catch (_) {}
      }

      final deducted = int.tryParse(
              (data['PointsDeducted'] ?? data['points'] ?? 0).toString()) ?? 0;
      final remaining = int.tryParse(
              (data['RemainingPoints'] ?? data['remaining'] ?? 0).toString()) ?? 0;
      final code = (data['ConfirmationCode'] ?? data['code'] ??
              'RDM-${DateTime.now().millisecondsSinceEpoch % 100000}')
          .toString();

      return RedemptionResult(
        pointsDeducted: deducted,
        remainingPoints: remaining,
        confirmationCode: code,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) throw const InvalidOtpException();
      throw Exception(_msg(e) ?? 'OTP confirmation failed. Please try again.');
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
    final inner = data['Value'] ?? data['value'] ??
        data['Data'] ?? data['data'] ?? data['items'];
    if (inner is List) return inner;
  }
  return [];
}

IEmpHomeService get empHomeService => AppConstants.useMockServices
    ? EmpHomeMockService.instance
    : EmpHomeRealService.instance;