import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/customer/home/screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/password_reset_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgDeep,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: LoyaltyApp()));
}

class LoyaltyApp extends StatefulWidget {
  const LoyaltyApp({super.key});

  @override
  State<LoyaltyApp> createState() => _LoyaltyAppState();
}

class _LoyaltyAppState extends State<LoyaltyApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    // Handle links when app is already running (foreground)
    try {
      _appLinks.uriLinkStream.listen(
        _handleLink,
        onError: (_) {}, // ignore stream errors
      );
    } catch (_) {}

    // Handle the link that cold-started the app
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleLink(uri);
    }).catchError((_) {});
  }

  void _handleLink(Uri uri) {
    // Expected: loyaltyapp://reset-password?email=...&token=...
    if (uri.host != 'reset-password') return;

    final email = uri.queryParameters['email'] ?? '';
    final token = uri.queryParameters['token'] ?? '';

    if (email.isEmpty || token.isEmpty) return;

    // Navigate — works whether the app is cold-started or already in the foreground
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => PasswordResetScreen(email: email, token: token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LoyaltyHub',
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    navigatorKey: navigatorKey,
    home: const SplashScreen(),
  );
}
