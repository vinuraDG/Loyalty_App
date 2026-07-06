// auth_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/features/auth/data/auth_api_service.dart';
import 'package:loyalty_app/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String?    errorMessage;
  final String?    pendingPhone;
  final bool       registrationSuccess;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.pendingPhone,
    this.registrationSuccess = false,
  });

  bool get isLoading       => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isEmployee      => user?.role == 'employee';

  AuthState copyWith({
    AuthStatus? status,
    UserModel?  user,
    String?     errorMessage,
    String?     pendingPhone,
    bool?       registrationSuccess,
  }) =>
      AuthState(
        status:              status              ?? this.status,
        user:                user                ?? this.user,
        errorMessage:        errorMessage,
        pendingPhone:        pendingPhone        ?? this.pendingPhone,
        registrationSuccess: registrationSuccess ?? false,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _restoreSession();
  }

  final _auth = authService;

  // ── Session ───────────────────────────────────────────────────────────────

  Future<void> _restoreSession() async {
    final prefs    = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(AppConstants.prefIsLoggedIn) ?? false;
    final userId   = prefs.getString(AppConstants.prefUserId);

    if (loggedIn && userId != null) {
      final user = await _auth.findById(userId).timeout(
        const Duration(seconds: 8),
        onTimeout: () => null,
      );
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        return;
      }
      await _clearSession();
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
    ApiClient.instance.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefIsLoggedIn);
    await prefs.remove(AppConstants.prefUserId);
    await prefs.remove(AppConstants.prefUserRole);
    await prefs.remove(AppConstants.prefAuthToken);
    await prefs.remove(AppConstants.prefUserPhone);
    await prefs.remove(AppConstants.prefUserEmail);
    await prefs.remove(AppConstants.prefUserPassword);
    await prefs.remove('userJson');
  }

  // ── Error helper — raw message, zero transformation ───────────────────────

  void _setError(String message, {bool preserveAuthenticated = false}) {
    // When preserveAuthenticated is true (profile/password updates), always
    // stay authenticated — state.isAuthenticated is false during loading so
    // checking it here would incorrectly log the user out on any error.
    final targetStatus = preserveAuthenticated
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    state = state.copyWith(status: targetStatus, errorMessage: message);
  }

  // ── Sign in ───────────────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _auth.signInWithEmail(email: email, password: password);
      await _saveSession(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── Sign up ───────────────────────────────────────────────────────────────

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
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        registrationSuccess: true,
      );
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
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
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
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
        _setError('Invalid OTP. Please try again.');
      }
      return user;
    } on AuthException catch (e) {
      _setError(e.message);
      return null;
    } catch (e) {
      _setError(e.toString());
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
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
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
      _setError(e.message, preserveAuthenticated: true);
    } catch (e) {
      _setError(e.toString(), preserveAuthenticated: true);
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
      _setError(e.message, preserveAuthenticated: true);
    } catch (e) {
      _setError(e.toString(), preserveAuthenticated: true);
    }
  }

  // ── Dev bypass ────────────────────────────────────────────────────────────

  Future<void> devLogin(UserModel user) async {
    await _saveSession(user);
    state = state.copyWith(status: AuthStatus.authenticated, user: user);
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() =>
      state = state.copyWith(status: state.status, errorMessage: null);

  void refreshUser() async {
    if (state.user == null) return;
    try {
      final fresh = await _auth.findById(state.user!.id);
      if (fresh != null) state = state.copyWith(user: fresh);
    } catch (_) {}
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

final currentUserProvider = Provider<UserModel?>(
  (ref) => ref.watch(authProvider).user,
);