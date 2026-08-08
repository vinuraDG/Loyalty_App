import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/data/customer_ledger_service.dart';
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

  /// Sum of PointsExpire across all customer wallets. Returns 0 if none.
  Future<int> getPointsExpire(String userId);
}

// ── Real API service ──────────────────────────────────────────────────────────

class HomeApiService implements IHomeService {
  HomeApiService._();
  static final HomeApiService instance = HomeApiService._();

  // Delegates to the shared CustomerLedgerService so that all services
  // (HomeApiService + PointsApiService) share a single in-flight request
  // and TTL cache rather than each firing their own.
  Future<List<dynamic>> _fetchLedger(String phone) =>
      CustomerLedgerService.instance.fetchLedger(phone);

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

  /// Total points = sum of all Earn PointsValue − sum of all Redeem PointsValue.
  /// Matches the balance shown on the Points History screen.
  @override
  Future<int> getTotalPoints(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    if (phone.isEmpty) return 0;

    try {
      final list = await _fetchLedger(phone);
      int balance = 0;
      for (final entry in list) {
        final m    = entry as Map<String, dynamic>;
        final type = (m['PointsTransactionType'] ?? '').toString().toLowerCase();
        if (type != 'earn') continue;
        balance += (double.tryParse(
                (m['PointBalance'] ?? 0).toString()) ?? 0).round();
      }
      return balance.clamp(0, 999999999);
    } catch (_) {
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

      final points = (double.tryParse(
              (m['PointsValue'] ?? m['Points'] ?? 0).toString()) ?? 0).round();
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
  } catch (_) {
    return List.filled(7, 0);
  }
}

  @override
  Future<int> getPointsExpire(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    if (phone.isEmpty) return 0;
    try {
      final res = await ApiClient.instance.dio.get(
        'Common/GetAllCustomerWallets',
        data: {'TransactionCompanyId': 0, 'CustomerPhoneNo': phone},
      );
      final list = _asList(res.data);
      int total = 0;
      for (final w in list) {
        if (w is! Map) continue;
        total += (double.tryParse(
                (w['PointsExpire'] ?? w['pointsExpire'] ?? 0).toString()) ??
            0).round();
      }
      return total.clamp(0, 999999999);
    } catch (_) {
      return 0;
    }
  }
}

List _asList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final inner = data['Value'] ?? data['value'] ?? data['data'] ?? data['items'];
    if (inner is List) return inner;
  }
  return [];
}

// ── Service factory ───────────────────────────────────────────────────────────

IHomeService get homeService => AppConstants.useMockServices
    ? HomeMockService.instance
    : HomeApiService.instance;