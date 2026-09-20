import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/locale_provider.dart';
import '../../theme.dart';

// ─────────────────────────────────────────────────────────────
// Language Selection Screen — 7 Indian languages supported
// ─────────────────────────────────────────────────────────────

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCode = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Language'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Header ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1AAE9F), Color(0xFF1B2A4A)],
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.translate,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose Your Language',
                          style: TextStyle(
                              color:      Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize:   16)),
                      SizedBox(height: 4),
                      Text(
                        'மொழியை தேர்ந்தெடுக்கவும்  •  भाषा चुनें\n'
                        'ഭാഷ തിരഞ്ഞെടുക്കുക  •  భాష ఎంచుకోండి',
                        style: TextStyle(
                            color:    Colors.white70,
                            fontSize: 11.5,
                            height:   1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Available Languages',
              style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w700,
                  color:      AppColors.mute,
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),

          // ── Language tiles ─────────────────────────────────
          ...supportedLocales.map((locale) {
            final code       = locale.languageCode;
            final isSelected = currentCode == code;
            final info       = _langInfo[code]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () async {
                  await ref.read(localeProvider.notifier).setLocale(locale);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Text(info['flag']!,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Text(
                              '${info['native']} selected',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.teal,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.ink
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.ink
                          : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:      AppColors.ink.withAlpha(40),
                              blurRadius: 8,
                              offset:     const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      // Flag emoji
                      Container(
                        width:  48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:        isSelected
                              ? Colors.white.withAlpha(20)
                              : AppColors.paper,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(info['flag']!,
                              style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info['native']!,
                              style: TextStyle(
                                fontSize:   17,
                                fontWeight: FontWeight.w800,
                                color:      isSelected
                                    ? Colors.white
                                    : AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              info['subtitle']!,
                              style: TextStyle(
                                fontSize: 12,
                                color:    isSelected
                                    ? Colors.white60
                                    : AppColors.mute,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Check / radio
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 26,
                                key: ValueKey('check'))
                            : Icon(Icons.circle_outlined,
                                color: AppColors.border, size: 24,
                                key: ValueKey('empty')),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // ── Note ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        AppColors.tealLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.teal, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Language change takes effect immediately across the entire app.',
                    style: TextStyle(
                        fontSize: 12.5,
                        color:    AppColors.teal,
                        height:   1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Language metadata
// ─────────────────────────────────────────────────────────────

const _langInfo = {
  'en': {
    'native':   'English',
    'flag':     '🇬🇧',
    'subtitle': 'English — Default language',
  },
  'ta': {
    'native':   'தமிழ்',
    'flag':     '🇮🇳',
    'subtitle': 'Tamil — தமிழ்நாடு',
  },
  'hi': {
    'native':   'हिन्दी',
    'flag':     '🇮🇳',
    'subtitle': 'Hindi — उत्तर भारत',
  },
  'ml': {
    'native':   'മലയാളം',
    'flag':     '🇮🇳',
    'subtitle': 'Malayalam — Kerala',
  },
  'te': {
    'native':   'తెలుగు',
    'flag':     '🇮🇳',
    'subtitle': 'Telugu — Andhra / Telangana',
  },
  'kn': {
    'native':   'ಕನ್ನಡ',
    'flag':     '🇮🇳',
    'subtitle': 'Kannada — Karnataka',
  },
  'mr': {
    'native':   'मराठी',
    'flag':     '🇮🇳',
    'subtitle': 'Marathi — Maharashtra',
  },
};
