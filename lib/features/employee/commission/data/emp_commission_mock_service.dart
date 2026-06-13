// lib/features/employee/commission/data/emp_commission_mock_service.dart

import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/data/mock_data.dart';
import 'emp_commission_api_service.dart';

class EmpCommissionMockService implements IEmpCommissionService {
  EmpCommissionMockService._();
  static final EmpCommissionMockService instance = EmpCommissionMockService._();

  late final List<SaleEntry> _all = kMockCommissionSales
      .map((m) => SaleEntry.fromJson(
            Map<String, dynamic>.from(m),
            commissionRate: kCommissionRate,
          ))
      .toList();

  @override
  Future<List<SaleEntry>> getSalesForMonth(String employeeId, String month) async {
    await _delay();
    return _all.where((s) => s.month == month).toList();
  }

  @override
  Future<MonthlySummary> getMonthlySummary(String employeeId, String month) async {
    await _delay(ms: 200);
    final sales = _all.where((s) => s.month == month).toList();
    final totalSales = sales.fold<double>(0, (sum, s) => sum + s.saleAmount);
    return MonthlySummary(
      month:            month,
      totalCommission:  totalSales * kCommissionRate,
      totalSales:       totalSales,
      transactionCount: sales.length,
      uniqueCustomers:  sales.map((s) => s.customerName).toSet().length,
    );
  }

  @override
  Future<List<String>> getAvailableMonths(String employeeId) async {
    await _delay(ms: 100);
    final seen = <String>{};
    return kMockCommissionSales
        .map((m) => m['month'] as String)
        .where(seen.add)
        .toList();
  }

  Future<void> _delay({int ms = 400}) =>
      Future.delayed(Duration(milliseconds: ms));
}