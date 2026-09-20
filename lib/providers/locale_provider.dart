import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
// Locale Provider
//
// FIX: The initial locale is now loaded synchronously from
// SharedPreferences BEFORE the app starts (see main.dart).
// We pass it as an argument to LocaleNotifier so the UI
// never shows the wrong language on first frame.
// ─────────────────────────────────────────────────────────────

const _kLocaleKey = 'app_locale';

// Called once in main() before runApp — returns the saved locale.
Future<Locale> loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final code  = prefs.getString(_kLocaleKey) ?? 'en';
  // Validate — fall back to English if stored code isn't supported
  final supported = supportedLocales.map((l) => l.languageCode).toSet();
  return Locale(supported.contains(code) ? code : 'en');
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  // Initial value is overridden in main.dart via ProviderScope overrides.
  return LocaleNotifier(const Locale('en'));
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(super.initial);

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }
}

// ─────────────────────────────────────────────────────────────
// Supported locales — add more here to expand language support
// ─────────────────────────────────────────────────────────────

const supportedLocales = [
  Locale('en'),  // English
  Locale('ta'),  // Tamil
  Locale('hi'),  // Hindi
  Locale('ml'),  // Malayalam
  Locale('te'),  // Telugu
  Locale('kn'),  // Kannada
  Locale('mr'),  // Marathi
];

const localeNames = {
  'en': 'English',
  'ta': 'தமிழ்',
  'hi': 'हिन्दी',
  'ml': 'മലയാളം',
  'te': 'తెలుగు',
  'kn': 'ಕನ್ನಡ',
  'mr': 'मराठी',
};

const localeSubtitles = {
  'en': 'English — Default',
  'ta': 'Tamil — தமிழ்நாடு',
  'hi': 'Hindi — हिंदी',
  'ml': 'Malayalam — Kerala',
  'te': 'Telugu — Andhra / Telangana',
  'kn': 'Kannada — Karnataka',
  'mr': 'Marathi — Maharashtra',
};
