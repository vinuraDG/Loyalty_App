import 'package:flutter/material.dart';
import 'package:loyalty_app/core/theme/app_theme.dart';
import 'package:loyalty_app/features/auth/screens/login_screen.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';


class _Slide {
  final IconData icon;
  final Color color;
  final String step;
  final String title;
  final String description;
  const _Slide({required this.icon, required this.color, required this.step,
    required this.title, required this.description});
}

const _slides = [
  _Slide(
    icon: Icons.local_gas_station_rounded,
    color: AppColors.fuelColor,
    step: '01 / 03',
    title: 'Earn points at our fuel station',
    description: 'Fill up your tank and collect loyalty points every time. Just show your QR code to the attendant.',
  ),
  _Slide(
    icon: Icons.local_laundry_service_rounded,
    color: AppColors.laundryColor,
    step: '02 / 03',
    title: 'Redeem at our laundry service',
    description: 'Use your earned points to get free washes and discounts at our premium laundry service.',
  ),
  _Slide(
    icon: Icons.diamond,
    color: AppColors.accentGold,
    step: '03 / 03',
    title: 'Shop gold with your rewards',
    description: 'Redeem your loyalty points for exclusive discounts and special offers at partner gold shops.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _idx = 0;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _next() {
    if (_idx < 2) {
      _ctrl.reset();
      setState(() => _idx++);
      _ctrl.forward();
    } else {
      _goLogin();
    }
  }

  void _goLogin() => Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: const LoginScreen()),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_idx];
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              // Illustration area
              Expanded(
                flex: 5,
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(
                      color: slide.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(slide.icon, size: 110, color: slide.color.withOpacity(0.9)),
                ]),
              ),

              // Content area
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slide.step, style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary, letterSpacing: 2)),
                      const SizedBox(height: 12),
                      Text(slide.title, style: AppTextStyles.h2),
                      const SizedBox(height: 14),
                      Text(slide.description, style: AppTextStyles.bodySmall.copyWith(height: 1.7)),
                      const SizedBox(height: 28),

                      // Dots
                      Row(children: List.generate(3, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: i == _idx ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _idx ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ))),

                      const SizedBox(height: 28),
                      GradientButton(
                        label: _idx < 2 ? 'Next' : 'Get started',
                        icon: _idx < 2 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                        onPressed: _next,
                      ),
                      const SizedBox(height: 12),
                      GhostButton(label: 'Skip intro', onPressed: _goLogin),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}