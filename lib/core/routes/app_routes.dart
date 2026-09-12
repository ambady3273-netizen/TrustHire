/// Centralised route name constants — mirrors the route map in main.dart.
class AppRoutes {
  // ── Auth ──────────────────────────────────────────────────
  static const authGate       = '/authGate';
  static const login          = '/login';
  static const register       = '/register';
  static const forgotPassword = '/forgotPassword';
  static const verifyEmail    = '/verifyEmail';

  // ── Role dashboards ───────────────────────────────────────
  static const seekerDashboard   = '/seekerDashboard';
  static const employerDashboard = '/employerDashboard';
  static const adminDashboard    = '/adminDashboard';

  // ── Onboarding ────────────────────────────────────────────
  static const splash     = '/splash';
  static const role       = '/role';
  static const kyc        = '/kyc';
  static const trustIntro = '/trustIntro';

  // ── Seeker ────────────────────────────────────────────────
  static const jobDetails     = '/jobDetails';
  static const myApplications = '/myApplications';

  // ── Employer ──────────────────────────────────────────────
  static const postJob        = '/postJob';
  static const employerJobs   = '/employerJobs';
  static const jobApplicants  = '/jobApplicants';
  static const applicants     = '/applicants';
  static const escrow         = '/escrow';
  static const confirmRelease = '/confirmRelease';

  // ── Admin ─────────────────────────────────────────────────
  static const adminFraud        = '/adminFraud';
  static const adminVerification = '/adminVerification';

  // ── Chat ──────────────────────────────────────────────────
  static const chats      = '/chats';
  static const chatScreen = '/chatScreen';

  // ── Shared ────────────────────────────────────────────────
  static const rateScreen  = '/rateScreen';
  static const editProfile = '/editProfile';

  // ── Notifications ─────────────────────────────────────────
  static const notifications = '/notifications';
}
