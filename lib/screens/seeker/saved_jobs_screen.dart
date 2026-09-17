import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

// ── Providers ─────────────────────────────────────────────────

/// Stream of bookmarked job IDs for the current user.
final bookmarkedIdsProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(authServiceProvider).currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).watchBookmarkedJobIds(uid);
});

/// Stream of full bookmarked JobModel objects.
final savedJobsProvider = StreamProvider<List<JobModel>>((ref) {
  final uid = ref.watch(authServiceProvider).currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).watchBookmarkedJobs(uid);
});

// ─────────────────────────────────────────────────────────────
// SavedJobsScreen
// ─────────────────────────────────────────────────────────────

class SavedJobsScreen extends ConsumerWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(savedJobsProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Saved Jobs')),
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.coral)),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_border,
                        size: 64, color: AppColors.mute),
                    SizedBox(height: 16),
                    Text(
                      'No saved jobs yet.\nTap the bookmark icon on any job to save it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mute, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: jobs.length,
            itemBuilder: (context, i) =>
                _SavedJobCard(job: jobs[i]),
          );
        },
      ),
    );
  }
}

class _SavedJobCard extends ConsumerWidget {
  final JobModel job;
  const _SavedJobCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authServiceProvider).currentUser?.uid ?? '';

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
                    Text(job.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text('${job.companyName} · ${job.location}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.mute)),
                  ],
                ),
              ),
              // Remove bookmark button
              IconButton(
                tooltip: 'Remove bookmark',
                icon: const Icon(Icons.bookmark,
                    color: AppColors.marigoldDark),
                onPressed: () async {
                  await ref
                      .read(firestoreServiceProvider)
                      .removeBookmark(uid, job.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Job removed from saved.'),
                        backgroundColor: AppColors.mute,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹${job.salary.toStringAsFixed(0)}/mo',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.teal)),
              AppBadge(job.category, type: BadgeType.ink),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(selectedJobProvider.notifier).state = job;
                Navigator.pushNamed(context, '/jobDetails');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View & Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
