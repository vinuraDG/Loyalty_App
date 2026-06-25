// lib/features/employee/commission/data/emp_commission_api_service.dart

import 'package:dio/dio.dart';
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
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _dateLabelFromDate(DateTime d) =>
      '${d.day} ${_shortMonths[d.month - 1]}';

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
          'TransactionCompanyId': AppConstants.transactionCompanyId,
          'CompanyId':            AppConstants.transactionCompanyId,
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
        final dateStr =
            (m['DateExpire'] ?? m['Date'] ?? m['date'] ?? '').toString();
        final parsed = DateTime.tryParse(dateStr);
        final safeDate =
            (parsed == null || parsed.year < 2000) ? null : parsed;
        return SaleEntry(
          id:           (m['Id']           ?? m['id']           ?? '').toString(),
          business:     (m['CompanyName']   ?? m['MerchantName'] ?? '').toString(),
          customerName: (m['CustomerName']  ?? m['MemberName']   ??
                         m['customerName']  ?? '').toString(),
          litres:       0.0,
          saleAmount:   amount,
          commission:   amount * kCommissionRate,
          time:         safeDate != null ? _timeFromDate(safeDate) : '',
          date:         safeDate != null ? _dateLabelFromDate(safeDate) : '',
          month:        month,
        );
      }).toList();
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  @override
  Future<MonthlySummary> getMonthlySummary(
      String employeeId, String month) async {
    final phone = await _empPhone;
    final range = _monthRange(month);
    double totalCommission = 0;

    // Try dedicated commission endpoint first
    try {
      final res = await _dio.get(
        'Common/CalculateCommission',
        data: {
          'TransactionCompanyId': AppConstants.transactionCompanyId,
          'EmployeePhoneNo':      phone,
          'DateFrom':             _fmt(range[0]),
          'DateTo':               _fmt(range[1]),
        },
      );
      final data = res.data;
      totalCommission = double.tryParse(
            (data is Map
                    ? (data['Value'] ?? data['commission'] ?? data['Commission'] ?? 0)
                    : (data is num ? data : 0))
                .toString()) ??
          0;
    } on DioException catch (_) {}

    final sales = await getSalesForMonth(employeeId, month);
    final totalSales =
        sales.fold<double>(0, (sum, s) => sum + s.saleAmount);

    // Fallback: derive from sales when endpoint returns 0
    if (totalCommission == 0 && totalSales > 0) {
      totalCommission = totalSales * kCommissionRate;
    }

    return MonthlySummary(
      month:            month,
      totalCommission:  totalCommission,
      totalSales:       totalSales,
      transactionCount: sales.length,
      uniqueCustomers:  sales
          .map((s) => s.customerName)
          .where((n) => n.isNotEmpty)
          .toSet()
          .length,
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

// Backend wraps lists in {"Value": [...], "StatusCode": 200}
List _asList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final inner = data['Value'] ?? data['value'] ?? data['data'] ?? data['items'];
    if (inner is List) return inner;
  }
  return [];
}

// ── Factory ───────────────────────────────────────────────────────────────────

IEmpCommissionService get empCommissionService => AppConstants.useMockServices
    ? EmpCommissionMockService.instance
    : EmpCommissionApiService.instance;
