import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme.dart';

// ── Auth ──────────────────────────────────────────────────────
import 'screens/auth/auth_gate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/email_verification_screen.dart';

// ── Seeker (all production screens) ──────────────────────────
import 'screens/seeker/seeker_dashboard.dart';
import 'screens/seeker/job_details_screen.dart';
import 'screens/seeker/my_applications_screen.dart';

// ── Employer (all production screens) ────────────────────────
import 'screens/employer/employer_dashboard.dart';
import 'screens/employer/employer_jobs_screen.dart';
import 'screens/employer/job_applicants_screen.dart';
import 'screens/employer/post_job_screen.dart';
import 'screens/employer/applicants_screen.dart';
// EscrowScreen / ConfirmReleaseScreen still live in employer_screens.dart
// (only real implementations available). ApplicantsScreen (old demo) hidden.
import 'screens/employer_screens.dart' hide ApplicantsScreen;

// ── Admin ─────────────────────────────────────────────────────
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_fraud_screen.dart';
import 'screens/admin/admin_verification_screen.dart';

// ── Chat ──────────────────────────────────────────────────────
import 'screens/chat/chat_screen.dart';
import 'screens/chat/chat_list_screen.dart';

// ── Shared ────────────────────────────────────────────────────
import 'screens/shared/rating_screen.dart';

// ── Onboarding ────────────────────────────────────────────────
import 'screens/onboarding_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: TrustHireApp()));
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
        // ── Auth ────────────────────────────────────────────
        '/authGate':      (context) => const AuthGate(),
        '/login':         (context) => const LoginScreen(),
        '/register':      (context) => const RegisterScreen(),
        '/forgotPassword':(context) => const ForgotPasswordScreen(),
        '/verifyEmail':   (context) => const EmailVerificationScreen(),

        // ── Role dashboards ──────────────────────────────────
        '/seekerDashboard':   (context) => const SeekerDashboard(),
        '/employerDashboard': (context) => const EmployerDashboard(),
        '/adminDashboard':    (context) => const AdminDashboard(),

        // ── Seeker sub-screens ────────────────────────────────
        '/jobDetails':      (context) => const JobDetailsScreen(),
        '/myApplications':  (context) => const MyApplicationsScreen(),

        // ── Employer sub-screens ──────────────────────────────
        '/postJob':         (context) => const PostJobScreen(),
        '/employerJobs':    (context) => const EmployerJobsScreen(),
        '/jobApplicants':   (context) => const JobApplicantsScreen(),
        '/applicants':      (context) => const ApplicantsScreen(),
        '/escrow':          (context) => const EscrowScreen(),
        '/confirmRelease':  (context) => const ConfirmReleaseScreen(),

        // ── Admin sub-screens ─────────────────────────────────
        '/adminFraud':        (context) => const AdminFraudScreen(),
        '/adminVerification': (context) => const AdminVerificationScreen(),

        // ── Chat ──────────────────────────────────────────────
        '/chats':      (context) => const ChatListScreen(),
        '/chatScreen': (context) => const ChatScreen(),

        // ── Rating ────────────────────────────────────────────
        '/rateScreen': (context) => const RatingScreen(),

        // ── Onboarding ────────────────────────────────────────
        '/splash':     (context) => const SplashScreen(),
        '/role':       (context) => const RoleSelectScreen(),
        '/kyc':        (context) => const KycScreen(),
        '/trustIntro': (context) => const TrustIntroScreen(),
      },
    );
  }
}
