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

  @override
  Future<List<CompanyModel>> getCompanies() async {
    if (_cache != null) return _cache!;
    try {
      final res  = await _dio.get('Mobile/GetAllCompanies');
      final list = _asList(res.data);
      // Pass the list index as fallbackIndex so each company gets a stable id
      _cache = List.generate(list.length, (i) {
        return CompanyModel.fromMap(
          list[i] as Map<String, dynamic>,
          fallbackIndex: i,
        );
      }).where((c) => c.name.isNotEmpty).toList();
      return _cache!;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  void clearCache() => _cache = null;
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