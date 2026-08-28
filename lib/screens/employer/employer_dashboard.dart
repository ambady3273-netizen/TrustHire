import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/application_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Employer Dashboard — live job and applicant counts from Firestore.
class EmployerDashboard extends ConsumerWidget {
  const EmployerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final jobsAsync = ref.watch(employerJobsProvider);
    final appsAsync = ref.watch(employerApplicationsProvider);

    final displayName = userAsync.maybeWhen(
      data: (u) => u?.fullName ?? 'Employer',
      orElse: () => 'Employer',
    );

    final totalJobs = jobsAsync.maybeWhen(
      data: (jobs) => jobs.length,
      orElse: () => 0,
    );

    final pendingApps = appsAsync.maybeWhen(
      data: (apps) => apps
          .where((a) => ApplicationStatus.isActionable(a.status))
          .length,
      orElse: () => 0,
    );

    final totalApps = appsAsync.maybeWhen(
      data: (apps) => apps.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, size: 18),
            SizedBox(width: 6),
            Text('TrustHire · Employer'),
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
            'Manage your job postings and applicants.',
            style: TextStyle(color: AppColors.mute),
          ),
          const SizedBox(height: 24),

          // Live stats row
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: totalJobs.toString(),
                  label: 'Jobs Posted',
                  color: AppColors.ink,
                  isLoading: jobsAsync.isLoading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: pendingApps.toString(),
                  label: 'Pending Review',
                  color: AppColors.marigoldDark,
                  isLoading: appsAsync.isLoading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: totalApps.toString(),
                  label: 'Total Applicants',
                  color: AppColors.teal,
                  isLoading: appsAsync.isLoading,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Quick actions
          _QuickAction(
            icon: Icons.add_circle_outline,
            color: AppColors.teal,
            label: 'Post a New Job',
            subtitle: 'Create a verified job listing',
            onTap: () => Navigator.pushNamed(context, '/postJob'),
          ),
          const SizedBox(height: 14),
          _QuickAction(
            icon: Icons.people_outline,
            color: AppColors.ink,
            label: 'My Posted Jobs',
            subtitle: pendingApps > 0
                ? '$pendingApps pending review'
                : 'See who applied to your jobs',
            badge: pendingApps > 0 ? pendingApps.toString() : null,
            onTap: () => Navigator.pushNamed(context, '/employerJobs'),
          ),
          const SizedBox(height: 14),
          _QuickAction(
            icon: Icons.lock_outline,
            color: AppColors.marigoldDark,
            label: 'Escrow Payments',
            subtitle: 'Manage secure escrow payments',
            onTap: () => Navigator.pushNamed(context, '/escrow'),
          ),

          const SizedBox(height: 32),

          // AI info card
          AppCard(
            bg: AppColors.tealLight,
            borderColor: Colors.transparent,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.smart_toy_outlined,
                        color: AppColors.teal, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'AI Safety Check',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Every job you post is automatically scanned for scam '
                  'indicators before going live. High-risk posts are held '
                  'for admin review.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF245957),
                    height: 1.5,
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
// Stat tile
// ─────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isLoading;

  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
    this.isLoading = false,
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
          isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Text(
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
            style:
                const TextStyle(fontSize: 10, color: AppColors.mute),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Quick action tile
// ─────────────────────────────────────────────────────────────

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
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
