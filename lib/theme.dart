import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens shared across every screen.
/// Colors have FIXED meaning app-wide:
///   teal    -> "verified" (never used for anything else)
///   coral   -> "flagged / danger"
///   marigold-> primary action / community warmth
///   ink     -> platform chrome / authority
class AppColors {
  static const ink        = Color(0xFF1B2A4A);
  static const inkDark    = Color(0xFF101A30);
  static const marigold   = Color(0xFFF5A623);
  static const marigoldDark = Color(0xFFC97C0E);
  static const teal       = Color(0xFF0E7C7B);
  static const tealLight  = Color(0xFFE6F5F0);
  static const coral      = Color(0xFFE15B4F);
  static const coralLight = Color(0xFFFBEAE8);
  static const paper      = Color(0xFFF2F5FA);
  static const card       = Color(0xFFFFFFFF);
  static const text       = Color(0xFF1F2430);
  static const mute       = Color(0xFF5B6478);
  static const border     = Color(0xFFDFE4EF);
  static const warnBg     = Color(0xFFFDF1E4);

  // Gradient presets
  static const gradientInk = LinearGradient(
    colors: [Color(0xFF1B2A4A), Color(0xFF243760)],
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
  );
  static const gradientTeal = LinearGradient(
    colors: [Color(0xFF0E7C7B), Color(0xFF15A39E)],
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
  );
  static const gradientGold = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFE88C0A)],
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.paper,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor:   AppColors.ink,
      primary:     AppColors.ink,
      secondary:   AppColors.marigold,
      surface:     AppColors.card,
    ),

    // ── AppBar ───────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor:  AppColors.card,
      foregroundColor:  AppColors.ink,
      elevation:        0,
      centerTitle:      false,
      scrolledUnderElevation: 1,
      shadowColor:      AppColors.border.withAlpha(120),
      titleTextStyle: const TextStyle(
        color:      AppColors.ink,
        fontSize:   16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    // ── Cards ────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color:        AppColors.card,
      elevation:    0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),

    // ── Input fields ─────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled:          true,
      fillColor:       AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: AppColors.ink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   const BorderSide(color: AppColors.coral),
      ),
      labelStyle:  const TextStyle(color: AppColors.mute, fontSize: 13.5),
      hintStyle:   const TextStyle(color: AppColors.mute, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ── Elevated button ──────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation:    0,
        padding:      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),

    // ── Outlined button ──────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13.5),
      ),
    ),

    // ── Text button ──────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13.5),
      ),
    ),

    // ── Chips ─────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor:  AppColors.paper,
      selectedColor:    AppColors.ink,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border)),
    ),

    // ── Bottom sheet ─────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor:  AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // ── Divider ──────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color:     AppColors.border,
      thickness: 1,
      space:     1,
    ),

    // ── Text ─────────────────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          color: AppColors.ink, fontWeight: FontWeight.w800),
      headlineMedium: TextStyle(
          color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 22),
      titleLarge: TextStyle(
          color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 17),
      titleMedium: TextStyle(
          color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 15),
      bodyLarge: TextStyle(
          color: AppColors.text, fontSize: 14, height: 1.5),
      bodyMedium: TextStyle(
          color: AppColors.text, fontSize: 13, height: 1.4),
      bodySmall: TextStyle(
          color: AppColors.mute, fontSize: 11.5),
      labelLarge: TextStyle(
          color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 14),
    ),

    // ── ListTile ─────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      iconColor: AppColors.mute,
    ),
  );
}
