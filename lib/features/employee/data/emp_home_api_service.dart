// lib/features/employee/data/emp_home_api_service.dart
//
// Contains:
//   • ScannedMember     — member returned after QR scan
//   • ScanEntry         — one completed fuel-sale scan
//   • IEmpHomeService   — interface both mock and real services implement
//   • EmpHomeApiService — real backend stubs (fill in TODOs when ready)
//
// ─── How to go live ───────────────────────────────────────────────────────────
// 1. Set kBaseUrl in lib/data/mock_data.dart.
// 2. Fill in every TODO below.
// 3. In emp_home_provider.dart swap:
//      final _svc = EmpHomeMockService.instance;  // ← remove
//      final _svc = EmpHomeApiService.instance;   // ← add
// ─────────────────────────────────────────────────────────────────────────────

import 'package:loyalty_app/data/mock_data.dart';

// ── Data models ───────────────────────────────────────────────────────────────

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

  factory ScannedMember.fromJson(String userId, Map<String, dynamic> json) {
    return ScannedMember(
      userId: userId,
      name: json['name'] as String,
      memberId: json['memberId'] as String,
      tier: json['tier'] as String,
      currentPoints: json['currentPoints'] as int,
    );
  }
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

  factory ScanEntry.fromJson(Map<String, dynamic> json) {
    return ScanEntry(
      memberName: json['memberName'] as String,
      saleAmount: (json['saleAmount'] as num).toDouble(),
      points: json['points'] as int,
      time: json['time'] as String,
    );
  }
}

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IEmpHomeService {
  /// Look up a loyalty member by the userId decoded from their QR code.
  Future<ScannedMember> getMemberByQr(String userId);

  /// Record a completed fuel sale and award points to the member.
  Future<void> recordFuelSale({
    required String employeeId,
    required String customerId,
    required double saleAmount,
    required int pointsAwarded,
  });

  /// Today's scan history for this employee (newest first).
  Future<List<ScanEntry>> getTodayScans(String employeeId);

  /// Weekly commission chart data in LKR cents (÷100 = LKR).
  /// Index 0 = Monday … index 6 = Sunday.
  Future<List<int>> getWeeklyCommission(String employeeId);
}

// ── Real API service (stubs) ──────────────────────────────────────────────────

class EmpHomeApiService implements IEmpHomeService {
  EmpHomeApiService._();
  static final EmpHomeApiService instance = EmpHomeApiService._();

  @override
  Future<ScannedMember> getMemberByQr(String userId) async {
    // TODO: GET $kBaseUrl/members/$userId
    // Headers → { "Authorization": "Bearer <token>" }
    // 200 → ScannedMember JSON
    // 404 → throw Exception('Member not found.')
    throw UnimplementedError(
        'Backend not connected: GET $kBaseUrl/members/$userId');
  }

  @override
  Future<void> recordFuelSale({
    required String employeeId,
    required String customerId,
    required double saleAmount,
    required int pointsAwarded,
  }) async {
    // TODO: POST $kBaseUrl/fuel-sales
    // Body → { "employeeId", "customerId", "saleAmount", "pointsAwarded" }
    // 201 → Created
    throw UnimplementedError(
        'Backend not connected: POST $kBaseUrl/fuel-sales');
  }

  @override
  Future<List<ScanEntry>> getTodayScans(String employeeId) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/scans/today
    // 200 → [ ScanEntry JSON, … ] newest first
    throw UnimplementedError(
        'Backend not connected: GET $kBaseUrl/employees/$employeeId/scans/today');
  }

  @override
  Future<List<int>> getWeeklyCommission(String employeeId) async {
    // TODO: GET $kBaseUrl/employees/$employeeId/commission/weekly
    // 200 → { "amounts": [1240, 3800, 2650, 4200, 5100, 3200, 800] }
    //        values are LKR cents
    throw UnimplementedError(
        'Backend not connected: GET $kBaseUrl/employees/$employeeId/commission/weekly');
  }
}