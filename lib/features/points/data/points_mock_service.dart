import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/points/data/points_api_service.dart';
import 'package:loyalty_app/models/transaction_model.dart';

class PointsMockService implements IPointsService {
  PointsMockService._();
  static final PointsMockService instance = PointsMockService._();

  // Built once from mock_data.dart (a flat List), then appended during session.
  final List<TransactionModel> _transactions = kMockTransactions.map((m) {
    final Duration ago = m.containsKey('hoursAgo')
        ? Duration(hours: m['hoursAgo'] as int)
        : Duration(days: (m['daysAgo'] as int? ?? 0));
    return TransactionModel(
      id:       m['id']       as String,
      userId:   m['userId']   as String,
      business: m['business'] as String,
      points:   m['points']   as int,
      type:     (m['isEarned'] as bool)
                    ? TransactionType.earned
                    : TransactionType.redeemed,
      date:     DateTime.now().subtract(ago),
      note:     m['note']     as String?,
    );
  }).toList();

  // ── IPointsService ────────────────────────────────────────────────────────

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    await _delay();
    return _transactions
        .where((t) => t.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<TransactionModel>> getTransactionsByBusiness(
      String userId, String business) async {
    final all = await getTransactions(userId);
    return all.where((t) => t.business == business).toList();
  }

  @override
  Future<void> awardPoints(String userId, String business, int points) async {
    await _delay(ms: 600);
    _transactions.add(TransactionModel(
      id:       '${DateTime.now().millisecondsSinceEpoch}',
      userId:   userId,
      business: business,
      points:   points,
      type:     TransactionType.earned,
      date:     DateTime.now(),
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _delay({int ms = 400}) =>
      Future.delayed(Duration(milliseconds: ms));
}