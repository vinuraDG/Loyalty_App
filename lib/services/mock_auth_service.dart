import 'dart:math';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override String toString() => message;
}

class MockAuthService {
  MockAuthService._();
  static final MockAuthService instance = MockAuthService._();

  final List<UserModel> _users = [
    UserModel(id:'cust-001', name:'Kasun Perera', email:'kasun@email.com',
      phone:'0771234567', role:'customer', totalPoints:4820,
      createdAt:DateTime(2024,1,15)),
    UserModel(id:'emp-001', name:'Nimal Silva', email:'nimal@loyaltyhub.lk',
      phone:'0779876543', role:'employee', totalPoints:0,
      createdAt:DateTime(2024,1,10)),
  ];

  final Map<String, String> _otpStore = {};

  Future<UserModel> signUpWithEmail({
    required String name, required String email,
    required String phone, required String password,
  }) async {
    await _delay();
    if (_users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      throw const AuthException('An account with this email already exists.');
    }
    if (_users.any((u) => u.phone.trim() == phone.trim())) {
      throw const AuthException('This phone number is already registered.');
    }
    final user = UserModel(
      id: _genId(), name: name.trim(),
      email: email.trim().toLowerCase(), phone: phone.trim(),
      role: 'customer', totalPoints: 0, createdAt: DateTime.now(),
    );
    _users.add(user);
    return user;
  }

  Future<UserModel> signInWithEmail({
    required String email, required String password,
  }) async {
    await _delay();
    final user = _users.where(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase()
    ).firstOrNull;
    if (user == null) throw const AuthException('No account found with this email address.');
    if (password.isEmpty) throw const AuthException('Password cannot be empty.');
    return user;
  }

  Future<void> sendOtp(String phone) async {
    await _delay(ms: 800);
    _otpStore[phone.trim()] = '1234';
  }

  Future<UserModel?> verifyOtp({required String phone, required String otp}) async {
    await _delay(ms: 600);
    final stored = _otpStore[phone.trim()];
    if (stored == null || stored != otp.trim()) {
      throw const AuthException('Invalid OTP. Please check and try again.');
    }
    _otpStore.remove(phone.trim());
    return _users.where((u) => u.phone.trim() == phone.trim()).firstOrNull;
  }

  Future<UserModel> createAccountWithPhone({
    required String name, required String email, required String phone,
  }) async {
    await _delay();
    if (_users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      throw const AuthException('This email is already in use.');
    }
    final user = UserModel(
      id: _genId(), name: name.trim(),
      email: email.trim().toLowerCase(), phone: phone.trim(),
      role: 'customer', totalPoints: 0, createdAt: DateTime.now(),
    );
    _users.add(user);
    return user;
  }

  UserModel? findById(String id) => _users.where((u) => u.id == id).firstOrNull;
  void updateUser(UserModel updated) {
    final i = _users.indexWhere((u) => u.id == updated.id);
    if (i != -1) _users[i] = updated;
  }

  Future<void> _delay({int ms = 1200}) => Future.delayed(Duration(milliseconds: ms));
  String _genId() => '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
}