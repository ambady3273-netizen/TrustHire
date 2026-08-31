import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme.dart';
import 'core/routes/app_routes.dart';

// ── Auth ────────────────────────────────────────────────────
import 'screens/auth/auth_gate.dart';
<<<<<<< HEAD
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/email_verification_screen.dart';

// ── Seeker screens ───────────────────────────────────────────
import 'screens/seeker/seeker_dashboard.dart';
import 'screens/seeker/job_details_screen.dart';
import 'screens/seeker/my_applications_screen.dart';

// ── Seeker legacy sub-screens (chat, rate) ───────────────────
import 'screens/seeker_screens.dart' hide JobDetailsScreen;

// ── Employer screens ─────────────────────────────────────────
import 'screens/employer/employer_dashboard.dart';
import 'screens/employer/employer_jobs_screen.dart';
import 'screens/employer/job_applicants_screen.dart';
import 'screens/employer/post_job_screen.dart';
import 'screens/employer/applicants_screen.dart';

// ── Employer legacy sub-screens (escrow, confirmRelease) ─────
import 'screens/employer_screens.dart' hide ApplicantsScreen;

// ── Admin screens ────────────────────────────────────────────
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin_screens.dart';

// ── Onboarding ───────────────────────────────────────────────
import 'screens/onboarding_screens.dart';
=======
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/my_applications_screen.dart';
// Full functional PostJobScreen (Firebase-backed)
import 'screens/employer/post_job_screen.dart' as employer_post;
>>>>>>> origin/user1

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
<<<<<<< HEAD
  runApp(const ProviderScope(child: TrustHireApp()));
=======

  runApp(
    const ProviderScope(
      child: TrustHireApp(),
    ),
  );
>>>>>>> origin/user1
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
<<<<<<< HEAD
        // ── Auth ────────────────────────────────────────────
        '/authGate': (context) => const AuthGate(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/verifyEmail': (context) => const EmailVerificationScreen(),

        // ── Role dashboards ──────────────────────────────────
        '/seekerDashboard': (context) => const SeekerDashboard(),
        '/employerDashboard': (context) => const EmployerDashboard(),
        '/adminDashboard': (context) => const AdminDashboard(),

        // ── Seeker sub-screens ───────────────────────────────
        '/jobDetails': (context) => const JobDetailsScreen(),
        '/myApplications': (context) => const MyApplicationsScreen(),
        '/chat': (context) => const ChatScreen(),
        '/rate': (context) => const RateScreen(),

        // ── Employer sub-screens ─────────────────────────────
        '/postJob': (context) => const PostJobScreen(),
        '/employerJobs': (context) => const EmployerJobsScreen(),
        '/jobApplicants': (context) => const JobApplicantsScreen(),
        '/applicants': (context) => const ApplicantsScreen(),
        '/escrow': (context) => const EscrowScreen(),
        '/confirmRelease': (context) => const ConfirmReleaseScreen(),

        // ── Admin sub-screens ────────────────────────────────
        '/adminFraud': (context) => const AdminFraudScreen(),
        '/adminVerification': (context) => const AdminVerificationScreen(),

        // ── Onboarding ───────────────────────────────────────
        '/splash': (context) => const SplashScreen(),
        '/role': (context) => const RoleSelectScreen(),
        '/kyc': (context) => const KycScreen(),
        '/trustIntro': (context) => const TrustIntroScreen(),
=======
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
>>>>>>> origin/user1
      },
    );
  }
}
