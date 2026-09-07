import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/application_model.dart';
import '../models/job_model.dart';
import '../models/notification_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  // Private constructor — use FirestoreService.instance everywhere.
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // COLLECTION REFERENCES
  // ============================================================

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get jobs =>
      _firestore.collection('jobs');

  CollectionReference<Map<String, dynamic>> get applications =>
      _firestore.collection('applications');

  CollectionReference<Map<String, dynamic>> get notifications =>
      _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> get reviews =>
      _firestore.collection('reviews');

  // ============================================================
  // USER FUNCTIONS
  // ============================================================

  Future<void> createUser(UserModel user) async {
    await users.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateUser(UserModel user) async {
    await users.doc(user.uid).update(user.toMap());
  }

  Future<void> updateName(String uid, String name) async {
    await users.doc(uid).update({'fullName': name});
  }

  Future<void> updateProfileImage(String uid, String image) async {
    await users.doc(uid).update({'profileImage': image});
  }

  /// Save the KYC selfie download URL to the user document.
  Future<void> updateKycSelfie(String uid, String selfieUrl) async {
    await users.doc(uid).update({'kycSelfieUrl': selfieUrl});
  }

  Future<void> updateTrustScore(String uid, double score) async {
    await users.doc(uid).update({'trustScore': score});
  }

  Future<void> verifyUser(String uid, bool verified) async {
    await users.doc(uid).update({'verified': verified});
  }

  Future<void> updateRole(String uid, String role) async {
    await users.doc(uid).update({'role': role});
  }

  Future<void> updateLastLogin(String uid) async {
    await users.doc(uid).update({'lastLogin': Timestamp.now()});
  }

  Future<void> deleteUser(String uid) async {
    await users.doc(uid).delete();
  }

  // ============================================================
  // JOB FUNCTIONS
  // ============================================================

  Future<String> createJob(JobModel job) async {
    final doc = await jobs.add(job.toMap());
    return doc.id;
  }

  Future<JobModel?> getJob(String jobId) async {
    final doc = await jobs.doc(jobId).get();
    if (!doc.exists || doc.data() == null) return null;
    return JobModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<JobModel>> getJobs() {
    return jobs
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => JobModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<JobModel>> getEmployerJobs(String employerId) {
    return jobs
        .where('employerId', isEqualTo: employerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => JobModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<JobModel>> getApprovedJobs() {
    return jobs
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => JobModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream jobs pending admin review.
  Stream<List<JobModel>> getPendingReviewJobs() {
    return jobs
        .where('status', isEqualTo: 'pending_review')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => JobModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    await jobs.doc(jobId).update(data);
  }

  Future<void> deleteJob(String jobId) async {
    await jobs.doc(jobId).delete();
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    await jobs.doc(jobId).update({'status': status});
  }

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
  // APPLICATION FUNCTIONS
  // ============================================================

  /// Apply for a job. Throws if the seeker has already applied.
  /// Uses server timestamps for appliedAt and updatedAt.
  Future<String> applyForJob(ApplicationModel application) async {
    final existing = await applications
        .where('jobId', isEqualTo: application.jobId)
        .where('seekerId', isEqualTo: application.seekerId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You have already applied for this job.');
    }

    final data = application.toMap();
    data['appliedAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    final doc = await applications.add(data);
    return doc.id;
  }

  /// Stream all applications for a specific job (employer view).
  Stream<List<ApplicationModel>> getApplicationsForJob(String jobId) {
    return applications
        .where('jobId', isEqualTo: jobId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ApplicationModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream all applications submitted by a seeker.
  Stream<List<ApplicationModel>> getMyApplications(String seekerId) {
    return applications
        .where('seekerId', isEqualTo: seekerId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ApplicationModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream all applications across all jobs posted by an employer.
  Stream<List<ApplicationModel>> getApplicationsForEmployer(String employerId) {
    return applications
        .where('employerId', isEqualTo: employerId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ApplicationModel.fromMap(d.data(), d.id)).toList());
  }

  /// Update an application's status and stamp updatedAt.
  Future<void> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    await applications.doc(applicationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Seeker withdraws their own application.
  Future<void> withdrawApplication(String applicationId) async {
    await applications.doc(applicationId).update({
      'status': ApplicationStatus.withdrawn,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns the existing application if the seeker has already applied,
  /// null otherwise.
  Future<ApplicationModel?> getExistingApplication({
    required String jobId,
    required String seekerId,
  }) async {
    final snap = await applications
        .where('jobId', isEqualTo: jobId)
        .where('seekerId', isEqualTo: seekerId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return ApplicationModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  // ============================================================
  // NOTIFICATION FUNCTIONS
  // ============================================================

  /// Stream all notifications for a user, newest first.
  Stream<List<NotificationModel>> getNotifications(String uid) {
    return notifications
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => NotificationModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream only the unread count — cheap to watch from the app bar.
  Stream<int> getUnreadCount(String uid) {
    return notifications
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<void> createNotification(NotificationModel n) async {
    await notifications.add(n.toMap());
  }

  Future<void> markNotificationRead(String notifId) async {
    await notifications.doc(notifId).update({'isRead': true});
  }

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

  Future<void> deleteNotification(String notifId) async {
    await notifications.doc(notifId).delete();
  }

  Future<void> clearAllNotifications(String uid) async {
    final all = await notifications.where('userId', isEqualTo: uid).get();
    if (all.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in all.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ============================================================
  // REVIEW FUNCTIONS
  // ============================================================

  /// Save a review and recalculate the reviewed user's TrustScore.
  ///
  /// Formula: base 20 (verified) + up to 60 pts from avg rating
  ///          + up to 20 pts from job count (capped at 20 jobs).
  Future<void> submitReview(ReviewModel review) async {
    await reviews.add(review.toMap());

    final snap = await reviews
        .where('reviewedUserId', isEqualTo: review.reviewedUserId)
        .get();
    if (snap.docs.isEmpty) return;

    double total = 0;
    for (final doc in snap.docs) {
      total += (doc.data()['rating'] ?? 0).toDouble();
    }
    final avg = total / snap.docs.length;
    final jobCount = snap.docs.length;
    final ratingPts = (avg / 5.0) * 60;
    final jobPts = jobCount > 20 ? 20.0 : jobCount.toDouble();
    final score = (20 + ratingPts + jobPts).clamp(0.0, 100.0);

    await updateTrustScore(review.reviewedUserId, score);
  }

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

  /// Stream users whose KYC is not yet verified.
  Stream<List<UserModel>> getUnverifiedUsers() {
    return users
        .where('verified', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromMap(d.data())).toList());
  }
}
