import 'package:flutter/material.dart';

class AppColors {
  static const bgDark       = Color(0xFF0F0A1E);
  static const bgCard       = Color(0xFF1A1035);
  static const bgCardLight  = Color(0xFF251A4A);
  static const bgInput      = Color(0xFF1E1540);
  static const primary      = Color(0xFF6C4FE8);
  static const accent       = Color(0xFFFF6B35);
  static const accentGold   = Color(0xFFFFB627);
  static const fuelColor    = Color(0xFF4ECDC4);
  static const laundryColor = Color(0xFFFF6B9D);
  static const golfColor    = Color(0xFF45B7D1);
  static const textPrimary  = Color(0xFFFFFFFF);
  static const textSecondary= Color(0xFFB0A8C8);
  static const border       = Color(0xFF2E2358);
  static const surface      = Color(0xFF1A1035);
  static const success      = Color(0xFF4CAF50);
  static const error        = Color(0xFFFF5252);

  // Tier colors
  static const bronze   = Color(0xFFCD7F32);
  static const silver   = Color(0xFFC0C0C0);
  static const gold     = Color(0xFFFFD700);
  static const platinum = Color(0xFFE5E4E2);
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
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.bgCard,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
);

class AppTextStyles {
  static const heading1 = TextStyle(
      fontFamily: 'Poppins', fontSize: 28,
      fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const heading2 = TextStyle(
      fontFamily: 'Poppins', fontSize: 22,
      fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const body = TextStyle(
      fontFamily: 'Poppins', fontSize: 14,
      fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static const caption = TextStyle(
      fontFamily: 'Poppins', fontSize: 12,
      fontWeight: FontWeight.w400, color: AppColors.textSecondary);
}