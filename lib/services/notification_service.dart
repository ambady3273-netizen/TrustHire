import '../models/notification_model.dart';
import 'firestore_service.dart';

/// Central helper for creating typed in-app notifications.
///
/// Every public method corresponds to one business event.
/// All writes go through [FirestoreService.createNotification] so
/// they appear instantly in every listener's Firestore stream.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _db = FirestoreService.instance;

  // ── helpers ────────────────────────────────────────────────

  Future<void> _send({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? actionRoute,
    String? actionId,
  }) async {
    final n = NotificationModel(
      id: '',
      userId: userId,
      type: type,
      title: title,
      body: body,
      isRead: false,
      actionRoute: actionRoute,
      actionId: actionId,
      createdAt: DateTime.now(),
    );
    try {
      await _db.createNotification(n);
    } catch (_) {
      // Notification failure must never crash the primary action.
    }
  }

  // ── Seeker events ──────────────────────────────────────────

  /// Fired when a seeker submits an application.
  Future<void> applicationSubmitted({
    required String seekerId,
    required String jobTitle,
    required String companyName,
    required String jobId,
  }) =>
      _send(
        userId: seekerId,
        type: NotificationType.applicationSent,
        title: 'Application sent!',
        body: 'You applied for "$jobTitle" at $companyName.',
        actionRoute: '/myApplications',
        actionId: jobId,
      );

  /// Fired when an employer shortlists/accepts a seeker.
  Future<void> applicationAccepted({
    required String seekerId,
    required String jobTitle,
    required String companyName,
    required String applicationId,
  }) =>
      _send(
        userId: seekerId,
        type: NotificationType.shortlisted,
        title: 'You\'ve been shortlisted! 🎉',
        body: '$companyName shortlisted you for "$jobTitle".',
        actionRoute: '/myApplications',
        actionId: applicationId,
      );

  /// Fired when an employer rejects a seeker.
  Future<void> applicationRejected({
    required String seekerId,
    required String jobTitle,
    required String companyName,
    required String applicationId,
  }) =>
      _send(
        userId: seekerId,
        type: NotificationType.general,
        title: 'Application update',
        body: 'Your application for "$jobTitle" at $companyName was not selected.',
        actionRoute: '/myApplications',
        actionId: applicationId,
      );

  // ── Employer events ────────────────────────────────────────

  /// Fired when a seeker applies to the employer's job.
  Future<void> newApplicant({
    required String employerId,
    required String seekerName,
    required String jobTitle,
    required String jobId,
  }) =>
      _send(
        userId: employerId,
        type: NotificationType.newApplicant,
        title: 'New applicant!',
        body: '$seekerName applied for your job "$jobTitle".',
        actionRoute: '/jobApplicants',
        actionId: jobId,
      );

  /// Fired when admin approves the employer's job.
  Future<void> jobApproved({
    required String employerId,
    required String jobTitle,
    required String jobId,
  }) =>
      _send(
        userId: employerId,
        type: NotificationType.jobApproved,
        title: 'Job approved ✓',
        body: 'Your job "$jobTitle" passed the safety check and is now live.',
        actionRoute: '/employerJobs',
        actionId: jobId,
      );

  /// Fired when admin rejects the employer's job.
  Future<void> jobRejected({
    required String employerId,
    required String jobTitle,
    required String jobId,
  }) =>
      _send(
        userId: employerId,
        type: NotificationType.jobRejected,
        title: 'Job not approved',
        body: 'Your job "$jobTitle" was removed by the admin team.',
        actionRoute: '/employerJobs',
        actionId: jobId,
      );

  // ── KYC events ─────────────────────────────────────────────

  /// Fired when admin verifies a user's KYC.
  Future<void> kycApproved({required String userId}) =>
      _send(
        userId: userId,
        type: NotificationType.kycApproved,
        title: 'Identity verified ✓',
        body: 'Your documents were reviewed and your account is now verified.',
      );

  /// Fired when admin rejects a user's KYC.
  Future<void> kycRejected({
    required String userId,
    required String reason,
  }) =>
      _send(
        userId: userId,
        type: NotificationType.kycRejected,
        title: 'Verification not approved',
        body: reason.isNotEmpty
            ? reason
            : 'Your identity documents could not be verified. Please resubmit.',
      );

  // ── Review events ──────────────────────────────────────────

  /// Fired when either party receives a new review.
  Future<void> reviewReceived({
    required String userId,
    required String reviewerName,
    required int rating,
    required String jobTitle,
  }) =>
      _send(
        userId: userId,
        type: NotificationType.reviewReceived,
        title: 'New review received',
        body: '$reviewerName gave you $rating★ for "$jobTitle".',
      );
}
