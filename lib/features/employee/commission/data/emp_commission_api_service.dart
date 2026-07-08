// lib/features/employee/commission/data/emp_commission_api_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/core/errors/app_exception.dart';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/employee/commission/data/emp_commission_mock_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class SaleEntry {
  final String id;
  final String business;
  final String customerName;
  final String customerId;
  final double litres;
  final double saleAmount;
  final double commission;
  final String time;
  final String date;
  final String month;

  const SaleEntry({
    required this.id,
    required this.business,
    required this.customerName,
    this.customerId = '',
    required this.litres,
    required this.saleAmount,
    required this.commission,
    required this.time,
    required this.date,
    required this.month,
  });

  factory SaleEntry.fromJson(
    Map<String, dynamic> json, {
    double commissionRate = kCommissionRate,
  }) {
    final amount = (json['saleAmount'] as num).toDouble();
    return SaleEntry(
      id:           json['id']           as String,
      business:     json['business']     as String,
      customerName: json['customerName'] as String,
      litres:       (json['litres']      as num).toDouble(),
      saleAmount:   amount,
      commission:   amount * commissionRate,
      time:         json['time']         as String,
      date:         json['date']         as String,
      month:        json['month']        as String,
    );
  }
}

class MonthlySummary {
  final String month;
  final double totalCommission;
  final double totalSales;
  final int    transactionCount;
  final int    uniqueCustomers;

  const MonthlySummary({
    required this.month,
    required this.totalCommission,
    required this.totalSales,
    required this.transactionCount,
    required this.uniqueCustomers,
  });
}

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IEmpCommissionService {
  Future<List<SaleEntry>>  getSalesForMonth(String employeeId, String month);
  Future<MonthlySummary>   getMonthlySummary(String employeeId, String month);
  Future<List<String>>     getAvailableMonths(String employeeId);
}

// ── Real API service ──────────────────────────────────────────────────────────

class EmpCommissionApiService implements IEmpCommissionService {
  EmpCommissionApiService._();
  static final EmpCommissionApiService instance = EmpCommissionApiService._();

