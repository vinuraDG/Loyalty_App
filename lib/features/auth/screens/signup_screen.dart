// signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/customer/home/screens/main_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _addressCtrl   = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confCtrl      = TextEditingController();
  bool _agreed = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ASP.NET Identity default password rules
  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 12) return 'Password must be at least 12 characters';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Must contain at least one uppercase letter (A-Z)';
    if (!v.contains(RegExp(r'[a-z]'))) return 'Must contain at least one lowercase letter (a-z)';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Must contain at least one number (0-9)';
    if (!v.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return 'Must contain at least one special character (!@#\$%^&* etc.)';
    }
    return null;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      _showError('Please agree to the terms and conditions.');
      return;
    }
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).signUpWithEmail(
      firstName: _firstNameCtrl.text.trim(),
      lastName:  _lastNameCtrl.text.trim(),
      email:     _emailCtrl.text.trim(),
      phone:     _phoneCtrl.text.trim(),
      address:   _addressCtrl.text.trim(),
      password:  _passCtrl.text,
    );

    if (!mounted) return;
    final auth = ref.read(authProvider);

    if (auth.errorMessage != null) {
      _showError(auth.errorMessage!);
      ref.read(authProvider.notifier).clearError();
      return;
    }

    if (auth.isAuthenticated) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    }
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
        title: const Text('Create account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Center(
                  child: Column(children: [
                    AppLogo(size: 60),
                    SizedBox(height: 14),
                    Text('Join LoyaltyHub', style: AppTextStyles.h2),
                    SizedBox(height: 4),
                    Text(
                      'Earn points at fuel stations, laundry & gold shops',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),
                const SizedBox(height: 28),

                Row(children: [
                  Expanded(
                    child: AppTextField(
                      label: 'First name',
                      hint: 'Kasun',
                      controller: _firstNameCtrl,
                      keyboardType: TextInputType.name,
                      prefixIconData: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Too short';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Last name',
                      hint: 'Perera',
                      controller: _lastNameCtrl,
                      keyboardType: TextInputType.name,
                      prefixIconData: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 2) return 'Too short';
                        return null;
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Email address',
                  hint: 'you@example.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIconData: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Phone number',
                  hint: '07X XXX XXXX',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  prefixIconData: Icons.phone_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone number is required';
                    if (!RegExp(r'^0[0-9]{9}$').hasMatch(v.trim())) {
                      return 'Enter a valid 10-digit phone number (e.g. 07XXXXXXXX)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Address',
                  hint: 'No. 12, Main Street, Colombo',
                  controller: _addressCtrl,
                  keyboardType: TextInputType.streetAddress,
                  prefixIconData: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Password',
                  hint: 'Min 6 chars, A-Z, a-z, 0-9, symbol',
                  controller: _passCtrl,
                  isPassword: true,
                  prefixIconData: Icons.lock_outline,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 8),
                _PasswordStrengthHint(controller: _passCtrl),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  controller: _confCtrl,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  prefixIconData: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  GestureDetector(
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _agreed ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _agreed ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: _agreed
                          ? const Icon(Icons.check_circle_outline_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySmall,
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryLight,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primaryLight,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryLight,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 28),

                GradientButton(
                  label: 'Create Account',
                  icon: Icons.person_add_alt_1_rounded,
                  isLoading: auth.isLoading,
                  onPressed: _signUp,
                ),
                const SizedBox(height: 16),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySmall,
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign in',
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
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Password strength hint ─────────────────────────────────────────────────────

class _PasswordStrengthHint extends StatefulWidget {
  final TextEditingController controller;
  const _PasswordStrengthHint({required this.controller});

  @override
  State<_PasswordStrengthHint> createState() => _PasswordStrengthHintState();
}

class _PasswordStrengthHintState extends State<_PasswordStrengthHint> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.controller.text;
    final rules = [
      (_RuleCheck('At least 6 characters',        p.length >= 6)),
      (_RuleCheck('Uppercase letter (A-Z)',        p.contains(RegExp(r'[A-Z]')))),
      (_RuleCheck('Lowercase letter (a-z)',        p.contains(RegExp(r'[a-z]')))),
      (_RuleCheck('Number (0-9)',                  p.contains(RegExp(r'[0-9]')))),
      (_RuleCheck('Special character (!@#\$%...)', p.contains(RegExp(r'[^A-Za-z0-9]')))),
    ];

    if (p.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rules.map((r) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Icon(
              r.met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: r.met ? Colors.greenAccent : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              r.label,
              style: TextStyle(
                fontSize: 11,
                color: r.met ? Colors.greenAccent : AppColors.textMuted,
              ),
            ),
          ]),
        )).toList(),
      ),
    );
  }
}

class _RuleCheck {
  final String label;
  final bool   met;
  const _RuleCheck(this.label, this.met);
}