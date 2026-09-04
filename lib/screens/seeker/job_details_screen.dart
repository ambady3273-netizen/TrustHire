import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/application_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

/// Full job details screen.
/// Reads the selected job from [selectedJobProvider].
/// Only job seekers see the Apply button â€” employers and admins do not.
class JobDetailsScreen extends ConsumerStatefulWidget {
  const JobDetailsScreen({super.key});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  bool _isApplying = false;
  ApplicationModel? _existingApplication;
  bool _checkingApplication = true;

  @override
  void initState() {
    super.initState();
    _checkExistingApplication();
  }

  Future<void> _checkExistingApplication() async {
    final job = ref.read(selectedJobProvider);
    final uid = ref.read(currentFirebaseUserProvider)?.uid;
    if (job == null || uid == null) {
      setState(() => _checkingApplication = false);
      return;
    }
    final firestore = ref.read(firestoreServiceProvider);
    final existing = await firestore.getExistingApplication(
      jobId: job.id,
      seekerId: uid,
    );
    if (mounted) {
      setState(() {
        _existingApplication = existing;
        _checkingApplication = false;
      });
    }
  }

  Future<void> _apply() async {
    final job = ref.read(selectedJobProvider);
    final firebaseUser = ref.read(currentFirebaseUserProvider);
    final userModel = ref.read(userProvider).valueOrNull;

    if (job == null || firebaseUser == null) return;

    setState(() => _isApplying = true);

    try {
      final now = DateTime.now();
      final firestore = ref.read(firestoreServiceProvider);
      final application = ApplicationModel(
        id: '',
        jobId: job.id,
        jobTitle: job.title,
        companyName: job.companyName,
        employerId: job.employerId,
        seekerId: firebaseUser.uid,
        seekerName: userModel?.fullName ?? firebaseUser.displayName ?? '',
        seekerEmail: firebaseUser.email ?? '',
        status: ApplicationStatus.applied,
        appliedAt: now,
        updatedAt: now,
      );

      await firestore.applyForJob(application);
      // Notify the seeker and employer simultaneously (fire-and-forget).
      final ns = NotificationService.instance;
      unawaited(ns.applicationSubmitted(
        seekerId: application.seekerId,
        jobTitle: application.jobTitle,
        companyName: application.companyName,
        jobId: application.jobId,
      ));
      unawaited(ns.newApplicant(
        employerId: application.employerId,
        seekerName: application.seekerName.isNotEmpty
            ? application.seekerName
            : 'A seeker',
        jobTitle: application.jobTitle,
        jobId: application.jobId,
      ));

      if (!mounted) return;
      await _checkExistingApplication();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: AppColors.teal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.coral,
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(selectedJobProvider);
    final userModel = ref.watch(userProvider).valueOrNull;
    final isSeeker = userModel?.role == 'job_seeker';

    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(child: Text('Job not found.')),
      );
    }

    final isVerified = job.riskScore < 31;
    final trustPercent = (100 - job.riskScore).clamp(0, 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: const [Icon(Icons.flag_outlined), SizedBox(width: 16)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          AppBadge(
            isVerified ? 'âœ“ Passed AI fraud check' : 'âš  Under admin review',
            type: isVerified ? BadgeType.verified : BadgeType.warn,
          ),
          const SizedBox(height: 10),
          Text(
            job.title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            '${job.companyName} Â· ${job.location}',
            style: const TextStyle(fontSize: 12, color: AppColors.mute),
          ),
          const SizedBox(height: 16),

          // Employer card
          AppCard(
            child: Row(
              children: [
                const Avatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.companyName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        'Posted ${DateFormat('d MMM yyyy').format(job.createdAt)}',
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.mute),
                      ),
                    ],
                  ),
                ),
                TrustRing(percent: trustPercent, size: 34),
              ],
            ),
          ),

          // Details card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LabelSmall('Job Details'),
                _kv('Category', job.category),
                _kv('Salary', 'â‚¹${job.salary.toStringAsFixed(0)}'),
                _kv('Location', job.location),
                _kv('Contact', job.contact),
                _kv('Payment protection', 'ðŸ”’ Escrow protected',
                    valueColor: AppColors.teal),
              ],
            ),
          ),

          // Description card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LabelSmall('Description'),
                Text(job.description,
                    style: const TextStyle(fontSize: 13, height: 1.6)),
              ],
            ),
          ),

          // Risk notes (only when not fully safe)
          if (!isVerified && job.scamReasons.isNotEmpty)
            AppCard(
              borderColor: AppColors.marigold,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.marigoldDark, size: 16),
                    SizedBox(width: 6),
                    Text('AI Safety Notes',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.marigoldDark)),
                  ]),
                  const SizedBox(height: 8),
                  ...job.scamReasons.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('â€¢ $r',
                            style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.mute,
                                height: 1.5)),
                      )),
                ],
              ),
            ),

          // Non-seeker info banner
          if (!isSeeker && userModel != null)
            AppCard(
              bg: AppColors.tealLight,
              borderColor: Colors.transparent,
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.teal, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      userModel.role == 'employer'
                          ? 'You are viewing as an employer. Switch to a job seeker account to apply.'
                          : 'Admin view â€” applications are read-only.',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.teal,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),

      // Apply button â€” only for job seekers
      bottomSheet: isSeeker ? _buildApplyButton() : const SizedBox.shrink(),
    );
  }

  Widget _buildApplyButton() {
    if (_checkingApplication) {
      return Container(
        color: AppColors.paper,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: const SizedBox(
            height: 52, child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_existingApplication != null) {
      final status = _existingApplication!.status;
      final Color statusColor;
      final String statusLabel;

      switch (status) {
        case ApplicationStatus.accepted:
          statusColor = AppColors.teal;
          statusLabel = 'âœ“ Application Accepted';
          break;
        case ApplicationStatus.rejected:
          statusColor = AppColors.coral;
          statusLabel = 'âœ— Application Rejected';
          break;
        case ApplicationStatus.withdrawn:
          statusColor = AppColors.mute;
          statusLabel = 'Application Withdrawn';
          break;
        case ApplicationStatus.shortlisted:
          statusColor = AppColors.ink;
          statusLabel = 'â˜… Shortlisted';
          break;
        case ApplicationStatus.underReview:
          statusColor = AppColors.marigoldDark;
          statusLabel = 'ðŸ” Under Review';
          break;
        default:
          statusColor = AppColors.marigoldDark;
          statusLabel = 'â³ Applied â€” Pending Review';
      }

      return Container(
        color: AppColors.paper,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor),
          ),
          child: Center(
            child: Text(statusLabel,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.paper,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isApplying ? null : _apply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.marigold,
            foregroundColor: AppColors.inkDark,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _isApplying
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.inkDark))
              : const Text('Apply Now',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _kv(String k, String v, {Color valueColor = AppColors.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k,
              style: const TextStyle(fontSize: 12, color: AppColors.mute)),
          Flexible(
            child: Text(v,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: valueColor),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

