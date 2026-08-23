import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/core/providers/refresh_provider.dart';
import 'package:loyalty_app/customer/home/screens/home_screen.dart';
import 'package:loyalty_app/customer/points/screens/points_screen.dart';
import 'package:loyalty_app/customer/profile/screens/profile_screen.dart';
import 'package:loyalty_app/customer/qr/screens/qr_screen.dart';
import 'package:loyalty_app/shared/widgets/app_widgets.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  ConsumerState<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends ConsumerState<MainScreen> {
  late int _idx;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
  }

  void setIndex(int idx) {
    if ((idx == 0 || idx == 1) && idx != _idx) appRefresh(ref);
    setState(() => _idx = idx);
  }

  final _screens = const [
    HomeScreen(),
    PointsScreen(),
    QrScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _idx, children: _screens),
    bottomNavigationBar: AppBottomNav(
      currentIndex: _idx,
      onTap: (i) {
        if ((i == 0 || i == 1) && i != _idx) appRefresh(ref);
        setState(() => _idx = i);
      },
    ),
  );
}