import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'services/local_notification_service.dart';
import 'theme.dart';

import 'screens/auth/auth_gate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/phone_login_screen.dart';

import 'screens/seeker/seeker_dashboard.dart';
import 'screens/seeker/job_details_screen.dart';
import 'screens/seeker/my_applications_screen.dart';
import 'screens/seeker/work_history_screen.dart';
import 'screens/seeker/saved_jobs_screen.dart';

import 'screens/employer/employer_dashboard.dart';
import 'screens/employer/employer_jobs_screen.dart';
import 'screens/employer/job_applicants_screen.dart';
import 'screens/employer/post_job_screen.dart';
import 'screens/employer/applicants_screen.dart';
import 'screens/employer_screens.dart' hide ApplicantsScreen;

import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_fraud_screen.dart';
import 'screens/admin/admin_verification_screen.dart';

import 'screens/chat/chat_screen.dart';
import 'screens/chat/chat_list_screen.dart';

import 'screens/shared/rating_screen.dart';
import 'screens/shared/profile_edit_screen.dart';
import 'screens/shared/live_location_screen.dart';
import 'screens/shared/language_screen.dart';
import 'screens/shared/referral_screen.dart';
import 'screens/shared/attendance_screen.dart';
import 'screens/admin/admin_analytics_screen.dart';

import 'screens/onboarding_screens.dart';
import 'screens/notifications_screen.dart';

import 'providers/locale_provider.dart';
import 'providers/auth_provider.dart';
import 'models/user_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Global navigator key — used by FcmService to navigate from
/// background notification taps.
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load saved locale BEFORE runApp — first frame shows correct language.
  final savedLocale = await loadSavedLocale();

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => LocaleNotifier(savedLocale)),
      ],
      child: const TrustHireApp(),
    ),
  );
}

class TrustHireApp extends ConsumerStatefulWidget {
  const TrustHireApp({super.key});
  @override
  ConsumerState<TrustHireApp> createState() => _TrustHireAppState();
}

class _TrustHireAppState extends ConsumerState<TrustHireApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmService.instance.init(ref: ref, navigatorKey: navigatorKey);
      LocalNotificationService.instance.init();

      // ── Pop to root on logout — runs after navigator is ready ──
      ref.listenManual<AsyncValue<UserModel?>>(userProvider,
          (AsyncValue<UserModel?>? previous, AsyncValue<UserModel?> next) {
        final wasSignedIn = previous?.valueOrNull != null;
        final isSignedOut = next.valueOrNull == null && !next.isLoading;
        if (wasSignedIn && isSignedOut) {
          navigatorKey.currentState
              ?.popUntil((route) => route.isFirst);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'TrustHire',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      navigatorKey: navigatorKey,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // home: AuthGate — no initialRoute, no named-route navigation for auth.
      // AuthGate watches userProvider and returns the correct widget directly.
      // This means the Navigator stack is always:
      //   [AuthGate]  ← root, never popped
      //   [jobDetails, chat, etc.]  ← pushed on top
      // Logout clears the auth state, AuthGate rebuilds to LoginScreen,
      // and we pop everything above root so LoginScreen is visible.
      home: const AuthGate(),
      routes: {
        '/login':            (c) => const LoginScreen(),
        '/register':         (c) => const RegisterScreen(),
        '/forgotPassword':   (c) => const ForgotPasswordScreen(),
        '/verifyEmail':      (c) => const EmailVerificationScreen(),
        '/phoneLogin':       (c) => const PhoneLoginScreen(),
        '/seekerDashboard':  (c) => const SeekerDashboard(),
        '/employerDashboard':(c) => const EmployerDashboard(),
        '/adminDashboard':   (c) => const AdminDashboard(),
        '/jobDetails':       (c) => const JobDetailsScreen(),
        '/myApplications':   (c) => const MyApplicationsScreen(),
        '/postJob':          (c) => const PostJobScreen(),
        '/employerJobs':     (c) => const EmployerJobsScreen(),
        '/jobApplicants':    (c) => const JobApplicantsScreen(),
        '/applicants':       (c) => const ApplicantsScreen(),
        '/escrow':           (c) => const EscrowScreen(),
        '/confirmRelease':   (c) => const ConfirmReleaseScreen(),
        '/adminFraud':       (c) => const AdminFraudScreen(),
        '/adminVerification':(c) => const AdminVerificationScreen(),
        '/chats':            (c) => const ChatListScreen(),
        '/chatScreen':       (c) => const ChatScreen(),
        '/rateScreen':       (c) => const RatingScreen(),
        '/editProfile':      (c) => const ProfileEditScreen(),
        '/notifications':    (c) => const NotificationsScreen(),
        '/liveLocation':     (c) => const LiveLocationScreen(),
        '/shareLocation':    (c) => const SeekerLiveLocationScreen(),
        '/workHistory':      (c) => const WorkHistoryScreen(),
        '/portfolio':        (c) => const SeekerPortfolioScreen(),
        '/referral':         (c) => const ReferralScreen(),
        '/language':         (c) => const LanguageScreen(),
        '/geofence':         (c) => const GeofenceScreen(),
        '/attendanceLog':    (c) => const AttendanceLogScreen(),
        '/savedJobs':        (c) => const SavedJobsScreen(),
        '/adminAnalytics':   (c) => const AdminAnalyticsScreen(),
        '/splash':           (c) => const SplashScreen(),
        '/role':             (c) => const RoleSelectScreen(),
        '/kyc':              (c) => const KycScreen(),
        '/trustIntro':       (c) => const TrustIntroScreen(),
      },
    );
  }
}
