import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // In-memory token — updated immediately on login so subsequent requests
  // don't wait for a SharedPreferences round-trip.
  String _cachedToken = '';

  String get token => _cachedToken;
  void setToken(String token) => _cachedToken = token;
  void clearToken() => _cachedToken = '';

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
      _AuthInterceptor(this),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    ]);
}

class _AuthInterceptor extends Interceptor {
  final ApiClient _client;
  _AuthInterceptor(this._client);

  bool _isRetrying = false;

  // These endpoints issue or reset credentials — never attach a Bearer token
  // to them. Sending a stale token on a login call can cause the backend to
  // reject the request or silently return the old session instead of a new one.
  static const _publicPaths = [
    'Account/Login',
    'Account/Register',
    'Account/ForgotPassword',
    'Mobile/ForgotPassword',
    'Mobile/ResetPassword',
    'Mobile/SendPhoneConfirmation',
    'Mobile/ConfirmPhone',
    'Common/ForgotPassword',
    'Common/ResetPassword',
  ];

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final isPublic = _publicPaths.any((p) => options.path.contains(p));
    if (!isPublic) {
      // Prefer the in-memory cache; fall back to SharedPreferences on cold
      // start (e.g. session restore before the first explicit login).
      String token = _client._cachedToken;
      if (token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString(AppConstants.prefAuthToken) ?? '';
        if (token.isNotEmpty) _client._cachedToken = token;
      }
      if (token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
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
          // Update both caches so the retried request and all future
          // requests immediately have the fresh token.
          _client._cachedToken = newToken;
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryDio = Dio();
          final response = await retryDio.fetch(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (_) {
        // Re-login failed — fall through and propagate the original 401.
      } finally {
        _isRetrying = false;
      }
      // Clear stale session so subsequent requests don't keep failing.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.prefAuthToken);
      await prefs.remove(AppConstants.prefIsLoggedIn);
      _client.clearToken();
    }
    handler.next(err);
  }

  Future<String?> _tryReLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final phone    = prefs.getString(AppConstants.prefUserPhone);
    final password = prefs.getString(AppConstants.prefUserPassword);
    if (phone == null    || phone.isEmpty ||
        password == null || password.isEmpty) return null;

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

  static String _extractToken(Map<String, dynamic> data) {
    for (final key in [
      'token',       'Token',
      'accessToken', 'AccessToken',
      'access_token',
      'jwt',         'JWT',
      'jwtToken',    'JwtToken',
      'authToken',   'AuthToken',
      'bearerToken', 'BearerToken',
    ]) {
      final v = data[key];
      if (v is String && v.isNotEmpty) return v;
    }
    for (final key in ['data', 'Data', 'result', 'Result', 'payload']) {
      final nested = data[key];
      if (nested is Map<String, dynamic>) {
        final t = _extractToken(nested);
        if (t.isNotEmpty) return t;
      }
    }
    for (final v in data.values) {
      if (v is String && v.startsWith('eyJ') && v.split('.').length == 3) {
        return v;
      }
    }
    return '';
  }
}
