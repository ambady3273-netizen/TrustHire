import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

// ── Provider ──────────────────────────────────────────────────

final analyticsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.watch(firestoreServiceProvider).getAnalytics();
});

// ─────────────────────────────────────────────────────────────
// AdminAnalyticsScreen
// ─────────────────────────────────────────────────────────────

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Platform Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(analyticsProvider),
          ),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.coral),
              const SizedBox(height: 12),
              Text('Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mute)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(analyticsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Section: Users ───────────────────────────────
            _SectionHeader(
                icon: Icons.people_outline,
                title: 'Users',
                color: AppColors.ink),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatCard(
                    label: 'Total Users',
                    value: data['totalUsers'] ?? 0,
                    color: AppColors.ink,
                    icon: Icons.people),
                const SizedBox(width: 10),
                _StatCard(
                    label: 'Job Seekers',
                    value: data['totalSeekers'] ?? 0,
                    color: AppColors.teal,
                    icon: Icons.person_search),
                const SizedBox(width: 10),
                _StatCard(
                    label: 'Employers',
                    value: data['totalEmployers'] ?? 0,
                    color: AppColors.marigoldDark,
                    icon: Icons.business),
              ],
            ),

            const SizedBox(height: 24),

            // ── Section: Jobs ────────────────────────────────
            _SectionHeader(
                icon: Icons.work_outline,
                title: 'Jobs',
                color: AppColors.teal),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatCard(
                    label: 'Total Jobs',
                    value: data['totalJobs'] ?? 0,
                    color: AppColors.ink,
                    icon: Icons.work),
                const SizedBox(width: 10),
                _StatCard(
                    label: 'Approved',
                    value: data['approvedJobs'] ?? 0,
                    color: AppColors.teal,
                    icon: Icons.check_circle_outline),
                const SizedBox(width: 10),
                _StatCard(
                    label: 'Scam Blocked',
                    value: data['rejectedJobs'] ?? 0,
                    color: AppColors.coral,
                    icon: Icons.gpp_bad_outlined),
              ],
            ),

            const SizedBox(height: 24),

            // ── Section: Applications ────────────────────────
            _SectionHeader(
                icon: Icons.receipt_long_outlined,
                title: 'Applications',
                color: AppColors.marigoldDark),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatCard(
                    label: 'Total Apps',
                    value: data['totalApplications'] ?? 0,
                    color: AppColors.ink,
                    icon: Icons.assignment_outlined),
                const SizedBox(width: 10),
                _StatCard(
                    label: 'Completed',
                    value: data['completedJobs'] ?? 0,
                    color: AppColors.teal,
                    icon: Icons.task_alt),
              ],
            ),

            const SizedBox(height: 24),

            // ── Section: Platform Safety ─────────────────────
            _SectionHeader(
                icon: Icons.shield_outlined,
                title: 'Platform Safety',
                color: AppColors.coral),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatCard(
                    label: 'Pending Reports',
                    value: data['pendingReports'] ?? 0,
                    color: AppColors.coral,
                    icon: Icons.flag_outlined),
              ],
            ),

            const SizedBox(height: 24),

            // ── AI safety rate ────────────────────────────────
            if ((data['totalJobs'] ?? 0) > 0) ...[
              _SectionHeader(
                  icon: Icons.smart_toy_outlined,
                  title: 'AI Scam Detection',
                  color: AppColors.ink),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Scam Block Rate',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        Text(
                          '${(((data['rejectedJobs'] ?? 0) / (data['totalJobs'] ?? 1)) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.coral),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (data['rejectedJobs'] ?? 0) /
                            (data['totalJobs'] ?? 1),
                        minHeight: 10,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.coral),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Percentage of job postings flagged as scam by AI',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.mute),
                    ),
                  ],
                ),
              ),
            ],

            // ── Job Completion rate ───────────────────────────
            if ((data['totalApplications'] ?? 0) > 0) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Job Completion Rate',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        Text(
                          '${(((data['completedJobs'] ?? 0) / (data['totalApplications'] ?? 1)) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.teal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (data['completedJobs'] ?? 0) /
                            (data['totalApplications'] ?? 1),
                        minHeight: 10,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.teal),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Percentage of applications that resulted in a completed job',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.mute),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: color)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value.toString(),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.mute),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
