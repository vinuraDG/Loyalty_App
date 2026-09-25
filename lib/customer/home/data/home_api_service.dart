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

  /// Live promotions/ads from the backend. Returns an empty list when the
  /// backend has none (or the call fails) so the UI can hide the ads card
  /// entirely instead of showing mock/placeholder content.
  Future<List<Map<String, dynamic>>> getPromotions();
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

  // Fallback gradient/tag colors for promotions, since the backend only
  // supplies text/image content — cycles by index so cards still look distinct.
  static const List<List<int>> _promoPalette = [
    [0xFF6366F1, 0xFF8B5CF6, 0xFFC4B5FD], // indigo → violet
    [0xFFF97316, 0xFFEA580C, 0xFFFED7AA], // orange
    [0xFF059669, 0xFF10B981, 0xFFA7F3D0], // green
    [0xFFDB2777, 0xFFEC4899, 0xFFFBCFE8], // pink
    [0xFF0EA5E9, 0xFF0284C7, 0xFFBAE6FD], // sky
  ];

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

  /// Fetches live promotions from the backend. Each entry only carries an
  /// image (no title/subtitle/points), so this extracts and resolves that
  /// image URL. An entry with no recognized image field is skipped — it
  /// never gets guessed from an arbitrary field, so it can't silently show
  /// a broken-image placeholder. Returns [] on any failure (network error,
  /// 500, empty payload, no real images found) so the caller can hide the
  /// ads card entirely when there's nothing valid to show.
  @override
  Future<List<Map<String, dynamic>>> getPromotions() async {
    try {
      final res = await ApiClient.instance.dio.get('Mobile/GetAllPromotions');
      final list = _asList(res.data);
      if (list.isEmpty) return [];

      final result = <Map<String, dynamic>>[];
      for (int i = 0; i < list.length; i++) {
        final entry = list[i];
        String rawImage = '';

        if (entry is String) {
          // Backend returns a plain list of image paths/URLs.
          rawImage = entry;
        } else if (entry is Map) {
          final m = entry as Map<String, dynamic>;
          rawImage = (m['Image'] ??
                  m['ImageUrl'] ??
                  m['ImagePath'] ??
                  m['PromotionImage'] ??
                  m['Banner'] ??
                  m['Picture'] ??
                  m['PhotoUrl'] ??
                  m['image'] ??
                  m['imageUrl'] ??
                  m['url'] ??
                  '')
              .toString();
        }

        if (rawImage.isEmpty) continue; // no recognized image → skip, no guessing
        result.add({
          'id': i.toString(),
          'imageUrl': _resolveImageUrl(rawImage),
        });
      }
      return result;
    } catch (_) {
      return [];
    }
  }
  /// Turns a possibly-relative image path from the backend into a full URL.
  /// If the backend already returns an absolute http(s) URL, it's used as-is.
  String _resolveImageUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    final base = AppConstants.baseUrl.endsWith('/')
        ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
        : AppConstants.baseUrl;
    final path = raw.startsWith('/') ? raw : '/$raw';
    return '$base$path';
  }

  /// Total points = earned − redeemed − expired, matching the Points History screen.
  @override
  Future<int> getTotalPoints(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    if (phone.isEmpty) return 0;

    try {
      final list = await _fetchLedger(phone);
      int balance = 0;
      for (final entry in list) {
        final m      = entry as Map<String, dynamic>;
        final type   = (m['PointsTransactionType'] ?? '').toString().toLowerCase();
        final points = (double.tryParse(
                (m['PointsValue'] ?? m['Points'] ?? 0).toString()) ?? 0).round();
        if (type == 'earn') {
          balance += points;
        } else if (type == 'redeem') {
          balance -= points;
        } else if (type == 'expired' || type == 'expire' ||
                   type == 'expiring' || type == 'pointsexpired') {
          balance -= points;
        }
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