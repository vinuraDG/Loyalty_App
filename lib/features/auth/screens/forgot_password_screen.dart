import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {

  final _formKey    = GlobalKey<FormState>();
  final _phoneCtrl  = TextEditingController();

  bool _emailSent = false;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    // Form is only in the tree on the initial input card; skip validation on resend
    if (!_emailSent && !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier)
        .sendPasswordResetEmail(_phoneCtrl.text.trim());

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

    setState(() => _emailSent = true);
    _animCtrl.forward(from: 0);
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
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: _emailSent ? _buildSentCard() : _buildInputCard(auth),
          ),
        ),
      ),
    );
  }

  // ── Step 1: phone input ───────────────────────────────────────────────────

  Widget _buildInputCard(auth) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),

      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.lock_reset_rounded,
            color: AppColors.primary, size: 30),
      ),
      const SizedBox(height: 20),

      const Text('Reset your password', style: AppTextStyles.h2),
      const SizedBox(height: 8),
      Text(
        'Enter your registered phone number. '
        'We\'ll send a password reset link to your email address.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 32),

      Form(
        key: _formKey,
        child: AppTextField(
          label: 'Phone number',
          hint: '07X XXX XXXX',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          prefixIconData: Icons.phone_outlined,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Phone number is required';
            if (!RegExp(r'^0[0-9]{9}$').hasMatch(v.trim())) {
              return 'Enter a valid 10-digit phone number (e.g. 07XXXXXXXX)';
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 28),

      GradientButton(
        label: 'Send Reset Link',
        icon: Icons.send_rounded,
        isLoading: auth.isLoading,
        onPressed: auth.isLoading ? null : _sendLink,
      ),
      const SizedBox(height: 20),

      Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall,
              children: [
                const TextSpan(text: 'Remembered it? '),
                TextSpan(
                  text: 'Back to Sign In',
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
      const SizedBox(height: 32),
    ],
  );

  // ── Step 2: email sent confirmation ───────────────────────────────────────

  Widget _buildSentCard() => Column(
    children: [
      const SizedBox(height: 40),

      Container(
        width: 88, height: 88,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3), width: 1.5),
        ),
        child: const Icon(Icons.mark_email_read_outlined,
            color: AppColors.success, size: 42),
      ),
      const SizedBox(height: 28),

      const Text('Check your email inbox', style: AppTextStyles.h2,
          textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(
        'We\'ve sent a password reset link to the email address linked to your account.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 40),

      GradientButton(
        label: 'Back to Sign In',
        icon: Icons.arrow_back_rounded,
        onPressed: () => Navigator.pop(context),
      ),
      const SizedBox(height: 32),
    ],
  );
}

