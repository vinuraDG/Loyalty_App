// lib/features/employee/data/emp_home_mock_service.dart
//
// Mock implementation of IEmpHomeService.
// All seed data comes from lib/data/mock_data.dart — no raw data lives here.
// Swap to EmpHomeApiService.instance when the backend is ready.

import 'dart:math';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/employee/data/emp_home_api_service.dart';

class EmpHomeMockService implements IEmpHomeService {
  EmpHomeMockService._();
  static final EmpHomeMockService instance = EmpHomeMockService._();

  // ── Session state ─────────────────────────────────────────────────────────

  /// In-memory scan list seeded from mock_data on first access.
  final List<ScanEntry> _todayScans = [];
  bool _seedLoaded = false;

  /// Active OTPs keyed by "customerId:offerId".
  final Map<String, String> _activeOtps = {};

  /// In-memory point balances — starts from kMockScannedMember and mutates
  /// as redemptions are confirmed.
  final Map<String, int> _pointBalances = {};

  // ── getMemberByQr ─────────────────────────────────────────────────────────

  @override
  Future<ScannedMember> getMemberByQr(String userId) async {
    await _delay(ms: 600);
    final basePoints = kMockScannedMember['currentPoints'] as int;
    _pointBalances.putIfAbsent(userId, () => basePoints);

    return ScannedMember(
      userId: userId,
      name: kMockScannedMember['name'] as String,
      memberId: kMockScannedMember['memberId'] as String,
      tier: kMockScannedMember['tier'] as String,
      currentPoints: _pointBalances[userId]!,
      phone: kMockScannedMember['phone'] as String? ?? '07X XXX XXXX',
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
    _ensureSeedLoaded();

    _pointBalances.update(
      customerId,
      (v) => v + pointsAwarded,
      ifAbsent: () => pointsAwarded,
    );

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
      kMockEmployeeWeeklyCommission[employeeId] ?? List.filled(7, 0),
    );
  }

  // ── getRedeemableOffers ───────────────────────────────────────────────────
  //
  // Returns ALL offers (active + expired) so the summary screen can show
  // expired point totals per company alongside active totals.
  // The UI layer splits them via offer.isExpired.

  @override
  Future<List<RedeemableOffer>> getRedeemableOffers(String customerId) async {
    await _delay(ms: 400);
    return kMockOffers.map(RedeemableOffer.fromJson).toList();
  }

  // ── sendRedemptionOtp ─────────────────────────────────────────────────────

  @override
  Future<String> sendRedemptionOtp({
    required String customerId,
    required String offerId,
  }) async {
    await _delay(ms: 700);
    final otp = (1000 + Random().nextInt(9000)).toString();
    _activeOtps['$customerId:$offerId'] = otp;
    // ignore: avoid_print
    print('[MOCK] OTP for $customerId → $otp  (simulated SMS sent)');
    return otp;
  }

  // ── confirmRedemption ─────────────────────────────────────────────────────

  @override
  Future<RedemptionResult> confirmRedemption({
    required String customerId,
    required String offerId,
    required String otp,
    required String employeeId,
  }) async {
    await _delay(ms: 600);

    final expectedOtp = _activeOtps['$customerId:$offerId'];
    if (expectedOtp == null || otp != expectedOtp) {
      throw const InvalidOtpException();
    }

    final offerData = kMockOffers.firstWhere(
      (o) => o['id'] == offerId,
      orElse: () => throw Exception('Offer not found'),
    );
    final cost = offerData['pointsCost'] as int;
    final currentPoints =
        _pointBalances[customerId] ?? (kMockScannedMember['currentPoints'] as int);

    if (currentPoints < cost) {
      throw const InsufficientPointsException();
    }

    final remaining = currentPoints - cost;
    _pointBalances[customerId] = remaining;
    _activeOtps.remove('$customerId:$offerId');

    return RedemptionResult(
      pointsDeducted: cost,
      remainingPoints: remaining,
      confirmationCode: 'RDM-${DateTime.now().millisecondsSinceEpoch % 100000}',
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

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}