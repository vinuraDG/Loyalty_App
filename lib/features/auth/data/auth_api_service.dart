// auth_api_service.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:loyalty_app/features/auth/data/auth_mock_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/models/user_model.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class RegistrationSuccessException implements Exception {
  const RegistrationSuccessException();
}

abstract class IAuthService {
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });
  Future<UserModel> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  });
  Future<void> sendOtp(String phone);
  Future<UserModel?> verifyOtp({required String phone, required String otp});
  Future<UserModel> createAccountWithPhone({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  });
  Future<UserModel> updateProfile({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String address,
  });
  Future<void> changePassword({
    required String id,
    required String currentPassword,
    required String newPassword,
  });
  Future<void> sendOtpForReset(String phone);
  Future<bool> verifyOtpForReset({required String phone, required String otp});
  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  });
  Future<UserModel?> findById(String id);
}

class AuthApiService implements IAuthService {
  AuthApiService._();
  static final AuthApiService instance = AuthApiService._();

  final Dio _dio = ApiClient.instance.dio;

  Future<void> _persistSession(String token, UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefAuthToken, token);
      await prefs.setBool(AppConstants.prefIsLoggedIn, true);
      await prefs.setString(AppConstants.prefUserId, user.id);
      await prefs.setString(AppConstants.prefUserRole, user.role);
      await prefs.setString(AppConstants.prefUserPhone, user.phone);
    } catch (_) {}
  }

  // ── Error handling ────────────────────────────────────────────────────────

  AuthException _handleDioError(DioException e) {
    assert(() {
      debugPrint(
        '[Auth] ${e.requestOptions.method} ${e.requestOptions.path} '
        '-> status=${e.response?.statusCode} body=${e.response?.data}',
      );
      return true;
    }());

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AuthException('Connection timed out.');
      case DioExceptionType.connectionError:
        return const AuthException('Cannot reach the server.');
      case DioExceptionType.cancel:
        return const AuthException('Request cancelled.');
      case DioExceptionType.badCertificate:
        return const AuthException('SSL certificate error.');
      default:
        break;
    }

    final status = e.response?.statusCode;
    final serverMsg = _extractServerMessage(e.response?.data);
    if (serverMsg != null && serverMsg.isNotEmpty) {
      return AuthException(serverMsg);
    }
    return AuthException('Request failed (HTTP $status). Please try again.');
  }

  String? _extractServerMessage(dynamic data) {
    if (data == null) return null;
    if (data is String && data.isNotEmpty) return data;
    if (data is Map) {
      // Check structured error envelope first
      final notifType = data['NotificationType'] ?? data['notificationType'];
      if (notifType == 'Error') {
        final msg = data['Message'] ?? data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      // Generic message keys
      for (final key in [
        'message', 'Message', 'error', 'Error',
        'errorMessage', 'ErrorMessage', 'title', 'Title',
      ]) {
        final v = data[key];
        if (v is String && v.isNotEmpty) return v;
      }
      // ASP.NET validation errors
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first is String) return first;
      }
    }
    return null;
  }

  bool _isErrorEnvelope(dynamic data) {
    if (data is! Map) return false;
    final notifType = data['NotificationType'] ?? data['notificationType'];
    return notifType == 'Error';
  }

  // ── Response parsing ──────────────────────────────────────────────────────

  String _extractToken(Map<String, dynamic> data) =>
      (data['token'] ?? data['Token'] ?? data['accessToken'] ??
          data['AccessToken'] ?? data['jwt'] ?? '')
          .toString();

  UserModel _userFromResponse(Map<String, dynamic> data) {
    final raw = data['customer'] ?? data['user'] ?? data['data'] ?? data;
    final u = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};

    return UserModel(
      id: (u['Id'] ?? u['id'] ?? u['CustomerId'] ?? u['customerID'] ?? '')
          .toString(),
      firstName:
          (u['FirstName'] ?? u['firstName'] ?? u['first_name'] ?? '').toString(),
      lastName:
          (u['LastName'] ?? u['lastName'] ?? u['last_name'] ?? '').toString(),
      email: (u['Email'] ?? u['email'] ?? '').toString(),
      phone: (u['PhoneNo'] ?? u['phoneNo'] ?? u['phone'] ?? u['Phone'] ?? '')
          .toString(),
      role: (u['Role'] ?? u['role'] ?? 'customer').toString().toLowerCase(),
      totalPoints: int.tryParse(
              (u['TotalPoints'] ?? u['totalPoints'] ?? u['points'] ?? 0)
                  .toString()) ??
          0,
      address: (u['Address'] ?? u['address'] ?? '').toString(),
      createdAt: u['CreatedAt'] != null
          ? DateTime.tryParse(u['CreatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // ── Auth endpoints ────────────────────────────────────────────────────────

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        'Common/Login',
        data: {
          'UserName': email.trim(),
          'Password': password,
        },
      );

      final data = res.data;

      if (_isErrorEnvelope(data)) {
        throw AuthException(
          _extractServerMessage(data) ?? 'Login failed.',
        );
      }
      if (data is! Map<String, dynamic>) {
        throw const AuthException('Unexpected response from server.');
      }

      final user = _userFromResponse(data);
      await _persistSession(_extractToken(data), user);
      return user;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        'Common/RegisterCustomer',
        data: {
          'TransactionCompanyId': AppConstants.transactionCompanyId,
          'FirstName': firstName.trim(),
          'LastName': lastName.trim(),
          'Address': '',
          'Email': email.trim().toLowerCase(),
          'PhoneNo': phone.trim(),
          'Password': password,
          'ConfirmPassword': password,
        },
      );

      final data = res.data;

      if (_isErrorEnvelope(data)) {
        throw AuthException(
          _extractServerMessage(data) ?? 'Registration failed.',
        );
      }

      throw const RegistrationSuccessException();
    } on RegistrationSuccessException {
      rethrow;
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // ── OTP / Phone ───────────────────────────────────────────────────────────

  @override
  Future<void> sendOtp(String phone) async {
    try {
      final res = await _dio.post(
        'Common/ForgotPassword',
        data: {'UserName': phone.trim()},
      );
      if (_isErrorEnvelope(res.data)) {
        throw AuthException(
          _extractServerMessage(res.data) ?? 'Failed to send OTP.',
        );
      }
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel?> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final res = await _dio.get(
        'Common/GetCustomerByPhoneNo',
        queryParameters: {'CustomerPhoneNo': phone.trim()},
      );
      if (res.data == null || res.data is! Map) return null;
      if (_isErrorEnvelope(res.data)) return null;
      return _userFromResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> createAccountWithPhone({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    try {
      final res = await _dio.post(
        'Common/RegisterCustomer',
        data: {
          'TransactionCompanyId': AppConstants.transactionCompanyId,
          'FirstName': firstName.trim(),
          'LastName': lastName.trim(),
          'Address': '',
          'Email': email.trim().toLowerCase(),
          'PhoneNo': phone.trim(),
        },
      );
      if (_isErrorEnvelope(res.data)) {
        throw AuthException(
          _extractServerMessage(res.data) ?? 'Account creation failed.',
        );
      }
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }

    try {
      final res = await _dio.get(
        'Common/GetCustomerByPhoneNo',
        queryParameters: {'CustomerPhoneNo': phone.trim()},
      );
      if (res.data == null || res.data is! Map) {
        throw const AuthException('Account created but could not retrieve user.');
      }
      if (_isErrorEnvelope(res.data)) {
        throw AuthException(
          _extractServerMessage(res.data) ?? 'Could not retrieve account.',
        );
      }
      final user = _userFromResponse(res.data as Map<String, dynamic>);
      await _persistSession('', user);
      return user;
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  @override
  Future<UserModel> updateProfile({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    try {
      final res = await _dio.post(
        'Common/UpdateCustomer',
        data: {
          'TransactionCompanyId': AppConstants.transactionCompanyId,
          'FirstName': firstName.trim(),
          'LastName': lastName.trim(),
          'Address': address.trim(),
          'Email': email.trim().toLowerCase(),
          'PhoneNo': phone,
        },
      );
      if (_isErrorEnvelope(res.data)) {
        throw AuthException(
          _extractServerMessage(res.data) ?? 'Profile update failed.',
        );
      }
      return _userFromResponse(res.data as Map<String, dynamic>);
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> changePassword({
    required String id,
    required String currentPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    try {
      final res = await _dio.post(
        'Common/ResetPassword',
        data: {
          'UserName': phone,
          'OldPassword': currentPassword,
          'NewPassword': newPassword,
          'ConfirmPassword': newPassword,
        },
      );
      if (_isErrorEnvelope(res.data)) {
        throw AuthException(
          _extractServerMessage(res.data) ?? 'Password change failed.',
        );
      }
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────

  @override
  Future<void> sendOtpForReset(String phone) async {
    try {
      final res = await _dio.post(
        'Common/ForgotPassword',
        data: {'UserName': phone.trim()},
      );
      if (_isErrorEnvelope(res.data)) {
        throw AuthException(
          _extractServerMessage(res.data) ?? 'Failed to send OTP.',
        );
      }
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<bool> verifyOtpForReset({
    required String phone,
    required String otp,
  }) async {
    return otp.trim().length == 4;
  }

  @override
  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final res = await _dio.post(
        'Common/ResetPassword',
        data: {
          'UserName': phone.trim(),
          'OTP': otp.trim(),
          'NewPassword': newPassword,
          'ConfirmPassword': newPassword,
        },
      );
      if (_isErrorEnvelope(res.data)) {
        throw AuthException(
          _extractServerMessage(res.data) ?? 'Password reset failed.',
        );
      }
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // ── Session restore ───────────────────────────────────────────────────────

  @override
  Future<UserModel?> findById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone);
    if (phone == null || phone.isEmpty) return null;
    try {
      final res = await _dio.get(
        'Common/GetCustomerByPhoneNo',
        queryParameters: {'CustomerPhoneNo': phone},
      );
      if (res.data == null || res.data is! Map) return null;
      if (_isErrorEnvelope(res.data)) return null;
      return _userFromResponse(res.data as Map<String, dynamic>);
    } on DioException catch (_) {
      return null;
    }
  }
}

IAuthService get authService => AppConstants.useMockServices
    ? AuthMockService.instance
    : AuthApiService.instance;