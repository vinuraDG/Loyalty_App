import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';
import '../../../customer/home/screens/main_screen.dart';
import '../../../features/employee/home/screens/employee_dashboard_screen.dart';
import 'login_screen.dart';

class LoginEmailVerifyScreen extends ConsumerStatefulWidget {
  final String phone;
  final String password;

  const LoginEmailVerifyScreen({
    super.key,
    required this.phone,
    required this.password,
  });

  @override
  ConsumerState<LoginEmailVerifyScreen> createState() =>
      _LoginEmailVerifyScreenState();
}

class _LoginEmailVerifyScreenState
    extends ConsumerState<LoginEmailVerifyScreen> {
  bool _resending = false;

  Future<void> _resend() async {
    setState(() => _resending = true);
    await ref.read(authProvider.notifier).resendEmailVerification(widget.phone);
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Verification email resent. Check your inbox.'),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _confirmAndLogin() async {
    await ref.read(authProvider.notifier).signInAfterEmailVerification(
      widget.phone,
      widget.password,
    );
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
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
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(auth.errorMessage!)),
          ]),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      ref.read(authProvider.notifier).clearError();
    }
  }

  void _backToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
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
          onPressed: _backToLogin,
        ),
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.mark_email_unread_outlined,
                    color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 28),

              const Text('Check Your Email', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              const Text(
                'We\'ve sent a verification link to your registered email address.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Click the link in the email to verify, then tap the button below to continue.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18)),
                ),
                child: Column(
                  children: [
                    _StepRow(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                      label: 'Phone number verified',
                    ),
                    const SizedBox(height: 12),
                    _StepRow(
                      icon: Icons.radio_button_unchecked_rounded,
                      color: AppColors.primary,
                      label: 'Email verification pending',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              GradientButton(
                label: 'I\'ve Verified My Email',
                icon: Icons.verified_rounded,
                isLoading: auth.isLoading,
                onPressed: auth.isLoading ? null : _confirmAndLogin,
              ),
              const SizedBox(height: 16),

              TextButton.icon(
                onPressed: (_resending || auth.isLoading) ? null : _resend,
                icon: _resending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textMuted),
                      )
                    : const Icon(Icons.refresh_rounded,
                        size: 16, color: AppColors.textMuted),
                label: const Text('Resend Verification Email',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: _backToLogin,
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _StepRow({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}
