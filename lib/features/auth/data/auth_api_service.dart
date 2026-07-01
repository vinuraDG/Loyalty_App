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

  /// Looks up an employee record by phone number. Throws [AuthException]
  /// if no employee exists for that number or the response is malformed.
  Future<UserModel> getEmployeeByPhone(String phone);
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

  /// True when [data] is "technically a response" but carries nothing usable
  /// — null, an empty string, or an empty map. Several of this backend's GET
  /// endpoints return HTTP 200 with an empty body instead of 404 when a
  /// record isn't found, so this has to be checked explicitly everywhere
  /// before attempting to read fields off the response.
  bool _isEmptyBody(dynamic data) {
    if (data == null) return true;
    if (data is String && data.trim().isEmpty) return true;
    if (data is Map && data.isEmpty) return true;
    return false;
  }

  // ── Response parsing ──────────────────────────────────────────────────────

  String _extractToken(Map<String, dynamic> data) =>
      (data['token'] ?? data['Token'] ?? data['accessToken'] ??
          data['AccessToken'] ?? data['jwt'] ?? '')
          .toString();

  UserModel _userFromResponse(Map<String, dynamic> data) {
    final raw = data['customer'] ?? data['user'] ?? data['employee'] ??
        data['data'] ?? data;
    final u = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};

    return UserModel(
      id: (u['Id'] ?? u['id'] ?? u['CustomerId'] ?? u['customerID'] ??
              u['EmployeeId'] ?? u['employeeId'] ?? '')
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

      if (_isEmptyBody(data)) {
        throw const AuthException('Invalid email or password.');
      }
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
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioError(e);
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
      if (_isEmptyBody(res.data) || res.data is! Map) return null;
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
      if (_isEmptyBody(res.data) || res.data is! Map) {
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
      if (_isEmptyBody(res.data) || res.data is! Map) {
        throw const AuthException('Profile update failed: empty response from server.');
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
    final role = prefs.getString(AppConstants.prefUserRole);
    if (phone == null || phone.isEmpty) return null;

    // Employees aren't in the Customer table — route session restore to the
    // matching lookup based on the role that was persisted at login time.
    if (role == 'employee') {
      try {
        return await getEmployeeByPhone(phone);
      } catch (_) {
        return null;
      }
    }

    try {
      final res = await _dio.get(
        'Common/GetCustomerByPhoneNo',
        queryParameters: {'CustomerPhoneNo': phone},
      );
      if (_isEmptyBody(res.data) || res.data is! Map) return null;
      if (_isErrorEnvelope(res.data)) return null;
      return _userFromResponse(res.data as Map<String, dynamic>);
    } on DioException catch (_) {
      return null;
    }
  }

  // ── Employee lookup ──────────────────────────────────────────────────────
  // Confirmed via live response: this endpoint returns
  // {Title, FirstName, LastName, Email, PhoneNo, FullName, TransactionCompanyId}
  // — NOTE: no Id field at all. Phone number is used as the stable id since
  // the backend doesn't expose one for employees.

  @override
  Future<UserModel> getEmployeeByPhone(String phone) async {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) {
      throw const AuthException('Employee phone number is required.');
    }

    try {
      final res = await _dio.get(
        'Common/GetEmployeeByPhoneNo',
        queryParameters: {'EmployeePhoneNo': trimmed},
      );

      final data = res.data;

      // Defensive check: this backend can return HTTP 200 with an empty
      // body instead of a 404/error envelope when nothing is found.
      if (_isEmptyBody(data)) {
        throw AuthException('No employee found for phone number $trimmed.');
      }

      if (data is! Map<String, dynamic>) {
        throw const AuthException(
          'Unexpected response from server while fetching employee.',
        );
      }

      if (_isErrorEnvelope(data)) {
        throw AuthException(
          _extractServerMessage(data) ?? 'Employee not found.',
        );
      }

      final firstName = (data['FirstName'] ?? data['firstName'] ?? '').toString();
      final lastName = (data['LastName'] ?? data['lastName'] ?? '').toString();
      final email = (data['Email'] ?? data['email'] ?? '').toString();
      final respPhone = (data['PhoneNo'] ?? data['phoneNo'] ?? '').toString();

      // Backend doesn't return an Id for employees — use phone as the id.
      final resolvedId = respPhone.isNotEmpty ? respPhone : trimmed;

      // Genuinely empty (no name, no phone confirmed) means not found.
      if (firstName.isEmpty && lastName.isEmpty && respPhone.isEmpty) {
        throw AuthException('No employee found for phone number $trimmed.');
      }

      return UserModel(
        id: resolvedId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: respPhone.isNotEmpty ? respPhone : trimmed,
        role: 'employee',
        totalPoints: 0,
        address: '',
        createdAt: DateTime.now(),
      );
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw AuthException('No employee found for phone number $trimmed.');
      }
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }
}

IAuthService get authService => AppConstants.useMockServices
    ? AuthMockService.instance
    : AuthApiService.instance;