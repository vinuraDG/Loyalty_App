import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/features/auth/providers/auth_provider.dart';
import 'package:loyalty_app/features/employee/screens/employee_dashboard_screen.dart';
import 'package:loyalty_app/features/employee/screens/employee_screens.dart';
import 'package:loyalty_app/customer/home/screens/main_screen.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.7, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _navigate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    // Wait until auth state resolves from initial
    while (ref.read(authProvider).status == AuthStatus.initial) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;

    final auth = ref.read(authProvider);

    Widget destination;
    if (!auth.isAuthenticated) {
      destination = const OnboardingScreen();
    } else if (auth.isEmployee) {
      // Restored employee session → go to employee dashboard
      destination = EmployeeDashboardScreen(employee: auth.user!);
    } else {
      // Restored customer session → go to main screen
      destination = const MainScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, anim, __) =>
            FadeTransition(opacity: anim, child: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bgDeep,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.splashGradient,
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const AppLogo(size: 96),
                    const SizedBox(height: 22),
                    Text(
                      'LoyaltyHub',
                      style: AppTextStyles.h1
                          .copyWith(fontSize: 32, letterSpacing: -1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'EARN · COLLECT · REDEEM',
                      style: AppTextStyles.caption.copyWith(letterSpacing: 3),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 36, height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}