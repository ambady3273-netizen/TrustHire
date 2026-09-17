import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/locale_provider.dart';
import '../../theme.dart';

// ─────────────────────────────────────────────────────────────
// Language Selection Screen
// Accessible from all 3 dashboards via Settings or Profile
// ─────────────────────────────────────────────────────────────

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Language / மொழி / भाषा'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.translate, color: AppColors.teal, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose the language for the app interface.\n'
                    'செல்லும் மொழியை தேர்ந்தெடுக்கவும்.\n'
                    'ऐप भाषा चुनें।',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.teal,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Language tiles
          ...supportedLocales.map((locale) {
            final isSelected =
                currentLocale.languageCode == locale.languageCode;
            final name = localeNames[locale.languageCode] ?? locale.languageCode;
            final subtitle = _subtitle(locale.languageCode);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () async {
                  await ref.read(localeProvider.notifier).setLocale(locale);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Language changed to $name'),
                      backgroundColor: AppColors.teal,
                    ));
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.tealLight : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.teal
                          : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _flag(locale.languageCode),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.teal
                                    : AppColors.ink,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.mute),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.teal, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _flag(String code) {
    switch (code) {
      case 'ta': return '🇮🇳';
      case 'hi': return '🇮🇳';
      default:   return '🇬🇧';
    }
  }

  String _subtitle(String code) {
    switch (code) {
      case 'ta': return 'Tamil — தமிழ்நாடு';
      case 'hi': return 'Hindi — हिंदी';
      default:   return 'English — Default';
    }
  }
}
