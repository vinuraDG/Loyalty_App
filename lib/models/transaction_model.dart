enum TransactionType { earned, redeemed }

class TransactionModel {
  final String id;
  final String userId;
  final String business;
  final int points;
  final TransactionType type;
  final DateTime date;
  final String? note;
  final String? billNo;

  const TransactionModel({
    required this.id, required this.userId, required this.business,
    required this.points, required this.type, required this.date, this.note, this.billNo,
  });

  bool get isEarned => type == TransactionType.earned;
  String get displayPoints => isEarned ? '+$points pts' : '-$points pts';
}