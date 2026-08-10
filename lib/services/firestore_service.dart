import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../models/job_model.dart';

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
}