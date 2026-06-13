// lib/features/employee/commission/data/emp_commission_api_service.dart

import 'package:loyalty_app/core/constants/app_constants.dart';
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

// ── Real API service (stubs) ──────────────────────────────────────────────────

class EmpCommissionApiService implements IEmpCommissionService {
  EmpCommissionApiService._();
  static final EmpCommissionApiService instance = EmpCommissionApiService._();

  @override
  Future<List<SaleEntry>> getSalesForMonth(String employeeId, String month) async {
    // TODO(backend): GET /employees/$employeeId/sales?month=$month
    throw UnimplementedError();
  }

  @override
  Future<MonthlySummary> getMonthlySummary(String employeeId, String month) async {
    // TODO(backend): GET /employees/$employeeId/commission/summary?month=$month
    throw UnimplementedError();
  }

  @override
  Future<List<String>> getAvailableMonths(String employeeId) async {
    // TODO(backend): GET /employees/$employeeId/sales/months
    throw UnimplementedError();
  }
}

// ── Factory ───────────────────────────────────────────────────────────────────

IEmpCommissionService get empCommissionService => AppConstants.useMockServices
    ? EmpCommissionMockService.instance
    : EmpCommissionApiService.instance;