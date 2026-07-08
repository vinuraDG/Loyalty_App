// ── Models ────────────────────────────────────────────────────────────────────

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

class ScanEntry {
  final String memberName;
  final double saleAmount;
  final int points;
  final double commission;
  final String time;

  const ScanEntry({
    required this.memberName,
    required this.saleAmount,
    required this.points,
    required this.commission,
    required this.time,
  });

  factory ScanEntry.fromJson(Map<String, dynamic> j) {
    final rawDate =
        j['DateCreated'] ?? j['dateCreated'] ?? j['CreatedAt'] ?? j['Date'];
    final parsed = rawDate != null
        ? DateTime.tryParse(rawDate.toString())
        : null;
    final txDate = parsed != null
        ? DateTime(parsed.year, parsed.month, parsed.day, parsed.hour, parsed.minute, parsed.second)
        : DateTime.now();

    final h = txDate.hour % 12 == 0 ? 12 : txDate.hour % 12;
    final m = txDate.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m ${txDate.hour >= 12 ? 'PM' : 'AM'}';

    final saleAmount = double.tryParse(
            (j['ValueFrom'] ?? j['saleAmount'] ?? j['Amount'] ?? 0)
                .toString()) ??
        0;
    final commissionRaw = j['Commission'] ?? j['commission'] ?? j['CommissionAmount'];
    final commission = commissionRaw != null
        ? (double.tryParse(commissionRaw.toString()) ?? saleAmount * 0.02)
        : saleAmount * 0.02;

    return ScanEntry(
      memberName: (j['CustomerName'] ??
              j['MemberName'] ??
              j['memberName'] ??
              '')
          .toString(),
      saleAmount: saleAmount,
      points: int.tryParse(
              (j['PointsValue'] ?? j['points'] ?? j['Points'] ?? 0)
                  .toString()) ??
          0,
      commission: commission,
      time: timeStr,
    );
  }
}

class RedeemableOffer {
  final String id;
  final String title;
  final String description;
  final String business;
  final int pointsCost;
  final bool isExpired;
  final String companyPhoneNo;

  const RedeemableOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.business,
    required this.pointsCost,
    this.isExpired = false,
    this.companyPhoneNo = '',
  });

  factory RedeemableOffer.fromJson(Map<String, dynamic> j) => RedeemableOffer(
        id: (j['id'] ?? j['Id'] ?? '').toString(),
        title: (j['title'] ?? j['Title'] ?? '').toString(),
        description: (j['description'] ?? j['Description'] ?? '').toString(),
        business: (j['business'] ?? j['Business'] ?? '').toString(),
        pointsCost:
            int.tryParse((j['pointsCost'] ?? j['Points'] ?? 0).toString()) ??
                0,
        isExpired: j['isExpired'] as bool? ?? false,
      );
}

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

// ── Exceptions ────────────────────────────────────────────────────────────────

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

// ── Interface ─────────────────────────────────────────────────────────────────

abstract interface class IEmpHomeService {
  Future<ScannedMember> getMemberByQr(String userId);
  Future<int> recordFuelSale({
    required String employeeId,
    required String customerId,
    required double saleAmount,
    required int pointsAwarded,
  });
  Future<List<ScanEntry>> getTodayScans(String employeeId);
  Future<List<int>> getWeeklyCommission(String employeeId);
  Future<List<RedeemableOffer>> getRedeemableOffers(String customerId);
  Future<String> sendRedemptionOtp({
    required String customerId,
    required String offerId,
  });
  Future<RedemptionResult> confirmRedemption({
    required String customerId,
    required String offerId,
    required String otp,
    required String employeeId,
    int pointsToRedeem = 0,
    String companyPhoneNo = '',
  });
}