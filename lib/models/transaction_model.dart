// transaction_model.dart

enum TransactionType { earned, redeemed, expired }

class TransactionModel {
  final String id;
  final String userId;
  final String business;
  final int points;
  final TransactionType type;
  final DateTime date;
  final String? note;
  final String? billNo;
  final int? pointsOwnCompanyId;
  final int? pointsRedeemCompanyId;
  final String? redeemCompanyName;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.business,
    required this.points,
    required this.type,
    required this.date,
    this.note,
    this.billNo,
    this.pointsOwnCompanyId,
    this.pointsRedeemCompanyId,
    this.redeemCompanyName,
  });

  bool get isEarned   => type == TransactionType.earned;
  bool get isRedeemed => type == TransactionType.redeemed;
  bool get isExpired  => type == TransactionType.expired;

  String get displayPoints {
    switch (type) {
      case TransactionType.earned:   return '+$points pts';
      case TransactionType.redeemed: return '-$points pts';
      case TransactionType.expired:  return '$points pts';
    }
  }
}