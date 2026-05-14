import 'package:loyalty_app/models/offer_models.dart';
import '../models/transaction_model.dart';


class MockPointsService {
  MockPointsService._();
  static final instance = MockPointsService._();

  // Factory constructor so callers can use MockPointsService() or .instance
  factory MockPointsService() => instance;

  final List<TransactionModel> _transactions = [
    TransactionModel(
      id: 't1', userId: 'demo-001', business: 'Fuel Station',
      points: 120, type: TransactionType.earned,
      date: DateTime.now().subtract(const Duration(days: 1))),
    TransactionModel(
      id: 't2', userId: 'demo-001', business: 'Laundry',
      points: 80, type: TransactionType.earned,
      date: DateTime.now().subtract(const Duration(days: 3))),
    TransactionModel(
      id: 't3', userId: 'demo-001', business: 'Golf',
      points: 200, type: TransactionType.earned,
      date: DateTime.now().subtract(const Duration(days: 5))),
    TransactionModel(
      id: 't4', userId: 'demo-001', business: 'Fuel Station',
      points: 500, type: TransactionType.redeemed,
      date: DateTime.now().subtract(const Duration(days: 7))),
  ];

  final List<OfferModel> _offers = const [
    OfferModel(id: 'o1', title: 'Free Car Wash',    description: 'One free wash at Fuel Station', pointsCost: 300,  isFeatured: true,  business: 'Fuel Station'),
    OfferModel(id: 'o2', title: '10% Off Laundry',  description: 'Discount on next laundry visit',  pointsCost: 150,  isFeatured: false, business: 'Laundry'),
    OfferModel(id: 'o3', title: 'Free Golf Round',  description: 'One complimentary golf round',     pointsCost: 1000, isFeatured: true,  business: 'Golf'),
    OfferModel(id: 'o4', title: '50L Fuel Voucher',  description: 'Redeem 50 litres of fuel',        pointsCost: 800,  isFeatured: false, business: 'Fuel Station'),
  ];

  List<TransactionModel> getTransactions(String userId) =>
      _transactions.where((t) => t.userId == userId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  // Alias used by HomeScreen
  List<TransactionModel> getForUser(String userId) => getTransactions(userId);

  List<OfferModel> getOffers() => _offers;

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