import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/customer/home/data/home_mock_service.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class AdItem {
  final String id;
  final String tag;
  final String title;
  final String subtitle;
  final int gradientStart;
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
  Future<List<AdItem>> getAds();
  Future<List<int>> getWeeklyPoints(String userId);

  /// Total redeemable points balance derived from the ledger.
  Future<int> getTotalPoints(String userId);
}

// ── Real API service ──────────────────────────────────────────────────────────

class HomeApiService implements IHomeService {
  HomeApiService._();
  static final HomeApiService instance = HomeApiService._();

  final Dio _dio = ApiClient.instance.dio;

  // Fetch the full ledger once and cache it for this request cycle.
  Future<List<dynamic>> _fetchLedger(String phone) async {
    final res = await _dio.get(
      'Mobile/GetAllCustomerLedgers',
      data: {
        'TransactionCompanyId': AppConstants.activeCompanyId,
        'CustomerPhoneNo': phone,
      },
    );
    return _asList(res.data);
  }

  @override
  Future<List<AdItem>> getAds() async {
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

  /// Total points = PointBalance from the most recent Earn entry.
  /// The backend stores the running balance on each Earn ledger row,
  /// so the last Earn row's PointBalance IS the current spendable balance.
  @override
  Future<int> getTotalPoints(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    if (phone.isEmpty) return 0;

    try {
      final list = await _fetchLedger(phone);

      // Walk backwards to find the most recent Earn entry — its PointBalance
      // is the current running balance after all redeems have been applied.
      for (int i = list.length - 1; i >= 0; i--) {
        final m = list[i] as Map<String, dynamic>;
        final type = (m['PointsTransactionType'] ?? '').toString().toLowerCase();
        if (type == 'earn') {
          final balance = int.tryParse(
                  (m['PointBalance'] ?? 0).toString()) ??
              0;
          return balance;
        }
      }
      return 0;
    } on DioException catch (_) {
      return 0;
    }
  }

  @override
Future<List<int>> getWeeklyPoints(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
  if (phone.isEmpty) return List.filled(7, 0);

  final now    = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));

  try {
    final list      = await _fetchLedger(phone);
    final result    = List<int>.filled(7, 0);
    final weekStart = DateTime(monday.year, monday.month, monday.day);

    for (final entry in list) {
      final m    = entry as Map<String, dynamic>;
      final type = (m['PointsTransactionType'] ?? '').toString().toLowerCase();
      if (type != 'earn') continue;

      final points = int.tryParse(
              (m['PointsValue'] ?? m['Points'] ?? 0).toString()) ?? 0;
      if (points <= 0) continue;

      // DateCreated is the real transaction timestamp
      final dateStr = (m['DateCreated'] ?? '').toString();
      final parsed  = DateTime.tryParse(dateStr);
      if (parsed == null || parsed.year < 2000) continue;

      final dayIdx = DateTime(parsed.year, parsed.month, parsed.day)
          .difference(weekStart)
          .inDays;
      if (dayIdx >= 0 && dayIdx < 7) result[dayIdx] += points;
    }
    return result;
  } on DioException catch (_) {
    return List.filled(7, 0);
  }
}
}

/// If the backend stores the expiry year instead of transaction year,
/// shift back one year so the date lands in the past correctly.
DateTime _normaliseDate(DateTime parsed) {
  if (parsed.year < 2000) return DateTime.now();
  final now = DateTime.now();
  if (parsed.year > now.year) {
    return DateTime(
        parsed.year - 1, parsed.month, parsed.day,
        parsed.hour, parsed.minute, parsed.second);
  }
  return parsed;
}

List _asList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final inner =
        data['Value'] ?? data['value'] ?? data['data'] ?? data['items'];
    if (inner is List) return inner;
  }
  return [];
}

// ── Service factory ───────────────────────────────────────────────────────────

IHomeService get homeService => AppConstants.useMockServices
    ? HomeMockService.instance
    : HomeApiService.instance;