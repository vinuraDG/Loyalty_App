import 'package:flutter/material.dart';
import 'package:loyalty_app/features/home/screens/home_screen.dart';
import 'package:loyalty_app/features/points/screens/points_screen.dart';
import 'package:loyalty_app/features/profile/screens/profile_screen.dart';
import 'package:loyalty_app/features/qr/screens/qr_screen.dart';
import 'package:loyalty_app/features/redeem/screens/redeem_screen.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late int _idx;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
  }

  void setIndex(int idx) {
    setState(() => _idx = idx);
  }

  final _screens = const [
    HomeScreen(),
    PointsScreen(),
    QrScreen(),
    RedeemScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _idx, children: _screens),
    bottomNavigationBar: AppBottomNav(
      currentIndex: _idx,
      onTap: (i) => setState(() => _idx = i),
    ),
  );
}