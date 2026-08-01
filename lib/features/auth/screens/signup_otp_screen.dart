import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SignupOtpScreen extends ConsumerStatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String address;

  const SignupOtpScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.address,
  });

  @override
  ConsumerState<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends ConsumerState<SignupOtpScreen> {
  final _ctrls = List.generate(4, (_) => TextEditingController());
  final _focus = List.generate(4, (_) => FocusNode());
  bool _hasError = false;
  String? _errorText;
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus[0].requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) c.dispose();
    for (final f in _focus) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) { t.cancel(); return; }
      setState(() => _seconds--);
    });
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  void _clearBoxes() {
    for (final c in _ctrls) c.clear();
    _focus[0].requestFocus();
  }

  Future<void> _verify() async {
    if (_otp.length < 4) {
      setState(() { _hasError = true; _errorText = 'Please enter the 4-digit OTP.'; });
      return;
    }
    setState(() { _hasError = false; _errorText = null; });
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).registerAccount(
      firstName: widget.firstName,
      lastName:  widget.lastName,
      email:     widget.email,
      phone:     widget.phone,
      password:  widget.password,
      address:   widget.address,
    );

    if (!mounted) return;
    final auth = ref.read(authProvider);

    if (auth.errorMessage != null) {
      setState(() {
        _hasError = true;
        _errorText = auth.errorMessage;
      });
      ref.read(authProvider.notifier).clearError();
      _clearBoxes();
      return;
    }

    // Account created — navigate to login for fresh sign-in
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Account created! Please sign in.')),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _resend() async {
    await ref.read(authProvider.notifier).sendOtpForReset(widget.phone);
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.errorMessage != null) {
      setState(() { _hasError = true; _errorText = auth.errorMessage; });
      ref.read(authProvider.notifier).clearError();
      return;
    }
    _clearBoxes();
    _startTimer();
    setState(() { _hasError = false; _errorText = null; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('OTP resent to your phone.'),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        title: const Text('Verify Phone'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.sms_outlined,
                    color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 24),

              const Text('Enter OTP', style: AppTextStyles.h2),
              const SizedBox(height: 10),
              const Text('We sent a 4-digit code to',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 4),
              Text(widget.phone, style: AppTextStyles.h4),
              const SizedBox(height: 32),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 14 : 0),
                  child: OtpBox(
                    controller: _ctrls[i],
                    focusNode: _focus[i],
                    nextFocus: i < 3 ? _focus[i + 1] : null,
                    hasError: _hasError,
                  ),
                )),
              ),

              // Error message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _errorText != null
                    ? Padding(
                        key: const ValueKey('err'),
                        padding: const EdgeInsets.only(top: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.error),
                              ),
                            ),
                          ]),
                        ),
                      )
                    : const SizedBox(key: ValueKey('no-err'), height: 14),
              ),

              const SizedBox(height: 32),

              GradientButton(
                label: 'Verify & Create Account',
                icon: Icons.person_add_alt_1_rounded,
                isLoading: auth.isLoading,
                onPressed: auth.isLoading ? null : _verify,
              ),
              const SizedBox(height: 24),

              // Resend timer / button
              _seconds > 0
                  ? Text(
                      'Resend OTP in $_seconds seconds',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    )
                  : GestureDetector(
                      onTap: auth.isLoading ? null : _resend,
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySmall,
                          children: [
                            const TextSpan(text: "Didn't receive it? "),
                            TextSpan(
                              text: 'Resend OTP',
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

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
