import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/work_history_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

// ── Provider ─────────────────────────────────────────────────
final workHistoryProvider =
    StreamProvider.family<List<WorkHistoryModel>, String>((ref, seekerId) {
  return ref.watch(firestoreServiceProvider).watchWorkHistory(seekerId);
});

// ── Public provider for viewing another user's history ────────
final selectedSeekerIdForPortfolioProvider =
    StateProvider<String?>((ref) => null);

// ─────────────────────────────────────────────────────────────
// WorkHistoryScreen — seeker sees their own portfolio
// ─────────────────────────────────────────────────────────────

class WorkHistoryScreen extends ConsumerWidget {
  const WorkHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentFirebaseUserProvider)?.uid ?? '';
    return _WorkHistoryBody(seekerId: uid, isOwner: true);
  }
}

// ─────────────────────────────────────────────────────────────
// SeekerPortfolioScreen — employer views a seeker's portfolio
// ─────────────────────────────────────────────────────────────

class SeekerPortfolioScreen extends ConsumerWidget {
  const SeekerPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seekerId =
        ref.watch(selectedSeekerIdForPortfolioProvider) ?? '';
    return _WorkHistoryBody(seekerId: seekerId, isOwner: false);
  }
}

// ─────────────────────────────────────────────────────────────
// Shared body
// ─────────────────────────────────────────────────────────────

class _WorkHistoryBody extends ConsumerWidget {
  final String seekerId;
  final bool   isOwner;
  const _WorkHistoryBody({required this.seekerId, required this.isOwner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workHistoryProvider(seekerId));

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(isOwner ? 'My Work Portfolio' : 'Work Portfolio'),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.coral)),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.work_history_outlined,
                        size: 64, color: AppColors.mute),
                    const SizedBox(height: 16),
                    Text(
                      isOwner
                          ? 'No completed jobs yet.\n'
                            'Complete your first job to build your portfolio!'
                          : 'This seeker has no completed jobs yet.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.mute, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }

          // Stats
          final totalJobs    = entries.length;
          final avgRating    = entries
              .where((e) => e.rating > 0)
              .fold(0.0, (s, e) => s + e.rating) /
              (entries.where((e) => e.rating > 0).length.clamp(1, 999));
          final totalEarned  = entries.fold(0.0, (s, e) => s + e.salary);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Stats strip ──────────────────────────────
              Row(
                children: [
                  _StatCard(
                      label: 'Jobs Done',
                      value: totalJobs.toString(),
                      color: AppColors.teal),
                  const SizedBox(width: 10),
                  _StatCard(
                      label: 'Avg Rating',
                      value: avgRating > 0
                          ? '${avgRating.toStringAsFixed(1)} ★'
                          : '—',
                      color: AppColors.marigoldDark),
                  const SizedBox(width: 10),
                  _StatCard(
                      label: 'Total Earned',
                      value:
                          '₹${(totalEarned / 1000).toStringAsFixed(1)}k',
                      color: AppColors.ink),
                ],
              ),
              const SizedBox(height: 20),

              // ── Job entries ──────────────────────────────
              ...entries.map((e) => _HistoryCard(entry: e)),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.mute),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final WorkHistoryModel entry;
  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.jobTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(entry.companyName,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.mute)),
                  ],
                ),
              ),
              AppBadge(entry.category, type: BadgeType.ink),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.mute),
              const SizedBox(width: 4),
              Text(entry.location,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.mute)),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: AppColors.mute),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM yyyy').format(entry.completedAt),
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.mute),
              ),
            ],
          ),
          if (entry.rating > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < entry.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: AppColors.marigold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.marigoldDark),
                ),
              ],
            ),
          ],
          if (entry.review.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"${entry.review}"',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mute,
                  fontStyle: FontStyle.italic,
                  height: 1.4),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.payments_outlined,
                  size: 13, color: AppColors.teal),
              const SizedBox(width: 4),
              Text(
                '₹${entry.salary.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
