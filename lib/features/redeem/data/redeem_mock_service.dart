
import 'dart:math';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/auth/data/auth_mock_service.dart';
import 'package:loyalty_app/features/redeem/data/redeem_api_service.dart';
import 'package:loyalty_app/models/offer_models.dart';

class RedeemMockService implements IRedeemService {
  RedeemMockService._();
  static final RedeemMockService instance = RedeemMockService._();

  @override
  Future<List<OfferModel>> getOffers() async {
    await _delay(ms: 400);
    var kMockOffers;
    return kMockOffers
        .map((m) => OfferModel(
              id: m['id'] as String,
              title: m['title'] as String,
              description: m['description'] as String,
              business: m['business'] as String,
              pointsCost: m['pointsCost'] as int,
            ))
        .toList();
  }

  @override
  Future<String> redeemOffer(String userId, OfferModel offer) async {
    await _delay(ms: 600);
    // Check balance via the shared in-memory user store
    final user = AuthMockService.instance.findById(userId);
    if (user == null) throw Exception('User not found.');
    if (user.totalPoints < offer.pointsCost) {
      throw Exception('Not enough points.');
    }
    // Deduct points
    AuthMockService.instance.updateUser(
      user.copyWith(totalPoints: user.totalPoints - offer.pointsCost),
    );
    return _genCode();
  }

  String _genCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<void> _delay({int ms = 400}) =>
      Future.delayed(Duration(milliseconds: ms));
}