import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/models/offer_models.dart';
import 'package:loyalty_app/customer/redeem/data/redeem_mock_service.dart';

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IRedeemService {
  Future<List<OfferModel>> getOffers();
  Future<String> redeemOffer(String userId, OfferModel offer);
}

// ── Real API service ──────────────────────────────────────────────────────────

class RedeemApiService implements IRedeemService {
  RedeemApiService._();
  static final RedeemApiService instance = RedeemApiService._();

  final Dio _dio = ApiClient.instance.dio;

  @override
  Future<List<OfferModel>> getOffers() async {
    // No offers endpoint in Swagger yet — return empty list
    // When backend adds it: GET /Common/GetOffers or similar
    return [];
  }

  @override
  Future<String> redeemOffer(String userId, OfferModel offer) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    try {
      final res = await _dio.post('Common/RedeemPoints', data: {
        'TransactionCompanyId': AppConstants.transactionCompanyId,
        'CustomerPhoneNo': phone,
        'EmployeePhoneNo': '',
        'PointsRedeemCompany': offer.business,
        'DocumentNo': '',
        'Amount': offer.pointsCost.toDouble(),
        'Points': offer.pointsCost,
      });
      final data = res.data;
      if (data is Map && (data['code'] ?? data['Code']) != null) {
        return (data['code'] ?? data['Code']).toString();
      }
      return 'REDEEMED';
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['message'] ?? e.response!.data['Message'])
          : null;
      throw Exception(msg ?? 'Redeem failed. Please try again.');
    }
  }
}

// ── Service factory ───────────────────────────────────────────────────────────

IRedeemService get redeemService => AppConstants.useMockServices
    ? RedeemMockService.instance
    : RedeemApiService.instance;