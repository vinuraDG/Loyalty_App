

import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/employee/data/emp_commission_api_service.dart';

// If mock_data.dart does not provide kMockCommissionSales, provide an
// empty fallback to avoid analyzer errors. Real data should come from
// lib/data/mock_data.dart.
const List<Map<String, Object?>> kMockCommissionSales = const [];
// Fallback commission rate for mock service. Real rate should come from
// shared configuration when using the real API/service.
const double kCommissionRate = 0.05;

class EmpCommissionMockService implements IEmpCommissionService {
  EmpCommissionMockService._();
  static final EmpCommissionMockService instance =
      EmpCommissionMockService._();

  // Build SaleEntry list once from mock_data.dart
  late final List<SaleEntry> _allSales = kMockCommissionSales
      .map((m) => SaleEntry(
            id: m['id'] as String,
            customerName: m['customerName'] as String,
            litres: (m['litres'] as num).toDouble(),
            saleAmount: (m['saleAmount'] as num).toDouble(),
            commission:
                (m['saleAmount'] as num).toDouble() * kCommissionRate,
            time: m['time'] as String,
            date: m['date'] as String,
            month: m['month'] as String,
          ))
      .toList();

  @override
  Future<List<SaleEntry>> getSalesForMonth(
      String employeeId, String month) async {
    await _delay();
    return _allSales.where((s) => s.month == month).toList();
  }

  @override
  Future<MonthlySummary> getMonthlySummary(
      String employeeId, String month) async {
    await _delay(ms: 200);
    final sales = _allSales.where((s) => s.month == month).toList();
    final totalSales =
        sales.fold<double>(0, (sum, s) => sum + s.saleAmount);
    final totalCommission = totalSales * kCommissionRate;
    final uniqueCustomers =
        sales.map((s) => s.customerName).toSet().length;

    return MonthlySummary(
      month: month,
      totalCommission: totalCommission,
      totalSales: totalSales,
      transactionCount: sales.length,
      uniqueCustomers: uniqueCustomers,
    );
  }

  @override
  Future<List<String>> getAvailableMonths(String employeeId) async {
    await _delay(ms: 100);
    // Derive unique months in original order from mock_data.dart
    final seen = <String>{};
    return kMockCommissionSales
        .map((m) => m['month'] as String)
        .where((month) => seen.add(month))
        .toList();
  }

  Future<void> _delay({int ms = 400}) =>
      Future.delayed(Duration(milliseconds: ms));
}