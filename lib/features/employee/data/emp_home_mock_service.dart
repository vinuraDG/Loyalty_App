// lib/features/employee/data/emp_home_mock_service.dart
//
// Mock implementation of IEmpHomeService.
// All data is sourced from lib/data/mock_data.dart — no data lives here.
// Swap to EmpHomeApiService.instance when the backend is ready.

import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/employee/data/emp_home_api_service.dart';

class EmpHomeMockService implements IEmpHomeService {
  EmpHomeMockService._();
  static final EmpHomeMockService instance = EmpHomeMockService._();

  // Session-scoped scan history — seeded once from mock_data.dart,
  // then extended in-memory as the employee records new sales.
  final List<ScanEntry> _todayScans = [];
  bool _seedLoaded = false;

  // ── getMemberByQr ─────────────────────────────────────────────────────────

  @override
  Future<ScannedMember> getMemberByQr(String userId) async {
    await _delay(ms: 600);
    // kMockScannedMember is the single demo member returned for any QR scan.
    return ScannedMember.fromJson(userId, kMockScannedMember);
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
    _ensureSeedLoaded();
    _todayScans.insert(
      0,
      ScanEntry(
        memberName: kMockScannedMember['name'] as String,
        saleAmount: saleAmount,
        points: pointsAwarded,
        time: _timeNow(),
      ),
    );
  }

  // ── getTodayScans ─────────────────────────────────────────────────────────

  @override
  Future<List<ScanEntry>> getTodayScans(String employeeId) async {
    await _delay(ms: 300);
    _ensureSeedLoaded();
    return List.unmodifiable(_todayScans);
  }

  // ── getWeeklyCommission ───────────────────────────────────────────────────

  @override
  Future<List<int>> getWeeklyCommission(String employeeId) async {
    await _delay(ms: 200);
    return List<int>.from(
      kMockEmployeeWeeklyCommission[employeeId] ?? [0, 0, 0, 0, 0, 0, 0],
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  void _ensureSeedLoaded() {
    if (_seedLoaded) return;
    _seedLoaded = true;
    for (final m in kMockTodayScans) {
      _todayScans.add(ScanEntry.fromJson(Map<String, dynamic>.from(m)));
    }
  }

  Future<void> _delay({int ms = 400}) =>
      Future.delayed(Duration(milliseconds: ms));

  /// Returns current time as "h:mm AM/PM" without importing flutter/material.
  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}