import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/notification_model.dart';
import '../models/application_model.dart';
import '../models/review_model.dart';

class FirestoreService {
  // Private constructor — use FirestoreService.instance everywhere.
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // USERS COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  // ============================================================
  // JOBS COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> get jobs =>
      _firestore.collection('jobs');

  // ============================================================
  // USER FUNCTIONS
  // ============================================================

  /// Create User
  Future<void> createUser(UserModel user) async {
    await users.doc(user.uid).set(user.toMap());
  }

  /// Get User
  Future<UserModel?> getUser(String uid) async {
    final doc = await users.doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(
      doc.data()!,
    );
  }

  /// Update User
  Future<void> updateUser(UserModel user) async {
    await users.doc(user.uid).update(
      user.toMap(),
    );
  }

  /// Update User Name
  Future<void> updateName(
    String uid,
    String name,
  ) async {
    await users.doc(uid).update({
      'fullName': name,
    });
  }

  /// Update Profile Image
  Future<void> updateProfileImage(
    String uid,
    String image,
  ) async {
    await users.doc(uid).update({
      'profileImage': image,
    });
  }

  /// Update Trust Score
  Future<void> updateTrustScore(
    String uid,
    double score,
  ) async {
    await users.doc(uid).update({
      'trustScore': score,
    });
  }

  /// Update Verification
  Future<void> verifyUser(
    String uid,
    bool verified,
  ) async {
    await users.doc(uid).update({
      'verified': verified,
    });
  }

  /// Update Role
  Future<void> updateRole(
    String uid,
    String role,
  ) async {
    await users.doc(uid).update({
      'role': role,
    });
  }

  /// Update Last Login
  Future<void> updateLastLogin(
    String uid,
  ) async {
    await users.doc(uid).update({
      'lastLogin': Timestamp.now(),
    });
  }

  /// Delete User
  Future<void> deleteUser(
    String uid,
  ) async {
    await users.doc(uid).delete();
  }

  // ============================================================
  // JOB FUNCTIONS
  // ============================================================

  /// Create Job
  Future<String> createJob(JobModel job) async {
    final doc = await jobs.add(
      job.toMap(),
    );

    return doc.id;
  }

