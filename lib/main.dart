import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme.dart';
import 'core/routes/app_routes.dart';

import 'screens/root_menu_screen.dart';
import 'screens/onboarding_screens.dart';
import 'screens/seeker_screens.dart';
import 'screens/employer_screens.dart';
import 'screens/admin_screens.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/my_applications_screen.dart';
// Full functional PostJobScreen (Firebase-backed)
import 'screens/employer/post_job_screen.dart' as employer_post;

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

class TrustHireApp extends StatelessWidget {
  const TrustHireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrustHire',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.authGate,
      routes: {
        AppRoutes.root: (context) => const RootMenuScreen(),

        // Authentication
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.authGate: (context) => const AuthGate(),
        AppRoutes.verifyEmail: (context) => const EmailVerificationScreen(),

        // Onboarding
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.role: (context) => const RoleSelectScreen(),
        AppRoutes.kyc: (context) => const KycScreen(),
        AppRoutes.trustIntro: (context) => const TrustIntroScreen(),

        // Job Seeker
        AppRoutes.jobFeed: (context) => const JobFeedScreen(),
        AppRoutes.jobDetails: (context) => const JobDetailsScreen(),
        AppRoutes.chat: (context) => const ChatScreen(),
        AppRoutes.rate: (context) => const RateScreen(),

        // Employer — full Firebase-backed PostJobScreen
        AppRoutes.postJob: (context) => const employer_post.PostJobScreen(),
        AppRoutes.applicants: (context) => const ApplicantsScreen(),
        AppRoutes.escrow: (context) => const EscrowScreen(),
        AppRoutes.confirmRelease: (context) => const ConfirmReleaseScreen(),

        // Admin
        AppRoutes.adminFraud: (context) => const AdminFraudScreen(),
        AppRoutes.adminVerification: (context) => const AdminVerificationScreen(),

        // Notifications
        AppRoutes.notifications: (context) => const NotificationsScreen(),

        // My Applications (seeker)
        AppRoutes.myApplications: (context) =>
            const MyApplicationsScreen(),
      },
    );
  }
}
