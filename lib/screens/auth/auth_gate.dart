import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),

      error: (error, stack) => Scaffold(
        body: Center(
          child: Text(
            error.toString(),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),

      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // Check email verification before routing.
        final authService = ref.read(authServiceProvider);
        if (!authService.isEmailVerified) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/verifyEmail');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _HomeRedirect(uid: user.uid);
      },
    );
  }
}

/// Fetches the user's role from Firestore and redirects to the
/// appropriate home screen. Avoids hardcoding a single route for
/// all roles.
class _HomeRedirect extends StatefulWidget {
  final String uid;
  const _HomeRedirect({required this.uid});

  @override
  State<_HomeRedirect> createState() => _HomeRedirectState();
}

class _HomeRedirectState extends State<_HomeRedirect> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final user = await FirestoreService.instance.getUser(widget.uid);

    if (!mounted) return;

    final role = user?.role ?? AppConstants.roleJobSeeker;
    final route = AppConstants.homeRouteForRole(role);

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
