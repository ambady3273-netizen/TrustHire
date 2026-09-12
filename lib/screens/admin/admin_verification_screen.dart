import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme.dart';
import '../../widgets.dart';

// ── Providers ─────────────────────────────────────────────────

final _pendingKycProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getPendingKycUsers();
});

final _allUsersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllUsers();
});

// ── Screen ────────────────────────────────────────────────────

/// Admin KYC Verification screen.
/// Shows two tabs:
///   1. Pending — users who have submitted KYC documents.
///   2. All Users — full user list with role/verification status.
class AdminVerificationScreen extends ConsumerStatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  ConsumerState<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState
    extends ConsumerState<AdminVerificationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin · KYC Verification'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Pending KYC'),
            Tab(text: 'All Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _PendingKycTab(),
          _AllUsersTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: Pending KYC ────────────────────────────────────────

class _PendingKycTab extends ConsumerWidget {
  const _PendingKycTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(_pendingKycProvider);

    return usersAsync.when(
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
              Text('Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mute)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(_pendingKycProvider),
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
      data: (users) {
        if (users.isEmpty) {
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
                    'No pending KYC submissions.\nAll caught up!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mute, height: 1.5),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: users.length,
          itemBuilder: (context, i) => _KycCard(user: users[i]),
        );
      },
    );
  }
}

// ── KYC Card with Approve / Reject ────────────────────────────

class _KycCard extends ConsumerStatefulWidget {
  final UserModel user;
  const _KycCard({required this.user});

  @override
  ConsumerState<_KycCard> createState() => _KycCardState();
}

class _KycCardState extends ConsumerState<_KycCard> {
  bool _loading = false;

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve KYC?'),
        content: Text(
            'Approve KYC for ${widget.user.fullName}? '
            'This will mark their account as verified.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final adminUid = ref.read(currentFirebaseUserProvider)?.uid ?? '';
      await ref.read(firestoreServiceProvider).approveKyc(
            uid: widget.user.uid,
            adminUid: adminUid,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.user.fullName} KYC approved!'),
        backgroundColor: AppColors.teal,
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

  Future<void> _reject() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject KYC?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting KYC for ${widget.user.fullName}.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection (shown to user)…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final adminUid = ref.read(currentFirebaseUserProvider)?.uid ?? '';
      await ref.read(firestoreServiceProvider).rejectKyc(
            uid: widget.user.uid,
            adminUid: adminUid,
            reason: reasonCtrl.text.trim().isNotEmpty
                ? reasonCtrl.text.trim()
                : 'Documents could not be verified.',
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.user.fullName} KYC rejected.'),
        backgroundColor: AppColors.coral,
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
    reasonCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final submittedAt = u.kycSubmittedAt?.toDate();

    return AppCard(
      borderColor: AppColors.marigold,
      borderWidth: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Row(
            children: [
              const Avatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(u.email,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.mute)),
                    const SizedBox(height: 2),
                    Text(u.role,
                        style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.marigoldDark)),
                  ],
                ),
              ),
              const AppBadge('Pending', type: BadgeType.warn),
            ],
          ),

          if (submittedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Submitted ${DateFormat('d MMM yyyy, h:mm a').format(submittedAt)}',
              style: const TextStyle(fontSize: 10.5, color: AppColors.mute),
            ),
          ],

          // ── Document links ───────────────────────────────
          const SizedBox(height: 12),
          const Text('Submitted Documents',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 6),
          Row(
            children: [
              _DocChip(
                icon: Icons.badge_outlined,
                label: 'Govt. ID',
                hasUrl: u.governmentIdUrl.isNotEmpty,
              ),
              const SizedBox(width: 8),
              _DocChip(
                icon: Icons.face_retouching_natural,
                label: 'Selfie',
                hasUrl: u.selfieUrl.isNotEmpty,
              ),
            ],
          ),

          // ── Actions ──────────────────────────────────────
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
                            label: 'Reject', onTap: _reject)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: PrimaryButton(
                            label: 'Approve',
                            color: AppColors.teal,
                            onTap: _approve)),
                  ],
                ),
        ],
      ),
    );
  }
}

