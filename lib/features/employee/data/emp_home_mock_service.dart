import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/employee/data/emp_home_api_service.dart';

// Fallback mock weekly commission map in case mock_data.dart doesn't provide one.
const Map<String, List<int>> kMockEmployeeWeeklyCommission = <String, List<int>>{};
// Fallback mock today scans in case mock_data.dart doesn't provide one.
const List<Map<String, dynamic>> kMockTodayScans = <Map<String, dynamic>>[];
// Fallback scanned member map in case mock_data.dart doesn't provide one.
const Map<String, dynamic> kMockScannedMember = <String, dynamic>{
  'name': 'Guest Member',
  'memberId': '000000',
  'tier': 'Standard',
  'currentPoints': 0,
};

class EmpHomeMockService implements IEmpHomeService {
  EmpHomeMockService._();
  static final EmpHomeMockService instance = EmpHomeMockService._();

  // Session-scoped scan history — starts empty, grows as employee records sales
  final List<ScanEntry> _todayScans = [];

  // Tracks whether seed data has been loaded yet this session
  bool _seedLoaded = false;

  // ── getMemberByQr ─────────────────────────────────────────────────────────
  // kMockScannedMember is Map<String, dynamic> — access each key individually.

  @override
  Future<ScannedMember> getMemberByQr(String userId) async {
    await _delay(ms: 600);
    return ScannedMember(
      userId:        userId,
      name:          kMockScannedMember['name']         as String,
      memberId:      kMockScannedMember['memberId']      as String,
      tier:          kMockScannedMember['tier']          as String,
      currentPoints: kMockScannedMember['currentPoints'] as int,
    );
  }

  // ── recordFuelSale ────────────────────────────────────────────────────────

  @override
  Future<void> recordFuelSale({
    required String employeeId,
    required String customerId,
    required double saleAmount,
    required int pointsAwarded,
  }) async {
    await _delay(ms: 500);
    _todayScans.insert(
      0,
      ScanEntry(
        memberName: kMockScannedMember['name'] as String,
        saleAmount: saleAmount,
        points:     pointsAwarded,
        time:       _timeNow(),
      ),
    );
  }

  // ── getTodayScans ─────────────────────────────────────────────────────────
  // kMockTodayScans is List<Map<String, dynamic>> — iterate and cast each field.

  @override
  Future<List<ScanEntry>> getTodayScans(String employeeId) async {
    await _delay(ms: 300);
    // Load seed data from mock_data.dart only once per session
    if (!_seedLoaded) {
      _seedLoaded = true;
      for (final s in kMockTodayScans) {
        _todayScans.add(ScanEntry(
          memberName: s['memberName'] as String,
          saleAmount: (s['saleAmount'] as num).toDouble(),
          points:     s['points']     as int,
          time:       s['time']       as String,
        ));
      }
    }
    return List.unmodifiable(_todayScans);
  }

  // ── getWeeklyCommission ───────────────────────────────────────────────────
  // kMockEmployeeWeeklyCommission is Map<String, List<int>> — look up by employeeId.

  @override
  Future<List<int>> getWeeklyCommission(String employeeId) async {
    await _delay(ms: 200);
    // Falls back to a zero week if the employeeId has no entry
    return List<int>.from(
      kMockEmployeeWeeklyCommission[employeeId] ?? [0, 0, 0, 0, 0, 0, 0],
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Future<void> _delay({int ms = 400}) =>
      Future.delayed(Duration(milliseconds: ms));

  /// Returns current time as "h:mm AM/PM" without importing flutter/material.
  String _timeNow() {
    final now    = DateTime.now();
    final h      = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m      = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}