import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color bgDeep       = Color(0xFF07041A);
  static const Color bgDark       = Color(0xFF0F0A1E);
  static const Color bgCard       = Color(0xFF1A1035);
  static const Color bgCardLight  = Color(0xFF241A48);
  static const Color bgInput      = Color(0xFF1C1240);
  static const Color primary      = Color(0xFF7C5CF6);
  static const Color primaryLight = Color(0xFF9D80FF);
  static const Color primaryDark  = Color(0xFF5A3FD4);
  static const Color accent       = Color(0xFFFF6B35);
  static const Color accentGold   = Color(0xFFFFB627);
  static const Color fuelColor    = Color(0xFF4ECDC4);
  static const Color laundryColor = Color(0xFFFF6B9D);
  static const Color golfColor    = Color(0xFF45B7D1);
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B0D0);
  static const Color textMuted     = Color(0xFF6B6080);
  static const Color textHint      = Color(0xFF4E4370);
  static const Color success = Color(0xFF4ADE80);
  static const Color error   = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB627);
  static const Color border      = Color(0xFF2A1F58);
  static const Color borderFocus = Color(0xFF7C5CF6);
  static const List<Color> cardGradient   = [Color(0xFF4B2FBE), Color(0xFF9B30C8)];
  static const List<Color> buttonGradient = [Color(0xFF7C5CF6), Color(0xFF5A3FD4)];
  static const List<Color> splashGradient = [Color(0xFF07041A), Color(0xFF1A0A3D)];
}

class AppTextStyles {
  AppTextStyles._();
  static const TextStyle display = TextStyle(fontFamily:'Poppins',fontSize:48,fontWeight:FontWeight.w700,color:AppColors.textPrimary,letterSpacing:-2,height:1);
  static const TextStyle h1 = TextStyle(fontFamily:'Poppins',fontSize:28,fontWeight:FontWeight.w700,color:AppColors.textPrimary,letterSpacing:-0.5);
  static const TextStyle h2 = TextStyle(fontFamily:'Poppins',fontSize:22,fontWeight:FontWeight.w600,color:AppColors.textPrimary);
  static const TextStyle h3 = TextStyle(fontFamily:'Poppins',fontSize:18,fontWeight:FontWeight.w600,color:AppColors.textPrimary);
  static const TextStyle h4 = TextStyle(fontFamily:'Poppins',fontSize:16,fontWeight:FontWeight.w600,color:AppColors.textPrimary);
  static const TextStyle bodyLarge = TextStyle(fontFamily:'Poppins',fontSize:16,fontWeight:FontWeight.w400,color:AppColors.textPrimary,height:1.5);
  static const TextStyle bodyMedium = TextStyle(fontFamily:'Poppins',fontSize:14,fontWeight:FontWeight.w400,color:AppColors.textPrimary,height:1.5);
  static const TextStyle bodySmall = TextStyle(fontFamily:'Poppins',fontSize:13,fontWeight:FontWeight.w400,color:AppColors.textSecondary,height:1.5);
  static const TextStyle caption = TextStyle(fontFamily:'Poppins',fontSize:12,fontWeight:FontWeight.w400,color:AppColors.textMuted);
  static const TextStyle labelLarge = TextStyle(fontFamily:'Poppins',fontSize:16,fontWeight:FontWeight.w600,color:AppColors.textPrimary,letterSpacing:0.3);
  static const TextStyle labelMedium = TextStyle(fontFamily:'Poppins',fontSize:14,fontWeight:FontWeight.w500,color:AppColors.textPrimary);
  static const TextStyle labelSmall = TextStyle(fontFamily:'Poppins',fontSize:12,fontWeight:FontWeight.w500,color:AppColors.textSecondary);
  static const TextStyle hint = TextStyle(fontFamily:'Poppins',fontSize:14,fontWeight:FontWeight.w400,color:AppColors.textHint);
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Poppins',
  scaffoldBackgroundColor: AppColors.bgDark,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary, secondary: AppColors.accent,
    surface: AppColors.bgCard, onPrimary: AppColors.textPrimary,
    onSurface: AppColors.textPrimary, error: AppColors.error,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent, elevation: 0,
    scrolledUnderElevation: 0, centerTitle: false,
    titleTextStyle: AppTextStyles.h4,
    iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true, fillColor: AppColors.bgInput,
    contentPadding: const EdgeInsets.symmetric(horizontal:20,vertical:18),
    hintStyle: AppTextStyles.hint,
    border: OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:AppColors.borderFocus,width:1.5)),
    errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:AppColors.error)),
    focusedErrorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:AppColors.error,width:1.5)),
    errorStyle: AppTextStyles.caption.copyWith(color:AppColors.error),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary, foregroundColor: AppColors.textPrimary,
      minimumSize: const Size(double.infinity,54),
      shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),
      textStyle: AppTextStyles.labelLarge, elevation: 0,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor:AppColors.primaryLight,textStyle:AppTextStyles.labelMedium),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.bgCardLight, contentTextStyle: AppTextStyles.bodyMedium,
    shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
  ),
  dividerTheme: const DividerThemeData(color:AppColors.border,thickness:1),
);