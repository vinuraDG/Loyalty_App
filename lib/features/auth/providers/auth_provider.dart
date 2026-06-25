import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/features/auth/data/auth_api_service.dart';
import 'package:loyalty_app/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String?    errorMessage;
  final String?    pendingPhone;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.pendingPhone,
  });

  bool get isLoading       => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isEmployee      => user?.role == 'employee';

  AuthState copyWith({
    AuthStatus? status,
    UserModel?  user,
    String?     errorMessage,
    String?     pendingPhone,
  }) =>
      AuthState(
        status:       status       ?? this.status,
        user:         user         ?? this.user,
        errorMessage: errorMessage,
        pendingPhone: pendingPhone ?? this.pendingPhone,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _restoreSession();
  }

  // ── routes through AppConstants.useMockServices ────────────────────────────
  final _auth = authService;

  // ── Session ───────────────────────────────────────────────────────────────

  Future<void> _restoreSession() async {
    final prefs   = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;
    final userId   = prefs.getString(AppConstants.prefUserId);

    if (loggedIn && userId != null) {
      final user = await _auth.findById(userId).timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
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
    await prefs.setString(AppConstants.prefUserPhone, user.phone);
    await prefs.setString('userJson', jsonEncode(user.toJson()));
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefIsLoggedIn);
    await prefs.remove(AppConstants.prefUserId);
    await prefs.remove(AppConstants.prefUserRole);
    await prefs.remove(AppConstants.prefAuthToken);
    await prefs.remove(AppConstants.prefUserPhone);
    await prefs.remove('userJson');
  }

  // ── Email / username login ────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _auth.signInWithEmail(
        email: email,
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

  Future<void> signUpWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _auth.signUpWithEmail(
        firstName: firstName,
        lastName:  lastName,
        email:     email,
        phone:     phone,
        password:  password,
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

  // ── Phone / OTP ───────────────────────────────────────────────────────────

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _auth.sendOtp(phone);
      state = state.copyWith(
          status: AuthStatus.unauthenticated, pendingPhone: phone);
    } on AuthException catch (e) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated, errorMessage: e.message);
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
      final user =
          await _auth.verifyOtp(phone: state.pendingPhone!, otp: otp);
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
        lastName:  lastName,
        email:     email,
        phone:     state.pendingPhone!,
      );
      await _saveSession(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(
          status: AuthStatus.unauthenticated, errorMessage: e.message);
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────

  Future<void> sendOtpForReset(String phone) async {
    await _auth.sendOtpForReset(phone);
  }

  Future<bool> verifyOtpForReset({
    required String phone,
    required String otp,
  }) async {
    return _auth.verifyOtpForReset(phone: phone, otp: otp);
  }

  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    await _auth.resetPassword(phone: phone, otp: otp, newPassword: newPassword);
  }

  // ── Profile ───────────────────────────────────────────────────────────────

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
        id:        state.user!.id,
        firstName: firstName,
        lastName:  lastName,
        email:     email,
        address:   address,
      );
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
        id:              state.user!.id,
        currentPassword: currentPassword,
        newPassword:     newPassword,
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

  // ── Dev bypass login (no backend auth required) ───────────────────────────

  void devLogin(UserModel user) {
    state = state.copyWith(status: AuthStatus.authenticated, user: user);
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  void refreshUser() async {
    if (state.user == null) return;
    try {
      final fresh = await _auth.findById(state.user!.id);
      if (fresh != null) state = state.copyWith(user: fresh);
    } catch (_) {
      // Non-critical: stale user data remains in state.
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

final currentUserProvider = Provider<UserModel?>(
  (ref) => ref.watch(authProvider).user,
);