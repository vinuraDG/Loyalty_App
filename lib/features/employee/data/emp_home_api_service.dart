// lib/features/employee/data/emp_home_api_service.dart
//
// Models + service interface for the employee home feature.
// The mock implementation lives in emp_home_mock_service.dart.
// The real implementation lives in emp_home_real_service.dart (to be created).

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class ScannedMember {
  final String userId;
  final String name;
  final String memberId;
  final String tier;
  final int currentPoints;
  final String phone;

  const ScannedMember({
    required this.userId,
    required this.name,
    required this.memberId,
    required this.tier,
    required this.currentPoints,
    required this.phone,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

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

  factory ScanEntry.fromJson(Map<String, dynamic> j) => ScanEntry(
        memberName: j['memberName'] as String,
        saleAmount: (j['saleAmount'] as num).toDouble(),
        points: j['points'] as int,
        time: j['time'] as String,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class RedeemableOffer {
  final String id;
  final String title;
  final String description;
  final String business;
  final int pointsCost;

  /// True when the offer's validity window has passed.
  /// Expired offers are shown in the summary but cannot be redeemed.
  final bool isExpired;

  const RedeemableOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.business,
    required this.pointsCost,
    this.isExpired = false,
  });

  factory RedeemableOffer.fromJson(Map<String, dynamic> j) => RedeemableOffer(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        business: j['business'] as String,
        pointsCost: j['pointsCost'] as int,
        isExpired: j['isExpired'] as bool? ?? false,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class RedemptionResult {
  final int pointsDeducted;
  final int remainingPoints;
  final String confirmationCode;

  const RedemptionResult({
    required this.pointsDeducted,
    required this.remainingPoints,
    required this.confirmationCode,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Exceptions
// ─────────────────────────────────────────────────────────────────────────────

class InvalidOtpException implements Exception {
  const InvalidOtpException();
  String get message => 'The OTP entered is incorrect. Please try again.';
  @override
  String toString() => message;
}

class InsufficientPointsException implements Exception {
  const InsufficientPointsException();
  String get message => 'Not enough points to redeem this offer.';
  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────────────────────
// Service interface
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class IEmpHomeService {
  /// Looks up the loyalty member by their QR payload (userId).
  Future<ScannedMember> getMemberByQr(String userId);

  /// Records a completed fuel sale and awards points to the customer.
  Future<void> recordFuelSale({
    required String employeeId,
    required String customerId,
    required double saleAmount,
    required int pointsAwarded,
  });

  /// Returns today's scan entries for the given employee.
  Future<List<ScanEntry>> getTodayScans(String employeeId);

  /// Returns 7 daily commission amounts (Mon–Sun) for the current week.
  Future<List<int>> getWeeklyCommission(String employeeId);

  /// Returns all offers for the customer — both active and expired.
  /// Filtering by isExpired is done in the UI layer.
  Future<List<RedeemableOffer>> getRedeemableOffers(String customerId);

  /// Sends a redemption OTP to the customer's phone.
  /// Returns the OTP string in mock mode (ignored in production).
  Future<String> sendRedemptionOtp({
    required String customerId,
    required String offerId,
  });

  /// Validates the OTP and deducts points if correct.
  Future<RedemptionResult> confirmRedemption({
    required String customerId,
    required String offerId,
    required String otp,
    required String employeeId,
  });
}