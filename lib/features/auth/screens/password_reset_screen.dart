import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

/// Shown when the user taps the password-reset link from their email.
/// [email] and [token] are extracted from the deep-link URL.
class PasswordResetScreen extends ConsumerStatefulWidget {
  final String email;
  final String token;

  const PasswordResetScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _strength = 0;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(_calcStrength);
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _calcStrength() {
    final v = _passCtrl.text;
    int s = 0;
    if (v.length >= 12)                                          s++;
    if (v.length >= 16)                                          s++;
    if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v)) s++;
    if (RegExp(r'[0-9]').hasMatch(v))                            s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v))          s++;
    setState(() => _strength = s.clamp(0, 4));
  }

  Color get _strengthColor {
    if (_strength <= 1) return AppColors.error;
    if (_strength == 2) return const Color(0xFFFF9800);
    if (_strength == 3) return const Color(0xFFFFD700);
    return AppColors.success;
  }

  String get _strengthLabel {
    if (_passCtrl.text.isEmpty) return '';
    if (_strength <= 1) return 'Weak';
    if (_strength == 2) return 'Fair';
    if (_strength == 3) return 'Good';
    return 'Strong';
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 12) return 'Minimum 12 characters required';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must include an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Must include a lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must include a number';
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v)) {
      return 'Must include a special character (!@#\$%^&* etc.)';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).resetPasswordWithToken(
      email:       widget.email,
      token:       widget.token,
      newPassword: _passCtrl.text,
    );

    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 17),
          const SizedBox(width: 10),
          Expanded(child: Text(auth.errorMessage!)),
        ]),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      ref.read(authProvider.notifier).clearError();
      return;
    }

    _showSuccess();
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.success, size: 42),
            ),
            const SizedBox(height: 20),
            const Text('Password Updated!', style: AppTextStyles.h2,
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Your password has been reset successfully.\nSign in with your new password.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Sign In Now',
              icon: Icons.login_rounded,
              onPressed: () {
                Navigator.pop(context); // close sheet
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Set New Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header icon
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.lock_open_rounded,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 20),

              const Text('Create a new password', style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                'Choose a strong, unique password for your account.',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),

              // Email badge
              Row(children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(widget.email,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
              ]),
              const SizedBox(height: 28),

              Form(
                key: _formKey,
                child: Column(children: [

                  // New password
                  AppTextField(
                    label: 'New password',
                    hint: 'Min 12 chars, A-Z, 0-9, symbol',
                    controller: _passCtrl,
                    isPassword: true,
                    prefixIconData: Icons.lock_outline,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: _validatePassword,
                  ),

                  // Strength bar
                  if (_passCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _strength / 4,
                            minHeight: 4,
                            backgroundColor: AppColors.border,
                            valueColor:
                                AlwaysStoppedAnimation(_strengthColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(_strengthLabel,
                          style: AppTextStyles.caption.copyWith(
                              color: _strengthColor,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                  ] else
                    const SizedBox(height: 16),

                  // Confirm password
                  AppTextField(
                    label: 'Confirm new password',
                    hint: 'Re-enter your password',
                    controller: _confirmCtrl,
                    isPassword: true,
                    prefixIconData: Icons.lock_outline,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (v != _passCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Password requirements card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Column(children: [
                  _ReqRow('At least 12 characters',
                      _passCtrl.text.length >= 12),
                  _ReqRow('Uppercase letter (A-Z)',
                      RegExp(r'[A-Z]').hasMatch(_passCtrl.text)),
                  _ReqRow('Lowercase letter (a-z)',
                      RegExp(r'[a-z]').hasMatch(_passCtrl.text)),
                  _ReqRow('Number (0-9)',
                      RegExp(r'[0-9]').hasMatch(_passCtrl.text)),
                  _ReqRow('Special character (!@#\$%^&*)',
                      RegExp(r'[!@#\$%^&*(),.?":{}|<>]')
                          .hasMatch(_passCtrl.text)),
                ]),
              ),
              const SizedBox(height: 28),

              GradientButton(
                label: 'Update Password',
                icon: Icons.check_rounded,
                isLoading: auth.isLoading,
                onPressed: auth.isLoading ? null : _submit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReqRow extends StatelessWidget {
  final String label;
  final bool   met;
  const _ReqRow(this.label, this.met);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Icon(
        met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        size: 13,
        color: met ? AppColors.success : AppColors.textMuted,
      ),
      const SizedBox(width: 8),
      Text(label,
          style: TextStyle(
            fontSize: 11,
            color: met ? AppColors.success : AppColors.textMuted,
          )),
    ]),
  );
}
