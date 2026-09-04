import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import 'login_screen.dart';

/// AuthGate â€” app entry point after Firebase initialises.
///
/// Flow:
///   loading              â†’ spinner
///   not signed in        â†’ LoginScreen
///   signed in + doc      â†’ route by role to the correct dashboard
///   signed in, no doc    â†’ auto-create Firestore doc â†’ re-route
///   Firestore error      â†’ retry / logout screen
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const _LoadingScreen(),

      error: (error, _) => _ErrorScreen(
        message: 'Something went wrong.\n\n${error.toString()}',
        onRetry: () => ref.invalidate(userProvider),
        onLogout: () => ref.read(authProvider.notifier).logout(),
      ),

      data: (userModel) {
        // â”€â”€ Not signed in â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (userModel == null) {
          final firebaseUser = ref.read(authServiceProvider).currentUser;

          if (firebaseUser == null) {
            return const LoginScreen();
          }

          // Firebase user exists but Firestore doc is missing.
          // Auto-create the document from available Firebase Auth data
          // so the user is not permanently blocked.
          return _AutoCreateProfileScreen(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName ?? '',
            onLogout: () => ref.read(authProvider.notifier).logout(),
          );
        }

        // â”€â”€ Signed in â€” route by role â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        return _RoleRouter(role: userModel.role);
      },
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Role router â€” reads role and pushes the correct dashboard
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RoleRouter extends StatefulWidget {
  final String role;
  const _RoleRouter({required this.role});

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = _routeForRole(widget.role);
      if (route != null) Navigator.pushReplacementNamed(context, route);
    });
  }

  String? _routeForRole(String role) {
    switch (role) {
      case 'job_seeker':
        return '/seekerDashboard';
      case 'employer':
        return '/employerDashboard';
      case 'admin':
        return '/adminDashboard';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show spinner while the post-frame callback fires, or unknown-role screen.
    if (_routeForRole(widget.role) != null) return const _LoadingScreen();
    return _UnknownRoleScreen(role: widget.role);
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Auto-create profile when Firestore doc is missing
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final firestore = ref.read(firestoreServiceProvider);
      final now = Timestamp.now();
      final user = UserModel(
        uid: widget.uid,
        fullName: widget.displayName.isNotEmpty
            ? widget.displayName
            : widget.email.split('@').first,
        email: widget.email,
        role: _selectedRole,
        verified: false,
        trustScore: 0,
        profileImage: '',
        createdAt: now,
        lastLogin: now,
      );
      await firestore.createUser(user);
      if (mounted) ref.invalidate(userProvider);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We found your account (${widget.email}) but your profile '
                'data is incomplete. Choose your role to continue.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.mute, height: 1.5),
              ),
              const SizedBox(height: 28),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'job_seeker',
                    icon: Icon(Icons.person),
                    label: Text('Job Seeker'),
                  ),
                  ButtonSegment(
                    value: 'employer',
                    icon: Icon(Icons.business),
                    label: Text('Employer'),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: _isCreating
                    ? null
                    : (v) => setState(() => _selectedRole = v.first),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.coral),
                  textAlign: TextAlign.center,
                ),
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
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isCreating
                      ? null
                      : () async {
                          await widget.onLogout();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/login', (r) => false);
                          }
                        },
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Helper screens
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
              const Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.mute, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await onLogout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (r) => false);
                    }
                  },
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
              const Text(
                'Unknown Role',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your account has an unrecognised role: "$role". '
                'Please contact support or log out and register again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.mute, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Consumer(
                  builder: (context, ref, _) => ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (r) => false);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
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
