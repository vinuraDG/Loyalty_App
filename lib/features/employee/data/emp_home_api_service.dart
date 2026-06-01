
import 'package:loyalty_app/data/mock_data.dart';

class ScannedMember {
  final String userId;
  final String name;
  final String memberId;
  final String tier;
  final int currentPoints;

  const ScannedMember({
    required this.userId,
    required this.name,
    required this.memberId,
    required this.tier,
    required this.currentPoints,
  });
}

class ScanEntry {
  final String memberName;
  final double saleAmount;
  final int points;
  final String time;

  const ScanEntry({
    required this.memberName,
    required this.saleAmount,
    required this.points,
    required this.time,
  });
}

abstract class IEmpHomeService {
  /// Look up a member by userId decoded from their QR code.
  Future<ScannedMember> getMemberByQr(String userId);

  /// Record a fuel sale and award points to the member.
  Future<void> recordFuelSale({
    required String employeeId,
    required String customerId,
    required double saleAmount,
    required int pointsAwarded,
  });

  /// Today's scan history for this employee.
  Future<List<ScanEntry>> getTodayScans(String employeeId);

  /// Weekly commission chart data (Mon–Sun) for this employee.
  Future<List<int>> getWeeklyCommission(String employeeId);
}

class EmpHomeApiService implements IEmpHomeService {
  EmpHomeApiService._();
  static final EmpHomeApiService instance = EmpHomeApiService._();

  @override
  Future<ScannedMember> getMemberByQr(String userId) async {
    // TODO: GET $kBaseUrl/members/$userId
    // expect → ScannedMember JSON
    // 404    → throw Exception('Member not found.')
    throw UnimplementedError('Backend not connected yet: GET $kBaseUrl/members/$userId');
  }

  @override
  Future<void> recordFuelSale({
    required String employeeId,
    required String customerId,
    required double saleAmount,
    required int pointsAwarded,
  }) async {
    // TODO: POST $kBaseUrl/fuel-sales
    // body   → { "employeeId", "customerId", "saleAmount", "pointsAwarded" }
    // expect → 201 Created
    throw UnimplementedError('Backend not connected yet: POST $kBaseUrl/fuel-sales');
  }

  @override
  Future<List<ScanEntry>> getTodayScans(String employeeId) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/scans/today
    // expect → List of ScanEntry JSON
    throw UnimplementedError('Backend not connected yet: GET $kBaseUrl/employees/$employeeId/scans/today');
  }

  @override
  Future<List<int>> getWeeklyCommission(String employeeId) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/commission/weekly
    // expect → { "amounts": [1240, 3800, 2650, 4200, 5100, 3200, 800] }
    throw UnimplementedError('Backend not connected yet: GET $kBaseUrl/employees/$employeeId/commission/weekly');
  }
}