import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/core/errors/app_exception.dart';
import 'package:loyalty_app/customer/profile/data/profile_mock_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class ProfileSummary {
  final String loyaltyTier;
  final int totalPoints;
  final int pointsToNextTier;

  const ProfileSummary({
    required this.loyaltyTier,
    required this.totalPoints,
    required this.pointsToNextTier,
  });
}

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IProfileService {
  Future<ProfileSummary> getProfileSummary(String userId);
}

// ── Real API service ──────────────────────────────────────────────────────────

class ProfileApiService implements IProfileService {
  ProfileApiService._();
  static final ProfileApiService instance = ProfileApiService._();

  final Dio _dio = ApiClient.instance.dio;

  @override
  Future<ProfileSummary> getProfileSummary(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    try {
      final res = await _dio.get('Common/GetCustomerByPhoneNo',
          queryParameters: {'PhoneNo': phone});
      final data = (res.data['customer'] ?? res.data['data'] ?? res.data)
          as Map<String, dynamic>;
      final points =
          int.tryParse((data['TotalPoints'] ?? data['totalPoints'] ?? 0).toString()) ?? 0;
      return ProfileSummary(
        loyaltyTier: _tierFromPoints(points),
        totalPoints: points,
        pointsToNextTier: _nextTier(points),
      );
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  String _tierFromPoints(int p) {
    if (p >= 5000) return 'Platinum';
    if (p >= 2000) return 'Gold';
    if (p >= 500)  return 'Silver';
    return 'Bronze';
  }

  int _nextTier(int p) {
    if (p >= 5000) return 0;
    if (p >= 2000) return 5000 - p;
    if (p >= 500)  return 2000 - p;
    return 500 - p;
  }
}

// ── Service factory ───────────────────────────────────────────────────────────

IProfileService get profileService => AppConstants.useMockServices
    ? ProfileMockService.instance
    : ProfileApiService.instance;