// lib/features/employee/data/emp_commission_api_service.dart
//
// Contains:
//   • SaleEntry         — one fuel sale record
//   • MonthlySummary    — aggregated totals for the summary card
//   • IEmpCommissionService — interface both mock and real services implement
//   • EmpCommissionApiService — real backend stubs (fill in TODOs when ready)
//
// ─── How to go live ───────────────────────────────────────────────────────────
// 1. Set kBaseUrl in lib/data/mock_data.dart to the URL from your backend dev.
// 2. Fill in every TODO below with the real http call.
// 3. In emp_commission_provider.dart swap the service instance:
//      final _svc = EmpCommissionMockService.instance;  // ← remove
//      final _svc = EmpCommissionApiService.instance;   // ← add
// 4. Done — screens need zero changes.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:loyalty_app/data/mock_data.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class SaleEntry {
  final String id;
  final String customerName;
  final double litres;
  final double saleAmount; // LKR
  final double commission; // saleAmount × commissionRate
  final String time;
  final String date;
  final String month; // e.g. "May 2026"

  const SaleEntry({
    required this.id,
    required this.customerName,
    required this.litres,
    required this.saleAmount,
    required this.commission,
    required this.time,
    required this.date,
    required this.month,
  });

  factory SaleEntry.fromJson(Map<String, dynamic> json,
      {double commissionRate = kCommissionRate}) {
    final amount = (json['saleAmount'] as num).toDouble();
    return SaleEntry(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      litres: (json['litres'] as num).toDouble(),
      saleAmount: amount,
      commission: amount * commissionRate,
      time: json['time'] as String,
      date: json['date'] as String,
      month: json['month'] as String,
    );
  }
}

class MonthlySummary {
  final String month;
  final double totalCommission;
  final double totalSales;
  final int transactionCount;
  final int uniqueCustomers;

  const MonthlySummary({
    required this.month,
    required this.totalCommission,
    required this.totalSales,
    required this.transactionCount,
    required this.uniqueCustomers,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      month: json['month'] as String,
      totalCommission: (json['totalCommission'] as num).toDouble(),
      totalSales: (json['totalSales'] as num).toDouble(),
      transactionCount: json['transactionCount'] as int,
      uniqueCustomers: json['uniqueCustomers'] as int,
    );
  }
}

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IEmpCommissionService {
  /// All fuel sales for [employeeId] in [month] (e.g. "May 2026").
  Future<List<SaleEntry>> getSalesForMonth(String employeeId, String month);

  /// Aggregated totals for the summary card.
  Future<MonthlySummary> getMonthlySummary(String employeeId, String month);

  /// Ordered list of available month labels for the filter chips.
  Future<List<String>> getAvailableMonths(String employeeId);
}

// ── Real API service (stubs) ──────────────────────────────────────────────────

class EmpCommissionApiService implements IEmpCommissionService {
  EmpCommissionApiService._();
  static final EmpCommissionApiService instance = EmpCommissionApiService._();

  @override
  Future<List<SaleEntry>> getSalesForMonth(
      String employeeId, String month) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/sales?month=$month
    // Headers → { "Authorization": "Bearer <token>" }
    // 200 → [ SaleEntry JSON, … ]
    // 401 → redirect to login
    throw UnimplementedError(
        'Backend not connected: GET $kBaseUrl/employees/$employeeId/sales');
  }

  @override
  Future<MonthlySummary> getMonthlySummary(
      String employeeId, String month) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/commission/summary?month=$month
    // 200 → MonthlySummary JSON
    throw UnimplementedError(
        'Backend not connected: GET $kBaseUrl/employees/$employeeId/commission/summary');
  }

  @override
  Future<List<String>> getAvailableMonths(String employeeId) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/sales/months
    // 200 → { "months": ["May 2026", "April 2026", …] }
    throw UnimplementedError(
        'Backend not connected: GET $kBaseUrl/employees/$employeeId/sales/months');
  }
}