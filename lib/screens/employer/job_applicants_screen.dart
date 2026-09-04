import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/application_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../screens/employer/employer_jobs_screen.dart'
    show selectedEmployerJobProvider;
import '../../services/notification_service.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Per-job applicants screen.
/// Shows all applications for the job stored in [selectedEmployerJobProvider].
/// Employer can accept or reject each application with a confirmation dialog.
class JobApplicantsScreen extends ConsumerWidget {
  const JobApplicantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(selectedEmployerJobProvider);

    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Applicants')),
        body: const Center(child: Text('No job selected.')),
      );
    }

    final appsAsync = ref.watch(jobApplicationsProvider(job.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Applicants',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(job.title,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.mute)),
          ],
        ),
      ),
      body: appsAsync.when(
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
                Text('Failed to load applicants.\n$e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mute)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(jobApplicationsProvider(job.id)),
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
        data: (applications) {
          if (applications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 64, color: AppColors.mute),
                    SizedBox(height: 16),
                    Text(
                      'No applications yet for this job.\n'
                      'Share your listing to attract candidates!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mute, height: 1.5),
                    ),
                  ],
                ),
              ),
            );
          }

          // Summary strip
          final pending = applications
              .where((a) => ApplicationStatus.isActionable(a.status))
              .length;
          final accepted = applications
              .where((a) => a.status == ApplicationStatus.accepted)
              .length;

          return Column(
            children: [
              // Stats strip
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    _Strip(
                        label: 'Total',
                        value: applications.length.toString(),
                        color: AppColors.ink),
                    const SizedBox(width: 20),
                    _Strip(
                        label: 'Pending',
                        value: pending.toString(),
                        color: AppColors.marigoldDark),
                    const SizedBox(width: 20),
                    _Strip(
                        label: 'Accepted',
                        value: accepted.toString(),
                        color: AppColors.teal),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.only(top: 8, bottom: 32),
                  itemCount: applications.length,
                  itemBuilder: (context, i) =>
                      _ApplicantCard(application: applications[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Strip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.mute)),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Single applicant card with confirm-then-update logic
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    final name = widget.application.seekerName.isNotEmpty
        ? widget.application.seekerName
        : 'this applicant';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAccept ? 'Accept Applicant?' : 'Reject Applicant?'),
        content: Text(
          isAccept
              ? 'Accept $name for this role? They will see their updated status.'
              : 'Reject $name? This action updates their application status.',
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
                    isAccept ? AppColors.teal : AppColors.coral),
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
      // Fire notification to the seeker.
      final ns = NotificationService.instance;
      final app = widget.application;
      if (isAccept) {
        unawaited(ns.applicationAccepted(
          seekerId: app.seekerId,
          jobTitle: app.jobTitle,
          companyName: app.companyName,
          applicationId: app.id,
        ));
      } else {
        unawaited(ns.applicationRejected(
          seekerId: app.seekerId,
          jobTitle: app.jobTitle,
          companyName: app.companyName,
          applicationId: app.id,
        ));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAccept
            ? '$name has been accepted!'
            : '$name has been rejected.'),
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

    return AppCard(
      borderColor: isAccepted
          ? AppColors.teal
          : isRejected
              ? AppColors.coral
              : null,
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
              _StatusChip(status: app.status),
            ],
          ),
          if (isActionable) ...[
            const SizedBox(height: 12),
            _isUpdating
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

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

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
      default:
        type = BadgeType.warn;
    }
    return AppBadge(ApplicationStatus.label(status), type: type);
  }
}

