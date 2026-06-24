import 'package:dio/dio.dart';
import 'package:loyalty_app/features/auth/data/auth_mock_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/models/user_model.dart';

// ── Shared exception ──────────────────────────────────────────────────────────

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

// ── Interface ─────────────────────────────────────────────────────────────────

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

// ── Real API service ──────────────────────────────────────────────────────────

class AuthApiService implements IAuthService {
  AuthApiService._();
  static final AuthApiService instance = AuthApiService._();

  final Dio _dio = ApiClient.instance.dio;

  Future<void> _persistSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefAuthToken, token);
    await prefs.setBool(AppConstants.prefIsLoggedIn, true);
    await prefs.setString(AppConstants.prefUserId, user.id);
    await prefs.setString(AppConstants.prefUserRole, user.role);
    await prefs.setString(AppConstants.prefUserPhone, user.phone);
  }

  AuthException _handleError(DioException e) {
    final status = e.response?.statusCode;
    String? msg;
    final data = e.response?.data;
    if (data is Map) {
      msg = (data['message'] ?? data['Message'] ?? data['error'])?.toString();
    } else if (data is String && data.isNotEmpty) {
      msg = data;
    }
    switch (status) {
      case 400: return AuthException(msg ?? 'Invalid request.');
      case 401: return AuthException(msg ?? 'Incorrect credentials.');
      case 404: return AuthException(msg ?? 'Account not found.');
      case 409: return AuthException(msg ?? 'Account already exists.');
      case 500: return AuthException(msg ?? 'Server error. Try again later.');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const AuthException('Connection timed out. Check your network.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const AuthException('Cannot reach server. Check your internet.');
    }
    return AuthException(msg ?? 'Something went wrong. Please try again.');
  }

  String _extractToken(Map<String, dynamic> data) =>
      (data['token'] ?? data['Token'] ?? data['accessToken'] ?? data['jwt'] ?? '')
          .toString();

  UserModel _userFromResponse(Map<String, dynamic> data) {
    final u = (data['customer'] ?? data['user'] ?? data['data'] ?? data)
        as Map<String, dynamic>;
    return UserModel(
      id: (u['Id'] ?? u['id'] ?? u['CustomerId'] ?? '').toString(),
      firstName: (u['FirstName'] ?? u['firstName'] ?? '').toString(),
      lastName: (u['LastName'] ?? u['lastName'] ?? '').toString(),
      email: (u['Email'] ?? u['email'] ?? '').toString(),
      phone: (u['PhoneNo'] ?? u['phoneNo'] ?? u['phone'] ?? '').toString(),
      role: (u['Role'] ?? u['role'] ?? 'customer').toString().toLowerCase(),
      totalPoints:
          int.tryParse((u['TotalPoints'] ?? u['totalPoints'] ?? 0).toString()) ?? 0,
      address: (u['Address'] ?? u['address'] ?? '').toString(),
      createdAt: u['CreatedAt'] != null
          ? DateTime.tryParse(u['CreatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post('Common/Login', data: {
        'UserName': email.trim(),
        'Password': password,
      });
      final data = res.data as Map<String, dynamic>;
      final user = _userFromResponse(data);
      await _persistSession(_extractToken(data), user);
      return user;
    } on DioException catch (e) {
      throw _handleError(e);
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
      final res = await _dio.post('Common/RegisterCustomer', data: {
        'TransactionCompanyId': AppConstants.transactionCompanyId,
        'FirstName': firstName.trim(),
        'LastName': lastName.trim(),
        'Address': '',
        'Email': email.trim().toLowerCase(),
        'PhoneNo': phone.trim(),
      });
      final data = res.data as Map<String, dynamic>;
      final user = _userFromResponse(data);
      await _persistSession(_extractToken(data), user);
      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> sendOtp(String phone) async {
    try {
      await _dio.post('Common/ForgotPassword', data: {'UserName': phone.trim()});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<UserModel?> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final res = await _dio.get('Common/GetCustomerByPhoneNo',
          queryParameters: {'PhoneNo': phone.trim()});
      if (res.data == null) return null;
      return _userFromResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleError(e);
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
      final res = await _dio.post('Common/RegisterCustomer', data: {
        'TransactionCompanyId': AppConstants.transactionCompanyId,
        'FirstName': firstName.trim(),
        'LastName': lastName.trim(),
        'Address': '',
        'Email': email.trim().toLowerCase(),
        'PhoneNo': phone.trim(),
      });
      final data = res.data as Map<String, dynamic>;
      final user = _userFromResponse(data);
      await _persistSession(_extractToken(data), user);
      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

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
      final res = await _dio.post('Common/UpdateCustomer', data: {
        'TransactionCompanyId': AppConstants.transactionCompanyId,
        'FirstName': firstName.trim(),
        'LastName': lastName.trim(),
        'Address': address.trim(),
        'Email': email.trim().toLowerCase(),
        'PhoneNo': phone,
      });
      return _userFromResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
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
      await _dio.post('Common/ResetPassword', data: {
        'UserName': phone,
        'OldPassword': currentPassword,
        'NewPassword': newPassword,
        'ConfirmPassword': newPassword,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> sendOtpForReset(String phone) async {
    try {
      await _dio.post('Common/ForgotPassword', data: {'UserName': phone.trim()});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> verifyOtpForReset({
    required String phone,
    required String otp,
  }) async {
    // OTP is validated by the server when resetPassword is called.
    // We just check it is non-empty client-side here.
    return otp.trim().length == 4;
  }

  @override
  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _dio.post('Common/ResetPassword', data: {
        'UserName': phone.trim(),
        'OTP': otp.trim(),
        'NewPassword': newPassword,
        'ConfirmPassword': newPassword,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<UserModel?> findById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(AppConstants.prefUserPhone);
    if (phone == null || phone.isEmpty) return null;
    try {
      final res = await _dio.get('Common/GetCustomerByPhoneNo',
          queryParameters: {'PhoneNo': phone});
      if (res.data == null) return null;
      return _userFromResponse(res.data as Map<String, dynamic>);
    } on DioException catch (_) {
      return null;
    }
  }
}

// ── Service factory ───────────────────────────────────────────────────────────

IAuthService get authService => AppConstants.useMockServices
    ? AuthMockService.instance
    : AuthApiService.instance;