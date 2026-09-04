import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/application_model.dart';
import '../models/job_model.dart';
import '../models/review_model.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../providers/notifications_provider.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// JOB FEED
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class JobFeedScreen extends ConsumerWidget {
  const JobFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount =
        ref.watch(unreadNotificationCountProvider).whenOrNull(data: (n) => n) ?? 0;
    final jobsAsync = ref.watch(approvedJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, size: 18),
            SizedBox(width: 6),
            Text('TrustHire'),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () =>
                    Navigator.pushNamed(context, '/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          const TrustRing(percent: 62, size: 30),
          const SizedBox(width: 16),
        ],
      ),
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading jobs\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mute)),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_off_outlined,
                      size: 52, color: AppColors.border),
                  const SizedBox(height: 14),
                  const Text('No approved jobs yet.',
                      style: TextStyle(color: AppColors.mute)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: jobs.length,
            itemBuilder: (context, i) => _JobCard(job: jobs[i]),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Jobs'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'My Applications'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onDestinationSelected: (i) {
          if (i == 1) {
            Navigator.pushNamed(context, '/myApplications');
          }
        },
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  final JobModel job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSafe = job.status == 'approved' && job.riskScore <= 30;
    return InkWell(
      onTap: () {
        ref.read(selectedJobProvider.notifier).state = job;
        Navigator.pushNamed(context, '/jobDetails');
      },
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppBadge(
                  isSafe ? 'âœ“ AI-verified' : 'âš  Under review',
                  type: isSafe ? BadgeType.verified : BadgeType.warn,
                ),
                Text(job.category,
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.mute)),
              ],
            ),
            const SizedBox(height: 8),
            Text(job.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 2),
            Text('${job.companyName} Â· ${job.location}',
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.mute)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('â‚¹${NumberFormat('#,##0', 'en_IN').format(job.salary.toInt())} / mo',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.ink)),
                Row(
                  children: [
                    TrustRing(
                        percent: job.riskScore > 0
                            ? (100 - job.riskScore).clamp(0, 100)
                            : 80,
                        size: 28),
                    const SizedBox(width: 5),
                    const Text('Safety',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.mute)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// JOB DETAILS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class JobDetailsScreen extends ConsumerStatefulWidget {
  const JobDetailsScreen({super.key});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  bool _applying = false;

  Future<void> _apply(JobModel job) async {
    setState(() => _applying = true);

    final firebaseUser = ref.read(currentFirebaseUserProvider);
    final userModel = ref.read(userProvider).valueOrNull;

    if (firebaseUser == null) {
      setState(() => _applying = false);
      return;
    }

    try {
      final now = DateTime.now();
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

      await FirestoreService.instance.applyForJob(application);

      setState(() => _applying = false);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Application Sent!'),
          content: Text(
              'You have applied for "${job.title}". '
              'The employer will review your profile.'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _applying = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.coral),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(selectedJobProvider);

    if (job == null) {
      return const Scaffold(
        body: Center(child: Text('Job not found.')),
      );
    }

    final isSafe = job.riskScore <= 30;
    final safetyScore = (100 - job.riskScore).clamp(0, 100);

    return Scaffold(
      appBar: AppBar(
        title: Text(job.title, overflow: TextOverflow.ellipsis),
        actions: const [Icon(Icons.flag_outlined), SizedBox(width: 16)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        children: [
          AppBadge(
            isSafe ? 'âœ“ Passed AI fraud check' : 'âš  Under review',
            type: isSafe ? BadgeType.verified : BadgeType.warn,
          ),
          const SizedBox(height: 10),
          Text(job.title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('${job.companyName} Â· ${job.location}',
              style: const TextStyle(fontSize: 12, color: AppColors.mute)),
          const SizedBox(height: 14),
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
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5)),
                      const SizedBox(height: 2),
                      Text('Category: ${job.category}',
                          style: const TextStyle(
                              fontSize: 10.5, color: AppColors.mute)),
                    ],
                  ),
                ),
                TrustRing(percent: safetyScore, size: 30),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LabelSmall('Pay & details'),
                _kv('Salary',
                    'â‚¹${NumberFormat('#,##0', 'en_IN').format(job.salary.toInt())}'),
                _kv('Location', job.location),
                _kv('Category', job.category),
                _kv('Contact', job.contact),
                _kv('Payment', 'ðŸ”’ Escrow protected',
                    valueColor: AppColors.teal),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LabelSmall('Description'),
                Text(job.description,
                    style: const TextStyle(fontSize: 12, height: 1.5)),
              ],
            ),
          ),
          if (job.scamReasons.isNotEmpty && !isSafe)
            AppCard(
              borderColor: AppColors.coral,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LabelSmall('Review notes'),
                  ...job.scamReasons.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              size: 13, color: AppColors.coral),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(r,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.mute))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 90),
        ],
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: PrimaryButton(
          label: _applying ? 'Applyingâ€¦' : 'Apply now',
          color: AppColors.marigold,
          textColor: AppColors.inkDark,
          onTap: _applying ? null : () => _apply(job),
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
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: valueColor)),
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// CHAT
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(selectedJobProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Avatar(size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(job?.companyName ?? 'Employer',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const Text('âœ“ Verified employer',
                      style: TextStyle(
                          fontSize: 10.5, color: AppColors.teal)),
                ],
              ),
            ),
          ],
        ),
        actions: const [Icon(Icons.call_outlined), SizedBox(width: 16)],
      ),
      body: Column(
        children: [
          EscrowLockBar(
              amountLabel:
                  job != null ? 'â‚¹${job.salary.toStringAsFixed(0)}' : 'â€”'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _bubble(
                    "Hi! You're selected for the role. "
                    "Can you start this Saturday, 10am?",
                    mine: false),
                _bubble('Yes, that works for me!', mine: true),
                const SizedBox(height: 10),
                const Center(
                    child: AppBadge('Payment locked in escrow âœ“',
                        type: BadgeType.verified)),
                const SizedBox(height: 10),
                _bubble('Great, see you Saturday!', mine: false),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              children: [
                const Expanded(child: FieldBox('Messageâ€¦')),
                const SizedBox(width: 8),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/rate'),
              child: const Text('Mark job complete â†’'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String text, {required bool mine}) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(mine ? 12 : 2),
            bottomRight: Radius.circular(mine ? 2 : 12),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12.5,
                color: mine ? Colors.white : AppColors.text)),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// RATE SCREEN â€” saves review + updates trust score
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class RateScreen extends ConsumerStatefulWidget {
  const RateScreen({super.key});

  @override
  ConsumerState<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends ConsumerState<RateScreen> {
  int _rating = 5;
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final job = ref.read(selectedJobProvider);
    final uid = ref.read(authProvider).whenOrNull(data: (u) => u?.uid);

    if (job != null && uid != null) {
      final review = ReviewModel(
        reviewId: '',
        jobId: job.id,
        applicationId: '',
        reviewerId: uid,
        reviewedUserId: job.employerId,
        reviewerRole: 'job_seeker',
        rating: _rating,
        comment: _noteController.text.trim(),
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      try {
        await FirestoreService.instance.submitReview(review);
      } catch (_) {}
    }

    setState(() => _submitting = false);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, '/seekerDashboard', (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(selectedJobProvider);
    final salary = job?.salary.toStringAsFixed(0) ?? '0';

    return Scaffold(
      appBar: AppBar(title: const Text('Job complete')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('ðŸŽ‰', style: TextStyle(fontSize: 34)),
            const SizedBox(height: 6),
            const Text('Job completed',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            const SizedBox(height: 4),
            Text('â‚¹$salary has been released to your wallet',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.mute)),
            const SizedBox(height: 18),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Escrow released',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.mute)),
                  Text('â‚¹$salary',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Rate ${job?.companyName ?? 'the employer'}',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.marigold,
                    size: 34,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a note for other job seekers (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: _submitting ? 'Submittingâ€¦' : 'Submit review',
              onTap: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
