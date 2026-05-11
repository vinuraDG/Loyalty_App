import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  static const bgDark = Color(0xFF0F0A1E);
  static const bgCard = Color(0xFF1A1035);
  static const bgCardLight = Color(0xFF251A4A);
  static const bgInput = Color(0xFF1E1540);
  static const primary = Color(0xFF6C4FE8); // purple
  static const accent = Color(0xFFFF6B35); // orange
  static const accentGold = Color(0xFFFFB627);
  static const fuelColor = Color(0xFF4ECDC4); // teal
  static const laundryColor = Color(0xFFFF6B9D); // pink
  static const golfColor = Color(0xFF45B7D1); // sky blue
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0A8C8);
  static const border = Color(0xFF2E2358);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFFF5252);
  static const cardGradient = [Color(0xFF4B2FBE), Color(0xFF8B2FC9)];
}

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.bgCard,
  fontFamily: 'Poppins',
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    surface: AppColors.bgCard,
  ),
);
