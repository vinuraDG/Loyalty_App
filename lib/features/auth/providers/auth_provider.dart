import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
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
  bool get isEmployee => user?.role == 'employee';

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    String? pendingPhone,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage,
        pendingPhone: pendingPhone ?? this.pendingPhone,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _restoreSession();
  }

  final _auth = MockAuthService.instance;

  // ── Session ───────────────────────────────────────────────────

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;
    final userId = prefs.getString(AppConstants.prefUserId);
    if (loggedIn && userId != null) {
      final user = _auth.findById(userId);
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        return;
      }
    }
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsLoggedIn, true);
    await prefs.setString(AppConstants.prefUserId, user.id);
    await prefs.setString(AppConstants.prefUserRole, user.role);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefIsLoggedIn);
    await prefs.remove(AppConstants.prefUserId);
    await prefs.remove(AppConstants.prefUserRole);
  }

  // ── Email Auth ────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user =
          await _auth.signInWithEmail(email: email, password: password);
      await _saveSession(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Something went wrong.');
    }
  }

  Future<void> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password, // ← removed 'required String name' from here
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _auth.signUpWithEmail(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      );
      await _saveSession(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Something went wrong.');
    }
  }

  // ── Phone / OTP ───────────────────────────────────────────────

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _auth.sendOtp(phone);
      state = state.copyWith(
          status: AuthStatus.unauthenticated, pendingPhone: phone);
    } catch (_) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Failed to send OTP.');
    }
  }

  Future<UserModel?> verifyOtp(String otp) async {
    if (state.pendingPhone == null) return null;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _auth.verifyOtp(phone: state.pendingPhone!, otp: otp);
      if (user != null) {
        await _saveSession(user);
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
      return user;
    } on AuthException catch (e) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated, errorMessage: e.message);
      return null;
    }
  }

  Future<void> createAccountWithPhone(
      String firstName, String lastName, String email) async {
    if (state.pendingPhone == null) return;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _auth.createAccountWithPhone(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: state.pendingPhone!,
      );
      await _saveSession(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated, errorMessage: e.message);
    }
  }

  // ── Profile update ────────────────────────────────────────────

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String address,
  }) async {
    if (state.user == null) return;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final updated = await _auth.updateProfile(
        id: state.user!.id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        address: address,
      );
      await _saveSession(updated);
      state = state.copyWith(status: AuthStatus.authenticated, user: updated);
    } on AuthException catch (e) {
      state = state.copyWith(
          status: AuthStatus.authenticated, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
          status: AuthStatus.authenticated,
          errorMessage: 'Something went wrong.');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.user == null) return;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _auth.changePassword(
        id: state.user!.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(status: AuthStatus.authenticated);
    } on AuthException catch (e) {
      state = state.copyWith(
          status: AuthStatus.authenticated, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
          status: AuthStatus.authenticated,
          errorMessage: 'Something went wrong.');
    }
  }

  // ── Misc ──────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  void refreshUser() {
    if (state.user == null) return;
    final fresh = _auth.findById(state.user!.id);
    if (fresh != null) state = state.copyWith(user: fresh);
  }
}

// ── Providers ─────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

final currentUserProvider = Provider<UserModel?>(
  (ref) => ref.watch(authProvider).user,
);
