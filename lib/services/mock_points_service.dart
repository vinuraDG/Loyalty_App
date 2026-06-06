// lib/services/mock_points_service.dart
// Used by: PointsScreen (home tab), OffersScreen, home screen chart.
// This is the app-wide singleton service — NOT the IPointsService
// implementation used by PointsHistoryScreen (that's PointsMockService).

import 'dart:math';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/models/offer_models.dart';
import 'package:loyalty_app/models/transaction_model.dart';
import 'package:loyalty_app/services/mock_auth_service.dart';

class MockPointsService {
  MockPointsService._();
  static final MockPointsService instance = MockPointsService._();

  // Seeded from mock_data.dart — single source of truth for demo transactions.
  final List<TransactionModel> _transactions = kMockTransactions.map((m) {
    final Duration ago = m.containsKey('hoursAgo')
        ? Duration(hours: m['hoursAgo'] as int)
        : Duration(days: (m['daysAgo'] as int? ?? 0));

    // isExpired takes priority: an expired row is its own type even though
    // isEarned is also true in the raw data (it was a real earn event that
    // has since lapsed).
    final bool expired = (m['isExpired'] as bool? ?? false);
    final bool earned  = (m['isEarned']  as bool? ?? false);
    final TransactionType txType = expired
        ? TransactionType.expired
        : earned
            ? TransactionType.earned
            : TransactionType.redeemed;

    return TransactionModel(
      id:       m['id']       as String,
      userId:   m['userId']   as String,
      business: m['business'] as String,
      points:   m['points']   as int,
      type:     txType,
      date:     DateTime.now().subtract(ago),
      note:     m['note']     as String?,
      billNo:   m['billNo']   as String?,
    );
  }).toList();

  // Seeded from mock_data.dart — single source of truth for demo offers.
  final List<OfferModel> _offers = kMockOffers
      .map((m) => OfferModel(
            id:          m['id']          as String,
            title:       m['title']       as String,
            description: m['description'] as String,
            business:    m['business']    as String,
            pointsCost:  m['pointsCost']  as int,
          ))
      .toList();

  // ── Transactions ──────────────────────────────────────────────────────────

  List<TransactionModel> getForUser(String userId) {
    return _transactions
        .where((t) => t.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionModel> getForUserByBusiness(
      String userId, String business) {
    return getForUser(userId)
        .where((t) => t.business == business)
        .toList();
  }

  /// Points earned per business (excludes expired and redeemed).
  Map<String, int> getEarnedByBusiness(String userId) {
    final map = <String, int>{};
    for (final t in getForUser(userId).where((t) => t.isEarned)) {
      map[t.business] = (map[t.business] ?? 0) + t.points;
    }
    return map;
  }

  int getTotalEarned(String userId) => getForUser(userId)
      .where((t) => t.isEarned)
      .fold(0, (sum, t) => sum + t.points);

  int getTotalRedeemed(String userId) => getForUser(userId)
      .where((t) => t.isRedeemed)
      .fold(0, (sum, t) => sum + t.points);

  int getTotalExpired(String userId) => getForUser(userId)
      .where((t) => t.isExpired)
      .fold(0, (sum, t) => sum + t.points);

  void awardPoints(String userId, String business, int points) {
    _transactions.add(TransactionModel(
      id:       '${DateTime.now().millisecondsSinceEpoch}',
      userId:   userId,
      business: business,
      points:   points,
      type:     TransactionType.earned,
      date:     DateTime.now(),
    ));
    final user = MockAuthService.instance.findById(userId);
    if (user != null) {
      MockAuthService.instance.updateUser(
        user.copyWith(totalPoints: user.totalPoints + points),
      );
    }
  }

  // ── Offers ────────────────────────────────────────────────────────────────

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
      id:       '${DateTime.now().millisecondsSinceEpoch}',
      userId:   userId,
      business: offer.business,
      points:   offer.pointsCost,
      type:     TransactionType.redeemed,
      date:     DateTime.now(),
      note:     offer.title,
    ));
    return _genCode();
  }

  // ── Weekly points (home screen chart) ────────────────────────────────────

  /// Returns the 7-day point totals [Mon…Sun] for the given user.
  /// Falls back to all-zeros if the user has no entry in kMockWeeklyPoints.
  List<int> getWeeklyPoints(String userId) {
    return List<int>.from(
      kMockWeeklyPoints[userId] ?? List.filled(7, 0),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}