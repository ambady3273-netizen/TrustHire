import 'package:flutter/material.dart';

/// Design tokens shared across every screen.
/// Colors have FIXED meaning app-wide:
///   teal    -> "verified" (never used for anything else)
///   coral   -> "flagged / danger" (never used for anything else)
///   marigold-> primary action / community warmth
///   ink     -> platform chrome / authority
class AppColors {
  static const ink = Color(0xFF1B2A4A);
  static const inkDark = Color(0xFF101A30);
  static const marigold = Color(0xFFF5A623);
  static const marigoldDark = Color(0xFFC97C0E);
  static const teal = Color(0xFF0E7C7B);
  static const tealLight = Color(0xFFE6F5F0);
  static const coral = Color(0xFFE15B4F);
  static const coralLight = Color(0xFFFBEAE8);
  static const paper = Color(0xFFEEF1F7);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF1F2430);
  static const mute = Color(0xFF5B6478);
  static const border = Color(0xFFDFE4EF);
  static const warnBg = Color(0xFFFDF1E4);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.paper,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.ink,
      primary: AppColors.ink,
      secondary: AppColors.marigold,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: AppColors.ink),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.text, fontSize: 13),
    ),
  );
}
