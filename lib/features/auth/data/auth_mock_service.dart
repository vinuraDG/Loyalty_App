import 'dart:math';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/features/auth/data/auth_api_service.dart';
import 'package:loyalty_app/models/user_model.dart';

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

  @override
  Future<UserModel> signUpWithEmail({
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
    if (password.isEmpty) throw const AuthException('Password cannot be empty.');
    final stored = kMockPasswords[user.id];
    if (stored != null && password != stored) {
      throw const AuthException('Incorrect password. Please try again.');
    }
    return user;
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
    return _users.where((u) => u.phone.trim() == phone.trim()).firstOrNull;
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
    // Mock: always succeeds when fields are non-empty
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
    required String newPassword,
  }) async {
    await _delay();
    // Mock: always succeeds
  }

  @override
  Future<UserModel?> findById(String id) async =>
      _users.where((u) => u.id == id).firstOrNull;

  // Mock-only helpers used by other mock services
  UserModel? findByIdSync(String id) =>
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

// ignore: non_constant_identifier_names
String get AppConstants_mockOtp => AppConstants.mockOtp;