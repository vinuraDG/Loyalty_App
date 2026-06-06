// lib/services/mock_auth_service.dart

import 'dart:math';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/models/user_model.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class MockAuthService {
  MockAuthService._();
  static final MockAuthService instance = MockAuthService._();

  // Seeded from mock_data.dart — single source of truth for demo accounts.
  final List<UserModel> _users = kMockUsers
      .map((m) => UserModel(
            id:          m['id']          as String,
            firstName:   m['firstName']   as String,
            lastName:    m['lastName']    as String,
            email:       m['email']       as String,
            phone:       m['phone']       as String,
            role:        m['role']        as String,
            totalPoints: m['points']      as int,
            address:     (m['address'] as String?) ?? '',
            createdAt:   DateTime(2024, 1, 15),
          ))
      .toList();

  // OTP store: phone → otp (used for both login and password-reset flows)
  final Map<String, String> _otpStore = {};

  // Temporary password-reset token store: phone → token
  // TODO (backend): replace with a real short-lived JWT / DB record.
  final Map<String, String> _resetTokenStore = {};

  // ── Sign up ───────────────────────────────────────────────────────────────

  Future<UserModel> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _delay();
    if (_users.any(
        (u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      throw const AuthException('An account with this email already exists.');
    }
    if (_users.any((u) => u.phone.trim() == phone.trim())) {
      throw const AuthException('This phone number is already registered.');
    }
    final user = UserModel(
      id:          _genId(),
      firstName:   firstName.trim(),
      lastName:    lastName.trim(),
      email:       email.trim().toLowerCase(),
      phone:       phone.trim(),
      role:        'customer',
      totalPoints: 0,
      createdAt:   DateTime.now(),
    );
    _users.add(user);
    return user;
  }

  // ── Sign in ───────────────────────────────────────────────────────────────

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _delay();
    final user = _users
        .where((u) => u.email.toLowerCase() == email.trim().toLowerCase())
        .firstOrNull;
    if (user == null) {
      throw const AuthException('No account found with this email address.');
    }
    if (password.isEmpty) {
      throw const AuthException('Password cannot be empty.');
    }
    // Passwords stored in kMockPasswords in mock_data.dart.
    // Newly registered users (no entry) accept any non-empty password.
    final stored = kMockPasswords[user.id];
    if (stored != null && password != stored) {
      throw const AuthException('Incorrect password. Please try again.');
    }
    return user;
  }

  // ── OTP (login) ───────────────────────────────────────────────────────────

  Future<void> sendOtp(String phone) async {
    await _delay(ms: 800);
    _otpStore[phone.trim()] = kMockOtp;
  }

  Future<UserModel?> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    await _delay(ms: 600);
    final stored = _otpStore[phone.trim()];
    if (stored == null || stored != otp.trim()) {
      throw const AuthException('Invalid OTP. Please check and try again.');
    }
    _otpStore.remove(phone.trim());
    return _users.where((u) => u.phone.trim() == phone.trim()).firstOrNull;
  }

  Future<UserModel> createAccountWithPhone({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    await _delay();
    if (_users.any(
        (u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      throw const AuthException('This email is already in use.');
    }
    final user = UserModel(
      id:          _genId(),
      firstName:   firstName.trim(),
      lastName:    lastName.trim(),
      email:       email.trim().toLowerCase(),
      phone:       phone.trim(),
      role:        'customer',
      totalPoints: 0,
      createdAt:   DateTime.now(),
    );
    _users.add(user);
    return user;
  }

  // ── Forgot password ───────────────────────────────────────────────────────
  //
  // Flow:
  //   1. sendOtpForReset  — verify phone exists, then "send" OTP (mock = kMockOtp)
  //   2. verifyOtpForReset — validate OTP, mint a reset token
  //   3. resetPassword    — validate token, update password in mock store
  //
  // TODO (backend): replace each method body with the corresponding real API call.

  /// Step 1 — verify the phone is registered, then SMS an OTP.
  /// Throws [AuthException] if the phone is not found.
  Future<void> sendOtpForReset(String phone) async {
    await _delay(ms: 800);
    final exists = _users.any((u) => u.phone.trim() == phone.trim());
    if (!exists) {
      throw const AuthException(
          'No account found with this phone number.');
    }
    // TODO (backend): generate a real OTP and send via SMS.
    _otpStore[phone.trim()] = kMockOtp;
  }

  /// Step 2 — validate the OTP. Returns true and mints a reset token on success.
  /// Returns false (never throws) when OTP is wrong so the screen can show
  /// a field-level error.
  Future<bool> verifyOtpForReset({
    required String phone,
    required String otp,
  }) async {
    await _delay(ms: 600);
    final stored = _otpStore[phone.trim()];
    if (stored == null || stored != otp.trim()) return false;
    _otpStore.remove(phone.trim());
    // Mint a mock reset token.
    // TODO (backend): return a real short-lived JWT here instead.
    _resetTokenStore[phone.trim()] = _genId();
    return true;
  }

  /// Step 3 — validate the reset token and update the mock password store.
  /// Throws [AuthException] if the reset token is missing (OTP not verified).
  Future<void> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    await _delay();
    final token = _resetTokenStore[phone.trim()];
    if (token == null) {
      throw const AuthException(
          'Reset session expired. Please start over.');
    }
    _resetTokenStore.remove(phone.trim());

    // In mock mode we just verify the user exists.
    // TODO (backend): hash newPassword and persist via API.
    final exists = _users.any((u) => u.phone.trim() == phone.trim());
    if (!exists) {
      throw const AuthException('User not found.');
    }
    // Mock: password "updated" — login via email will accept any non-empty
    // password for newly-registered users; for seeded users kMockPasswords
    // is not mutated here (acceptable for demo, backend will do the real work).
  }

  // ── Profile update ────────────────────────────────────────────────────────

  Future<UserModel> updateProfile({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    required String address,
  }) async {
    await _delay(ms: 800);
    final i = _users.indexWhere((u) => u.id == id);
    if (i == -1) throw const AuthException('User not found.');
    final emailTaken = _users.any(
      (u) => u.id != id &&
          u.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (emailTaken) {
      throw const AuthException(
          'This email is already used by another account.');
    }
    final updated = _users[i].copyWith(
      firstName: firstName.trim(),
      lastName:  lastName.trim(),
      email:     email.trim().toLowerCase(),
      address:   address.trim(),
    );
    _users[i] = updated;
    return updated;
  }

  Future<void> changePassword({
    required String id,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _delay();
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw const AuthException('Password fields cannot be empty.');
    }
    // Mock: always succeeds when fields are non-empty.
  }

  // ── Helpers (mock-only, used by auth_provider.dart) ───────────────────────

  UserModel? findById(String id) =>
      _users.where((u) => u.id == id).firstOrNull;

  void updateUser(UserModel updated) {
    final i = _users.indexWhere((u) => u.id == updated.id);
    if (i != -1) _users[i] = updated;
  }

  Future<void> _delay({int ms = 1200}) =>
      Future.delayed(Duration(milliseconds: ms));

  String _genId() =>
      '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
}