  /// Get Single Job
  Future<JobModel?> getJob(String jobId) async {
    final doc = await jobs.doc(jobId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return JobModel.fromMap(
      doc.data()!,
      doc.id,
    );
  }

  /// Get All Jobs
  Stream<List<JobModel>> getJobs() {
    return jobs
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                return JobModel.fromMap(
                  doc.data(),
                  doc.id,
                );
              },
            ).toList();
          },
        );
  }

  /// Get Employer Jobs
  Stream<List<JobModel>> getEmployerJobs(
    String employerId,
  ) {
    return jobs
        .where(
          'employerId',
          isEqualTo: employerId,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                return JobModel.fromMap(
                  doc.data(),
                  doc.id,
                );
              },
            ).toList();
          },
        );
  }

  /// Get Approved Jobs
  Stream<List<JobModel>> getApprovedJobs() {
    return jobs
        .where(
          'status',
          isEqualTo: 'approved',
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs.map(
              (doc) {
                return JobModel.fromMap(
                  doc.data(),
                  doc.id,
                );
              },
            ).toList();
          },
        );
  }

  /// Update Job
  Future<void> updateJob(
    String jobId,
    Map<String, dynamic> data,
  ) async {
    await jobs.doc(jobId).update(
      data,
    );
  }

  /// Delete Job
  Future<void> deleteJob(
    String jobId,
  ) async {
    await jobs.doc(jobId).delete();
  }

  /// Update Job Status
  Future<void> updateJobStatus(
    String jobId,
    String status,
  ) async {
    await jobs.doc(jobId).update({
      'status': status,
    });
  }

  /// Save AI Scam Detection Result
  Future<void> updateAIResult({
    required String jobId,
    required int riskScore,
    required String status,
    required List<String> reasons,
  }) async {
    await jobs.doc(jobId).update({
      'riskScore': riskScore,
      'status': status,
      'scamReasons': reasons,
      'aiAnalyzed': true,
      'aiAnalyzedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // NOTIFICATIONS COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> get notifications =>
      _firestore.collection('notifications');

  /// Stream all notifications for a user, newest first.
  Stream<List<NotificationModel>> getNotifications(String uid) {
    return notifications
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => NotificationModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Stream only the unread count — cheap to watch from the app bar.
  Stream<int> getUnreadCount(String uid) {
    return notifications
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Create a new notification document.
  Future<void> createNotification(NotificationModel n) async {
    await notifications.add(n.toMap());
  }

  /// Mark a single notification as read.
  Future<void> markNotificationRead(String notifId) async {
    await notifications.doc(notifId).update({'isRead': true});
  }

  /// Mark every unread notification for a user as read in a batch.
  Future<void> markAllNotificationsRead(String uid) async {
    final unread = await notifications
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete a single notification.
  Future<void> deleteNotification(String notifId) async {
    await notifications.doc(notifId).delete();
  }

  /// Delete all notifications for a user.
  Future<void> clearAllNotifications(String uid) async {
    final all = await notifications
        .where('userId', isEqualTo: uid)
        .get();

    if (all.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in all.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ============================================================
  // APPLICATIONS COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> get applications =>
      _firestore.collection('applications');

  /// Submit a new application. Returns the new document id.
  Future<String> createApplication(ApplicationModel app) async {
    final doc = await applications.add(app.toMap());
    return doc.id;
  }

  /// Check whether a seeker already applied to a job.
  Future<bool> hasApplied({
    required String jobId,
    required String seekerId,
  }) async {
    final snap = await applications
        .where('jobId', isEqualTo: jobId)
        .where('seekerId', isEqualTo: seekerId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Stream all applications for a seeker (their application history).
  Stream<List<ApplicationModel>> getSeekerApplications(String seekerId) {
    return applications
        .where('seekerId', isEqualTo: seekerId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ApplicationModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream all applications for a specific job (employer view).
  Stream<List<ApplicationModel>> getJobApplications(String jobId) {
    return applications
        .where('jobId', isEqualTo: jobId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ApplicationModel.fromMap(d.data(), d.id)).toList());
  }

  /// Update application status (shortlist, hire, reject).
  Future<void> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    await applications.doc(applicationId).update({'status': status.value});
  }

  // ============================================================
  // REVIEWS COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> get reviews =>
      _firestore.collection('reviews');

  /// Save a review and recalculate the reviewed user's trust score.
  Future<void> submitReview(ReviewModel review) async {
    // Write review
    await reviews.add(review.toMap());

    // Recalculate average rating for the reviewed user
    final snap = await reviews
        .where('reviewedUserId', isEqualTo: review.reviewedUserId)
        .get();

    if (snap.docs.isEmpty) return;

    double total = 0;
    for (final doc in snap.docs) {
      total += (doc.data()['rating'] ?? 0).toDouble();
    }
    final avg = total / snap.docs.length;

    // TrustScore formula:
    //   base 20 (verified) + up to 60 from avg rating (max 5★ → 60pts)
    //   + up to 20 from job count (capped at 20)
    final jobCount = snap.docs.length;
    final ratingPts = (avg / 5.0) * 60;
    final jobPts = jobCount > 20 ? 20.0 : jobCount.toDouble();
    final score = (20 + ratingPts + jobPts).clamp(0.0, 100.0);

    await updateTrustScore(review.reviewedUserId, score);
  }

  /// Stream all reviews received by a user.
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return reviews
        .where('reviewedUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ReviewModel.fromMap(d.data(), d.id)).toList());
  }

  // ============================================================
  // ADMIN HELPERS
  // ============================================================

  /// Stream jobs pending admin review.
  Stream<List<JobModel>> getPendingReviewJobs() {
    return jobs
        .where('status', isEqualTo: 'pending_review')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => JobModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream users whose KYC is not yet verified.
  Stream<List<UserModel>> getUnverifiedUsers() {
    return users
        .where('verified', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => UserModel.fromMap(d.data())).toList());
  }
}