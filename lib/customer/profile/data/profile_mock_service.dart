import 'package:loyalty_app/features/auth/data/auth_mock_service.dart';
import 'package:loyalty_app/customer/profile/data/profile_api_service.dart';

class ProfileMockService implements IProfileService {
  ProfileMockService._();
  static final ProfileMockService instance = ProfileMockService._();

  @override
  Future<ProfileSummary> getProfileSummary(String userId) async {
    await _delay();
    final user = AuthMockService.instance.findByIdSync(userId);
    if (user == null) throw Exception('User not found: $userId');
    return ProfileSummary(
      loyaltyTier:      user.loyaltyTier,
      totalPoints:      user.totalPoints,
      pointsToNextTier: user.pointsToNextTier,
    );
  }

  Future<void> _delay({int ms = 300}) =>
      Future.delayed(Duration(milliseconds: ms));
}