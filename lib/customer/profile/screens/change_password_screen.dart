import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';


class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool    _isLoading       = false;
  bool    _showCurrentPass = false;
  bool    _showNewPass     = false;
  bool    _showConfirmPass = false;
  String? _errorText;

  int _strength = 0;

  @override
  void initState() {
    super.initState();
    _newPassCtrl.addListener(_calcStrength);
  }

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _calcStrength() {
    final v = _newPassCtrl.text;
    int s = 0;
    if (v.length >= 12)                                                  s++;
    if (v.length >= 16)                                                  s++;
    if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v))   s++;
    if (RegExp(r'[0-9]').hasMatch(v))                                    s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v))                  s++;
    setState(() => _strength = s.clamp(0, 4));
  }

  Color get _strengthColor {
    if (_strength <= 1) return AppColors.error;
    if (_strength == 2) return const Color(0xFFFF9800);
    if (_strength == 3) return const Color(0xFFFFD700);
    return AppColors.success;
  }

  String get _strengthLabel {
    if (_newPassCtrl.text.isEmpty) return '';
    if (_strength <= 1) return 'Weak';
    if (_strength == 2) return 'Fair';
    if (_strength == 3) return 'Good';
    return 'Strong';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _errorText = null; });

    try {
      await ref.read(authProvider.notifier).changePassword(
        currentPassword: _currentPassCtrl.text,
        newPassword:     _newPassCtrl.text,
      );
      if (!mounted) return;

      // Notifier captures errors into state instead of throwing
      final errorMsg = ref.read(authProvider).errorMessage;
      if (errorMsg != null) {
        ref.read(authProvider.notifier).clearError();
        setState(() { _isLoading = false; _errorText = errorMsg; });
        return;
      }

      setState(() => _isLoading = false);
      _showSuccess();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _showSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Expanded(child: Text('Password changed successfully')),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(children: [

          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Text('Change Password', style: AppTextStyles.h3),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Icon + title block
                    Center(
                      child: Column(children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_outline_rounded,
                              color: AppColors.primary, size: 30),
                        ),
                        const SizedBox(height: 12),
                        const Text('Update your password',
                            style: AppTextStyles.h4),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your current password then choose a new one.',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 28),

                    // ── Current password ──────────────────────────
                    _label('CURRENT PASSWORD'),
                    const SizedBox(height: 10),
                    _PasswordField(
                      controller: _currentPassCtrl,
                      label: 'Current Password',
                      visible: _showCurrentPass,
                      onToggle: () => setState(
                          () => _showCurrentPass = !_showCurrentPass),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Enter your current password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── New password ──────────────────────────────
                    _label('NEW PASSWORD'),
                    const SizedBox(height: 10),
                    _PasswordField(
                      controller: _newPassCtrl,
                      label: 'New Password',
                      visible: _showNewPass,
                      onToggle: () =>
                          setState(() => _showNewPass = !_showNewPass),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a new password';
                        if (v.length < 12) return 'Minimum 12 characters required';
                        if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must include an uppercase letter';
                        if (!RegExp(r'[a-z]').hasMatch(v)) return 'Must include a lowercase letter';
                        if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must include a number';
                        if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v)) {
                          return 'Must include a special character (!@#\$%^&* etc.)';
                        }
                        if (v == _currentPassCtrl.text) return 'New password must differ from current';
                        return null;
                      },
                    ),

                    // Strength bar
                    if (_newPassCtrl.text.isNotEmpty) ...[
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
                    ],
                    const SizedBox(height: 24),

                    // ── Confirm password ──────────────────────────
                    _label('CONFIRM NEW PASSWORD'),
                    const SizedBox(height: 10),
                    _PasswordField(
                      controller: _confirmPassCtrl,
                      label: 'Confirm New Password',
                      visible: _showConfirmPass,
                      onToggle: () => setState(
                          () => _showConfirmPass = !_showConfirmPass),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (v != _newPassCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Password requirements ─────────────────────
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
                          const Icon(Icons.shield_outlined,
                              size: 15, color: AppColors.primaryLight),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Required: at least 12 characters, one uppercase (A–Z), '
                              'one lowercase (a–z), one number (0–9), and one special character (!@#\$%^&* etc.).',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primaryLight, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Inline error ──────────────────────────────
                    if (_errorText != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorText!,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.error)),
                          ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // ── Submit ────────────────────────────────────
                    GradientButton(
                      label: 'Update Password',
                      icon: Icons.lock_reset_rounded,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTextStyles.caption
            .copyWith(color: AppColors.textMuted, letterSpacing: 0.8),
      );
}

// ── Password field ────────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController     controller;
  final String                    label;
  final bool                      visible;
  final VoidCallback              onToggle;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: !visible,
        validator: validator,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              color: AppColors.primary, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              visible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary,
              size: 18,
            ),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: AppColors.bgCard,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
}
