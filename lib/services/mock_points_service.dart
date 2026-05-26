import 'dart:math';
import 'package:loyalty_app/models/offer_models.dart';

import '../models/transaction_model.dart';
import 'mock_auth_service.dart';

class MockPointsService {
  MockPointsService._();
  static final MockPointsService instance = MockPointsService._();

  final List<TransactionModel> _transactions = [
    TransactionModel(id:'t1', userId:'cust-001', business:'Fuel Station',
      points:120, type:TransactionType.earned,
      date:DateTime.now().subtract(const Duration(hours:3))),
    TransactionModel(id:'t2', userId:'cust-001', business:'Laundry',
      points:200, type:TransactionType.redeemed,
      date:DateTime.now().subtract(const Duration(days:1))),
    TransactionModel(id:'t3', userId:'cust-001', business:'Gold Shop',
      points:200, type:TransactionType.earned,
      date:DateTime.now().subtract(const Duration(days:3))),
    TransactionModel(id:'t4', userId:'cust-001', business:'Fuel Station',
      points:120, type:TransactionType.earned,
      date:DateTime.now().subtract(const Duration(days:5))),
    TransactionModel(id:'t5', userId:'cust-001', business:'Laundry',
      points:80, type:TransactionType.earned,
      date:DateTime.now().subtract(const Duration(days:7))),
    TransactionModel(id:'t6', userId:'cust-001', business:'Gold Shop',
      points:200, type:TransactionType.earned,
      date:DateTime.now().subtract(const Duration(days:10))),
    TransactionModel(id:'t7', userId:'cust-001', business:'Fuel Station',
      points:120, type:TransactionType.earned,
      date:DateTime.now().subtract(const Duration(days:12))),
  ];

  final List<OfferModel> _offers = const [
    OfferModel(id:'o1', title:'Free wash service', description:'Any 1 load of laundry, any size',
      business:'Laundry', pointsCost:200),
    OfferModel(id:'o2', title:'10% fuel discount', description:'Per fill-up, any fuel type',
      business:'Fuel Station', pointsCost:150),
    OfferModel(id:'o3', title:'Free gold jewellery polish', description:'Professional polish for any gold item',
      business:'Gold Shop', pointsCost:500),
    OfferModel(id:'o4', title:'Premium wash + iron', description:'Full laundry + ironing service',
      business:'Laundry', pointsCost:350),
    OfferModel(id:'o5', title:'Gold valuation service', description:'Free gold item valuation',
      business:'Gold Shop', pointsCost:300),
  ];

  // ── Transactions ──────────────────────────────────────────────

  List<TransactionModel> getForUser(String userId) {
    return _transactions
        .where((t) => t.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionModel> getForUserByBusiness(String userId, String business) {
    return getForUser(userId).where((t) => t.business == business).toList();
  }

  Map<String, int> getEarnedByBusiness(String userId) {
    final txs = getForUser(userId).where((t) => t.isEarned);
    final map = <String, int>{};
    for (final t in txs) {
      map[t.business] = (map[t.business] ?? 0) + t.points;
    }
    return map;
  }

  int getTotalEarned(String userId) => getForUser(userId)
      .where((t) => t.isEarned).fold(0, (sum, t) => sum + t.points);

  int getTotalRedeemed(String userId) => getForUser(userId)
      .where((t) => !t.isEarned).fold(0, (sum, t) => sum + t.points);

  void awardPoints(String userId, String business, int points) {
    _transactions.add(TransactionModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      userId: userId, business: business, points: points,
      type: TransactionType.earned, date: DateTime.now(),
    ));
    final user = MockAuthService.instance.findById(userId);
    if (user != null) {
      MockAuthService.instance.updateUser(
        user.copyWith(totalPoints: user.totalPoints + points),
      );
    }
  }

  // ── Offers ────────────────────────────────────────────────────

  List<OfferModel> getAllOffers() => _offers;

  String redeemOffer(String userId, OfferModel offer) {
    final user = MockAuthService.instance.findById(userId);
    if (user == null) throw Exception('User not found');
    if (user.totalPoints < offer.pointsCost) {
      throw Exception('Not enough points');
    }
    MockAuthService.instance.updateUser(
      user.copyWith(totalPoints: user.totalPoints - offer.pointsCost),
    );
    _transactions.add(TransactionModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      userId: userId, business: offer.business,
      points: offer.pointsCost, type: TransactionType.redeemed,
      date: DateTime.now(), note: offer.title,
    ));
    return _genCode();
  }

  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}