import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

final _pendingJobsProvider = StreamProvider<List<JobModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getPendingJobs();
});

/// Real admin fraud-review screen — pulls pending_review jobs from Firestore.
class AdminFraudScreen extends ConsumerWidget {
  const AdminFraudScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(_pendingJobsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin · Fraud Review')),
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
                Text('Failed to load.\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mute)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(_pendingJobsProvider),
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 64, color: AppColors.teal),
                    SizedBox(height: 16),
                    Text(
                      'No jobs pending review.\nAll clear!',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppColors.mute, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: jobs.length,
            itemBuilder: (context, i) => _PendingJobCard(job: jobs[i]),
          );
        },
      ),
    );
  }
}

class _PendingJobCard extends ConsumerStatefulWidget {
  final JobModel job;
  const _PendingJobCard({required this.job});

  @override
  ConsumerState<_PendingJobCard> createState() => _PendingJobCardState();
}

class _PendingJobCardState extends ConsumerState<_PendingJobCard> {
  bool _loading = false;

  Future<void> _act(bool approve) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? 'Approve Job?' : 'Reject Job?'),
        content: Text(approve
            ? 'Approve "${widget.job.title}"? It will become visible to job seekers.'
            : 'Reject "${widget.job.title}"? The employer will see it as rejected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor:
                    approve ? AppColors.teal : AppColors.coral),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      final fs = ref.read(firestoreServiceProvider);
      if (approve) {
        await fs.approveJob(widget.job.id);
      } else {
        await fs.rejectJob(widget.job.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve ? 'Job approved!' : 'Job rejected.'),
        backgroundColor: approve ? AppColors.teal : AppColors.coral,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.coral,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final riskColor = job.riskScore > 60
        ? AppColors.coral
        : job.riskScore > 30
            ? AppColors.marigoldDark
            : AppColors.teal;

    return AppCard(
      borderColor: riskColor,
      borderWidth: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(job.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.ink)),
              ),
              AppBadge('${job.riskScore}% risk',
                  type: job.riskScore > 60
                      ? BadgeType.danger
                      : BadgeType.warn),
            ],
          ),
          const SizedBox(height: 4),
          Text('${job.companyName} · ${job.location}',
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.mute)),
          const SizedBox(height: 4),
          Text(
            'Posted ${DateFormat('d MMM yyyy').format(job.createdAt)}  ·  ₹${job.salary.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 11, color: AppColors.mute),
          ),
          if (job.scamReasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...job.scamReasons.take(3).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('• $r',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.mute)),
                )),
          ],
          const SizedBox(height: 12),
          _loading
              ? const Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : Row(
                  children: [
                    Expanded(
                        child: OutlineButton(
                            label: 'Reject',
                            onTap: () => _act(false))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: PrimaryButton(
                            label: 'Approve',
                            color: AppColors.teal,
                            onTap: () => _act(true))),
                  ],
                ),
        ],
      ),
    );
  }
}
