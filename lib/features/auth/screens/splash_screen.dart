import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _activeFeat = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final _features = [
    {'icon': '⭐', 'label': 'Earn Points',
     'desc': 'Earn points every time you visit. Points add up to unlock exclusive rewards.'},
    {'icon': '🎁', 'label': 'Rewards',
     'desc': 'Browse and redeem your points for discounts, free services, and exclusive offers.'},
    {'icon': '📷', 'label': 'QR Scan',
     'desc': 'Scan at checkout in seconds. Open LoyaltyGo and scan to earn instantly.'},
  ];

  final _onboardPages = [
    {'emoji': '⭐', 'title': 'Earn With Every Visit',
     'body': 'Visit your favourite spots and collect points automatically with a quick QR scan.'},
    {'emoji': '🎁', 'title': 'Unlock Amazing Rewards',
     'body': 'Redeem points for discounts, freebies, and exclusive member offers.'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 12, end: 20).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    setState(() => _currentPage = page);
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(children: [
        _orb(220, const Color(0xFF6C4FE8), top: -60, left: -60),
        _orb(180, const Color(0xFF6C4FE8), bottom: 80, right: -70),
        _orb(120, const Color(0xFFFF6B35), bottom: 160, left: -20),
        SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMainPage(),
              ..._onboardPages.asMap().entries
                  .map((e) => _buildOnboardPage(e.key, e.value)),
              _buildLoginPage(),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _orb(double size, Color color,
      {double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(0.18)),
      ),
    );
  }

  // ── Main / Landing Page ───────────────────────────────────
  Widget _buildMainPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        const Spacer(flex: 2),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF9A3C), Color(0xFFFFB627)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFFFB627).withOpacity(0.12),
                    blurRadius: _pulseAnim.value,
                    spreadRadius: _pulseAnim.value),
                BoxShadow(
                    color: const Color(0xFFFFB627).withOpacity(0.06),
                    blurRadius: _pulseAnim.value * 2,
                    spreadRadius: _pulseAnim.value * 2),
              ],
            ),
            child: const Center(
                child: Text('⭐', style: TextStyle(fontSize: 44))),
          ),
        ),
        const SizedBox(height: 22),
        const Text('LoyaltyGo',
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        const Text('Earn rewards every visit.\nYour loyalty, elevated.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 24),
        // Feature chips
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _features.asMap().entries.map((e) {
            final active = _activeFeat == e.key;
            return GestureDetector(
              onTap: () => setState(() => _activeFeat = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF6C4FE8).withOpacity(0.4)
                      : Colors.white.withOpacity(0.07),
                  border: Border.all(
                      color: active
                          ? const Color(0xFF6C4FE8)
                          : Colors.white.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.value['icon']!, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(e.value['label']!,
                      style: const TextStyle(fontSize: 11, color: Colors.white)),
                ]),
              ),
            );
          }).toList(),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey(_activeFeat),
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1035).withOpacity(0.95),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(_features[_activeFeat]['desc']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          ),
        ),
        const Spacer(flex: 3),
        _primaryBtn('Get Started', () => _goTo(1)),
        const SizedBox(height: 10),
        _secondaryBtn('I have an account', () => _goTo(3)),
        const SizedBox(height: 16),
        _dots(0, 3),
        const SizedBox(height: 10),
        const Text('By continuing you agree to our Terms & Privacy Policy',
            style: TextStyle(fontSize: 10, color: Color(0xFF4A3F6B))),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ── Onboarding Pages ──────────────────────────────────────
  Widget _buildOnboardPage(int index, Map<String, String> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        const Spacer(flex: 2),
        Text(data['emoji']!, style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 20),
        Text(data['title']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 10),
        Text(data['body']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
        const Spacer(flex: 3),
        _primaryBtn(
            index == 0 ? 'Next →' : 'Create Account →',
            () => _goTo(index == 0 ? 2 : 3)),
        const SizedBox(height: 10),
        _secondaryBtn('← Back', () => _goTo(index == 0 ? 0 : 1)),
        const SizedBox(height: 16),
        _dots(index + 1, 3),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ── Login Page ────────────────────────────────────────────
  Widget _buildLoginPage() {
    final phoneCtrl = TextEditingController(text: '0771234567');
    final passCtrl  = TextEditingController(text: 'password');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 32),
        const Text('Welcome back 👋',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        const Text('Sign in to your account',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 28),
        _inputField('Phone number', '0771234567', phoneCtrl, TextInputType.phone),
        const SizedBox(height: 14),
        _inputField('Password', '••••••••', passCtrl,
            TextInputType.visiblePassword, obscure: true),
        const Spacer(),
        _primaryBtn('Sign In', () {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }),
        const SizedBox(height: 10),
        _secondaryBtn('← Back', () => _goTo(0)),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  Widget _inputField(String label, String hint, TextEditingController ctrl,
      TextInputType type, {bool obscure = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: type,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.07),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }

  Widget _primaryBtn(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB627),
            foregroundColor: const Color(0xFF1A1035),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          child: Text(label),
        ),
      );

  Widget _secondaryBtn(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.15)),
            backgroundColor: Colors.white.withOpacity(0.06),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          child: Text(label),
        ),
      );

  Widget _dots(int active, int count) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
            count,
            (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == active
                        ? AppColors.accent
                        : Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
      );
}