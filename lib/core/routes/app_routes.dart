/// Centralised route name constants.
/// Every Navigator.pushNamed call and route map key must use these —
/// never raw string literals — so a typo causes a compile error rather
/// than a silent routing failure.
class AppRoutes {
  // Root demo menu
  static const root = '/';

  // Auth
  static const authGate = '/authGate';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgotPassword';
  static const verifyEmail = '/verifyEmail';

  // Onboarding
  static const splash = '/splash';
  static const role = '/role';
  static const kyc = '/kyc';
  static const trustIntro = '/trustIntro';

  // Job Seeker
  static const jobFeed = '/jobFeed';
  static const jobDetails = '/jobDetails';
  static const chat = '/chat';
  static const rate = '/rate';

  // Employer
  static const postJob = '/postJob';
  static const applicants = '/applicants';
  static const escrow = '/escrow';
  static const confirmRelease = '/confirmRelease';

  // Admin
  static const adminFraud = '/adminFraud';
  static const adminVerification = '/adminVerification';

  // Notifications
  static const notifications = '/notifications';

  // Seeker
  static const myApplications = '/myApplications';
}