class _DocChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasUrl;

  const _DocChip({
    required this.icon,
    required this.label,
    required this.hasUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasUrl ? AppColors.tealLight : AppColors.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: hasUrl ? AppColors.teal : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: hasUrl ? AppColors.teal : AppColors.mute),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: hasUrl ? AppColors.teal : AppColors.mute),
          ),
          const SizedBox(width: 4),
          Icon(
            hasUrl ? Icons.check_circle : Icons.cancel_outlined,
            size: 12,
            color: hasUrl ? AppColors.teal : AppColors.mute,
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: All Users ──────────────────────────────────────────

class _AllUsersTab extends ConsumerWidget {
  const _AllUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(_allUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.coral))),
      data: (users) {
        if (users.isEmpty) {
          return const Center(
              child: Text('No users found.',
                  style: TextStyle(color: AppColors.mute)));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: users.length,
          itemBuilder: (context, i) => _UserRow(user: users[i]),
        );
      },
    );
  }
}

class _UserRow extends ConsumerStatefulWidget {
  final UserModel user;
  const _UserRow({required this.user});

  @override
  ConsumerState<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends ConsumerState<_UserRow> {
  bool _loading = false;

  Future<void> _toggleSuspend() async {
    final u = widget.user;
    final isSuspending = !u.suspended;
    String reason = '';

    if (isSuspending) {
      final ctrl = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Suspend User?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Suspending ${u.fullName}. They will see a suspension '
                  'message and cannot use the app until reinstated.'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Reason for suspension…',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
              child: const Text('Suspend'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      reason = ctrl.text.trim().isNotEmpty
          ? ctrl.text.trim()
          : 'Suspended by administrator.';
      ctrl.dispose();
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Reinstate User?'),
          content: Text(
              'Remove the suspension on ${u.fullName}? '
              'They will regain full access to the app.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              child: const Text('Reinstate'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _loading = true);
    try {
      final adminUid = ref.read(currentFirebaseUserProvider)?.uid ?? '';
      final fs = ref.read(firestoreServiceProvider);
      if (isSuspending) {
        await fs.suspendUser(
            uid: u.uid, adminUid: adminUid, reason: reason);
      } else {
        await fs.unsuspendUser(u.uid);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isSuspending
            ? '${u.fullName} suspended.'
            : '${u.fullName} reinstated.'),
        backgroundColor:
            isSuspending ? AppColors.coral : AppColors.teal,
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
    final user = widget.user;
    BadgeType badgeType;
    String badgeLabel;
    switch (user.kycStatus) {
      case KycStatus.verified:
        badgeType = BadgeType.verified;
        badgeLabel = 'KYC ✓';
        break;
      case KycStatus.submitted:
        badgeType = BadgeType.warn;
        badgeLabel = 'KYC Pending';
        break;
      case KycStatus.rejected:
        badgeType = BadgeType.danger;
        badgeLabel = 'KYC Rejected';
        break;
      default:
        badgeType = BadgeType.ink;
        badgeLabel = user.verified ? 'Verified' : 'Unverified';
    }

    return AppCard(
      borderColor: user.suspended ? AppColors.coral : null,
      borderWidth: user.suspended ? 2 : 1,
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
                    Text(user.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(user.email,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.mute),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(user.role,
                        style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.marigoldDark)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppBadge(badgeLabel, type: badgeType),
                  if (user.suspended) ...[
                    const SizedBox(height: 4),
                    const AppBadge('Suspended', type: BadgeType.danger),
                  ],
                ],
              ),
            ],
          ),
          if (user.suspended && user.suspendedReason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Reason: ${user.suspendedReason}',
                style: const TextStyle(
                    fontSize: 10.5, color: AppColors.coral)),
          ],
          const SizedBox(height: 10),
          _loading
              ? const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _toggleSuspend,
                    icon: Icon(
                      user.suspended
                          ? Icons.lock_open_rounded
                          : Icons.block_rounded,
                      size: 16,
                      color: user.suspended
                          ? AppColors.teal
                          : AppColors.coral,
                    ),
                    label: Text(
                      user.suspended ? 'Reinstate Account' : 'Suspend Account',
                      style: TextStyle(
                          color: user.suspended
                              ? AppColors.teal
                              : AppColors.coral),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: user.suspended
                              ? AppColors.teal
                              : AppColors.coral),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
