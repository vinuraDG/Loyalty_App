import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.addAll([
      _AuthInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    ]);
}

class _AuthInterceptor extends Interceptor {
  // Guards against concurrent re-login attempts when multiple requests
  // fail with 401 simultaneously (e.g. home screen loads 3 endpoints at once).
  bool _isRetrying = false;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.prefAuthToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRetrying) {
      _isRetrying = true;
      try {
        final newToken = await _tryReLogin();
        if (newToken != null && newToken.isNotEmpty) {
          // Inject new token and retry the original request without
          // going through this interceptor again (avoids infinite loop).
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryDio = Dio();
          final response = await retryDio.fetch(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (_) {
        // Re-login or retry failed — let the original 401 propagate.
      } finally {
        _isRetrying = false;
      }
      // Re-login wasn't possible — clear the stale token so subsequent
      // requests don't keep sending it.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.prefAuthToken);
      await prefs.remove(AppConstants.prefIsLoggedIn);
    }
    handler.next(err);
  }

  /// Silently re-authenticates using credentials stored at login time.
  /// Returns the new Bearer token, or null if re-login isn't possible.
  Future<String?> _tryReLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone);
    final password = prefs.getString(AppConstants.prefUserPassword);
    if (phone == null || phone.isEmpty ||
        password == null || password.isEmpty) {
      return null;
    }

    // Use a bare Dio without this interceptor to avoid a recursive loop.
    final loginDio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    final res = await loginDio.post(
      'Account/Login',
      data: {'UserName': phone, 'Password': password},
    );

    final data = res.data;
    if (data is! Map<String, dynamic>) return null;

    final token = _extractToken(data);
    if (token.isNotEmpty) {
      await prefs.setString(AppConstants.prefAuthToken, token);
      return token;
    }
    return null;
  }

  /// Extracts a Bearer token from a login response map.
  /// Covers common ASP.NET field names, nested wrappers, and JWT auto-detect.
  static String _extractToken(Map<String, dynamic> data) {
    // Known field name variants (case-sensitive — check both casings)
    for (final key in [
      'token', 'Token',
      'accessToken', 'AccessToken',
      'access_token',
      'jwt', 'JWT',
      'jwtToken', 'JwtToken',
      'authToken', 'AuthToken',
      'bearerToken', 'BearerToken',
    ]) {
      final v = data[key];
      if (v is String && v.isNotEmpty) return v;
    }
    // Check common nested wrapper objects (e.g. { "data": { "token": "..." } })
    for (final key in ['data', 'Data', 'result', 'Result', 'payload']) {
      final nested = data[key];
      if (nested is Map<String, dynamic>) {
        final t = _extractToken(nested);
        if (t.isNotEmpty) return t;
      }
    }
    // Last resort: find any string value that looks like a JWT
    // (base64url header starts with eyJ, contains two dots)
    for (final v in data.values) {
      if (v is String && v.startsWith('eyJ') && v.split('.').length == 3) {
        return v;
      }
    }
    return '';
  }
}
