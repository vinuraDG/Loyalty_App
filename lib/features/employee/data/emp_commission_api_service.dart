// lib/features/employee/data/emp_commission_api_service.dart

import 'package:loyalty_app/data/mock_data.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class SaleEntry {
  final String id;
  final String business;   // 'Fuel' | 'Laundry' | 'Gold Shop'
  final String customerName;
  final double litres;
  final double saleAmount;
  final double commission;
  final String time;
  final String date;
  final String month;      // e.g. "Jun 2026"

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
      business:     json['business']     as String,   // ← reads the field properly
      customerName: json['customerName'] as String,
      litres:       (json['litres']      as num).toDouble(),
      saleAmount:   amount,
      commission:   amount * commissionRate,
      time:         json['time']         as String,
      date:         json['date']         as String,
      month:        json['month']        as String,
    );
  }
  // NOTE: NO stub getter here — business is a real final field above
}

// ── MonthlySummary ────────────────────────────────────────────────────────────

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

  factory MonthlySummary.fromJson(Map<String, dynamic> json) => MonthlySummary(
        month:            json['month']            as String,
        totalCommission:  (json['totalCommission'] as num).toDouble(),
        totalSales:       (json['totalSales']      as num).toDouble(),
        transactionCount: json['transactionCount'] as int,
        uniqueCustomers:  json['uniqueCustomers']  as int,
      );
}

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IEmpCommissionService {
  Future<List<SaleEntry>>  getSalesForMonth(String employeeId, String month);
  Future<MonthlySummary>   getMonthlySummary(String employeeId, String month);
  Future<List<String>>     getAvailableMonths(String employeeId);
}

// ── Real API service (stubs — fill in when backend is ready) ──────────────────

class EmpCommissionApiService implements IEmpCommissionService {
  EmpCommissionApiService._();
  static final EmpCommissionApiService instance = EmpCommissionApiService._();

  @override
  Future<List<SaleEntry>> getSalesForMonth(
      String employeeId, String month) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/sales?month=$month
    throw UnimplementedError(
        'Backend not connected: GET $kBaseUrl/employees/$employeeId/sales');
  }

  @override
  Future<MonthlySummary> getMonthlySummary(
      String employeeId, String month) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/commission/summary?month=$month
    throw UnimplementedError(
        'Backend not connected: GET $kBaseUrl/employees/$employeeId/commission/summary');
  }

  @override
  Future<List<String>> getAvailableMonths(String employeeId) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/sales/months
    throw UnimplementedError(
        'Backend not connected: GET $kBaseUrl/employees/$employeeId/sales/months');
  }
}