// lib/features/employee/home/data/emp_home_real_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/data/companies_api_service.dart';
import 'package:loyalty_app/models/company_model.dart';
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
          'TransactionCompanyId': AppConstants.activeCompanyId,
          'CustomerPhoneNo': userId,
        },
      );
      if (res.data == null || res.data is! Map) {
        throw Exception('Member not found.');
      }
      final data = res.data as Map<String, dynamic>;
      final phone = (data['PhoneNo'] ?? data['phoneNo'] ?? userId).toString();

      // ledger TC=0 → sum PointBalance from Earn entries = Total Points (left card).
      int points = 0;
      int ownCompanyId = 0;
      try {
        final ledgerRes = await _dio.get(
          'Mobile/GetAllCustomerLedgers',
          data: {'TransactionCompanyId': 0, 'CustomerPhoneNo': phone},
        );
        for (final raw in _asList(ledgerRes.data)) {
          if (raw is! Map) continue;
          final j = Map<String, dynamic>.from(raw);
          final type = (j['PointsTransactionType'] ?? '').toString().toLowerCase();
          if (type != 'earn') continue;
          points += (double.tryParse((j['PointBalance'] ?? 0).toString()) ?? 0).round();
          if (ownCompanyId == 0) {
            ownCompanyId = int.tryParse((j['PointsOwnCompanyId'] ?? 0).toString()) ?? 0;
          }
        }
      } catch (_) {}

      // Fall back to wallet → ledger per TC if TC=0 returned nothing.
      if (points <= 0) {
        try {
          final wallets = await _fetchCustomerWallets(phone);
          for (final w in wallets) {
            final tcId = int.tryParse(
                (w['TransactionCompanyId'] ?? w['transactionCompanyId'] ?? 0).toString()) ?? 0;
            if (tcId <= 0) continue;
            try {
              final ledgerRes = await _dio.get(
                'Mobile/GetAllCustomerLedgers',
                data: {'TransactionCompanyId': tcId, 'CustomerPhoneNo': phone},
              );
              for (final raw in _asList(ledgerRes.data)) {
                if (raw is! Map) continue;
                final j = Map<String, dynamic>.from(raw);
                final type = (j['PointsTransactionType'] ?? '').toString().toLowerCase();
                if (type != 'earn') continue;
                points += (double.tryParse((j['PointBalance'] ?? 0).toString()) ?? 0).round();
                if (ownCompanyId == 0) {
                  ownCompanyId = int.tryParse((j['PointsOwnCompanyId'] ?? 0).toString()) ?? 0;
                }
              }
            } catch (_) {}
          }
        } catch (_) {}
      }

      // Resolve earn company display name (try transactionCompanyId match first).
      String earnCompanyName = '';
      if (ownCompanyId > 0) {
        try {
          final companies = await CompaniesApiService.instance.getCompanies();
          final match = companies.where(
              (c) => c.transactionCompanyId == ownCompanyId || c.Id == ownCompanyId);
          if (match.isNotEmpty) earnCompanyName = match.first.displayName;
        } catch (_) {}
      }

      return ScannedMember(
        userId: phone,
        name: '${data['FirstName'] ?? ''} ${data['LastName'] ?? ''}'.trim(),
        memberId: phone,
        tier: _tierFromPoints(points),
        currentPoints: points,
        phone: phone,
        earnCompanyName: earnCompanyName,
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
    String customerName = '',
  }) async {
    final phone = await _empPhone;
    final callTime = DateTime.now().toUtc();

    // Resolve earn TC independently — never read activeCompanyId here because
    // getRedeemableOffers sets it to the ledger-based empId (may be wrong for
    // earn). GetCompanyById responses don't include TransactionCompanyId (always
    // 0), so we use the company Id directly. We iterate ALL companies and keep
    // overwriting the candidate so the LAST company with a non-empty
    // RedeemCompanies list wins. City Oil (Id=3) is last in GetAllCompanies and
    // has RedeemCompanies pointing to the redeem destinations, so earnTcId=3.
    // We do NOT write to activeCompanyId so the redeem flow is not affected.
    int earnTcId = 0;
    try {
      final companies = await CompaniesApiService.instance.getCompanies();
      int baseIdFallback = 0;
      for (final c in companies) {
        final baseId = c.Id > 0 ? c.Id : 0;
        if (baseId <= 0) continue;
        if (baseIdFallback == 0) baseIdFallback = baseId;
        try {
          final cr = await _dio.get('Mobile/GetCompanyById',
              queryParameters: {'CompanyId': baseId});
          final val = cr.data is Map ? cr.data['Value'] : null;
          if (val is Map) {
            final realTc = int.tryParse(
                (val['TransactionCompanyId'] ?? val['transactionCompanyId'] ?? 0).toString()) ?? 0;
            if (realTc > 0) {
              earnTcId = realTc; // overwrite — last TC > 0 wins
            } else {
              final raw = val['RedeemCompanies'];
              if (raw is List && raw.isNotEmpty) {
                earnTcId = baseId; // overwrite — last company with RedeemCompanies wins
              }
            }
          }
        } catch (_) {}
      }
      if (earnTcId == 0 && baseIdFallback > 0) {
        earnTcId = baseIdFallback;
      }
    } catch (_) {}

    try {
      final res = await _dio.post(
        'Common/EarnPoints',
        data: {
          'TransactionCompanyId': earnTcId,
          'CustomerPhoneNo': customerId,
          'EmployeePhoneNo': phone,
          'Amount': saleAmount,
          'DocumentNo': documentNo,
        },
      );
      final data = res.data;

      // Cache customer name keyed by exact server DateCreated.
      // EarnPoints response has no DateCreated, so we fetch today's employee
      // ledger immediately after and find the new entry by amount match
      // (picks the most-recent entry with Amount == saleAmount).
      // Fallback: client UTC call time with ±120 s fuzzy match in getTodayScans.
      if (customerName.isNotEmpty) {
        String dateKey = '';
        if (data is Map) {
          final raw = data['DateCreated'] ?? data['dateCreated'];
          if (raw != null) dateKey = raw.toString();
        }
        if (dateKey.isEmpty) {
          try {
            final now2 = DateTime.now();
            final lr = await _dio.get(
              'Mobile/GetAllEmployeeLedgers',
              data: {
                'TransactionCompanyId': AppConstants.activeCompanyId,
                'CompanyId': AppConstants.activeCompanyId,
                'EmployeePhoneNo': phone,
                'DateFrom': _fmt(DateTime(now2.year, now2.month, now2.day)),
                'DateTo': _fmt(now2),
              },
            );
            DateTime? bestTime;
            for (final raw in _asList(lr.data)) {
              if (raw is! Map) continue;
              final j = Map<String, dynamic>.from(raw);
              final amt = double.tryParse((j['Amount'] ?? 0).toString()) ?? 0;
              if ((amt - saleAmount).abs() > 0.01) continue;
              final dc = (j['DateCreated'] ?? j['dateCreated'] ?? '').toString();
              if (dc.isEmpty) continue;
              final t = DateTime.tryParse(dc);
              if (t == null) continue;
              if (bestTime == null || t.isAfter(bestTime)) {
                bestTime = t;
                dateKey = dc;
              }
            }
          } catch (_) {}
        }
        if (dateKey.isEmpty) dateKey = callTime.toIso8601String();
        await _saveScanName(dateKey, customerName);
      }

      if (data is Map) {
        final pts = (double.tryParse((data['Points'] ?? data['points'] ?? pointsAwarded).toString()) ?? 0).round();
        if (pts > 0) return pts;
      }
      return pointsAwarded;
    } on DioException catch (e) {
      throw Exception(_msg(e) ?? 'Failed to record sale.');
    }
  }

  // ── Scan name cache (SharedPreferences, keyed by UTC DateCreated) ─────────

  static String _scanNamesKey() {
    final d = DateTime.now();
    return 'scan_names_${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveScanName(String dateKey, String customerName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _scanNamesKey();
      final raw = prefs.getString(key);
      final map = raw != null
          ? Map<String, String>.from(
              (jsonDecode(raw) as Map).cast<String, String>())
          : <String, String>{};
      map[dateKey] = customerName;
      await prefs.setString(key, jsonEncode(map));
    } catch (_) {}
  }

  Future<Map<String, String>> _loadScanNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scanNamesKey());
      if (raw == null) return {};
      return Map<String, String>.from(
          (jsonDecode(raw) as Map).cast<String, String>());
    } catch (_) {
      return {};
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
          'TransactionCompanyId': 0,
          'CompanyId':            0,
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

      final todayEntries = entries.where(isToday).toList();

      // Load names saved at scan time (keyed by UTC DateCreated).
      final scanNames = await _loadScanNames();

      // Inject customer name: exact match on DateCreated, then fuzzy ±2 min.
      for (final j in todayEntries) {
        final dc = (j['DateCreated'] ?? j['dateCreated'] ?? '').toString().trim();
        if (dc.isEmpty) continue;

        String? name = scanNames[dc];
        if (name == null || name.isEmpty) {
          final entryTime = DateTime.tryParse(dc);
          if (entryTime != null) {
            for (final e in scanNames.entries) {
              final t = DateTime.tryParse(e.key);
              if (t != null &&
                  entryTime.difference(t).abs().inSeconds <= 600) {
                name = e.value;
                break;
              }
            }
          }
        }

        if (name != null && name.isNotEmpty) j['CustomerName'] = name;
      }

      return todayEntries.map((m) => ScanEntry.fromJson(m)).toList();
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
          'TransactionCompanyId': 0,
          'CompanyId':            0,
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

  // ── getRedeemableOffers — driven by employee's assigned company ──────────
  // Flow: employee company Id → GetAllCompanies → find that company →
  //   RedeemCompanies array → destination companies to show.
  // Customer balance comes from their wallet for the employee's company TC.
  //
  // GetEmployeeByPhoneNo returns TransactionCompanyId=0, so we read
  // PointsOwnCompanyId from the employee's own ledger as the company Id
  // (same fallback used in recordFuelSale). Result is cached in activeCompanyId.

  @override
  Future<List<RedeemableOffer>> getRedeemableOffers(String customerId) async {
    try {
      final companiesFuture = CompaniesApiService.instance.getCompanies();
      final walletsFuture   = _fetchCustomerWallets(customerId);
      final companies = await companiesFuture;
      final wallets   = await walletsFuture;

      if (companies.isEmpty) return [];

      final companyById = <int, CompanyModel>{for (final c in companies) c.Id: c};

      // Build wallet map: TC → PointsBalance.
      final walletBalanceByTc = <int, int>{};
      for (final w in wallets) {
        final tcId = int.tryParse(
            (w['TransactionCompanyId'] ?? w['transactionCompanyId'] ?? 0).toString()) ?? 0;
        if (tcId <= 0) continue;
        walletBalanceByTc[tcId] = (double.tryParse(
            (w['PointsBalance'] ?? w['pointsBalance'] ?? 0).toString()) ?? 0).round();
      }

      // Resolve the earn company Id from the customer's wallet TransactionCompanyId.
      // The wallet TC tells us which company's points the customer holds, so we read
      // that company's RedeemCompanies to know where they can redeem.
      // This is correct even when the employee ledger still has old TC=1 entries.
      int empId = 0;
      for (final w in wallets) {
        final tcId = int.tryParse(
            (w['TransactionCompanyId'] ?? w['transactionCompanyId'] ?? 0).toString()) ?? 0;
        if (tcId > 0) {
          empId = tcId;
          break;
        }
      }

      // Get employee's company RedeemCompanies via GetCompanyById.
      // GetAllCompanies may not include RedeemCompanies, so we fetch explicitly.
      List<int> redeemIds = [];
      if (empId > 0) {
        try {
          final cr = await _dio.get('Mobile/GetCompanyById',
              queryParameters: {'CompanyId': empId});
          final val = cr.data is Map ? cr.data['Value'] : null;
          if (val is Map) {
            final raw = val['RedeemCompanies'];
            if (raw is List) {
              redeemIds = raw
                  .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
                  .where((e) => e > 0)
                  .toList();
            }
          }
        } catch (_) {}

        // Fall back to RedeemCompanies from GetAllCompanies if GetCompanyById gave nothing.
        if (redeemIds.isEmpty) {
          redeemIds = companyById[empId]?.redeemCompanies ?? [];
        }
      }

      // Build one card per redeem company with that company's wallet balance.
      // Each card shows walletBalanceByTc[redeemId] — the customer's points
      // at that specific company. companyId = empId (earn TC) for RedeemPoints.
      if (redeemIds.isNotEmpty) {
        final offers = <RedeemableOffer>[];
        for (final redeemId in redeemIds) {
          final dest = companyById[redeemId];
          if (dest == null) continue;
          final customerBalance = walletBalanceByTc[redeemId] ?? 0;
          offers.add(RedeemableOffer(
            id: 'redeem-$redeemId',
            title: dest.name,
            description: 'Redeem at ${dest.displayName}',
            business: dest.displayName,
            pointsCost: 0,
            companyPhoneNo: dest.phoneNo,
            customerPoints: customerBalance,
            companyId: empId, // earn TC — used in RedeemPoints
          ));
        }
        if (offers.isNotEmpty) return offers;
      }

      // Fallback: show all non-earn companies with total wallet balance.
      final fallbackPts = walletBalanceByTc.values.fold<int>(0, (a, b) => a + b);
      final fallbackTc  = walletBalanceByTc.keys.isNotEmpty
          ? walletBalanceByTc.keys.first : 0;
      return companies
          .where((c) => !c.isEarnOnly)
          .map((c) => RedeemableOffer(
                id: 'redeem-${c.Id}',
                title: c.name,
                description: 'Redeem at ${c.displayName}',
                business: c.displayName,
                pointsCost: 0,
                companyPhoneNo: c.phoneNo,
                customerPoints: fallbackPts,
                companyId: fallbackTc,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Calls GetAllCustomerWallets with TransactionCompanyId:0 to get all wallets.
  Future<List<Map<String, dynamic>>> _fetchCustomerWallets(String customerId) async {
    try {
      final res = await _dio.get(
        'Common/GetAllCustomerWallets',
        data: {
          'TransactionCompanyId': 0,
          'CustomerPhoneNo': customerId,
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

  // Fallback: sum PointBalance across all Earn ledger entries.
  Future<int> _fetchCustomerPoints(String customerId) async {
    try {
      final res = await _dio.get(
        'Mobile/GetAllCustomerLedgers',
        data: {
          'TransactionCompanyId': AppConstants.transactionCompanyId,
          'CustomerPhoneNo': customerId,
        },
      );
      final list = _asList(res.data);
      int balance = 0;
      for (final raw in list) {
        if (raw is! Map) continue;
        final j    = Map<String, dynamic>.from(raw);
        final type = (j['PointsTransactionType'] ?? '').toString().toLowerCase();
        if (type != 'earn') continue;
        balance += (double.tryParse((j['PointBalance'] ?? 0).toString()) ?? 0).round();
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
    int companyId = 0,
  }) async {
    final phone = await _empPhone;
    final redeemPhone = companyPhoneNo.isNotEmpty ? companyPhoneNo : '0112948777';
    // companyId = wallet TC ID (set from offer.companyId in getRedeemableOffers).
    final tcId = companyId > 0 ? companyId : AppConstants.activeCompanyId;
    try {
      final res = await _dio.post(
        'Common/RedeemPoints',
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: {
          'TransactionCompanyId': tcId,
          'CustomerPhoneNo': customerId,
          'EmployeePhoneNo': phone,
          'Points': pointsToRedeem,
          'PointsRedeemCompanyPhoneNo': redeemPhone,
        },
      );
      return _extractOtp(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) throw const InsufficientPointsException();
      throw Exception(_msg(e) ?? 'Failed to initiate redemption.');
    }
  }

  /// Extracts the OTP from a RedeemPoints response body.
  /// Backend may return: plain digits ("1234"), JSON map ({"otp":"1234"}),
  /// or JSON string ("\"1234\"").
  String _extractOtp(dynamic rawBody) {
    final body = (rawBody as String? ?? '').trim();
    if (body.isEmpty) return '';
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map) {
        final otp = (parsed['otp'] ?? parsed['OTP'] ?? parsed['Otp'] ??
                parsed['Token'] ?? parsed['token'] ?? '')
            .toString()
            .trim();
        if (otp.isNotEmpty) return otp;
      }
      if (parsed is String && parsed.trim().isNotEmpty) return parsed.trim();
    } catch (_) {}
    // Plain text — accept any sequence of digits (e.g. "1234")
    final digitsOnly = body.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isNotEmpty) return digitsOnly;
    return body;
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
    int companyId = 0,
  }) async {
    final phone = await _empPhone;
    final redeemPhone = companyPhoneNo.isNotEmpty ? companyPhoneNo : '0112948777';
    final tcId = companyId;

    // Step 1: Initiate redemption — backend returns OTP in response body.
    String otp = '';
    try {
      final res = await _dio.post(
        'Common/RedeemPoints',
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: {
          'TransactionCompanyId': tcId,
          'CustomerPhoneNo': customerId,
          'EmployeePhoneNo': phone,
          'Points': pointsToRedeem,
          'PointsRedeemCompanyPhoneNo': redeemPhone,
        },
      );
      otp = _extractOtp(res.data);
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
          'TransactionCompanyId': tcId,
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
    int companyId = 0,
  }) async {
    final tcId = companyId;
    try {
      final res = await _dio.post(
        'Common/RedeemConfirmation',
        options: Options(responseType: ResponseType.plain),
        queryParameters: {
          'TransactionCompanyId': tcId,
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