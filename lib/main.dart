import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme.dart';

// â”€â”€ Auth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
import 'screens/auth/auth_gate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/email_verification_screen.dart';

// â”€â”€ Role dashboards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
import 'screens/seeker/seeker_dashboard.dart';
import 'screens/employer/employer_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

// â”€â”€ Seeker sub-screens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
import 'screens/seeker/job_details_screen.dart';
import 'screens/seeker/my_applications_screen.dart' as seeker;
import 'screens/seeker_screens.dart' show ChatScreen, RateScreen;

// â”€â”€ Employer sub-screens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
import 'screens/employer/post_job_screen.dart';
import 'screens/employer/employer_jobs_screen.dart';
import 'screens/employer/job_applicants_screen.dart';
import 'screens/employer/applicants_screen.dart';
import 'screens/employer_screens.dart' show EscrowScreen, ConfirmReleaseScreen;

// â”€â”€ Admin sub-screens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
import 'screens/admin_screens.dart'
    show AdminFraudScreen, AdminVerificationScreen;

// â”€â”€ Onboarding â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
import 'screens/onboarding_screens.dart';

// â”€â”€ Notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
import 'screens/notifications_screen.dart';

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
        // â”€â”€ Auth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        '/authGate':       (context) => const AuthGate(),
        '/login':          (context) => const LoginScreen(),
        '/register':       (context) => const RegisterScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/verifyEmail':    (context) => const EmailVerificationScreen(),

        // â”€â”€ Role dashboards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        '/seekerDashboard':   (context) => const SeekerDashboard(),
        '/employerDashboard': (context) => const EmployerDashboard(),
        '/adminDashboard':    (context) => const AdminDashboard(),

        // â”€â”€ Seeker sub-screens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        '/jobDetails':      (context) => const JobDetailsScreen(),
        '/myApplications':  (context) => const seeker.MyApplicationsScreen(),
        '/chat':            (context) => const ChatScreen(),
        '/rate':            (context) => const RateScreen(),

        // â”€â”€ Employer sub-screens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        '/postJob':         (context) => const PostJobScreen(),
        '/employerJobs':    (context) => const EmployerJobsScreen(),
        '/jobApplicants':   (context) => const JobApplicantsScreen(),
        '/applicants':      (context) => const ApplicantsScreen(),
        '/escrow':          (context) => const EscrowScreen(),
        '/confirmRelease':  (context) => const ConfirmReleaseScreen(),

        // â”€â”€ Admin sub-screens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        '/adminFraud':        (context) => const AdminFraudScreen(),
        '/adminVerification': (context) => const AdminVerificationScreen(),

        // â”€â”€ Onboarding â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        '/splash':      (context) => const SplashScreen(),
        '/role':        (context) => const RoleSelectScreen(),
        '/kyc':         (context) => const KycScreen(),
        '/trustIntro':  (context) => const TrustIntroScreen(),

        // â”€â”€ Notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}
