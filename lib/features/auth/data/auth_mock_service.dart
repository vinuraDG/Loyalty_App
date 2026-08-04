import 'dart:convert';
import 'dart:math';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/auth/data/auth_api_service.dart';
import 'package:loyalty_app/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthMockService implements IAuthService {
  AuthMockService._();
  static final AuthMockService instance = AuthMockService._();

  final List<UserModel> _users = kMockUsers
      .map((m) => UserModel(
            id: m['id'] as String,
            firstName: m['firstName'] as String,
            lastName: m['lastName'] as String,
            email: m['email'] as String,
            phone: m['phone'] as String,
            role: m['role'] as String,
            totalPoints: m['points'] as int,
            address: (m['address'] as String?) ?? '',
            createdAt: DateTime(2024, 1, 15),
          ))
      .toList();

  final Map<String, String> _otpStore = {};

  // ── All-time points helper ────────────────────────────────────────────────
  // Earned (non-expired) minus redeemed across ALL time = current balance.

  int _computePoints(String userId) {
    final earned = kMockTransactions
        .where((t) =>
            t['userId'] == userId &&
            (t['isEarned'] as bool? ?? false) == true &&
            (t['isExpired'] as bool? ?? false) == false)
        .fold<int>(0, (sum, t) => sum + (t['points'] as int));

    final redeemed = kMockTransactions
        .where((t) =>
            t['userId'] == userId &&
            (t['isEarned'] as bool? ?? false) == false &&
            (t['isExpired'] as bool? ?? false) == false)
        .fold<int>(0, (sum, t) => sum + (t['points'] as int));

    return earned - redeemed;
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
    await _delay();
    if (_users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      throw const AuthException('An account with this email already exists.');
    }
    if (_users.any((u) => u.phone.trim() == phone.trim())) {
      throw const AuthException('This phone number is already registered.');
    }
    final user = UserModel(
      id: _genId(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      role: 'customer',
      totalPoints: 0,
      address: address.trim(),
      createdAt: DateTime.now(),
    );
    _users.add(user);
    return user;
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _delay();
    var user = _users
        .where((u) => u.email.toLowerCase() == email.trim().toLowerCase())
        .firstOrNull;

    // Not in memory (e.g. after app restart) — try SharedPreferences cache
    if (user == null) {
      user = await _restoreUserByEmail(email.trim().toLowerCase());
    }

    if (user == null) {
      throw const AuthException('No account found with this email address.');
    }
    if (password.isEmpty) throw const AuthException('Password cannot be empty.');
    final stored = kMockPasswords[user.id];
    if (stored != null && password != stored) {
      throw const AuthException('Incorrect password. Please try again.');
    }
    return user.copyWith(totalPoints: _computePoints(user.id));
  }

  /// Reads the last-logged-in user from SharedPreferences.
  /// Used as a fallback when `_users` doesn't contain the user (after restart).
  Future<UserModel?> _restoreUserByEmail(String emailLower) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json  = prefs.getString('userJson');
      if (json == null) return null;
      final u = UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
      if (u.email.toLowerCase() != emailLower) return null;
      if (!_users.any((x) => x.id == u.id)) _users.add(u);
      return u;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> sendOtp(String phone) async {
    await _delay(ms: 800);
    _otpStore[phone.trim()] = AppConstants.mockOtp;
  }

  @override
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
    final user = _users.where((u) => u.phone.trim() == phone.trim()).firstOrNull;
    if (user == null) return null;
    return user.copyWith(totalPoints: _computePoints(user.id));
  }

  @override
  Future<UserModel> createAccountWithPhone({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    await _delay();
    if (_users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      throw const AuthException('This email is already in use.');
    }
    final user = UserModel(
      id: _genId(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      role: 'customer',
      totalPoints: 0,
      createdAt: DateTime.now(),
    );
    _users.add(user);
    return user;
  }

  @override
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
      (u) => u.id != id && u.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (emailTaken) throw const AuthException('This email is already in use.');
    final updated = _users[i].copyWith(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().toLowerCase(),
      address: address.trim(),
    );
    _users[i] = updated;
    return updated;
  }

  @override
  Future<void> changePassword({
    required String id,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _delay();
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw const AuthException('Password fields cannot be empty.');
    }
  }

  @override
  Future<void> sendOtpForReset(String phone) async {
    await _delay(ms: 800);
    _otpStore[phone.trim()] = AppConstants.mockOtp;
  }

  @override
  Future<bool> verifyOtpForReset({
    required String phone,
    required String otp,
  }) async {
    await _delay(ms: 600);
    final stored = _otpStore[phone.trim()];
    if (stored == null || stored != otp.trim()) return false;
    _otpStore.remove(phone.trim());
    return true;
  }

  @override
  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    await _delay();
  }

  @override
  Future<UserModel?> findById(String id) async {
    var user = _users.where((u) => u.id == id).firstOrNull;
    if (user != null) return user.copyWith(totalPoints: _computePoints(id));

    // Fallback: user was registered in a previous session — restore from prefs
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString(AppConstants.prefUserId);
      if (storedId != id) return null;
      final json = prefs.getString('userJson');
      if (json == null) return null;
      final restored = UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
      if (!_users.any((x) => x.id == restored.id)) _users.add(restored);
      return restored.copyWith(totalPoints: _computePoints(id));
    } catch (_) {
      return null;
    }
  }

  UserModel? findByIdSync(String id) =>
      _users.where((u) => u.id == id).firstOrNull;

  void updateUser(UserModel updated) {
    final i = _users.indexWhere((u) => u.id == updated.id);
    if (i != -1) _users[i] = updated;
  }

  // ── Employee lookup (mock) ───────────────────────────────────────────────

  @override
  Future<UserModel> getEmployeeByPhone(String phone) async {
    await _delay(ms: 600);
    final trimmed = phone.trim();
    final existing = _users
        .where((u) => u.phone.trim() == trimmed && u.role == 'employee')
        .firstOrNull;
    if (existing != null) {
      return existing.copyWith(totalPoints: _computePoints(existing.id));
    }

    // No seeded mock employee for this number — mirror the real API's
    // "not found" behavior instead of inventing one.
    final anyEmployee = _users.where((u) => u.role == 'employee').firstOrNull;
    if (anyEmployee != null) {
      return anyEmployee.copyWith(
        phone: trimmed,
        totalPoints: _computePoints(anyEmployee.id),
      );
    }

    throw AuthException('No employee found for phone number $trimmed.');
  }

  @override
  Future<void> registerIdentityOnly({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _delay();
    if (_users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      throw const AuthException('An account with this email already exists.');
    }
    if (_users.any((u) => u.phone.trim() == phone.trim())) {
      throw const AuthException('This phone number is already registered.');
    }
    _otpStore[phone.trim()] = AppConstants.mockOtp;
  }

  @override
  Future<UserModel> completeCustomerRegistration({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String address,
  }) async {
    await _delay();
    final existing = _users.where((u) => u.phone.trim() == phone.trim()).firstOrNull;
    if (existing != null) return existing;
    final user = UserModel(
      id: _genId(),
      firstName: firstName.trim(),
      lastName:  lastName.trim(),
      email:     email.trim().toLowerCase(),
      phone:     phone.trim(),
      role:      'customer',
      totalPoints: 0,
      address:   address.trim(),
      createdAt: DateTime.now(),
    );
    _users.add(user);
    return user;
  }

  @override
  Future<void> sendPhoneConfirmation(String phone) async {
    await _delay(ms: 800);
    _otpStore[phone.trim()] = AppConstants.mockOtp;
  }

  @override
  Future<void> confirmPhone({required String phone, required String otp}) async {
    await _delay(ms: 600);
    final expected = _otpStore[phone.trim()];
    if (expected == null || otp.trim() != expected) {
      throw const AuthException('Invalid OTP. Please try again.');
    }
  }

  @override
  Future<void> deleteAccount() async {
    await _delay(ms: 800);
    // In mock mode, simply remove the in-memory user record.
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(AppConstants.prefUserId) ?? '';
    _users.removeWhere((u) => u.id == id);
  }

  @override
  Future<void> sendEmailVerification(String phone) async {
    await _delay(ms: 800);
    // In mock mode, mark the user as email-confirmed after a simulated send.
    final i = _users.indexWhere((u) => u.phone.trim() == phone.trim());
    if (i != -1) _users[i] = _users[i].copyWith(emailConfirmed: true);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _delay(ms: 800);
    // In mock mode, store a fake token keyed by email.
    _otpStore[email.trim()] = AppConstants.mockOtp;
  }

  @override
  Future<void> resetPasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _delay();
    final expected = _otpStore[email.trim()];
    if (expected != null && token.trim() != expected) {
      throw const AuthException('Invalid or expired reset link.');
    }
    _otpStore.remove(email.trim());
  }

  Future<void> _delay({int ms = 1200}) =>
      Future.delayed(Duration(milliseconds: ms));

  String _genId() =>
      '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
}

// ignore: non_constant_identifier_names
String get AppConstants_mockOtp => AppConstants.mockOtp;