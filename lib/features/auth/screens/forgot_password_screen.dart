// lib/features/auth/screens/forgot_password_screen.dart
//
// Three-step forgot-password flow (mock only — backend TODO markers included):
//   Step 1 — Enter phone number
//   Step 2 — Verify OTP
//   Step 3 — Set new password
//
// All network calls are handled through AuthNotifier; swap
// MockAuthService → real API when the backend is ready.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';

// ── Step enum ─────────────────────────────────────────────────────────────────

enum _Step { phone, otp, newPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  _Step _step = _Step.phone;
  bool  _isLoading = false;
  String? _errorText;

  // ── Controllers ───────────────────────────────────────────────────────────
  final _phoneCtrl   = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneFormKey   = GlobalKey<FormState>();
  final _passFormKey    = GlobalKey<FormState>();

  // OTP — 4 individual boxes
  final List<TextEditingController> _otpCtrl =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocus =
      List.generate(4, (_) => FocusNode());

  bool _newPassVisible    = false;
  bool _confirmPassVisible = false;

  // Resend cooldown
  int _resendCooldown = 0;
  bool get _canResend => _resendCooldown == 0;

  // Animation
  late final AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    for (final c in _otpCtrl) c.dispose();
    for (final f in _otpFocus) f.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _goToStep(_Step step) {
    setState(() {
      _step = step;
      _errorText = null;
    });
    _animCtrl.forward(from: 0);
  }

  void _setError(String msg) => setState(() => _errorText = msg);
  void _clearError()         => setState(() => _errorText = null);

