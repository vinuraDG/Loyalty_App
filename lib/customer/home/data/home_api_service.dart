
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/customer/home/data/home_mock_service.dart';

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

// ── Real API service ──────────────────────────────────────────────────────────

class HomeApiService implements IHomeService {
  HomeApiService._();
  static final HomeApiService instance = HomeApiService._();

  final Dio _dio = ApiClient.instance.dio;

  @override
  Future<List<AdItem>> getAds() async {
    // No dedicated ads endpoint in the backend — return static promotional items
    return kMockAds
        .map((m) => AdItem(
              id: m['id'] as String,
              tag: m['tag'] as String,
              title: m['title'] as String,
              subtitle: m['subtitle'] as String,
              gradientStart: m['gradientStart'] as int,
              gradientEnd: m['gradientEnd'] as int,
              tagColor: m['tagColor'] as int,
            ))
        .toList();
  }

  @override
  Future<List<int>> getWeeklyPoints(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    if (phone.isEmpty) return List.filled(7, 0);

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    try {
      final res = await _dio.get(
        'Mobile/GetAllCustomerLedgers',
        queryParameters: {
          'TransactionCompanyId': AppConstants.transactionCompanyId,
          'CustomerPhoneNo': phone,
          'DateFrom': _fmt(monday),
          'DateTo': _fmt(sunday),
        },
      );

      final list = res.data as List? ?? [];
      final result = List<int>.filled(7, 0);
      final weekStart = DateTime(monday.year, monday.month, monday.day);

      for (final entry in list) {
        final m = entry as Map<String, dynamic>;
        final points =
            int.tryParse((m['Points'] ?? m['points'] ?? 0).toString()) ?? 0;
        if (points <= 0) continue; // skip redemptions

        final dateStr = (m['Date'] ?? m['date'] ?? '').toString();
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;

        final dayIdx = date.difference(weekStart).inDays;
        if (dayIdx >= 0 && dayIdx < 7) result[dayIdx] += points;
      }
      return result;
    } on DioException catch (_) {
      return List.filled(7, 0);
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ── Service factory ───────────────────────────────────────────────────────────

IHomeService get homeService => AppConstants.useMockServices
    ? HomeMockService.instance
    : HomeApiService.instance;
