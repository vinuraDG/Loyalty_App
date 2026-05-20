// ════════════════════════════════════════════════════════════════
//  mock_fuel_service.dart
//  Standalone mock data layer for fuel sales & commission
// ════════════════════════════════════════════════════════════════

class FuelSale {
  final String id;
  final String customerId;
  final String customerName;
  final double liters;
  final double pricePerLiter;
  final DateTime date;
  final String employeeId;

  const FuelSale({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.liters,
    required this.pricePerLiter,
    required this.date,
    required this.employeeId,
  });

  /// Total sale amount = liters × price per liter
  double get totalAmount => liters * pricePerLiter;

  /// Commission = 0.5 % of total sale amount
  double get commission => totalAmount * 0.005;
}

class MockFuelService {
  MockFuelService._();
  static final MockFuelService instance = MockFuelService._();

  // ── Seed data ────────────────────────────────────────────────
  final List<FuelSale> _sales = [
    // ── May 2025 ─────────────────────────────────────────────
    FuelSale(
      id: 'fs-001', customerId: 'cust-001', customerName: 'Kasun Perera',
      liters: 30, pricePerLiter: 340,
      date: DateTime(2025, 5, 1, 9, 15), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-002', customerId: 'cust-002', customerName: 'Amara Fernando',
      liters: 15, pricePerLiter: 340,
      date: DateTime(2025, 5, 2, 11, 40), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-003', customerId: 'cust-003', customerName: 'Ruwan Jayasuriya',
      liters: 50, pricePerLiter: 340,
      date: DateTime(2025, 5, 5, 14, 0), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-004', customerId: 'cust-004', customerName: 'Dilani Wickrama',
      liters: 20, pricePerLiter: 340,
      date: DateTime(2025, 5, 8, 8, 30), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-005', customerId: 'cust-005', customerName: 'Thilak Bandara',
      liters: 45, pricePerLiter: 340,
      date: DateTime(2025, 5, 10, 16, 20), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-006', customerId: 'cust-001', customerName: 'Kasun Perera',
      liters: 25, pricePerLiter: 340,
      date: DateTime(2025, 5, 12, 10, 0), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-007', customerId: 'cust-006', customerName: 'Nadee Rathnayake',
      liters: 38, pricePerLiter: 340,
      date: DateTime(2025, 5, 14, 13, 45), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-008', customerId: 'cust-007', customerName: 'Pradeep Silva',
      liters: 12, pricePerLiter: 340,
      date: DateTime(2025, 5, 16, 9, 0), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-009', customerId: 'cust-008', customerName: 'Chamari Perera',
      liters: 60, pricePerLiter: 340,
      date: DateTime(2025, 5, 18, 15, 10), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-010', customerId: 'cust-002', customerName: 'Amara Fernando',
      liters: 22, pricePerLiter: 340,
      date: DateTime(2025, 5, 19, 11, 30), employeeId: 'emp-001',
    ),

    // ── April 2025 ────────────────────────────────────────────
    FuelSale(
      id: 'fs-011', customerId: 'cust-003', customerName: 'Ruwan Jayasuriya',
      liters: 40, pricePerLiter: 330,
      date: DateTime(2025, 4, 3, 10, 0), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-012', customerId: 'cust-004', customerName: 'Dilani Wickrama',
      liters: 18, pricePerLiter: 330,
      date: DateTime(2025, 4, 7, 14, 30), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-013', customerId: 'cust-005', customerName: 'Thilak Bandara',
      liters: 55, pricePerLiter: 330,
      date: DateTime(2025, 4, 12, 9, 45), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-014', customerId: 'cust-001', customerName: 'Kasun Perera',
      liters: 28, pricePerLiter: 330,
      date: DateTime(2025, 4, 18, 16, 0), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-015', customerId: 'cust-006', customerName: 'Nadee Rathnayake',
      liters: 33, pricePerLiter: 330,
      date: DateTime(2025, 4, 25, 11, 15), employeeId: 'emp-001',
    ),

    // ── March 2025 ────────────────────────────────────────────
    FuelSale(
      id: 'fs-016', customerId: 'cust-007', customerName: 'Pradeep Silva',
      liters: 42, pricePerLiter: 325,
      date: DateTime(2025, 3, 5, 8, 0), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-017', customerId: 'cust-008', customerName: 'Chamari Perera',
      liters: 16, pricePerLiter: 325,
      date: DateTime(2025, 3, 11, 13, 30), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-018', customerId: 'cust-001', customerName: 'Kasun Perera',
      liters: 50, pricePerLiter: 325,
      date: DateTime(2025, 3, 19, 10, 45), employeeId: 'emp-001',
    ),
    FuelSale(
      id: 'fs-019', customerId: 'cust-002', customerName: 'Amara Fernando',
      liters: 30, pricePerLiter: 325,
      date: DateTime(2025, 3, 24, 15, 0), employeeId: 'emp-001',
    ),
  ];

  // ── Queries ──────────────────────────────────────────────────

  /// All sales for an employee, newest first.
  List<FuelSale> getForEmployee(String employeeId) =>
      _sales.where((s) => s.employeeId == employeeId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Sales for a specific month.
  List<FuelSale> getForMonth(String employeeId, int year, int month) =>
      getForEmployee(employeeId)
          .where((s) => s.date.year == year && s.date.month == month)
          .toList();

  /// Total commission earned in a month.
  double totalCommissionForMonth(String employeeId, int year, int month) =>
      getForMonth(employeeId, year, month)
          .fold(0.0, (sum, s) => sum + s.commission);

  /// Total liters dispensed in a month.
  double totalLitersForMonth(String employeeId, int year, int month) =>
      getForMonth(employeeId, year, month)
          .fold(0.0, (sum, s) => sum + s.liters);

  /// Add a new sale record (called after QR confirmation).
  void addSale(FuelSale sale) => _sales.add(sale);
}