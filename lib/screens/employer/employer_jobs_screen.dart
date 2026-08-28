import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/job_model.dart';
import '../../models/application_model.dart';
import '../../providers/job_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// StateProvider that holds the job selected by the employer when
/// navigating to the per-job applicants screen.
final selectedEmployerJobProvider = StateProvider<JobModel?>((ref) => null);

/// Lists all jobs posted by the signed-in employer.
/// Tapping a job opens the per-job applicants screen.
class EmployerJobsScreen extends ConsumerWidget {
  const EmployerJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(employerJobsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Posted Jobs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/postJob'),
        icon: const Icon(Icons.add),
        label: const Text('Post Job'),
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
      ),
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.coral),
                const SizedBox(height: 12),
                Text('Failed to load jobs.\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mute)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(employerJobsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.work_off_outlined,
                        size: 64, color: AppColors.mute),
                    const SizedBox(height: 16),
                    const Text(
                      'You haven\'t posted any jobs yet.\n'
                      'Tap the button below to create your first listing.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppColors.mute, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Post a Job',
                      onTap: () =>
                          Navigator.pushNamed(context, '/postJob'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: jobs.length,
            itemBuilder: (context, i) =>
                _JobTile(job: jobs[i]),
          );
        },
      ),
    );
  }
}

class _JobTile extends ConsumerWidget {
  final JobModel job;
  const _JobTile({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stream applicant count live for this job.
    final appsAsync = ref.watch(jobApplicationsProvider(job.id));
    final appCount = appsAsync.maybeWhen(
      data: (apps) => apps.length,
      orElse: () => 0,
    );
    final pendingCount = appsAsync.maybeWhen(
      data: (apps) => apps
          .where((a) => ApplicationStatus.isActionable(a.status))
          .length,
      orElse: () => 0,
    );

    final statusColor = job.status == 'approved'
        ? AppColors.teal
        : job.status == 'pending_review'
            ? AppColors.marigoldDark
            : AppColors.coral;

    final statusLabel = job.status == 'approved'
        ? 'Live'
        : job.status == 'pending_review'
            ? 'Under Review'
            : 'Rejected';

    return InkWell(
      onTap: () {
        ref.read(selectedEmployerJobProvider.notifier).state = job;
        Navigator.pushNamed(context, '/jobApplicants');
      },
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.ink),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${job.companyName} · ${job.location}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.mute),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: AppColors.mute),
                const SizedBox(width: 4),
                Text(
                  DateFormat('d MMM yyyy').format(job.createdAt),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.mute),
                ),
                const Spacer(),
                const Icon(Icons.people_outline,
                    size: 14, color: AppColors.mute),
                const SizedBox(width: 4),
                Text(
                  '$appCount applicant${appCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.mute),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$pendingCount new',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    color: AppColors.mute, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
