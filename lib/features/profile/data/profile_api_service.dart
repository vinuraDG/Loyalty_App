

import 'package:loyalty_app/data/mock_data.dart';

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

abstract class IProfileService {
  /// Fetch current loyalty summary for the profile screen header.
  Future<ProfileSummary> getProfileSummary(String userId);
}

class ProfileApiService implements IProfileService {
  ProfileApiService._();
  static final ProfileApiService instance = ProfileApiService._();

  @override
  Future<ProfileSummary> getProfileSummary(String userId) async {
    // TODO: GET $kBaseUrl/users/$userId/loyalty-summary
    // expect → { "loyaltyTier": "Gold", "totalPoints": 4820, "pointsToNextTier": 0 }
    throw UnimplementedError('Backend not connected yet: GET $kBaseUrl/users/$userId/loyalty-summary');
  }
}