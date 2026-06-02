// lib/features/auth/data/auth_api_service.dart
//
// Contains:
//   • AuthException  — shared error class used by both mock and real service
//   • IAuthService   — interface both services implement
//   • AuthApiService — real backend stubs (fill in TODOs when backend is ready)
//
// ─── How to go live ───────────────────────────────────────────────────────────
// 1. Set kBaseUrl in lib/data/mock_data.dart to the URL from your backend dev.
// 2. Fill in every TODO below with the real http call.
// 3. In auth_provider.dart change one line:
//      final _auth = AuthMockService.instance;   // ← remove
//      final _auth = AuthApiService.instance;    // ← add
// 4. Done. Screens and providers need zero changes.
// ─────────────────────────────────────────────────────────────────────────────

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
  Future<UserModel> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  });

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendOtp(String phone);

  Future<UserModel?> verifyOtp({
    required String phone,
    required String otp,
  });

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
}

// ── Real API service (stubs) ──────────────────────────────────────────────────

class AuthApiService implements IAuthService {
  AuthApiService._();
  static final AuthApiService instance = AuthApiService._();

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // TODO: POST $kBaseUrl/auth/login
    // body   → { "email": email, "password": password }
    // expect → UserModel JSON
    // 401    → throw AuthException('Incorrect email or password.')
    throw UnimplementedError('Backend not connected yet.');
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    // TODO: POST $kBaseUrl/auth/register
    // body   → { "firstName", "lastName", "email", "phone", "password" }
    // expect → UserModel JSON
    throw UnimplementedError('Backend not connected yet.');
  }

  @override
  Future<void> sendOtp(String phone) async {
    // TODO: POST $kBaseUrl/auth/otp/send
    // body   → { "phone": phone }
    // expect → 200 OK
    throw UnimplementedError('Backend not connected yet.');
  }

  @override
  Future<UserModel?> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    // TODO: POST $kBaseUrl/auth/otp/verify
    // body   → { "phone": phone, "otp": otp }
    // expect → UserModel JSON if phone registered, null if new user
    // 400/401→ throw AuthException('Invalid OTP.')
    throw UnimplementedError('Backend not connected yet.');
  }

  @override
  Future<UserModel> createAccountWithPhone({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    // TODO: POST $kBaseUrl/auth/register-phone
    // body   → { "firstName", "lastName", "email", "phone" }
    // expect → UserModel JSON
    throw UnimplementedError('Backend not connected yet.');
  }

  @override
  Future<UserModel> updateProfile({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String address,
  }) async {
    // TODO: PUT $kBaseUrl/users/$id/profile
    // body   → { "firstName", "lastName", "email", "address" }
    // expect → updated UserModel JSON
    throw UnimplementedError('Backend not connected yet.');
  }

  @override
  Future<void> changePassword({
    required String id,
    required String currentPassword,
    required String newPassword,
  }) async {
    // TODO: POST $kBaseUrl/users/$id/change-password
    // body   → { "currentPassword", "newPassword" }
    // 400    → throw AuthException('Incorrect current password.')
    throw UnimplementedError('Backend not connected yet.');
  }
}