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
    // FIX: guard against empty phone before firing a request
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    if (phone.isEmpty) {
      throw Exception('No authenticated user found. Please log in again.');
    }

    try {
      final ledgerRes = await _dio.get(
        'Mobile/GetAllCustomerLedgers',
        data: {
          'TransactionCompanyId': AppConstants.activeCompanyId,
          'CustomerPhoneNo': phone,
        },
      );

      final entries = _asList(ledgerRes.data);

      // FIX: handle null/malformed entries gracefully instead of crashing
      int earned = 0, redeemed = 0;
      for (final e in entries) {
        if (e is! Map) continue;
        final m = e as Map<String, dynamic>;
        final pts = int.tryParse((m['PointsValue'] ?? 0).toString()) ?? 0;
        final type =
            (m['PointsTransactionType'] ?? '').toString().toLowerCase();
        if (type == 'earn') {
          earned += pts;
        } else if (type == 'redeem') {
          redeemed += pts;
        }
        // Unknown transaction types are silently ignored instead of
        // being misclassified.
      }

      // Walk backwards to find the most recent Earn entry — its PointBalance
      // is the running balance after all subsequent redeems were applied.
      // (entries come in ascending date order from the API)
      int points = earned - redeemed;
      for (int i = entries.length - 1; i >= 0; i--) {
        final e = entries[i];
        if (e is Map) {
          final type =
              (e['PointsTransactionType'] ?? '').toString().toLowerCase();
          if (type == 'earn') {
            final balance =
                int.tryParse((e['PointBalance'] ?? 0).toString()) ?? 0;
            points = balance;
            break;
          }
        }
      }

      return ProfileSummary(
        loyaltyTier: _tierFromPoints(points),
        totalPoints: points,
        pointsToNextTier: _nextTier(points),
      );

    } on DioException catch (e) {
      // FIX: throw a plain Exception with a clean message so the UI can
      // display it without the "DioException [...]" noise.
      throw Exception(dioErrorMessage(e));
    } catch (e) {
      // Re-throw anything else as a clean Exception
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  List _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final inner = data['Value'] ?? data['value'] ?? data['data'];
      if (inner is List) return inner;
    }
    return [];
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