  Future<void> _startCooldown() async {
    setState(() => _resendCooldown = 30);
    for (int i = 30; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _resendCooldown = i - 1);
    }
  }

  String get _otpValue => _otpCtrl.map((c) => c.text).join();

  // ── Step 1 — Send OTP ─────────────────────────────────────────────────────

  Future<void> _sendOtp({bool resend = false}) async {
    if (!resend && !_phoneFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _clearError();
    setState(() => _isLoading = true);

    // TODO: replace with real API call — POST /auth/forgot-password/send-otp
    // Backend should:
    //   1. Verify phone exists in the system
    //   2. Generate + SMS a 4-digit OTP
    //   3. Return 200 OK or 404 if phone not found
    try {
      await ref.read(authProvider.notifier).sendOtpForReset(
            _phoneCtrl.text.trim(),
          );
      if (!mounted) return;
      if (!resend) {
        _goToStep(_Step.otp);
      } else {
        // Clear existing OTP boxes on resend
        for (final c in _otpCtrl) c.clear();
        _otpFocus[0].requestFocus();
      }
      _startCooldown();
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Step 2 — Verify OTP ───────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    if (_otpValue.length < 4) {
      _setError('Please enter the full 4-digit code.');
      return;
    }
    FocusScope.of(context).unfocus();
    _clearError();
    setState(() => _isLoading = true);

    // TODO: replace with real API call — POST /auth/forgot-password/verify-otp
    // Backend should:
    //   1. Validate the OTP for the given phone + expiry
    //   2. Return a short-lived reset token (e.g. JWT)
    //   3. Return 400 if OTP is wrong / expired
    try {
      final ok = await ref.read(authProvider.notifier).verifyOtpForReset(
            phone: _phoneCtrl.text.trim(),
            otp: _otpValue,
          );
      if (!mounted) return;
      if (ok) {
        _goToStep(_Step.newPassword);
      } else {
        _setError('Invalid OTP. Please try again.');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Step 3 — Set new password ──────────────────────────────────────────────

  Future<void> _resetPassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _clearError();
    setState(() => _isLoading = true);

    // TODO: replace with real API call — POST /auth/forgot-password/reset
    // Backend should:
    //   1. Accept reset token + new password
    //   2. Hash and store new password
    //   3. Invalidate the reset token
    //   4. Return 200 OK
    try {
      await ref.read(authProvider.notifier).resetPassword(
            phone: _phoneCtrl.text.trim(),
            otp: _otpValue,
            newPassword: _newPassCtrl.text,
          );
      if (!mounted) return;
      _showSuccessAndPop();
    } catch (e) {
      if (!mounted) return;
      // Password validation passed locally, so a backend rejection is
      // almost always an expired or incorrect OTP — navigate back to
      // step 2 so the user can re-enter the code.
      for (final c in _otpCtrl) c.clear();
      _goToStep(_Step.otp);
      _setError('The OTP was incorrect or has expired. Please re-enter the code.');
      _otpFocus[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessAndPop() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 18),
              const Text('Password Updated!', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                'Your password has been changed successfully.\nYou can now sign in with your new password.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: 'Back to Sign In',
                onPressed: () {
                  Navigator.pop(context);           // close sheet
                  Navigator.pop(context);           // close forgot-password
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(children: [
          // ── Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () {
                  if (_step == _Step.otp) {
                    _goToStep(_Step.phone);
                  } else if (_step == _Step.newPassword) {
                    _goToStep(_Step.otp);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              const Text('Forgot Password', style: AppTextStyles.h3),
            ]),
          ),

          // ── Progress indicator ────────────────────────────────────
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _StepIndicator(current: _step),
          ),
          const SizedBox(height: 28),

          // ── Content ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _buildStep(),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.phone:      return _buildPhoneStep();
      case _Step.otp:        return _buildOtpStep();
      case _Step.newPassword: return _buildNewPasswordStep();
    }
  }

  // ── Step 1 UI ─────────────────────────────────────────────────────────────

  Widget _buildPhoneStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            icon: Icons.phone_outlined,
            title: 'Enter your phone number',
            subtitle:
                'We\'ll send a verification code to reset your password.',
          ),
          const SizedBox(height: 28),

          Form(
            key: _phoneFormKey,
            child: AppTextField(
              label: 'Phone number',
              hint: '07X XXX XXXX',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              prefixIconData: Icons.phone_outlined,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone is required';
                if (v.trim().length < 9) return 'Enter a valid phone number';
                return null;
              },
            ),
          ),

          if (_errorText != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _errorText!),
          ],

          const SizedBox(height: 24),
          GradientButton(
            label: 'Send OTP',
            icon: Icons.send_rounded,
            isLoading: _isLoading,
            onPressed: _sendOtp,
          ),
          const SizedBox(height: 32),
        ],
      );

  // ── Step 2 UI ─────────────────────────────────────────────────────────────

  Widget _buildOtpStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            icon: Icons.lock_open_rounded,
            title: 'Enter verification code',
            subtitle:
                'A 4-digit OTP was sent to ${_phoneCtrl.text.trim()}',
          ),
          const SizedBox(height: 32),

          // Mock-mode hint
          if (AppConstants.useMockServices) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.accentGold),
                const SizedBox(width: 8),
                Text(
                  'Demo mode — enter code: ${AppConstants.mockOtp}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.accentGold),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // OTP boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => _OtpBox(
              controller: _otpCtrl[i],
              focusNode: _otpFocus[i],
              onChanged: (v) {
                if (v.isNotEmpty && i < 3) {
                  _otpFocus[i + 1].requestFocus();
                }
                if (v.isEmpty && i > 0) {
                  _otpFocus[i - 1].requestFocus();
                }
                // Auto-submit when all 4 filled
                if (_otpValue.length == 4) {
                  Future.delayed(
                    const Duration(milliseconds: 150),
                    _verifyOtp,
                  );
                }
                setState(() {});
              },
            )),
          ),

          if (_errorText != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: _errorText!),
          ],

          const SizedBox(height: 28),
          GradientButton(
            label: 'Verify Code',
            isLoading: _isLoading,
            onPressed: _otpValue.length == 4 ? _verifyOtp : null,
          ),
          const SizedBox(height: 20),

          // Resend row
          Center(
            child: _canResend
                ? GestureDetector(
                    onTap: () => _sendOtp(resend: true),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySmall,
                        children: [
                          const TextSpan(text: "Didn't receive it? "),
                          TextSpan(
                            text: 'Resend OTP',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(
                    'Resend in ${_resendCooldown}s',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
          const SizedBox(height: 32),
        ],
      );

  // ── Step 3 UI ─────────────────────────────────────────────────────────────

  Widget _buildNewPasswordStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            icon: Icons.lock_reset_rounded,
            title: 'Create new password',
            subtitle: 'Choose a strong password you haven\'t used before.',
          ),
          const SizedBox(height: 28),

          Form(
            key: _passFormKey,
            child: Column(children: [
              AppTextField(
                label: 'New password',
                hint: 'Min 6 characters',
                controller: _newPassCtrl,
                isPassword: !_newPassVisible,
                prefixIconData: Icons.lock_outline,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      setState(() => _newPassVisible = !_newPassVisible),
                  child: Text(
                    _newPassVisible ? 'Hide' : 'Show',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primaryLight),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AppTextField(
                label: 'Confirm new password',
                hint: 'Re-enter your password',
                controller: _confirmCtrl,
                isPassword: !_confirmPassVisible,
                prefixIconData: Icons.lock_outline,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm password';
                  if (v != _newPassCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(
                      () => _confirmPassVisible = !_confirmPassVisible),
                  child: Text(
                    _confirmPassVisible ? 'Hide' : 'Show',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primaryLight),
                  ),
                ),
              ),
            ]),
          ),

          // Password strength hint
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 15, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use at least 6 characters with a mix of letters and numbers for a stronger password.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primaryLight),
                  ),
                ),
              ],
            ),
          ),

          if (_errorText != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _errorText!),
          ],

          const SizedBox(height: 24),
          GradientButton(
            label: 'Update Password',
            icon: Icons.check_rounded,
            isLoading: _isLoading,
            onPressed: _resetPassword,
          ),
          const SizedBox(height: 32),
        ],
      );
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final _Step current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = [_Step.phone, _Step.otp, _Step.newPassword];
    final labels = ['Phone', 'Verify', 'Password'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final leftDone = steps[i ~/ 2].index < current.index;
          return Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: leftDone
                    ? const LinearGradient(colors: AppColors.buttonGradient)
                    : null,
                color: leftDone ? null : AppColors.border,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }
        final step     = steps[i ~/ 2];
        final isDone   = step.index < current.index;
        final isActive = step == current;
        final num      = (i ~/ 2) + 1;

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive || isDone
                    ? const LinearGradient(
                        colors: AppColors.buttonGradient)
                    : null,
                color: isActive || isDone ? null : AppColors.bgCard,
                border: Border.all(
                  color: isActive || isDone
                      ? Colors.transparent
                      : AppColors.border,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : Text(
                        '$num',
                        style: AppTextStyles.caption.copyWith(
                          color: isActive
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[i ~/ 2],
              style: AppTextStyles.caption.copyWith(
                color: isActive
                    ? AppColors.primary
                    : isDone
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Step header ───────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;
  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      );
}

// ── OTP box ───────────────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final ValueChanged<String>  onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: 60, height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: focusNode.hasFocus
                ? AppColors.primary
                : controller.text.isNotEmpty
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.border,
            width: focusNode.hasFocus ? 1.5 : 1,
          ),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.h3.copyWith(fontSize: 22),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
        ),
      );
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded,
              size: 15, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.error),
            ),
          ),
        ]),
      );
}