import 'dart:math';
import 'package:loyalty_app/data/mock_data.dart';
import 'emp_home_api_service.dart';

class EmpHomeMockService implements IEmpHomeService {
  EmpHomeMockService._();
  static final EmpHomeMockService instance = EmpHomeMockService._();

  final List<ScanEntry> _todayScans = [];
  bool _seedLoaded = false;
  final Map<String, String> _activeOtps = {};
  final Map<String, int> _pointBalances = {};

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
      phone: (kMockScannedMember['phone'] as String?) ?? '07X XXX XXXX',
    );
  }

  @override
  Future<int> recordFuelSale({
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
        commission: saleAmount * 0.02,
        time: _timeNow(),
      ),
    );
    return pointsAwarded;
  }

  @override
  Future<List<ScanEntry>> getTodayScans(String employeeId) async {
    await _delay(ms: 300);
    _ensureSeedLoaded();
    return List.unmodifiable(_todayScans);
  }

  @override
  Future<List<int>> getWeeklyCommission(String employeeId) async {
    await _delay(ms: 200);
    return List<int>.from(
      kMockEmployeeWeeklyCommission[employeeId] ?? List.filled(7, 0),
    );
  }

  @override
  Future<List<RedeemableOffer>> getRedeemableOffers(String customerId) async {
    await _delay(ms: 400);
    return kMockOffers.map(RedeemableOffer.fromJson).toList();
  }

  @override
  Future<String> sendRedemptionOtp({
    required String customerId,
    required String offerId,
  }) async {
    await _delay(ms: 700);
    final otp = (1000 + Random().nextInt(9000)).toString();
    _activeOtps['$customerId:$offerId'] = otp;
    // ignore: avoid_print
    print('[MOCK] OTP → $otp');
    return otp;
  }

  @override
  Future<RedemptionResult> confirmRedemption({
    required String customerId,
    required String offerId,
    required String otp,
    required String employeeId,
    int pointsToRedeem = 0,
    String companyPhoneNo = '',
  }) async {
    await _delay(ms: 600);
    final expected = _activeOtps['$customerId:$offerId'];
    if (expected == null || otp != expected) throw const InvalidOtpException();

    final cost = pointsToRedeem > 0
        ? pointsToRedeem
        : () {
            final offerData = kMockOffers.firstWhere(
              (o) => o['id'] == offerId,
              orElse: () => <String, dynamic>{'pointsCost': 0},
            );
            return offerData['pointsCost'] as int;
          }();
    final current = _pointBalances[customerId] ??
        (kMockScannedMember['currentPoints'] as int);
    if (current < cost) throw const InsufficientPointsException();

    final remaining = current - cost;
    _pointBalances[customerId] = remaining;
    _activeOtps.remove('$customerId:$offerId');

    return RedemptionResult(
      pointsDeducted: cost,
      remainingPoints: remaining,
      confirmationCode:
          'RDM-${DateTime.now().millisecondsSinceEpoch % 100000}',
    );
  }

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
    return '$h:$m ${now.hour >= 12 ? 'PM' : 'AM'}';
  }
}