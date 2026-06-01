
import 'package:loyalty_app/data/mock_data.dart';

// ── Data model ────────────────────────────────────────────────────────────────

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
}

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IEmpCommissionService {
  /// All sales for a given employee and month label (e.g. "May 2026").
  Future<List<SaleEntry>> getSalesForMonth(String employeeId, String month);

  /// Monthly summary (totals, counts) for the summary card.
  Future<MonthlySummary> getMonthlySummary(String employeeId, String month);

  /// List of available month labels to show in the filter chips.
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
    // expect → List of SaleEntry JSON
    throw UnimplementedError(
        'Backend not connected yet: GET $kBaseUrl/employees/$employeeId/sales');
  }

  @override
  Future<MonthlySummary> getMonthlySummary(
      String employeeId, String month) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/commission/summary?month=$month
    // expect → MonthlySummary JSON
    throw UnimplementedError(
        'Backend not connected yet: GET $kBaseUrl/employees/$employeeId/commission/summary');
  }

  @override
  Future<List<String>> getAvailableMonths(String employeeId) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/sales/months
    // expect → { "months": ["May 2026", "April 2026", "March 2026"] }
    throw UnimplementedError(
        'Backend not connected yet: GET $kBaseUrl/employees/$employeeId/sales/months');
  }
}