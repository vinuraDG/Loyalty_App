import 'package:dio/dio.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';

/// Shared in-flight deduplication + TTL cache for GetAllCustomerLedgers.
///
/// HomeApiService and PointsApiService each call ledger independently;
/// delegating to this singleton ensures at most one network request per
/// 30-second window regardless of how many callers arrive concurrently.
class CustomerLedgerService {
  CustomerLedgerService._();
  static final CustomerLedgerService instance = CustomerLedgerService._();

  final Dio _dio = ApiClient.instance.dio;

  Future<List<dynamic>>? _ledgerFuture;
  List<dynamic>? _ledgerCache;
  DateTime? _ledgerCacheTime;

  Future<List<dynamic>> fetchLedger(String phone) {
    const ttl = Duration(seconds: 30);
    final now = DateTime.now();
    if (_ledgerCache != null &&
        _ledgerCacheTime != null &&
        now.difference(_ledgerCacheTime!) < ttl) {
      return Future.value(_ledgerCache!);
    }
    if (_ledgerFuture != null) return _ledgerFuture!;
    _ledgerFuture = _doFetch(phone);
    _ledgerFuture!.then((list) {
      _ledgerCache = list;
      _ledgerCacheTime = DateTime.now();
    }).catchError((_) {})
      .whenComplete(() => _ledgerFuture = null);
    return _ledgerFuture!;
  }

  void clearCache() {
    _ledgerCache = null;
    _ledgerFuture = null;
  }

  Future<List<dynamic>> _doFetch(String phone) async {
    try {
      final res = await _dio.get(
        'Mobile/GetAllCustomerLedgers',
        data: {
          'TransactionCompanyId': AppConstants.transactionCompanyId,
          'CustomerPhoneNo': phone,
        },
      );
      return _asList(res.data);
    } catch (_) {
      return [];
    }
  }
}

List _asList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final inner = data['Value'] ?? data['value'] ??
        data['Data'] ?? data['data'] ?? data['items'];
    if (inner is List) return inner;
  }
  return [];
}
