// lib/features/employee/data/emp_commission_mock_service.dart
//
// Mock implementation of IEmpCommissionService.
// All data is sourced from lib/data/mock_data.dart — no data lives here.
// Swap to EmpCommissionApiService.instance when the backend is ready.

import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/employee/data/emp_commission_api_service.dart';

class EmpCommissionMockService implements IEmpCommissionService {
  EmpCommissionMockService._();
  static final EmpCommissionMockService instance =
      EmpCommissionMockService._();

  // Build typed list once from mock_data.dart on first access.
  late final List<SaleEntry> _allSales = kMockCommissionSales
      .map((m) => SaleEntry.fromJson(
            Map<String, dynamic>.from(m),
            commissionRate: kCommissionRate,
          ))
      .toList();

  @override
  Future<List<SaleEntry>> getSalesForMonth(
      String employeeId, String month) async {
    await _delay();
    return _allSales
        .where((s) => s.month == month)
        .toList();
  }

  @override
  Future<MonthlySummary> getMonthlySummary(
      String employeeId, String month) async {
    await _delay(ms: 200);
    final sales = _allSales.where((s) => s.month == month).toList();
    final totalSales =
        sales.fold<double>(0, (sum, s) => sum + s.saleAmount);
    return MonthlySummary(
      month: month,
      totalCommission: totalSales * kCommissionRate,
      totalSales: totalSales,
      transactionCount: sales.length,
      uniqueCustomers: sales.map((s) => s.customerName).toSet().length,
    );
  }

  @override
  Future<List<String>> getAvailableMonths(String employeeId) async {
    await _delay(ms: 100);
    // Preserve insertion order — same order as kMockCommissionSales.
    final seen = <String>{};
    return kMockCommissionSales
        .map((m) => m['month'] as String)
        .where(seen.add)
        .toList();
  }

  Future<void> _delay({int ms = 400}) =>
      Future.delayed(Duration(milliseconds: ms));
}