import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/data/customer_ledger_service.dart';
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

  @override
  Future<ProfileSummary> getProfileSummary(String userId) async {
    // FIX: guard against empty phone before firing a request
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    if (phone.isEmpty) {
      throw Exception('No authenticated user found. Please log in again.');
    }

    try {
      final entries = await CustomerLedgerService.instance.fetchLedger(phone);

      // Sum PointBalance for every Earn entry — backend pre-calculates each
      // batch's remaining balance after redemptions, so no app-side arithmetic.
      int points = 0;
      for (final e in entries) {
        if (e is! Map) continue;
        final m    = e as Map<String, dynamic>;
        final type = (m['PointsTransactionType'] ?? '').toString().toLowerCase();
        if (type != 'earn') continue;
        points += (double.tryParse(
                (m['PointBalance'] ?? 0).toString()) ?? 0).round();
      }

      return ProfileSummary(
        loyaltyTier: _tierFromPoints(points),
        totalPoints: points,
        pointsToNextTier: _nextTier(points),
      );

    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
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