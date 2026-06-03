import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

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

  bool _isLoading       = false;
  bool _showCurrentPass = false;
  bool _showNewPass     = false;
  bool _showConfirmPass = false;

  // Password strength (0–4)
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
    int score = 0;
    if (v.length >= 8)                          score++;
    if (RegExp(r'[A-Z]').hasMatch(v))           score++;
    if (RegExp(r'[0-9]').hasMatch(v))           score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v)) score++;
    setState(() => _strength = score);
  }

  Color get _strengthColor {
    if (_strength <= 1) return AppColors.error;
    if (_strength == 2) return Colors.orange;
    if (_strength == 3) return Colors.yellow;
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
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    // TODO: wire to authProvider.changePassword(
    //   _currentPassCtrl.text, _newPassCtrl.text)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed successfully!')),
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
          const SizedBox(height: 8),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Info banner ───────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Use at least 8 characters with uppercase letters, '
                            'numbers, and symbols for a strong password.',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryLight, height: 1.5),
                          ),
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
                        if (v.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (v == _currentPassCtrl.text) {
                          return 'New password must differ from current';
                        }
                        return null;
                      },
                    ),

                    // Strength bar
                    if (_newPassCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _strength / 4,
                              minHeight: 5,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation(_strengthColor),
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
                        if (v != _newPassCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),

                    // ── Submit ────────────────────────────────────
                    GradientButton(
                      label: 'Update Password',
                      isLoading: _isLoading,
                      onPressed: _submit,
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
    style: AppTextStyles.caption.copyWith(
        color: AppColors.textMuted, letterSpacing: 0.8),
  );
}

// ── Password field widget ─────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggle;
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
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}