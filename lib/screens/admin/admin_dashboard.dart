import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

// ── Live stat providers ────────────────────────────────────────

final _pendingJobCountProvider = StreamProvider.autoDispose<int>((ref) {
  return ref
      .watch(firestoreServiceProvider)
      .getPendingJobs()
      .map((jobs) => jobs.length);
});

final _pendingKycCountProvider = StreamProvider.autoDispose<int>((ref) {
  return ref
      .watch(firestoreServiceProvider)
      .getPendingKycUsers()
      .map((users) => users.length);
});

final _approvedJobCountProvider = StreamProvider.autoDispose<int>((ref) {
  return ref
      .watch(firestoreServiceProvider)
      .getApprovedJobs()
      .map((jobs) => jobs.length);
});

// ── Screen ────────────────────────────────────────────────────

/// Admin Dashboard — all statistics come from live Firestore streams.
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final pendingJobsAsync = ref.watch(_pendingJobCountProvider);
    final pendingKycAsync = ref.watch(_pendingKycCountProvider);
    final approvedJobsAsync = ref.watch(_approvedJobCountProvider);

    final displayName = userAsync.maybeWhen(
      data: (u) => u?.fullName ?? 'Admin',
      orElse: () => 'Admin',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined, size: 18),
            SizedBox(width: 6),
            Text('TrustHire · Admin'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/editProfile'),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (r) => false);
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
          const SizedBox(height: 24),

          // ── Live stats row ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  asyncValue: pendingJobsAsync,
                  label: 'Pending Review',
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  asyncValue: pendingKycAsync,
                  label: 'Pending KYC',
                  color: AppColors.marigoldDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  asyncValue: approvedJobsAsync,
                  label: 'Live Jobs',
                  color: AppColors.teal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Quick actions ───────────────────────────────────
          _QuickAction(
            icon: Icons.warning_amber_rounded,
            color: AppColors.coral,
            label: 'Fraud Reports',
            subtitle: pendingJobsAsync.maybeWhen(
              data: (n) =>
                  n > 0 ? '$n job${n == 1 ? '' : 's'} pending review' : 'No jobs pending review',
              orElse: () => 'Review AI-flagged job postings',
            ),
            badge: pendingJobsAsync.maybeWhen(
              data: (n) => n > 0 ? n.toString() : null,
              orElse: () => null,
            ),
            onTap: () => Navigator.pushNamed(context, '/adminFraud'),
          ),
          const SizedBox(height: 14),
          _QuickAction(
            icon: Icons.verified_user_outlined,
            color: AppColors.teal,
            label: 'KYC Verification',
            subtitle: pendingKycAsync.maybeWhen(
              data: (n) =>
                  n > 0 ? '$n user${n == 1 ? '' : 's'} awaiting verification' : 'No pending KYC submissions',
              orElse: () => 'Approve identity documents',
            ),
            badge: pendingKycAsync.maybeWhen(
              data: (n) => n > 0 ? n.toString() : null,
              orElse: () => null,
            ),
            onTap: () => Navigator.pushNamed(context, '/adminVerification'),
          ),
        ],
      ),
    );
  }
}

// ── Stat tile widget ──────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final AsyncValue<int> asyncValue;
  final String label;
  final Color color;

  const _StatTile({
    required this.asyncValue,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          asyncValue.when(
            loading: () => SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
            error: (_, __) => Text('—',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            data: (n) => Text(
              n.toString(),
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: color),
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

// ── Quick action tile ─────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badge,
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
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.mute)),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, color: AppColors.mute),
          ],
        ),
      ),
    );
  }
}
