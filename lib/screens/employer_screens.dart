import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/routes/app_routes.dart';
import '../models/application_model.dart';
import '../providers/applications_provider.dart';
import '../providers/jobs_provider.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets.dart';

<<<<<<< HEAD
/// Mock/demo PostJobScreen used in the prototype navigation flow.
/// The real Firebase-connected PostJobScreen lives at
/// screens/employer/post_job_screen.dart.
class MockPostJobScreen extends StatelessWidget {
  const MockPostJobScreen({super.key});
=======
// ═══════════════════════════════════════════════════════════════
// APPLICANTS SCREEN  — live Firestore stream per selected job
// ═══════════════════════════════════════════════════════════════

class ApplicantsScreen extends ConsumerWidget {
  const ApplicantsScreen({super.key});

>>>>>>> origin/user1
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(selectedJobProvider);
    final appsAsync = ref.watch(jobApplicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(job != null ? 'Applicants — ${job.title}' : 'Applicants'),
        actions: const [Icon(Icons.more_horiz), SizedBox(width: 12)],
      ),
      body: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading applicants\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mute)),
        ),
        data: (apps) {
          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 52, color: AppColors.border),
                  const SizedBox(height: 14),
                  const Text('No applications yet.',
                      style: TextStyle(color: AppColors.mute)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: apps.length,
            itemBuilder: (context, i) =>
                _ApplicantTile(app: apps[i]),
          );
        },
      ),
    );
  }
}

class _ApplicantTile extends ConsumerWidget {
  final ApplicationModel app;
  const _ApplicantTile({required this.app});

  Color get _statusColor {
    switch (app.status) {
      case ApplicationStatus.shortlisted:
        return AppColors.marigoldDark;
      case ApplicationStatus.hired:
        return AppColors.teal;
      case ApplicationStatus.rejected:
        return AppColors.coral;
      case ApplicationStatus.pending:
        return AppColors.mute;
    }
  }

  String get _statusLabel {
    switch (app.status) {
      case ApplicationStatus.shortlisted:
        return 'Shortlisted';
      case ApplicationStatus.hired:
        return 'Hired';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.pending:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(applicationsNotifierProvider.notifier);
    return AppCard(
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
                    Text(app.seekerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(app.seekerEmail,
                        style: const TextStyle(
                            fontSize: 10.5, color: AppColors.mute)),
                    const SizedBox(height: 2),
                    Text(
                      'Applied ${DateFormat('d MMM yyyy').format(app.appliedAt)}',
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.mute),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _statusColor)),
              ),
            ],
          ),
          if (app.coverNote != null && app.coverNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(app.coverNote!,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.mute, height: 1.4)),
          ],
          if (app.status == ApplicationStatus.pending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlineButton(
                    label: 'Reject',
                    onTap: () => notifier.updateStatus(
                        app.id, ApplicationStatus.rejected),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryButton(
                    label: 'Shortlist',
                    color: AppColors.marigold,
                    textColor: AppColors.inkDark,
                    onTap: () => notifier.updateStatus(
                        app.id, ApplicationStatus.shortlisted),
                  ),
                ),
              ],
            ),
          ],
          if (app.status == ApplicationStatus.shortlisted) ...[
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Hire & Fund Escrow',
              color: AppColors.teal,
              onTap: () async {
                await notifier.updateStatus(
                    app.id, ApplicationStatus.hired);
                if (context.mounted) {
                  Navigator.pushNamed(context, AppRoutes.escrow);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ESCROW SCREEN
// ═══════════════════════════════════════════════════════════════

class EscrowScreen extends ConsumerWidget {
  const EscrowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(selectedJobProvider);
    final salary = job?.salary ?? 0;
    final fmt = NumberFormat('#,##0', 'en_IN');

    return Scaffold(
      appBar: AppBar(title: const Text('Secure payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.lock, size: 26, color: AppColors.ink),
                const SizedBox(height: 6),
                const Text('Amount to escrow',
                    style: TextStyle(fontSize: 11, color: AppColors.mute)),
                Text('₹${fmt.format(salary.toInt())}',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(job?.title ?? '',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.mute)),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LabelSmall('How escrow works'),
                Text(
                  '1. Funds leave your wallet now, held by TrustHire\n'
                  '2. Worker sees the job as escrow-funded\n'
                  '3. Released to them only after you confirm completion',
                  style: TextStyle(fontSize: 11.5, height: 1.6),
                ),
              ],
            ),
          ),
          const LabelSmall('Pay via'),
          const FieldBox('Razorpay · UPI / Card / Netbanking',
              icon: Icons.credit_card),
          const SizedBox(height: 60),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: PrimaryButton(
          label: 'Deposit ₹${fmt.format(salary.toInt())} into escrow',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.confirmRelease),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONFIRM RELEASE SCREEN
// ═══════════════════════════════════════════════════════════════

class ConfirmReleaseScreen extends ConsumerWidget {
  const ConfirmReleaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(selectedJobProvider);
    final appsAsync = ref.watch(jobApplicationsProvider);

    // Find hired applicant if available
    final hiredApp = appsAsync.whenOrNull(
      data: (apps) => apps
          .where((a) => a.status == ApplicationStatus.hired)
          .firstOrNull,
    );

    return Scaffold(
      appBar: AppBar(
          title: Text(job?.title ?? 'Confirm Release')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EscrowLockBar(
              amountLabel:
                  '₹${NumberFormat('#,##0', 'en_IN').format((job?.salary ?? 0).toInt())}'),
          const SizedBox(height: 6),
          if (hiredApp != null)
            AppCard(
              child: Row(
                children: [
                  const Avatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hiredApp.seekerName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5)),
                        const SizedBox(height: 2),
                        const Text("Marked this shift as done",
                            style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.mute)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LabelSmall('Before you release'),
                Text(
                  '☑ Work was completed as described\n'
                  '☑ Hours match what was agreed\n'
                  '☑ No safety or conduct issues',
                  style: TextStyle(fontSize: 11.5, height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
                'Not satisfied? You can raise a dispute instead.',
                style: TextStyle(
                    fontSize: 10.5, color: AppColors.mute)),
          ),
          const SizedBox(height: 70),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Row(
          children: [
            Expanded(
                child:
                    OutlineButton(label: 'Raise dispute', onTap: () {})),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: 'Release payment',
                color: AppColors.teal,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.rate);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// UI-ONLY PREVIEW (root demo menu only — not used in real flow)
// ═══════════════════════════════════════════════════════════════

class PostJobPreviewScreen extends StatelessWidget {
  const PostJobPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New job post (preview)')),
      body: const Center(
          child: Text('Use the real Post Job flow.',
              style: TextStyle(color: AppColors.mute))),
    );
  }
}
