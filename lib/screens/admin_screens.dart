import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/routes/app_routes.dart';
import '../models/job_model.dart';
import '../models/user_model.dart';
import '../providers/applications_provider.dart';
import '../providers/job_provider.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets.dart';

// ═══════════════════════════════════════════════════════════════
// ADMIN FRAUD SCREEN — live pending_review jobs
// ═══════════════════════════════════════════════════════════════

class AdminFraudScreen extends ConsumerWidget {
  const AdminFraudScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingJobsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin · Fraud Review')),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child:
              Text('Error: $e', style: const TextStyle(color: AppColors.mute)),
        ),
        data: (jobs) => Column(
          children: [
            // Stats bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                      child: _StatTile(
                          '${jobs.length}', 'Pending review', AppColors.coral)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _StatTile(
                          '${jobs.where((j) => j.riskScore > 60).length}',
                          'High risk',
                          AppColors.marigoldDark)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _StatTile(
                          '${jobs.where((j) => j.riskScore <= 30).length}',
                          'Low risk',
                          AppColors.teal)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: LabelSmall('Jobs needing review'),
            ),
            Expanded(
              child: jobs.isEmpty
                  ? const Center(
                      child: Text('No jobs pending review. ✓',
                          style: TextStyle(color: AppColors.mute)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      itemCount: jobs.length,
                      itemBuilder: (context, i) => _FraudJobCard(job: jobs[i]),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.warning_amber_rounded), label: 'Fraud'),
          NavigationDestination(
              icon: Icon(Icons.verified_user_outlined), label: 'Verify'),
        ],
        onDestinationSelected: (i) {
          if (i == 1) {
            Navigator.pushNamed(context, AppRoutes.adminVerification);
          }
        },
      ),
    );
  }
}

class _FraudJobCard extends StatelessWidget {
  final JobModel job;
  const _FraudJobCard({required this.job});

  Color get _riskColor {
    if (job.riskScore > 60) return AppColors.coral;
    if (job.riskScore > 30) return AppColors.marigoldDark;
    return AppColors.teal;
  }

  BadgeType get _badgeType {
    if (job.riskScore > 60) return BadgeType.danger;
    if (job.riskScore > 30) return BadgeType.warn;
    return BadgeType.verified;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: _riskColor,
      borderWidth: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(job.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
              AppBadge('${job.riskScore}% risk', type: _badgeType),
            ],
          ),
          const SizedBox(height: 4),
          Text('${job.companyName} · ${job.location}',
              style: const TextStyle(fontSize: 10.5, color: AppColors.mute)),
          if (job.scamReasons.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              job.scamReasons.take(2).join(' · '),
              style: const TextStyle(fontSize: 10.5, color: AppColors.mute),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlineButton(
                  label: 'Approve',
                  onTap: () async {
                    await FirestoreService.instance
                        .updateJobStatus(job.id, 'approved');
                    // Notify employer
                    unawaited(NotificationService.instance.jobApproved(
                      employerId: job.employerId,
                      jobTitle: job.title,
                      jobId: job.id,
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Job approved and published.')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: 'Reject',
                  color: AppColors.coral,
                  onTap: () async {
                    await FirestoreService.instance
                        .updateJobStatus(job.id, 'rejected');
                    // Notify employer
                    unawaited(NotificationService.instance.jobRejected(
                      employerId: job.employerId,
                      jobTitle: job.title,
                      jobId: job.id,
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Job rejected and removed.')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatTile(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 9, color: AppColors.mute),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ADMIN VERIFICATION SCREEN — live unverified users
// ═══════════════════════════════════════════════════════════════

class AdminVerificationScreen extends ConsumerWidget {
  const AdminVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(unverifiedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin · Verification')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child:
              Text('Error: $e', style: const TextStyle(color: AppColors.mute)),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text('No pending verifications. ✓',
                  style: TextStyle(color: AppColors.mute)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            itemBuilder: (context, i) => _VerificationCard(user: users[i]),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.warning_amber_rounded), label: 'Fraud'),
          NavigationDestination(
              icon: Icon(Icons.verified_user_outlined), label: 'Verify'),
        ],
        onDestinationSelected: (i) {
          if (i == 0) Navigator.pop(context);
        },
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final UserModel user;
  const _VerificationCard({required this.user});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL not available.')),
      );
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Doc URLs stored during KYC upload via onboarding_screens.dart KycScreen.
    final idUrl = user.governmentIdUrl;
    final selfieUrl = user.kycSelfieUrl;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(user.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
              const AppBadge('Pending', type: BadgeType.warn),
            ],
          ),
          const SizedBox(height: 4),
          Text(user.email,
              style: const TextStyle(fontSize: 10.5, color: AppColors.mute)),
          Text('Role: ${user.role}',
              style: const TextStyle(fontSize: 10.5, color: AppColors.mute)),
          // ── KYC document chips ──────────────────────────
          const SizedBox(height: 10),
          Row(
            children: [
              _DocChip(
                label: 'Gov. ID',
                icon: Icons.description_outlined,
                available: idUrl.isNotEmpty,
                onTap: idUrl.isNotEmpty ? () => _openUrl(context, idUrl) : null,
              ),
              const SizedBox(width: 8),
              _DocChip(
                label: 'Selfie',
                icon: Icons.face_retouching_natural,
                available: selfieUrl.isNotEmpty,
                onTap: selfieUrl.isNotEmpty
                    ? () => _openUrl(context, selfieUrl)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlineButton(
                  label: 'Reject',
                  onTap: () async {
                    // Write rejection to Firestore and notify user
                    await FirestoreService.instance.verifyUser(user.uid, false);
                    unawaited(NotificationService.instance.kycRejected(
                      userId: user.uid,
                      reason: 'Your identity documents could not be verified. '
                          'Please resubmit with clear, valid documents.',
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${user.fullName} verification rejected.')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: 'Verify',
                  color: AppColors.teal,
                  onTap: () async {
                    await FirestoreService.instance.verifyUser(user.uid, true);
                    // Notify user their KYC passed
                    unawaited(NotificationService.instance.kycApproved(
                      userId: user.uid,
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${user.fullName} verified successfully.')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tappable chip that shows whether a KYC document is available.
/// Tapping opens the document URL in an external browser.
class _DocChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool available;
  final VoidCallback? onTap;
  const _DocChip({
    required this.label,
    required this.icon,
    required this.available,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.teal : AppColors.mute;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: available ? AppColors.tealLight : AppColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              available ? icon : Icons.block_outlined,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              available ? 'View $label' : '$label missing',
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
