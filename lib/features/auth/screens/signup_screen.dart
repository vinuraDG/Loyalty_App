import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/features/home/screens/main_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';


class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _confCtrl   = TextEditingController();
  bool _agreed = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms and conditions.')));
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).signUpWithEmail(
      name: _nameCtrl.text, email: _emailCtrl.text,
      phone: _phoneCtrl.text, password: _passCtrl.text,
    );
    if (!mounted) return;
    if (ref.read(authProvider).isAuthenticated) {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const MainScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)));
        ref.read(authProvider.notifier).clearError();
      }
    });

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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Header
              Center(child: Column(children: [
                const AppLogo(size: 60),
                const SizedBox(height: 14),
                Text('Join LoyaltyHub', style: AppTextStyles.h2),
                const SizedBox(height: 4),
                Text('Earn points at fuel stations, laundry & golf',
                  style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              ])),
              const SizedBox(height: 28),

              AppTextField(
                label: 'Full name', hint: 'Kasun Perera',
                controller: _nameCtrl, keyboardType: TextInputType.name,
                prefixIconData: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 3) return 'Min 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Email address', hint: 'you@example.com',
                controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                prefixIconData: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Phone number', hint: '07X XXX XXXX',
                controller: _phoneCtrl, keyboardType: TextInputType.phone,
                maxLength: 10, prefixIconData: Icons.phone_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Phone is required';
                  if (v.length < 9) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Password', hint: 'At least 6 characters',
                controller: _passCtrl, isPassword: true,
                prefixIconData: Icons.lock_outline,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Confirm password', hint: 'Re-enter your password',
                controller: _confCtrl, isPassword: true,
                textInputAction: TextInputAction.done,
                prefixIconData: Icons.lock_outline,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password';
                  if (v != _passCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 22),

              // Terms checkbox
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () => setState(() => _agreed = !_agreed),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: _agreed ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _agreed ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: _agreed
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: RichText(text: TextSpan(
                  style: AppTextStyles.bodySmall,
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(text: 'Terms & Conditions',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryLight,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primaryLight,
                      )),
                    const TextSpan(text: ' and '),
                    TextSpan(text: 'Privacy Policy',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryLight,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primaryLight,
                      )),
                  ],
                ))),
              ]),
              const SizedBox(height: 28),

              GradientButton(
                label: 'Create Account',
                icon: Icons.person_add_alt_1_rounded,
                isLoading: auth.isLoading,
                onPressed: _signUp,
              ),
              const SizedBox(height: 16),

              Center(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(text: TextSpan(
                  style: AppTextStyles.bodySmall,
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(text: 'Sign in',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryLight, fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primaryLight,
                      )),
                  ],
                )),
              )),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }
}