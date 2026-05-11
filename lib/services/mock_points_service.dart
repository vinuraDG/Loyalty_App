import 'package:loyalty_app/models/transaction_model.dart';

class MockPointsService {
  MockPointsService._();
  static final instance = MockPointsService._();

  final _transactions = <TransactionModel>[
    TransactionModel(
        id: 't1',
        userId: 'demo-001',
        business: 'Fuel Station',
        points: 120,
        type: TransactionType.earned,
        date: DateTime.now().subtract(const Duration(days: 1))),
    TransactionModel(
        id: 't2',
        userId: 'demo-001',
        business: 'Laundry',
        points: 80,
        type: TransactionType.earned,
        date: DateTime.now().subtract(const Duration(days: 3))),
    TransactionModel(
        id: 't3',
        userId: 'demo-001',
        business: 'Golf',
        points: 200,
        type: TransactionType.earned,
        date: DateTime.now().subtract(const Duration(days: 5))),
  ];
  List<TransactionModel> getForUser(String userId) =>
      _transactions.where((t) => t.userId == userId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  void awardPoints(String userId, String business, int pts) {
    _transactions.add(TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      business: business,
      points: pts,
      type: TransactionType.earned,
      date: DateTime.now(),
    ));
  }
}
