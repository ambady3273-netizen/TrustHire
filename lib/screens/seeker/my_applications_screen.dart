import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/application_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/job_provider.dart';
import '../../screens/shared/rating_screen.dart'
    show selectedApplicationForRatingProvider;
import '../../theme.dart';
import '../../widgets.dart';

/// Shows all applications submitted by the signed-in seeker.
/// Real-time Firestore stream — status updates appear automatically.
class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(myApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: applicationsAsync.when(
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
                Text(
                  'Failed to load applications.\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mute),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(myApplicationsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (apps) {
          if (apps.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 64, color: AppColors.mute),
                    SizedBox(height: 16),
                    Text(
                      "You haven't applied to any jobs yet.\n"
                          'Browse the job feed to get started!',
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
            itemCount: apps.length,
            itemBuilder: (context, i) =>
                _ApplicationCard(application: apps[i]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _ApplicationCard extends ConsumerStatefulWidget {
  final ApplicationModel application;
  const _ApplicationCard({required this.application});

  @override
  ConsumerState<_ApplicationCard> createState() =>
      _ApplicationCardState();
}

class _ApplicationCardState extends ConsumerState<_ApplicationCard> {
  bool _isWithdrawing = false;

  Future<void> _withdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw Application?'),
        content: Text(
          'Are you sure you want to withdraw your application for '
          '"${widget.application.jobTitle}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isWithdrawing = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .withdrawApplication(widget.application.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application withdrawn.'),
          backgroundColor: AppColors.mute,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.coral,
      ));
    } finally {
      if (mounted) setState(() => _isWithdrawing = false);
    }
  }

  Future<void> _openChat() async {
    final fs = ref.read(firestoreServiceProvider);
    final chat =
        await fs.getChatForApplication(widget.application.id);
    if (!mounted) return;
    if (chat != null) {
      ref.read(selectedChatProvider.notifier).state = chat;
      Navigator.pushNamed(context, '/chatScreen');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat not available yet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;

    final Color statusColor;
    final BadgeType badgeType;

    switch (app.status) {
      case ApplicationStatus.accepted:
      case ApplicationStatus.shortlisted:
      case ApplicationStatus.completed:
        statusColor = AppColors.teal;
        badgeType = BadgeType.verified;
        break;
      case ApplicationStatus.rejected:
      case ApplicationStatus.cancelled:
        statusColor = AppColors.coral;
        badgeType = BadgeType.danger;
        break;
      case ApplicationStatus.withdrawn:
        statusColor = AppColors.mute;
        badgeType = BadgeType.ink;
        break;
      default:
        statusColor = AppColors.marigoldDark;
        badgeType = BadgeType.warn;
    }

    final canWithdraw = ApplicationStatus.isWithdrawable(app.status);
    final isAcceptedOrDone = app.status == ApplicationStatus.accepted ||
        app.status == ApplicationStatus.completed;

    return AppCard(
      borderColor: statusColor.withAlpha(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + badge ─────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  app.jobTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppBadge(
                ApplicationStatus.label(app.status),
                type: badgeType,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Company ───────────────────────────────────
          Text(
            app.companyName,
            style: const TextStyle(
                fontSize: 11.5, color: AppColors.mute),
          ),
          const SizedBox(height: 6),

          // ── Dates ─────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.schedule,
                  size: 12, color: AppColors.mute),
              const SizedBox(width: 4),
              Text(
                'Applied ${DateFormat('d MMM yyyy').format(app.appliedAt)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.mute),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.update,
                  size: 12, color: AppColors.mute),
              const SizedBox(width: 4),
              Text(
                'Updated ${DateFormat('d MMM yyyy').format(app.updatedAt)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.mute),
              ),
            ],
          ),

          // ── Chat + Rate (accepted / completed) ────────
          if (isAcceptedOrDone) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(
                        Icons.chat_bubble_outline,
                        size: 15),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(
                          color: AppColors.teal),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(
                              selectedApplicationForRatingProvider
                                  .notifier)
                          .state = app;
                      Navigator.pushNamed(context, '/rateScreen');
                    },
                    icon: const Icon(
                        Icons.star_outline_rounded,
                        size: 15),
                    label: const Text('Rate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.marigoldDark,
                      side: const BorderSide(
                          color: AppColors.marigoldDark),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Withdraw (still actionable) ───────────────
          if (canWithdraw) ...[
            const SizedBox(height: 10),
            _isWithdrawing
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2),
                    ),
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _withdraw,
                      icon: const Icon(
                          Icons.cancel_outlined,
                          size: 16,
                          color: AppColors.coral),
                      label: const Text(
                        'Withdraw',
                        style: TextStyle(
                            color: AppColors.coral,
                            fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}
