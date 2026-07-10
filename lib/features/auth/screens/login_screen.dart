// login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/features/employee/home/screens/employee_dashboard_screen.dart';
import 'package:loyalty_app/customer/home/screens/main_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  final List<String> _logoAssets = [
    'assets/images/logo 1.png',
    'assets/images/logo 2.png',
    'assets/images/logo 3.png',
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
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

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).signInWithEmail(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;
    final auth = ref.read(authProvider);

    if (auth.isAuthenticated) {
      _navigateByRole(auth);
    } else if (auth.errorMessage != null) {
      _showError(auth.errorMessage!);
      ref.read(authProvider.notifier).clearError();
    }
  }

  void _navigateByRole(AuthState auth) {
    if (auth.isEmployee && auth.user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => EmployeeDashboardScreen(employee: auth.user!)),
        (_) => false,
      );
    } else {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              const Row(children: [
                AppLogo(size: 38),
                SizedBox(width: 10),
                Text('LoyaltyHub', style: AppTextStyles.h4),
              ]),
              const SizedBox(height: 28),

              const Text('Welcome back', style: AppTextStyles.h1),
              const SizedBox(height: 6),
              const Text(
                'Sign in to access your points and rewards',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 20),

              _PartnerLogosStrip(logos: _logoAssets),
              const SizedBox(height: 28),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Phone number or Email',
                      hint: '07X XXX XXXX or you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIconData: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number or email is required';
                        }
                        final val = v.trim();
                        final isEmail = val.contains('@');
                        if (isEmail) {
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(val)) {
                            return 'Enter a valid email address';
                          }
                        } else {
                          if (!RegExp(r'^0[0-9]{9}$').hasMatch(val)) {
                            return 'Enter a valid 10-digit phone number (e.g. 07XXXXXXXX)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      controller: _passCtrl,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      prefixIconData: Icons.lock_outline,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen()),
                        ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    GradientButton(
                      label: 'Sign In',
                      isLoading: auth.isLoading,
                      onPressed: _signIn,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const DividerText(text: 'or'),
              const SizedBox(height: 14),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySmall,
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign up',
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
    );
  }
}

// ── Partner Logos Strip ────────────────────────────────────────────────────────

class _PartnerLogosStrip extends StatelessWidget {
  final List<String> logos;
  const _PartnerLogosStrip({required this.logos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Our partner brands',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: List.generate(logos.length, (i) {
              final isLast = i == logos.length - 1;
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            right: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      logos[i],
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.store_outlined,
                          color: AppColors.primaryLight,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
