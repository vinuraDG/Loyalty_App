// auth_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/constants/app_constants.dart';
import 'package:loyalty_app/core/network/api_client.dart';
import 'package:loyalty_app/data/companies_api_service.dart';
import 'package:loyalty_app/data/customer_ledger_service.dart';
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
  final bool       emailNotConfirmed;
  final bool       phoneNotConfirmed;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.pendingPhone,
    this.registrationSuccess = false,
    this.emailNotConfirmed   = false,
    this.phoneNotConfirmed   = false,
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
    bool?       emailNotConfirmed,
    bool?       phoneNotConfirmed,
  }) =>
      AuthState(
        status:              status              ?? this.status,
        user:                user                ?? this.user,
        errorMessage:        errorMessage,
        pendingPhone:        pendingPhone        ?? this.pendingPhone,
        registrationSuccess: registrationSuccess ?? false,
        emailNotConfirmed:   emailNotConfirmed   ?? false,
        phoneNotConfirmed:   phoneNotConfirmed   ?? false,
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
      if (user != null && user.role != 'employee' &&
          (!user.phoneConfirmed || !user.emailConfirmed)) {
        await _clearSession();
      } else if (user != null) {
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
    AppConstants.resetActiveCompanyId();
    CompaniesApiService.instance.clearCache();
    CustomerLedgerService.instance.clearCache();
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('scan_names_')) await prefs.remove(key);
    }
    await prefs.remove(AppConstants.prefIsLoggedIn);
    await prefs.remove(AppConstants.prefUserId);
    await prefs.remove(AppConstants.prefUserRole);
    await prefs.remove(AppConstants.prefAuthToken);
    await prefs.remove(AppConstants.prefUserPhone);
    await prefs.remove(AppConstants.prefUserEmail);
    await prefs.remove(AppConstants.prefUserPassword);
    await prefs.remove(AppConstants.prefEmailConfirmed);
    await prefs.remove(AppConstants.prefPhoneConfirmed);
    await prefs.remove('userJson');
    await prefs.remove(AppConstants.prefEmployeeCompanyId);
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
      if (user.role != 'employee') {
        if (!user.phoneConfirmed) {
          try { await _auth.sendPhoneConfirmation(user.phone); } catch (_) {}
          // Also send email verification now so the link is ready when phone is done
          if (!user.emailConfirmed) {
            try { await _auth.sendEmailVerification(user.phone); } catch (_) {}
          }
          await _clearSession();
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            phoneNotConfirmed: true,
            pendingPhone: user.phone,
          );
          return;
        }
        if (!user.emailConfirmed) {
          try { await _auth.sendEmailVerification(user.phone); } catch (_) {}
          await _clearSession();
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            emailNotConfirmed: true,
            pendingPhone: user.phone,
          );
          return;
        }
      }
      await _saveSession(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Called by LoginPhoneOtpScreen after phone OTP is confirmed.
  /// Routes to email verification only if backend says email is unconfirmed.
  Future<void> signInAfterPhoneVerification(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _auth.signInWithEmail(email: email, password: password);
      if (user.role != 'employee' && !user.emailConfirmed) {
        try { await _auth.sendEmailVerification(user.phone); } catch (_) {}
        await _clearSession();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          emailNotConfirmed: true,
          pendingPhone: user.phone,
        );
        return;
      }
      await _saveSession(user);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Verifies the email OTP sent to the user's email address.
  Future<void> confirmEmail({required String phone, required String otp}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _auth.confirmEmail(phone: phone, otp: otp);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Final login step called from LoginEmailVerifyScreen after user clicks the email link.
  /// Checks IsEmailConfirmed from backend — blocks login if link not yet clicked.
  Future<void> signInAfterEmailVerification(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _auth.signInWithEmail(email: email, password: password);
      if (user.role != 'employee' && !user.emailConfirmed) {
        _setError(
          'Email not verified yet. Please click the link in your inbox first, then try again.',
        );
        return;
      }
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
    required String address,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _auth.signUpWithEmail(
        firstName: firstName,
        lastName:  lastName,
        email:     email,
        phone:     phone,
        password:  password,
        address:   address,
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

  /// Creates the account but does NOT authenticate — caller navigates to login.
  Future<void> registerAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String address,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _auth.signUpWithEmail(
        firstName: firstName,
        lastName:  lastName,
        email:     email,
        phone:     phone,
        password:  password,
        address:   address,
      );
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
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

  // ── Registration (split into identity + post-OTP completion) ─────────────

  /// Step 1 of the new signup flow: creates the ASP.NET Identity user.
  /// The backend sends an OTP to [phone] automatically at this point.
  Future<void> registerIdentityOnly({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String address = '',
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _auth.registerIdentityOnly(
        firstName: firstName,
        lastName:  lastName,
        email:     email,
        phone:     phone,
        password:  password,
        address:   address,
      );
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Step 2 (post-OTP): creates the customer loyalty profile then logs the
  /// user in. Call this only after [confirmPhone] succeeds.
  Future<void> completeRegistration({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String address,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _auth.completeCustomerRegistration(
        firstName: firstName,
        lastName:  lastName,
        email:     email,
        phone:     phone,
        password:  password,
        address:   address,
      );
      await _saveSession(user);
      // Send email verification link so the user can confirm before first login.
      try { await _auth.sendEmailVerification(phone); } catch (_) {}
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        registrationSuccess: true,
      );
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────

  Future<void> sendPhoneConfirmation(String phone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _auth.sendPhoneConfirmation(phone);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> confirmPhone({required String phone, required String otp}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _auth.confirmPhone(phone: phone, otp: otp);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> sendOtpForReset(String phone) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _auth.sendOtpForReset(phone);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _auth.sendPasswordResetEmail(email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> resetPasswordWithToken({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _auth.resetPasswordWithToken(
        email: email, token: token, newPassword: newPassword);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError(e.toString());
    }
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

  Future<void> deleteAccount() async {
    try {
      await _auth.deleteAccount();
      await _clearSession();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      _setError(e.toString(), preserveAuthenticated: true);
      rethrow;
    }
  }

  void clearError() =>
      state = state.copyWith(status: state.status, errorMessage: null);

  void clearEmailNotConfirmed() =>
      state = state.copyWith(emailNotConfirmed: false);

  void clearPhoneNotConfirmed() =>
      state = state.copyWith(phoneNotConfirmed: false);

  Future<void> resendEmailVerification(String phone) async {
    try { await _auth.sendEmailVerification(phone.trim()); } catch (_) {}
  }

  void refreshUser() async {
    if (state.user == null) return;
    try {
      final fresh = await _auth.findById(state.user!.id);
      if (fresh != null) state = state.copyWith(user: fresh);
    } catch (_) {}
  }

  Future<void> sendEmailVerification() async {
    if (state.user == null) return;
    await _auth.sendEmailVerification(state.user!.phone);
  }

  Future<void> refreshEmailStatus() async {
    if (state.user == null) return;
    try {
      final fresh = await _auth.findById(state.user!.id);
      if (fresh != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: fresh);
      }
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