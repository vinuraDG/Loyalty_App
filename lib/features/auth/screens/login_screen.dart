// login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/features/employee/home/screens/employee_dashboard_screen.dart';
import 'package:loyalty_app/features/employee/employee_screens.dart';
import 'package:loyalty_app/customer/home/screens/main_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'otp_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();

  final List<String> _logoAssets = [
    'assets/images/logo 1.png',
    'assets/images/logo 2.png',
    'assets/images/logo 3.png',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
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
    if (!_emailFormKey.currentState!.validate()) return;
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

  Future<void> _sendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).sendOtp(_phoneCtrl.text.trim());

    if (!mounted) return;
    final auth = ref.read(authProvider);

    if (auth.errorMessage != null) {
      _showError(auth.errorMessage!);
      ref.read(authProvider.notifier).clearError();
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const OtpScreen()));
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
              const SizedBox(height: 20),

              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.buttonGradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: AppTextStyles.labelMedium,
                  unselectedLabelStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  tabs: const [
                    Tab(text: 'Password'),
                    Tab(text: 'OTP'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 290,
                child: TabBarView(
                  controller: _tab,
                  children: [

                    // ── Phone + Password ──────────────────────────────
                    Form(
                      key: _emailFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: 'Phone number',
                            hint: '07X XXX XXXX',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            prefixIconData: Icons.phone_outlined,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Phone number is required';
                              if (v.length < 9) return 'Enter a valid phone number';
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
                              if (v.length < 6) return 'Min 6 characters';
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

                    // ── OTP tab ───────────────────────────────────────
                    Form(
                      key: _phoneFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: 'Phone number',
                            hint: '07X XXX XXXX',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            textInputAction: TextInputAction.done,
                            prefixIconData: Icons.phone_outlined,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Phone is required';
                              if (v.length < 9) return 'Enter a valid phone number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.info_outline,
                                  color: AppColors.primaryLight, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'A 4-digit OTP will be sent to your number.',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primaryLight),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 20),
                          GradientButton(
                            label: 'Send OTP',
                            icon: Icons.send_rounded,
                            isLoading: auth.isLoading,
                            onPressed: _sendOtp,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

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
              const SizedBox(height: 20),
              const DemoHintBox(),
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