import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';
import '../../../customer/home/screens/main_screen.dart';
import '../../../features/employee/home/screens/employee_dashboard_screen.dart';
import 'login_email_verify_screen.dart';

class LoginPhoneOtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String password;

  const LoginPhoneOtpScreen({
    super.key,
    required this.phone,
    required this.password,
  });

  @override
  ConsumerState<LoginPhoneOtpScreen> createState() => _LoginPhoneOtpScreenState();
}

class _LoginPhoneOtpScreenState extends ConsumerState<LoginPhoneOtpScreen> {
  static const _otpLength   = 6;
  static const _otpDuration = 90;

  final _ctrls = List.generate(_otpLength, (_) => TextEditingController());
  final _focus  = List.generate(_otpLength, (_) => FocusNode());

  bool    _hasError  = false;
  String? _errorText;
  int     _seconds   = _otpDuration;
  Timer?  _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus[0].requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) { c.dispose(); }
    for (final f in _focus) { f.dispose(); }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = _otpDuration);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) { t.cancel(); return; }
      setState(() => _seconds--);
    });
  }

  String get _timerLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  void _clearBoxes() {
    for (final c in _ctrls) { c.clear(); }
    _focus[0].requestFocus();
  }

  Future<void> _verify() async {
    if (_otp.length < _otpLength) {
      setState(() {
        _hasError  = true;
        _errorText = 'Please enter the 6-digit OTP.';
      });
      return;
    }
    setState(() { _hasError = false; _errorText = null; });
    FocusScope.of(context).unfocus();

    // Step 1 — confirm the phone OTP
    await ref.read(authProvider.notifier).confirmPhone(
      phone: widget.phone,
      otp:   _otp,
    );
    if (!mounted) return;
    final afterOtp = ref.read(authProvider);
    if (afterOtp.errorMessage != null) {
      setState(() { _hasError = true; _errorText = afterOtp.errorMessage; });
      ref.read(authProvider.notifier).clearError();
      _clearBoxes();
      return;
    }

    // Step 2 — re-login bypassing the phone OTP requirement (already verified)
    await ref.read(authProvider.notifier).signInAfterPhoneVerification(
      widget.phone,
      widget.password,
    );
    if (!mounted) return;
    final afterLogin = ref.read(authProvider);

    if (afterLogin.isAuthenticated) {
      _navigateByRole(afterLogin);
    } else if (afterLogin.emailNotConfirmed) {
      ref.read(authProvider.notifier).clearEmailNotConfirmed();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginEmailVerifyScreen(
            phone: widget.phone,
            password: widget.password,
          ),
        ),
      );
    } else if (afterLogin.errorMessage != null) {
      setState(() { _hasError = true; _errorText = afterLogin.errorMessage; });
      ref.read(authProvider.notifier).clearError();
    }
  }

  Future<void> _resend() async {
    await ref.read(authProvider.notifier).sendPhoneConfirmation(widget.phone);
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

              const Text('Verify Your Phone', style: AppTextStyles.h2),
              const SizedBox(height: 10),
              const Text('We sent a 6-digit code to',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 4),
              Text(widget.phone, style: AppTextStyles.h4),
              const SizedBox(height: 8),
              const Text(
                'Enter the code below to verify your phone number and sign in.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_otpLength, (i) => Padding(
                    padding: EdgeInsets.only(right: i < _otpLength - 1 ? 10 : 0),
                    child: OtpBox(
                      controller: _ctrls[i],
                      focusNode: _focus[i],
                      nextFocus: i < _otpLength - 1 ? _focus[i + 1] : null,
                      hasError: _hasError,
                    ),
                  )),
                ),
              ),

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
                label: 'Verify & Sign In',
                icon: Icons.verified_user_rounded,
                isLoading: auth.isLoading,
                onPressed: auth.isLoading ? null : _verify,
              ),
              const SizedBox(height: 24),

              _seconds > 0
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text('Resend in ',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textMuted)),
                        Text(
                          _timerLabel,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
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
