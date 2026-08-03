import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme.dart';

import 'screens/root_menu_screen.dart';
import 'screens/onboarding_screens.dart';
import 'screens/seeker_screens.dart';
import 'screens/employer_screens.dart';
import 'screens/admin_screens.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/email_verification_screen.dart';
// Auth Screens
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: TrustHireApp(),
    ),
  );
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: const Center(
        child: Text('Forgot Password screen'),
      ),
    );
  }
}

class TrustHireApp extends StatelessWidget {
  const TrustHireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrustHire',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: '/authGate',
      routes: {
        '/': (context) => const RootMenuScreen(),

        // Authentication
        '/login': (context) => const LoginScreen(),

        // Onboarding
        '/splash': (context) => const SplashScreen(),
        '/role': (context) => const RoleSelectScreen(),
        '/kyc': (context) => const KycScreen(),
        '/trustIntro': (context) => const TrustIntroScreen(),

        // Job Seeker
        '/jobFeed': (context) => const JobFeedScreen(),
        '/jobDetails': (context) => const JobDetailsScreen(),
        '/chat': (context) => const ChatScreen(),
        '/rate': (context) => const RateScreen(),

        // Employer
        '/postJob': (context) => const PostJobScreen(),
        '/applicants': (context) => const ApplicantsScreen(),
        '/escrow': (context) => const EscrowScreen(),
        '/confirmRelease': (context) => const ConfirmReleaseScreen(),

        // Admin
        '/adminFraud': (context) => const AdminFraudScreen(),
        '/adminVerification': (context) => const AdminVerificationScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/authGate': (context) => const AuthGate(),
        '/verifyEmail': (context) => const EmailVerificationScreen(),
      },
    );
  }
}