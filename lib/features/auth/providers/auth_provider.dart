import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/models/user_model.dart';
import 'package:loyalty_app/services/mock_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? pendingPhone;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.pendingPhone,
  });
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _restoreSession(); // auto-login on app start
  }

  final _auth = MockAuthService.instance;

  Future _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId');
    if (id != null) {
      final user = _auth.findUserById(id);
      if (user is UserModel) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return;
      }
    }
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', user.id);
  }

  Future signInWithEmail(String email, String pass) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final user = await _auth.signInWithEmail(email: email, password: pass);
      await _saveSession(user);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = AuthState(
          status: AuthStatus.unauthenticated, errorMessage: e.message);
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

final currentUserProvider =
    Provider<UserModel?>((ref) => ref.watch(authProvider).user);
