import 'package:dio/dio.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/errors/app_exception.dart';
import 'package:loyalty_app/models/company_model.dart';

abstract class ICompaniesService {
  Future<List<CompanyModel>> getCompanies();
}

class CompaniesApiService implements ICompaniesService {
  CompaniesApiService._();
  static final CompaniesApiService instance = CompaniesApiService._();

  final Dio _dio = ApiClient.instance.dio;

  List<CompanyModel>? _cache;
  DateTime? _cacheTime;
  // In-flight deduplication: multiple screens init concurrently at startup
  // (IndexedStack); without this, each fires a separate GetAllCompanies call.
  Future<List<CompanyModel>>? _pending;

  static const _cacheTtl = Duration(minutes: 5);

  @override
  Future<List<CompanyModel>> getCompanies() {
    final now = DateTime.now();
    if (_cache != null &&
        _cacheTime != null &&
        now.difference(_cacheTime!) < _cacheTtl) {
      return Future.value(_cache!);
    }
    if (_pending != null) return _pending!;
    _cache = null;
    _pending = _doGetCompanies();
    _pending!.then((list) { _cache = list; _cacheTime = DateTime.now(); })
             .catchError((_) {})
             .whenComplete(() => _pending = null);
    return _pending!;
  }

  Future<List<CompanyModel>> _doGetCompanies() async {
    try {
      final res  = await _dio.get('Mobile/GetAllCompanies');
      final list = _asList(res.data);
      return List.generate(list.length, (i) {
        return CompanyModel.fromMap(
          list[i] as Map<String, dynamic>,
          fallbackIndex: i,
        );
      }).where((c) => c.name.isNotEmpty).toList();
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  void clearCache() {
    _cache = null;
    _pending = null;
  }
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