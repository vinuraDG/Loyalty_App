
import 'package:loyalty_app/data/mock_data.dart';

// ── Data models returned by this service ─────────────────────────────────────

class AdItem {
  final String id;
  final String tag;
  final String title;
  final String subtitle;
  final int gradientStart; // ARGB int, e.g. 0xFF2D1B69
  final int gradientEnd;
  final int tagColor;

  const AdItem({
    required this.id,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
    required this.tagColor,
  });
}

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IHomeService {
  /// Promotional banners shown in the home screen carousel.
  Future<List<AdItem>> getAds();

  /// Points earned per day for the last 7 days (Mon–Sun) for a given user.
  Future<List<int>> getWeeklyPoints(String userId);
}

// ── Real API service (stubs) ──────────────────────────────────────────────────

class HomeApiService implements IHomeService {
  HomeApiService._();
  static final HomeApiService instance = HomeApiService._();

  @override
  Future<List<AdItem>> getAds() async {
    // TODO: GET $kBaseUrl/promotions
    // expect → List of AdItem JSON
    throw UnimplementedError('Backend not connected yet: GET $kBaseUrl/promotions');
  }

  @override
  Future<List<int>> getWeeklyPoints(String userId) async {
    // TODO: GET $kBaseUrl/users/$userId/stats/weekly
    // expect → { "points": [80, 210, 150, 60, 320, 200, 120] }  (Mon–Sun)
    throw UnimplementedError('Backend not connected yet: GET $kBaseUrl/users/$userId/stats/weekly');
  }
}