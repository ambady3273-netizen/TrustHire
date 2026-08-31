import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/notification_model.dart';
import '../providers/notifications_provider.dart';
import '../theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notifAsync.whenOrNull(
                data: (list) => list.isNotEmpty
                    ? TextButton(
                        onPressed: () async {
                          final confirm = await _confirmClear(context);
                          if (confirm == true) await notifier.clearAll();
                        },
                        child: const Text(
                          'Clear all',
                          style: TextStyle(
                            color: AppColors.coral,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
          // Mark all read
          notifAsync.whenOrNull(
                data: (list) {
                  final hasUnread = list.any((n) => !n.isRead);
                  return hasUnread
                      ? IconButton(
                          tooltip: 'Mark all as read',
                          icon: const Icon(Icons.done_all_rounded),
                          onPressed: notifier.markAllRead,
                        )
                      : null;
                },
              ) ??
              const SizedBox.shrink(),
          const SizedBox(width: 4),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Could not load notifications.\n$e',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mute),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
            itemBuilder: (context, i) {
              final n = notifications[i];
              return _NotificationTile(
                notification: n,
                onTap: () => _handleTap(context, ref, n),
                onDismiss: () => notifier.deleteOne(n.id),
              );
            },
          );
        },
      ),
    );
  }

  // Tap: mark read then optionally navigate to the linked screen.
  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel n,
  ) async {
    if (!n.isRead) {
      await ref.read(notificationsNotifierProvider.notifier).markRead(n.id);
    }
    if (n.actionRoute != null && context.mounted) {
      Navigator.pushNamed(context, n.actionRoute!);
    }
  }

  Future<bool?> _confirmClear(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Individual tile
// ──────────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final unread = !n.isRead;

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: AppColors.coral,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: unread
              ? AppColors.tealLight.withValues(alpha: 0.45)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconBg(n.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _icon(n.type),
                  size: 18,
                  color: _iconFg(n.type),
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _relativeTime(n.createdAt),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.mute,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.body,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mute,
                        height: 1.4,
                      ),
                    ),
                    // Deep-link label
                    if (n.actionRoute != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Tap to view →',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Unread dot
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────

  IconData _icon(NotificationType t) {
    switch (t) {
      case NotificationType.jobApproved:
        return Icons.verified_rounded;
      case NotificationType.jobRejected:
        return Icons.gpp_bad_rounded;
      case NotificationType.newApplicant:
        return Icons.person_add_rounded;
      case NotificationType.applicationSent:
        return Icons.send_rounded;
      case NotificationType.shortlisted:
        return Icons.star_rounded;
      case NotificationType.escrowFunded:
        return Icons.lock_rounded;
      case NotificationType.paymentReleased:
        return Icons.payments_rounded;
      case NotificationType.reviewReceived:
        return Icons.rate_review_rounded;
      case NotificationType.kycApproved:
        return Icons.badge_rounded;
      case NotificationType.kycRejected:
        return Icons.cancel_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color _iconBg(NotificationType t) {
    switch (t) {
      case NotificationType.jobApproved:
      case NotificationType.escrowFunded:
      case NotificationType.paymentReleased:
      case NotificationType.kycApproved:
        return AppColors.tealLight;
      case NotificationType.jobRejected:
      case NotificationType.kycRejected:
        return AppColors.coralLight;
      case NotificationType.shortlisted:
      case NotificationType.reviewReceived:
        return AppColors.warnBg;
      default:
        return AppColors.paper;
    }
  }

  Color _iconFg(NotificationType t) {
    switch (t) {
      case NotificationType.jobApproved:
      case NotificationType.escrowFunded:
      case NotificationType.paymentReleased:
      case NotificationType.kycApproved:
        return AppColors.teal;
      case NotificationType.jobRejected:
      case NotificationType.kycRejected:
        return AppColors.coral;
      case NotificationType.shortlisted:
      case NotificationType.reviewReceived:
        return AppColors.marigoldDark;
      default:
        return AppColors.mute;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(dt);
  }
}

// ──────────────────────────────────────────────────────────────
// Empty state
// ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 34,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "You're all caught up",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'New activity will appear here.',
            style: TextStyle(fontSize: 12.5, color: AppColors.mute),
          ),
        ],
      ),
    );
  }
}
