import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/application_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// All-jobs applicants view for the signed-in employer.
/// Groups applications by job title and allows Accept / Reject with
/// a confirmation dialog.
class ApplicantsScreen extends ConsumerWidget {
  const ApplicantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(employerApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Applicants')),
      body: applicationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(
          message: e.toString(),
          onRetry: () => ref.invalidate(employerApplicationsProvider),
        ),
        data: (applications) {
          if (applications.isEmpty) {
            return const _EmptyBody();
          }

          // Group by jobId → (title, list) preserving insertion order.
          final Map<String, _JobGroup> grouped = {};
          for (final app in applications) {
            grouped.putIfAbsent(
              app.jobId,
              () => _JobGroup(title: app.jobTitle),
            ).apps.add(app);
          }

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: grouped.values.map((group) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${group.apps.length} applicant${group.apps.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.mute),
                        ),
                      ],
                    ),
                  ),
                  ...group.apps.map((app) => _ApplicantCard(application: app)),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _JobGroup {
  final String title;
  final List<ApplicationModel> apps = [];
  _JobGroup({required this.title});
}

// ─────────────────────────────────────────────────────────────
// Single applicant card
// ─────────────────────────────────────────────────────────────

class _ApplicantCard extends ConsumerStatefulWidget {
  final ApplicationModel application;
  const _ApplicantCard({required this.application});

  @override
  ConsumerState<_ApplicantCard> createState() => _ApplicantCardState();
}

class _ApplicantCardState extends ConsumerState<_ApplicantCard> {
  bool _isUpdating = false;

  Future<void> _confirmAndUpdate(String newStatus) async {
    final isAccept = newStatus == ApplicationStatus.accepted;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAccept ? 'Accept Applicant?' : 'Reject Applicant?'),
        content: Text(
          isAccept
              ? 'Are you sure you want to accept ${widget.application.seekerName.isNotEmpty ? widget.application.seekerName : "this applicant"}? '
                  'They will be notified of your decision.'
              : 'Are you sure you want to reject ${widget.application.seekerName.isNotEmpty ? widget.application.seekerName : "this applicant"}? '
                  'This action can be reviewed but not undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  isAccept ? AppColors.teal : AppColors.coral,
            ),
            child: Text(isAccept ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateApplicationStatus(widget.application.id, newStatus);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAccept
            ? '${widget.application.seekerName} accepted!'
            : '${widget.application.seekerName} rejected.'),
        backgroundColor: isAccept ? AppColors.teal : AppColors.coral,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.coral,
      ));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;
    final isActionable = ApplicationStatus.isActionable(app.status);
    final isAccepted = app.status == ApplicationStatus.accepted;
    final isRejected = app.status == ApplicationStatus.rejected;

    final borderColor = isAccepted
        ? AppColors.teal
        : isRejected
            ? AppColors.coral
            : null;

    return AppCard(
      borderColor: borderColor,
      borderWidth: (isAccepted || isRejected) ? 2 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Avatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.seekerName.isNotEmpty
                          ? app.seekerName
                          : 'Anonymous Applicant',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(app.seekerEmail,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.mute)),
                    const SizedBox(height: 2),
                    Text(
                      'Applied ${DateFormat('d MMM yyyy').format(app.appliedAt)}',
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.mute),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: app.status),
            ],
          ),

          // Action buttons — only when employer can still act
          if (isActionable) ...[
            const SizedBox(height: 12),
            _isUpdating
                ? const Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(strokeWidth: 2)))
                : Row(
                    children: [
                      Expanded(
                        child: OutlineButton(
                          label: 'Reject',
                          onTap: () => _confirmAndUpdate(
                              ApplicationStatus.rejected),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Accept',
                          color: AppColors.teal,
                          onTap: () => _confirmAndUpdate(
                              ApplicationStatus.accepted),
                        ),
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Status badge helper
// ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    BadgeType type;
    switch (status) {
      case ApplicationStatus.accepted:
      case ApplicationStatus.shortlisted:
      case ApplicationStatus.completed:
        type = BadgeType.verified;
        break;
      case ApplicationStatus.rejected:
      case ApplicationStatus.cancelled:
        type = BadgeType.danger;
        break;
      case ApplicationStatus.applied:
      case ApplicationStatus.underReview:
        type = BadgeType.warn;
        break;
      default:
        type = BadgeType.ink;
    }
    return AppBadge(ApplicationStatus.label(status), type: type);
  }
}

// ─────────────────────────────────────────────────────────────
// Empty / Error bodies
// ─────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.mute),
            SizedBox(height: 16),
            Text(
              'No applications yet.\n'
              'Share your job postings to attract candidates!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mute, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.coral),
            const SizedBox(height: 12),
            Text('Failed to load applicants.\n$message',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.mute)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
