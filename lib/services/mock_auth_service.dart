import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class MockAuthService {
  MockAuthService._();
  static final instance = MockAuthService._();

  final List<UserModel> _users = [
    UserModel(
      id: 'demo-001',
      name: 'Kasun Perera',
      email: 'kasun@email.com',
      phone: '0771234567',
      totalPoints: 4820,
    ),
    UserModel(
      id: 'emp-001',
      name: 'Nimal Silva',
      email: 'nimal@loyaltyhub.lk',
      phone: '0779876543',
      role: 'employee',
    ),
  ];

  final _otpStore = <String, String>{};

  Future<UserModel> signInWithPhone(
      {required String phone, required String password}) async {
    await _delay();
    final user = _users.where((u) => u.phone == phone).firstOrNull;
    if (user == null) throw AuthException('No account found for that number.');
    // Mock: any non-empty password works
    if (password.isEmpty) throw AuthException('Password cannot be empty.');
    return user;
  }

  Future<UserModel> signInWithEmail(
      {required String email, required String password}) async {
    await _delay();
    final user =
        _users.where((u) => u.email == email.toLowerCase()).firstOrNull;
    if (user == null) throw AuthException('No account found.');
    return user;
  }

  Future<void> sendOtp(String phone) async {
    await _delay(ms: 800);
    _otpStore[phone] = '1234';
  }

  Future<UserModel?> verifyOtp(
      {required String phone, required String otp}) async {
    await _delay(ms: 600);
    if (_otpStore[phone] != otp) throw AuthException('Invalid OTP.');
    _otpStore.remove(phone);
    return _users.where((u) => u.phone == phone).firstOrNull;
  }

  UserModel? findUserById(String id) =>
      _users.where((u) => u.id == id).firstOrNull;

  Future _delay({int ms = 1000}) =>
      Future.delayed(Duration(milliseconds: ms));
}