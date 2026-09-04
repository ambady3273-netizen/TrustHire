import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
// KycStatus constants are defined in user_model.dart
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/rating_model.dart';

class FirestoreService {
  FirestoreService();

  static final FirestoreService instance =
      FirestoreService();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

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

  /// Update Verification — used by admin after KYC review.
  Future<void> verifyUser(String uid, bool verified) async {
    await users.doc(uid).update({'verified': verified});
  }

  /// Submit KYC documents (seeker/employer self-service).
  Future<void> submitKyc({
    required String uid,
    required String governmentIdUrl,
    required String selfieUrl,
  }) async {
    await users.doc(uid).update({
      'kycStatus': KycStatus.submitted,
      'governmentIdUrl': governmentIdUrl,
      'selfieUrl': selfieUrl,
      'kycSubmittedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin approves KYC — marks user as verified.
  Future<void> approveKyc({
    required String uid,
    required String adminUid,
  }) async {
    await users.doc(uid).update({
      'kycStatus': KycStatus.verified,
      'verified': true,
      'kycVerifiedAt': FieldValue.serverTimestamp(),
      'kycVerifiedBy': adminUid,
      'kycRejectReason': '',
    });
  }

  /// Admin rejects KYC — notifies the user of the reason.
  Future<void> rejectKyc({
    required String uid,
    required String adminUid,
    required String reason,
  }) async {
    await users.doc(uid).update({
      'kycStatus': KycStatus.rejected,
      'verified': false,
      'kycVerifiedAt': FieldValue.serverTimestamp(),
      'kycVerifiedBy': adminUid,
      'kycRejectReason': reason,
    });
  }

  /// Stream users with pending KYC submissions (admin view).
  Stream<List<UserModel>> getPendingKycUsers() {
    return users
        .where('kycStatus', isEqualTo: KycStatus.submitted)
        .orderBy('kycSubmittedAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromMap(d.data())).toList());
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

  /// Update Last Login — uses set+merge so it works even if
  /// the document doesn't exist yet (safe for all scenarios).
  Future<void> updateLastLogin(String uid) async {
    await users.doc(uid).set(
      {'lastLogin': Timestamp.now()},
      SetOptions(merge: true),
    );
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
  // APPLICATIONS COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> get applications =>
      _firestore.collection('applications');

  /// Apply for a job.
  /// Returns the new application document ID, or throws if the
  /// seeker has already applied to this job.
  Future<String> applyForJob(ApplicationModel application) async {
    // Prevent duplicate applications from the same seeker.
    final existing = await applications
        .where('jobId', isEqualTo: application.jobId)
        .where('seekerId', isEqualTo: application.seekerId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You have already applied for this job.');
    }

    // Use server timestamp for both appliedAt and updatedAt.
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
        .map((snap) => snap.docs
            .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream all applications submitted by a seeker (seeker view).
  Stream<List<ApplicationModel>> getMyApplications(String seekerId) {
    return applications
        .where('seekerId', isEqualTo: seekerId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream all applications across all jobs posted by an employer.
  Stream<List<ApplicationModel>> getApplicationsForEmployer(
      String employerId) {
    return applications
        .where('employerId', isEqualTo: employerId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Update an application's status (accept / reject / withdraw).
  /// Also stamps updatedAt with a server timestamp.
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

  /// Check whether a seeker has already applied for a job.
  /// Returns the application if found, null otherwise.
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
  // CHATS COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> get chats =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> messagesOf(String chatId) =>
      chats.doc(chatId).collection('messages');

  /// Create a chat for an accepted application.
  /// Uses a deterministic ID (`chat_applicationId`) so duplicates are
  /// impossible even with concurrent calls.
  Future<ChatModel> createChatForApplication({
    required ApplicationModel application,
    required String employerName,
  }) async {
    final chatId =
        ChatModel.chatIdFromApplicationId(application.id);
    final ref = chats.doc(chatId);

    final existing = await ref.get();
    if (existing.exists) {
      return ChatModel.fromMap(existing.data()!, chatId);
    }

    final now = DateTime.now();
    final chat = ChatModel(
      id: chatId,
      applicationId: application.id,
      jobId: application.jobId,
      jobTitle: application.jobTitle,
      seekerId: application.seekerId,
      seekerName: application.seekerName,
      employerId: application.employerId,
      employerName: employerName,
      createdAt: now,
      updatedAt: now,
    );

    final data = chat.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await ref.set(data);
    return chat;
  }

  /// Get the chat for an application (null if it doesn't exist yet).
  Future<ChatModel?> getChatForApplication(String applicationId) async {
    final chatId = ChatModel.chatIdFromApplicationId(applicationId);
    final doc = await chats.doc(chatId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ChatModel.fromMap(doc.data()!, doc.id);
  }

  /// Send a message inside a chat.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw Exception('Message cannot be empty.');

    final batch = _firestore.batch();

    final msgRef = messagesOf(chatId).doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': trimmed,
      'isRead': false,
      'sentAt': FieldValue.serverTimestamp(),
    });

    final chatRef = chats.doc(chatId);
    batch.update(chatRef, {
      'lastMessage': trimmed,
      'lastMessageSenderId': senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Real-time stream of messages for a chat, oldest-first.
  Stream<List<MessageModel>> watchMessages(String chatId) {
    return messagesOf(chatId)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Real-time stream of all chats the current user participates in.
  /// Pass `seekerId` or `employerId` as [fieldName].
  Stream<List<ChatModel>> watchUserChats(String uid, String fieldName) {
    return chats
        .where(fieldName, isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Mark all unread messages in a chat as read for the given receiver.
  Future<void> markMessagesRead({
    required String chatId,
    required String receiverId,
  }) async {
    final unread = await messagesOf(chatId)
        .where('receiverId', isEqualTo: receiverId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    if (unread.docs.isNotEmpty) await batch.commit();
  }

  // ============================================================
  // RATINGS COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> get ratings =>
      _firestore.collection('ratings');

  /// Submit a rating.
  ///
  /// Validates:
  ///   - reviewer != reviewee (no self-rating)
  ///   - reviewer is actually a participant in the application
  ///   - no duplicate rating from the same reviewer on the same application
  Future<void> submitRating(RatingModel rating) async {
    // 1. Prevent self-rating.
    if (rating.reviewerId == rating.revieweeId) {
      throw Exception('You cannot rate yourself.');
    }

    // 2. Verify the reviewer is a participant in this application.
    final appDoc = await applications.doc(rating.applicationId).get();
    if (!appDoc.exists || appDoc.data() == null) {
      throw Exception('Application not found. Cannot submit rating.');
    }
    final appData = appDoc.data()!;
    final seekerId = appData['seekerId'] as String? ?? '';
    final employerId = appData['employerId'] as String? ?? '';

    if (rating.reviewerId != seekerId && rating.reviewerId != employerId) {
      throw Exception(
          'You are not a participant in this application and cannot submit a rating.');
    }

    // 3. Verify the reviewee is the other participant.
    if (rating.revieweeId != seekerId && rating.revieweeId != employerId) {
      throw Exception('Invalid reviewee for this application.');
    }

    // 4. Prevent duplicate rating.
    final existing = await ratings
        .where('applicationId', isEqualTo: rating.applicationId)
        .where('reviewerId', isEqualTo: rating.reviewerId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You have already rated this person for this job.');
    }

    // 5. Persist the rating with a server timestamp.
    final data = rating.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await ratings.add(data);

    // 6. Update the reviewee's average trust score.
    await _updateTrustScore(rating.revieweeId);
  }

  /// Recalculate and persist a user's average trust score (0–100).
  Future<void> _updateTrustScore(String uid) async {
    final snap =
        await ratings.where('revieweeId', isEqualTo: uid).get();
    if (snap.docs.isEmpty) return;

    final scores = snap.docs
        .map((d) => (d.data()['stars'] as num).toDouble())
        .toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    // Normalise 1-5 stars → 0-100
    final score = ((avg - 1) / 4) * 100;
    await updateTrustScore(uid, double.parse(score.toStringAsFixed(1)));
  }

  /// Stream of ratings received by a user.
  Stream<List<RatingModel>> getRatingsForUser(String uid) {
    return ratings
        .where('revieweeId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RatingModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Check if the reviewer already rated this application.
  Future<bool> hasRated({
    required String applicationId,
    required String reviewerId,
  }) async {
    final snap = await ratings
        .where('applicationId', isEqualTo: applicationId)
        .where('reviewerId', isEqualTo: reviewerId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ============================================================
  // ADMIN METHODS
  // ============================================================

  /// Stream all jobs that are pending admin review.
  Stream<List<JobModel>> getPendingJobs() {
    return jobs
        .where('status', isEqualTo: 'pending_review')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => JobModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Approve a job posting.
  Future<void> approveJob(String jobId) async {
    await jobs.doc(jobId).update({
      'status': 'approved',
      'adminReviewedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject a job posting.
  Future<void> rejectJob(String jobId) async {
    await jobs.doc(jobId).update({
      'status': 'rejected',
      'adminReviewedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream all users (admin use).
  Stream<List<UserModel>> getAllUsers() {
    return users
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromMap(d.data())).toList());
  }
}