  final Dio _dio = ApiClient.instance.dio;

  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Future<String> get _empPhone async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefUserPhone) ?? '';
  }

  // Parse "Jun 2026" → [DateTime start, DateTime end] covering the full month
  List<DateTime> _monthRange(String month) {
    final parts = month.split(' ');
    final monthIdx = _shortMonths.indexOf(parts[0]) + 1;
    final year = int.parse(parts[1]);
    return [
      DateTime(year, monthIdx, 1),
      DateTime(year, monthIdx + 1, 0), // last day of month
    ];
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _timeFromDate(DateTime d) {
    final local = d.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m ${local.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _dateLabelFromDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day} ${_shortMonths[local.month - 1]}';
  }

  @override
  Future<List<SaleEntry>> getSalesForMonth(
      String employeeId, String month) async {
    final phone = await _empPhone;
    if (phone.isEmpty) return [];
    final range = _monthRange(month);
    try {
      final res = await _dio.get(
        'Mobile/GetAllEmployeeLedgers',
        data: {
          'TransactionCompanyId': AppConstants.activeCompanyId,
          'CompanyId':            AppConstants.activeCompanyId,
          'EmployeePhoneNo':      phone,
          'DateFrom':             _fmt(range[0]),
          'DateTo':               _fmt(range[1]),
        },
      );
      final list = _asList(res.data);
      return list.map((entry) {
        final m = entry as Map<String, dynamic>;
        final amount = double.tryParse(
                (m['ValueFrom'] ?? m['Amount'] ?? m['saleAmount'] ?? 0).toString()) ??
            0;
        // Prefer backend's Commission field; fall back to 2% calculation.
        final commissionRaw =
            m['Commission'] ?? m['commission'] ?? m['CommissionAmount'];
        final commission = commissionRaw != null
            ? (double.tryParse(commissionRaw.toString()) ?? amount * kCommissionRate)
            : amount * kCommissionRate;
        final dateStr =
            (m['DateCreated'] ?? m['Date'] ?? m['date'] ?? '').toString();
        final parsed = DateTime.tryParse(dateStr);
        final safeDate = (parsed == null || parsed.year < 2000) ? null : _txDate(parsed);
        return SaleEntry(
          id:           (m['Id']           ?? m['id']           ?? '').toString(),
          business:     (m['CompanyName']   ?? m['MerchantName'] ?? '').toString(),
          customerName: (m['CustomerName']  ?? m['MemberName']   ??
                         m['customerName']  ?? m['FullName']     ??
                         m['Name']          ?? '').toString(),
          customerId:   (m['CustomerPhoneNo'] ?? m['customerPhoneNo'] ??
                         m['PhoneNo']         ?? '').toString(),
          litres:       0.0,
          saleAmount:   amount,
          commission:   commission,
          time:         safeDate != null ? _timeFromDate(safeDate) : '',
          date:         safeDate != null ? _dateLabelFromDate(safeDate) : '',
          month:        month,
        );
      }).toList();
    } on DioException catch (e) {
      assert(() {
        debugPrint(
          '[EmpCommission] GetAllEmployeeLedgers failed: '
          'status=${e.response?.statusCode} msg=${dioErrorMessage(e)}',
        );
        return true;
      }());
      rethrow;
    }
  }

  // FIX (2026-06-30): Previously this attempted to call
  // `Common/CalculateCommission` with date-range params (TransactionCompanyId,
  // EmployeePhoneNo, DateFrom, DateTo) before falling back to a sales-derived
  // total. That endpoint is confirmed (per emp_home_real_service.dart's
  // diagnosis) to be a single-DOCUMENT commission lookup — it requires
  // `DocumentNo` + `CustomerPhoneNo` and has no concept of a date range, so
  // the call always failed with a 400 ("DocumentNo field is required",
  // "CustomerPhoneNo field is required"). It was wrapped in a silent
  // try/catch, so the failure never surfaced, it just added a guaranteed-bad
  // network round trip and log noise on every commission page load.
  //
  // Removed entirely. The monthly summary is now derived purely from
  // `getSalesForMonth`, which is the only real data source this had anyway
  // once the dedicated endpoint attempt failed.
  @override
  Future<MonthlySummary> getMonthlySummary(
      String employeeId, String month) async {
    final sales = await getSalesForMonth(employeeId, month);
    final totalSales =
        sales.fold<double>(0, (sum, s) => sum + s.saleAmount);
    final totalCommission =
        sales.fold<double>(0, (sum, s) => sum + s.commission);

    return MonthlySummary(
      month:            month,
      totalCommission:  totalCommission,
      totalSales:       totalSales,
      transactionCount: sales.length,
      uniqueCustomers:  _countUniqueCustomers(sales),
    );
  }

  @override
  Future<List<String>> getAvailableMonths(String employeeId) async {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return '${_shortMonths[d.month - 1]} ${d.year}';
    });
  }
}

int _countUniqueCustomers(List<SaleEntry> sales) =>
    sales.map((s) => s.customerId).where((s) => s.isNotEmpty).toSet().length;

DateTime _txDate(DateTime? parsed) {
  if (parsed == null || parsed.year < 2000) return DateTime.now();
  final now = DateTime.now();
  if (parsed.year > now.year) {
    return DateTime(parsed.year - 1, parsed.month, parsed.day,
        parsed.hour, parsed.minute, parsed.second);
  }
  return DateTime(parsed.year, parsed.month, parsed.day, parsed.hour, parsed.minute, parsed.second);
}

// Backend wraps lists in {"Value": [...], "StatusCode": 200}
List _asList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final inner = data['Value'] ?? data['value'] ??
        data['Data'] ?? data['data'] ?? data['items'];
    if (inner is List) return inner;
  }
  return [];
}

// ── Factory ───────────────────────────────────────────────────────────────────

IEmpCommissionService get empCommissionService => AppConstants.useMockServices
    ? EmpCommissionMockService.instance
    : EmpCommissionApiService.instance;