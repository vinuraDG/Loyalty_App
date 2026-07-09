// auth_api_service.dart
import 'dart:convert';
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
    required String address,
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

  /// Permanently deletes the current customer account and clears the session.
  Future<void> deleteAccount();
}

class AuthApiService implements IAuthService {
  AuthApiService._();
  static final AuthApiService instance = AuthApiService._();

  final Dio _dio = ApiClient.instance.dio;

  Future<void> _persistToken(String token) async {
    if (token.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefAuthToken, token);
  }

  Future<void> _persistSession(String token, UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token.isNotEmpty) {
        await prefs.setString(AppConstants.prefAuthToken, token);
      }
      await prefs.setBool(AppConstants.prefIsLoggedIn, true);
      await prefs.setString(AppConstants.prefUserId, user.id);
      await prefs.setString(AppConstants.prefUserRole, user.role);
      await prefs.setString(AppConstants.prefUserPhone, user.phone);
      if (user.email.isNotEmpty) {
        await prefs.setString(AppConstants.prefUserEmail, user.email);
      }
    } catch (_) {}
  }

  Future<void> _persistPassword(String password) async {
    if (password.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUserPassword, password);
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

    // ASP.NET Identity validation errors come back as a raw JSON array:
    // [{ "Code": "PasswordTooShort", "Description": "..." }, ...]
    final identityMsg = _extractIdentityErrors(e.response?.data);
    if (identityMsg != null) return AuthException(identityMsg);

    final status = e.response?.statusCode;
    final serverMsg = _extractServerMessage(e.response?.data);
    if (serverMsg != null && serverMsg.isNotEmpty) {
      return AuthException(serverMsg);
    }
    return AuthException('Request failed (HTTP $status). Please try again.');
  }

  /// Handles Account/Register's validation error shape:
  /// a bare JSON array of { Code, Description } objects.
  String? _extractIdentityErrors(dynamic data) {
    if (data is List && data.isNotEmpty) {
      final messages = data
          .whereType<Map>()
          .map((e) =>
              (e['Description'] ?? e['description'] ?? e['Code'] ?? '')
                  .toString())
          .where((s) => s.isNotEmpty)
          .toList();
      if (messages.isNotEmpty) return messages.join(' ');
    }
    return null;
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
      // ASP.NET ProblemDetails shape: { title, status, ... }
      final title = data['title'] ?? data['Title'];
      if (title is String && title.isNotEmpty) {
        return title;
      }
      // Generic message keys
      for (final key in [
        'message', 'Message', 'error', 'Error',
        'errorMessage', 'ErrorMessage',
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

  /// Decodes a JWT and returns the `sub` claim, which this backend sets to
  /// the account's phone number. Returns empty string on any failure.
  String _phoneFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';
      String payload = parts[1];
      // Base64url padding
      while (payload.length % 4 != 0) { payload += '='; }
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return (map['sub'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  String _extractToken(Map<String, dynamic> data) {
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

  /// Fetches the customer profile (points, name, etc.) now that a bearer
  /// token is attached, and persists the full session.
  Future<UserModel> _fetchAndPersistCustomer(String phone, String token) async {
    try {
      final res = await _dio.get(
        'Common/GetCustomerByPhoneNo',
        queryParameters: {'CustomerPhoneNo': phone},
      );
      final data = res.data;
      if (_isEmptyBody(data) || data is! Map<String, dynamic>) {
        throw const AuthException(
            'Signed in, but the profile could not be loaded. Please try again.');
      }
      if (_isErrorEnvelope(data)) {
        throw AuthException(_extractServerMessage(data) ?? 'Could not load profile.');
      }
      final user = _userFromResponse(data);
      await _persistSession(token, user);
      return user;
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ── Auth endpoints ────────────────────────────────────────────────────────

  @override
  Future<UserModel> signInWithEmail({
    required String email, // actually the phone number, per the login form
    required String password,
  }) async {
    final username = email.trim();
    try {
      final res = await _dio.post(
        'Account/Login',
        data: {
          'UserName': username,
          'Password': password,
        },
      );

      final data = res.data;
      if (_isEmptyBody(data) || data is! Map<String, dynamic>) {
        throw const AuthException('Invalid phone number or password.');
      }

      final token = _extractToken(data);
      if (token.isNotEmpty) {
        await _persistToken(token);
        ApiClient.instance.setToken(token); // cache in-memory immediately
      }
      await _persistPassword(password);

      // Prefer the JWT sub claim — the backend sets sub to the account's
      // phone number regardless of whether login was by email or phone.
      // data['UserName'] echoes whatever the user typed (may be an email),
      // so it must not be used as the phone for GetCustomerByPhoneNo.
      String phoneForLookup = token.isNotEmpty ? _phoneFromToken(token) : '';
      if (phoneForLookup.isEmpty) {
        phoneForLookup =
            (data['PhoneNo'] ?? data['phoneNo'] ?? '').toString().trim();
      }
      if (phoneForLookup.isEmpty) phoneForLookup = username;

      final role = (data['Role'] ?? data['role'] ?? '').toString().toLowerCase();

      if (role == 'employee') {
        final employee = await getEmployeeByPhone(phoneForLookup);
        await _persistSession(token, employee);
        return employee;
      }

      // Reset to Fuel (3) — guards against a previous employee session having
      // set activeCompanyId to a different company (e.g. Gold House = 1).
      AppConstants.setActiveCompanyId(AppConstants.transactionCompanyId);
      return _fetchAndPersistCustomer(phoneForLookup, token);
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        throw const AuthException('Invalid phone number or password.');
      }
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
    required String address,
  }) async {
    final trimmedPhone = phone.trim();
    String token = '';

    // Step 1 — create the login credential.
    try {
      final res = await _dio.post(
        'Account/Register',
        data: {
          'FirstName': firstName.trim(),
          'LastName': lastName.trim(),
          'PhoneNo': trimmedPhone,
          'UserName': trimmedPhone,
          'Email': email.trim().toLowerCase(),
          'Password': password,
          // NOTE: verify this matches the exact string in Swagger's Role
          // dropdown for a normal customer — confirmed value was
          // "Administrator" for admin accounts.
          'Role': 'Customer',
        },
      );

      final data = res.data;
      if (data is Map<String, dynamic>) {
        token = _extractToken(data);
        if (token.isNotEmpty) {
          await _persistToken(token);
          ApiClient.instance.setToken(token); // cache in-memory immediately
        }
      }
      await _persistPassword(password);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }

    // Step 2 — create the customer profile row (points/rewards tracking).
    try {
      await _dio.post(
        'Common/RegisterCustomer',
        data: {
          'TransactionCompanyId': AppConstants.activeCompanyId,
          'FirstName': firstName.trim(),
          'LastName': lastName.trim(),
          'Address': address.trim(),
          'Email': email.trim().toLowerCase(),
          'PhoneNo': trimmedPhone,
          'Password': password,
          'Username': trimmedPhone,
        },
      );
    } on DioException catch (e) {
      // Non-fatal — the account credential already exists from Step 1.
      // Continue to try fetching the profile; if it genuinely doesn't
      // exist, that fetch below will surface a clear error instead.
      assert(() {
        debugPrint('[Auth] Common/RegisterCustomer during signup -> '
            'status=${e.response?.statusCode} body=${e.response?.data}');
        return true;
      }());
    }

    // Step 3 — fetch the created profile and log the user in immediately.
    return _fetchAndPersistCustomer(trimmedPhone, token);
  }

  // ── OTP / Phone ───────────────────────────────────────────────────────────

  @override
  Future<void> sendOtp(String phone) async {
    try {
      await _dio.post(
        'Common/ForgotPassword',
        options: Options(responseType: ResponseType.plain),
        data: {'UserName': phone.trim(), 'Password': ''},
      );
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
          'TransactionCompanyId': AppConstants.activeCompanyId,
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
    final storedEmail = prefs.getString(AppConstants.prefUserEmail) ?? '';
    final storedPassword = prefs.getString(AppConstants.prefUserPassword) ?? '';
    final storedId = prefs.getString(AppConstants.prefUserId) ?? '';
    int storedPoints = 0;
    try {
      final uj = prefs.getString('userJson');
      if (uj != null && uj.isNotEmpty) {
        final parsed = jsonDecode(uj) as Map<String, dynamic>?;
        storedPoints = (parsed?['totalPoints'] as int?) ?? 0;
      }
    } catch (_) {}
    final newEmail = email.trim().toLowerCase();
    final emailChanging = newEmail.isNotEmpty && newEmail != storedEmail.toLowerCase();
    // Always send Email — backend marks it [Required] and returns 400 if absent.
    // When email is unchanged, storedEmail is sent; the backend may reject it
    // with "Email already taken" due to a missing self-exclusion in its
    // uniqueness check. That case is handled below.
    final emailForBody = emailChanging ? newEmail : storedEmail;

    try {
      final body = <String, dynamic>{
        'TransactionCompanyId': AppConstants.activeCompanyId,
        'FirstName': firstName.trim(),
        'LastName': lastName.trim(),
        'Address': address.trim(),
        'PhoneNo': phone,
        'Username': phone,
        'Password': storedPassword,
      };
      if (emailForBody.isNotEmpty) body['Email'] = emailForBody;

      final res = await _dio.post('Common/UpdateCustomer', data: body);
      if (_isErrorEnvelope(res.data)) {
        throw AuthException(
          _extractServerMessage(res.data) ?? 'Profile update failed.',
        );
      }
      if (emailChanging) {
        await prefs.setString(AppConstants.prefUserEmail, newEmail);
      }
      if (_isEmptyBody(res.data) || res.data is! Map) {
        return UserModel(
          id: storedId,
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          email: emailChanging ? newEmail : storedEmail,
          phone: phone,
          role: 'customer',
          totalPoints: storedPoints,
          address: address.trim(),
          createdAt: DateTime.now(),
        );
      }
      return _userFromResponse(res.data as Map<String, dynamic>);
    } on AuthException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && !emailChanging) {
        // Backend bug: rejects the user's own unchanged email as "already taken".
        // The name/address fields are applied on the backend before the email
        // check fires, so we return the updated model and continue normally.
        final data = e.response?.data;
        final hasEmailError = data is Map &&
            (data['errors'] as Map?)?.containsKey('Email') == true;
        if (hasEmailError) {
          return UserModel(
            id: storedId,
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            email: storedEmail,
            phone: phone,
            role: 'customer',
            totalPoints: storedPoints,
            address: address.trim(),
            createdAt: DateTime.now(),
          );
        }
      }
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
      // Use ResponseType.plain so Dio doesn't try to JSON-decode the empty
      // body this endpoint returns on success (200 + ""). DioException is
      // still thrown automatically for 4xx/5xx status codes.
      await _dio.post(
        'Common/ResetPassword',
        options: Options(responseType: ResponseType.plain),
        data: {
          'UserName': phone,
          'Password': currentPassword,
          'NewPassword': newPassword,
          'ConfirmPassword': newPassword,
        },
      );
      await _persistPassword(newPassword);
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
      await _dio.post(
        'Common/ForgotPassword',
        options: Options(responseType: ResponseType.plain),
        data: {'UserName': phone.trim(), 'Password': ''},
      );
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
      await _dio.post(
        'Common/ResetPassword',
        options: Options(responseType: ResponseType.plain),
        data: {
          'UserName': phone.trim(),
          'OTP': otp.trim(),
          'NewPassword': newPassword,
          'ConfirmPassword': newPassword,
        },
      );
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

  // ── Delete account ───────────────────────────────────────────────────────

  @override
  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone) ?? '';
    final userId = prefs.getString(AppConstants.prefUserId) ?? '';
    try {
      await _dio.delete(
        'Account/DeleteUser',
        queryParameters: {
          if (userId.isNotEmpty) 'userId': userId,
          if (phone.isNotEmpty) 'phoneNo': phone,
        },
        options: Options(responseType: ResponseType.plain),
      );
    } on DioException catch (e) {
      // 404 = already deleted; treat as success
      if (e.response?.statusCode == 404) return;
      throw _handleDioError(e);
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

      // Set the active company ID for all subsequent service calls.
      // Backend currently returns TransactionCompanyId=0; setActiveCompanyId
      // is a no-op for 0 so it falls back to the constant (=3).
      final companyId =
          int.tryParse((data['TransactionCompanyId'] ?? 0).toString()) ?? 0;
      AppConstants.setActiveCompanyId(companyId);

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