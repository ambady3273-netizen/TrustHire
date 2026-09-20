import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../screens/seeker/seeker_dashboard.dart';
import '../../screens/employer/employer_dashboard.dart';
import '../../screens/admin/admin_dashboard.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────
// AuthGate — the SINGLE source of truth for routing.
//
// KEY DESIGN:
//   • AuthGate watches userProvider (a real-time Firestore stream).
//   • It RETURNS the correct widget directly — NO Navigator calls.
//   • When userProvider emits a new value (login/logout/role change)
//     Riverpod rebuilds AuthGate instantly and the correct screen
//     appears without any delay or manual navigation.
//
// This completely eliminates the "need to restart app" bug.
// ─────────────────────────────────────────────────────────────

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      // ── Still loading ──────────────────────────────────────
      loading: () => const _LoadingScreen(),

      // ── Error ──────────────────────────────────────────────
      error: (error, _) => _ErrorScreen(
        message: 'Something went wrong.\n\n${error.toString()}',
        onRetry:  () => ref.invalidate(userProvider),
        onLogout: () => ref.read(authProvider.notifier).logout(),
      ),

      // ── Data ───────────────────────────────────────────────
      data: (userModel) {
        // Not signed in
        if (userModel == null) {
          final firebaseUser =
              ref.read(authServiceProvider).currentUser;
          if (firebaseUser == null) {
            return const LoginScreen();
          }
          // Firebase user exists but Firestore doc missing
          return _AutoCreateProfileScreen(
            uid:         firebaseUser.uid,
            email:       firebaseUser.email ?? '',
            displayName: firebaseUser.displayName ?? '',
            onLogout:    () => ref.read(authProvider.notifier).logout(),
          );
        }

        // Suspended
        if (userModel.suspended) {
          return _SuspendedScreen(
            reason:   userModel.suspendedReason,
            onLogout: () => ref.read(authProvider.notifier).logout(),
          );
        }

        // ── DIRECT widget return by role — NO navigation ──────
        // Riverpod rebuilds this instantly when role changes.
        switch (userModel.role) {
          case 'job_seeker':
            return const SeekerDashboard();
          case 'employer':
            return const EmployerDashboard();
          case 'admin':
            return const AdminDashboard();
          default:
            return _UnknownRoleScreen(role: userModel.role);
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Auto-create profile when Firestore doc is missing
// ─────────────────────────────────────────────────────────────

class _AutoCreateProfileScreen extends ConsumerStatefulWidget {
  final String uid;
  final String email;
  final String displayName;
  final Future<void> Function() onLogout;

  const _AutoCreateProfileScreen({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.onLogout,
  });

  @override
  ConsumerState<_AutoCreateProfileScreen> createState() =>
      _AutoCreateProfileScreenState();
}

class _AutoCreateProfileScreenState
    extends ConsumerState<_AutoCreateProfileScreen> {
  bool _isCreating = false;
  String? _error;
  String _selectedRole = 'job_seeker';

  Future<void> _createProfile() async {
    setState(() { _isCreating = true; _error = null; });

    try {
      final firestore = ref.read(firestoreServiceProvider);
      final now      = Timestamp.now();
      final user     = UserModel(
        uid:          widget.uid,
        fullName:     widget.displayName.isNotEmpty
            ? widget.displayName
            : widget.email.split('@').first,
        email:        widget.email,
        role:         _selectedRole,
        verified:     false,
        trustScore:   0,
        profileImage: '',
        createdAt:    now,
        lastLogin:    now,
      );
      await firestore.createUser(user);
      // userProvider will automatically pick up the new doc
      // and rebuild AuthGate with the correct dashboard.
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Failed to create profile: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_outlined,
                  size: 72, color: AppColors.ink),
              const SizedBox(height: 20),
              const Text('Complete Your Profile',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink)),
              const SizedBox(height: 12),
              Text(
                'We found your account (${widget.email}) but your '
                'profile data is incomplete. Choose your role to continue.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.mute, height: 1.5),
              ),
              const SizedBox(height: 28),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'job_seeker',
                      icon: Icon(Icons.person),
                      label: Text('Job Seeker')),
                  ButtonSegment(
                      value: 'employer',
                      icon: Icon(Icons.business),
                      label: Text('Employer')),
                ],
                selected: {_selectedRole},
                onSelectionChanged: _isCreating
                    ? null
                    : (v) =>
                        setState(() => _selectedRole = v.first),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style:
                        const TextStyle(color: AppColors.coral),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Text('Continue',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isCreating
                      ? null
                      : () async => await widget.onLogout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.coral,
                    side: const BorderSide(color: AppColors.coral),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helper screens
// ─────────────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onLogout;
  const _ErrorScreen({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: AppColors.coral),
              const SizedBox(height: 20),
              const Text('Connection Error',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.mute, height: 1.5)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async => await onLogout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.coral,
                    side: const BorderSide(color: AppColors.coral)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnknownRoleScreen extends StatelessWidget {
  final String role;
  const _UnknownRoleScreen({required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.help_outline,
                  size: 64, color: AppColors.marigoldDark),
              const SizedBox(height: 20),
              const Text('Unknown Role',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink)),
              const SizedBox(height: 12),
              Text(
                'Your account has an unrecognised role: "$role". '
                'Please contact support.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.mute, height: 1.5),
              ),
              const SizedBox(height: 32),
              Consumer(
                builder: (context, ref, _) => ElevatedButton.icon(
                  onPressed: () async =>
                      await ref.read(authProvider.notifier).logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Suspended account screen
// ─────────────────────────────────────────────────────────────

class _SuspendedScreen extends StatelessWidget {
  final String reason;
  final Future<void> Function() onLogout;
  const _SuspendedScreen({
    required this.reason,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color:  AppColors.coralLight,
                  shape:  BoxShape.circle,
                ),
                child: const Icon(Icons.block_rounded,
                    size: 38, color: AppColors.coral),
              ),
              const SizedBox(height: 20),
              const Text('Account Suspended',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink)),
              const SizedBox(height: 12),
              Text(
                reason.isNotEmpty
                    ? 'Reason: $reason'
                    : 'Your account has been suspended. '
                        'Please contact support for assistance.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.mute, height: 1.5),
              ),
              const SizedBox(height: 10),
              const Text(
                'If you believe this is a mistake, contact:\nsupport@trusthire.app',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.mute),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () async => await onLogout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  side: const BorderSide(color: AppColors.coral),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
