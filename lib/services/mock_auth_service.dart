import 'dart:math';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class MockAuthService {
  MockAuthService._();
  static final MockAuthService instance = MockAuthService._();

  final List<UserModel> _users = [
    UserModel(
      id: 'cust-001',
      firstName: 'Kasun',
      lastName: 'Perera',
      email: 'customer@gmail.com',
      phone: '0771234567',
      role: 'customer',
      totalPoints: 4820,
      address: '42 Galle Road, Colombo 03',
      createdAt: DateTime(2024, 1, 15),
    ),
    UserModel(
      id: 'emp-001',
      firstName: 'Nimal',
      lastName: 'Silva',
      email: 'employee@gmail.com',
      phone: '0779876543',
      role: 'employee',
      totalPoints: 0,
      createdAt: DateTime(2024, 1, 10),
    ),
  ];

  final Map<String, String> _otpStore = {};

  // ── Auth ───────────────────────────────────────────────────────────────────

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
    return user;
  }

  // ── OTP ────────────────────────────────────────────────────────────────────

  Future<void> sendOtp(String phone) async {
    await _delay(ms: 800);
    _otpStore[phone.trim()] = '1234';
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

  // ── Profile update ─────────────────────────────────────────────────────────

  /// Updates editable profile fields. Phone is intentionally excluded
  /// (phone changes require OTP re-verification).
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

    // Check email uniqueness (allow same user to keep their own email)
    final emailTaken = _users.any(
      (u) => u.id != id &&
             u.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (emailTaken) {
      throw const AuthException('This email is already used by another account.');
    }

    final updated = _users[i].copyWith(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().toLowerCase(),
      address: address.trim(),
    );
    _users[i] = updated;
    return updated;
  }

  /// Stub password change — swap for real auth logic when ready.
  Future<void> changePassword({
    required String id,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _delay();
    // TODO: verify currentPassword against stored hash
    // For now, always succeeds as long as fields are non-empty.
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw const AuthException('Password fields cannot be empty.');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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