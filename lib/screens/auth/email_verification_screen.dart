import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool loading = false;

  Future<void> checkVerification() async {
    setState(() {
      loading = true;
    });

    final authService = ref.read(authServiceProvider);

    await authService.reloadUser();

    setState(() {
      loading = false;
    });

    if (authService.isEmailVerified) {
      if (!mounted) return;

      // Route through AuthGate so it reads the role and goes to
      // the correct dashboard.
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/authGate',
        (route) => false,
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Your email is not verified yet."),
      ),
    );
  }

  Future<void> resendEmail() async {
    final authService = ref.read(authServiceProvider);

    try {
      await authService.sendVerificationEmail();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification email sent."),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> logout() async {
    await ref.read(authProvider.notifier).logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login",
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text("Verify Email"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Verify your email",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "We've sent a verification email to your registered address. Please verify your account before continuing.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mute,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: loading ? null : checkVerification,
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text("I HAVE VERIFIED"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: resendEmail,
                      child: const Text("RESEND EMAIL"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: logout,
                      child: const Text("LOGOUT"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}