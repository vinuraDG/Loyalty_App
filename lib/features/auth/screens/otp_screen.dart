import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/features/home/screens/main_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/auth_provider.dart';
import 'new_user_phone_screen.dart'; // create-account screen for new phone users

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _ctrls = List.generate(4, (_) => TextEditingController());
  final _focus  = List.generate(4, (_) => FocusNode());
  bool _hasError = false;
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
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
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

  Future<void> _verify() async {
    if (_otp.length < 4) {
      setState(() => _hasError = true);
      return;
    }
    setState(() => _hasError = false);
    FocusScope.of(context).unfocus();

    final user = await ref.read(authProvider.notifier).verifyOtp(_otp);
    if (!mounted) return;

    if (user != null) {
      // Existing user — go home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } else if (ref.read(authProvider).errorMessage == null) {
      // OTP valid but phone not registered — collect name/email
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NewUserPhoneScreen()),
      );
    }
  }

  Future<void> _resend() async {
    final phone = ref.read(authProvider).pendingPhone;
    if (phone == null) return;
    await ref.read(authProvider.notifier).sendOtp(phone);
    for (final c in _ctrls) {
      c.clear();
    }
    _focus[0].requestFocus();
    _startTimer();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('OTP resent!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final phone = auth.pendingPhone ?? '';

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.errorMessage != null) {
        setState(() => _hasError = true);
        for (final c in _ctrls) {
          c.clear();
        }
        _focus[0].requestFocus();
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Icon circle
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

              const Text('Verify your number', style: AppTextStyles.h2),
              const SizedBox(height: 10),
              const Text('We sent a 4-digit OTP to',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 4),
              Text(phone, style: AppTextStyles.h4),
              const SizedBox(height: 16),

              // Dev hint
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accentGold.withValues(alpha: 0.25)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lock_open_outlined,
                      color: AppColors.accentGold, size: 15),
                  const SizedBox(width: 8),
                  Text(
                    'Dev mode OTP: 1234',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.accentGold),
                  ),
                ]),
              ),
              const SizedBox(height: 36),

              // 4 OTP boxes
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
              const SizedBox(height: 36),

              GradientButton(
                label: 'Verify OTP',
                isLoading: auth.isLoading,
                onPressed: _verify,
              ),
              const SizedBox(height: 24),

              _seconds > 0
                  ? Text('Resend OTP in $_seconds seconds',
                      style: AppTextStyles.bodySmall)
                  : GestureDetector(
                      onTap: _resend,
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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}