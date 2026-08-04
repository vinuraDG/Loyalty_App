// transaction_model.dart

import 'package:loyalty_app/core/utils/formatters.dart';

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
  final String?   redeemCompanyName;
  final String?   businessFullName;
  final String?   redeemCompanyFullName;
  // Backend's remaining balance for this Earn batch (PointBalance field).
  // Always set for Earn entries; 0 for Redeem/Expired.
  final int       pointBalance;
  // Non-null on Earn entries whose DateExpire is in the future.
  final int?      expiringBalance;
  final DateTime? expiryDate;

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
    this.businessFullName,
    this.redeemCompanyFullName,
    this.pointBalance = 0,
    this.expiringBalance,
    this.expiryDate,
  });

  bool get isEarned   => type == TransactionType.earned;
  bool get isRedeemed => type == TransactionType.redeemed;
  bool get isExpired  => type == TransactionType.expired;

  String get displayPoints {
    final fmt = formatPoints(points);
    switch (type) {
      case TransactionType.earned:   return '+$fmt pts';
      case TransactionType.redeemed: return '-$fmt pts';
      case TransactionType.expired:  return '$fmt pts';
    }
  }
}