import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/features/employee/screens/employee_screens.dart';
import 'package:loyalty_app/features/home/screens/main_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'otp_screen.dart';


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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).signInWithEmail(_emailCtrl.text, _passCtrl.text);
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) _navigateByRole(auth.isEmployee);
  }

  void _navigateByRole(bool isEmployee) {
    final page = isEmployee
        ? const EmployeeDashboardScreen()
        : const MainScreen();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (_) => false,
    );
  }

  Future<void> _sendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).sendOtp(_phoneCtrl.text.trim());
    if (!mounted) return;
    if (ref.read(authProvider).errorMessage == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const OtpScreen()));
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),

            // Logo row
            Row(children: [
              const AppLogo(size: 38),
              const SizedBox(width: 10),
              Text('LoyaltyHub', style: AppTextStyles.h4),
            ]),
            const SizedBox(height: 28),

            Text('Welcome back', style: AppTextStyles.h1),
            const SizedBox(height: 6),
            Text('Sign in to access your points and rewards',
              style: AppTextStyles.bodySmall),
            const SizedBox(height: 24),

            // Tab selector
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.buttonGradient),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: AppTextStyles.labelMedium,
                unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted),
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textMuted,
                tabs: const [Tab(text: 'Email'), Tab(text: 'Phone number')],
              ),
            ),
            const SizedBox(height: 24),

            // Tab views — fixed height
            SizedBox(
              height: 290,
              child: TabBarView(controller: _tab, children: [

                // ── Email form ──────────────────────────────────────
                Form(
                  key: _emailFormKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AppTextField(
                      label: 'Email address', hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIconData: Icons.email_outlined,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password', hint: 'Enter your password',
                      controller: _passCtrl, isPassword: true,
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
                      child: TextButton(onPressed: () {}, child: const Text('Forgot password?')),
                    ),
                    GradientButton(
                      label: 'Sign In', isLoading: auth.isLoading,
                      onPressed: _signIn,
                    ),
                  ]),
                ),

                // ── Phone form ──────────────────────────────────────
                Form(
                  key: _phoneFormKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AppTextField(
                      label: 'Phone number', hint: '07X XXX XXXX',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10, textInputAction: TextInputAction.done,
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
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: AppColors.primaryLight, size: 16),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          'A 4-digit OTP will be sent to your number.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: 'Send OTP', icon: Icons.send_rounded,
                      isLoading: auth.isLoading, onPressed: _sendOtp,
                    ),
                  ]),
                ),
              ]),
            ),

            const DividerText(text: 'or'),
            const SizedBox(height: 14),

            // Sign up link
            Center(child: GestureDetector(
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SignupScreen())),
              child: RichText(text: TextSpan(
                style: AppTextStyles.bodySmall,
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  TextSpan(text: 'Sign up',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryLight, fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryLight,
                    )),
                ],
              )),
            )),
            const SizedBox(height: 20),
            const DemoHintBox(),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}