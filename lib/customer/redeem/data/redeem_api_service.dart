

import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/models/offer_models.dart';

abstract class IRedeemService {
  /// All available offers a customer can redeem points for.
  Future<List<OfferModel>> getOffers();

  /// Redeem an offer — deducts points, returns a redemption code.
  Future<String> redeemOffer(String userId, OfferModel offer);
}

class RedeemApiService implements IRedeemService {
  RedeemApiService._();
  static final RedeemApiService instance = RedeemApiService._();

  @override
  Future<List<OfferModel>> getOffers() async {
    // TODO: GET $kBaseUrl/offers
    // expect → List of OfferModel JSON
    throw UnimplementedError('Backend not connected yet: GET $kBaseUrl/offers');
  }

  @override
  Future<String> redeemOffer(String userId, OfferModel offer) async {
    // TODO: POST $kBaseUrl/users/$userId/redeem
    // body   → { "offerId": offer.id }
    // expect → { "code": "ABC123" }
    // 400    → throw Exception('Not enough points.')
    throw UnimplementedError('Backend not connected yet: POST $kBaseUrl/users/$userId/redeem');
  }
}