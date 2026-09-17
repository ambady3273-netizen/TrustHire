import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

// ─────────────────────────────────────────────────────────────
// ReferralScreen
// Shows the user's unique referral code + share button.
// Both referrer and new user get +5 trust score on join.
// ─────────────────────────────────────────────────────────────

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final user = userAsync.valueOrNull;

    // Generate referral code from uid if not set
    final code = (user?.referralCode.isNotEmpty == true)
        ? user!.referralCode
        : (user?.uid.substring(0, 8).toUpperCase() ?? '--------');

    final shareText =
        'Join TrustHire — India\'s trusted part-time job platform! '
        'Use my referral code $code to sign up and we both earn '
        '+5 Trust Score. Download: https://trusthire.app';

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Refer a Friend')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // ── Hero illustration ────────────────────────────
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_alt_outlined,
                  size: 56, color: AppColors.teal),
            ),
            const SizedBox(height: 20),
            const Text(
              'Invite Friends, Earn Together!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'When a friend signs up using your code,\n'
              'you both earn +5 Trust Score instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.mute, height: 1.5, fontSize: 13.5),
            ),
            const SizedBox(height: 32),

            // ── Referral code box ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:       Border.all(
                    color: AppColors.teal, width: 2),
              ),
              child: Column(
                children: [
                  const Text('Your Referral Code',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.mute)),
                  const SizedBox(height: 8),
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.teal,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied to clipboard!'),
                          backgroundColor: AppColors.teal,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Code'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Share button ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => Share.share(shareText),
                icon: const Icon(Icons.share_rounded),
                label: const Text(
                  'Share Invite Link',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── How it works ─────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('How it works',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.ink)),
                  SizedBox(height: 12),
                  _HowStep(
                    num: '1',
                    text: 'Share your referral code with a friend.',
                  ),
                  _HowStep(
                    num: '2',
                    text:
                        'They register on TrustHire and enter your code.',
                  ),
                  _HowStep(
                    num: '3',
                    text:
                        'Both of you receive +5 Trust Score immediately.',
                  ),
                  _HowStep(
                    num: '4',
                    text:
                        'Higher trust score = more visibility to employers!',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Referral stats ────────────────────────────────
            if (user != null)
              AppCard(
                bg: AppColors.tealLight,
                borderColor: Colors.transparent,
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.teal, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Trust Score: ${user.trustScore.toStringAsFixed(1)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal,
                                fontSize: 14),
                          ),
                          const Text(
                            'Invite more friends to boost it!',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.teal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HowStep extends StatelessWidget {
  final String num;
  final String text;
  const _HowStep({required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color:  AppColors.teal,
              shape:  BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.text)),
          ),
        ],
      ),
    );
  }
}
