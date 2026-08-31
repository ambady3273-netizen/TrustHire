class AppConstants {
  static const String appName = "TrustHire";

  static const String usersCollection = "users";
  static const String jobsCollection = "jobs";
  static const String applicationsCollection = "applications";

  static const String roleJobSeeker = "job_seeker";
  static const String roleEmployer = "employer";
  static const String roleAdmin = "admin";

  /// Returns the home route for a given role string.
  /// Defaults to the job feed if the role is unrecognised.
  static String homeRouteForRole(String role) {
    switch (role) {
      case roleEmployer:
        return '/postJob';
      case roleAdmin:
        return '/adminFraud';
      case roleJobSeeker:
      default:
        return '/jobFeed';
    }
  }
}