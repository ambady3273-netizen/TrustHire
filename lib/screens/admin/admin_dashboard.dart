import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Admin Dashboard — landing screen for users with role == 'admin'.
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    final displayName = userAsync.maybeWhen(
      data: (u) => u?.fullName ?? 'Admin',
      orElse: () => 'Admin',
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.admin_panel_settings_outlined, size: 18),
            SizedBox(width: 6),
            Text('TrustHire · Admin'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Welcome
          Text(
            'Welcome, $displayName 👋',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage fraud reports, verifications, and platform safety.',
            style: TextStyle(color: AppColors.mute),
          ),
          const SizedBox(height: 28),

                    // Stats row — live from Firestore
          Builder(
            builder: (context) {
              final flagged = ref.watch(adminFlaggedCountProvider)
                  .maybeWhen(data: (n) => '$n', orElse: () => '…');
              final kyc = ref.watch(adminPendingKycCountProvider)
                  .maybeWhen(data: (n) => '$n', orElse: () => '…');
              final cleared = ref.watch(adminApprovedCountProvider)
                  .maybeWhen(data: (n) => '$n', orElse: () => '…');
              return Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: flagged,
                      label: 'Flagged',
                      color: AppColors.coral,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: kyc,
                      label: 'Pending KYC',
                      color: AppColors.marigoldDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      value: cleared,
                      label: 'Approved',
                      color: AppColors.teal,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // Quick actions
          _QuickAction(
            icon: Icons.warning_amber_rounded,
            color: AppColors.coral,
            label: 'Fraud Reports',
            subtitle: 'Review AI-flagged job postings',
            onTap: () => Navigator.pushNamed(context, '/adminFraud'),
          ),
          const SizedBox(height: 14),
          _QuickAction(
            icon: Icons.verified_user_outlined,
            color: AppColors.teal,
            label: 'KYC Verification',
            subtitle: 'Approve employer identity documents',
            onTap: () => Navigator.pushNamed(context, '/adminVerification'),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.mute),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.mute,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mute),
          ],
        ),
      ),
    );
  }
}
