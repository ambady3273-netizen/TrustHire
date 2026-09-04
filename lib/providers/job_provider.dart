import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job_model.dart';
import '../models/application_model.dart';
import '../providers/auth_provider.dart';

// ============================================================
// JOB FEED — approved jobs for seekers
// ============================================================

/// Streams all approved jobs from Firestore ordered by creation date.
/// Used by the Seeker Dashboard job feed.
final approvedJobsProvider = StreamProvider<List<JobModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getApprovedJobs();
});

// ============================================================
// EMPLOYER JOBS — jobs posted by the currently signed-in employer
// ============================================================

/// Streams all jobs posted by the currently authenticated employer.
final employerJobsProvider = StreamProvider<List<JobModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final uid = authService.currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return firestore.getEmployerJobs(uid);
});

// ============================================================
// MY APPLICATIONS — applications submitted by the signed-in seeker
// ============================================================

/// Streams all applications made by the currently authenticated seeker.
final myApplicationsProvider =
    StreamProvider<List<ApplicationModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final uid = authService.currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return firestore.getMyApplications(uid);
});

// ============================================================
// EMPLOYER APPLICATIONS — all applications to the employer's jobs
// ============================================================

/// Streams all applications received by the currently authenticated employer.
final employerApplicationsProvider =
    StreamProvider<List<ApplicationModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final uid = authService.currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return firestore.getApplicationsForEmployer(uid);
});

// ============================================================
// PENDING REVIEW JOBS — admin fraud queue
// ============================================================

/// Streams all jobs with status 'pending_review' for admin moderation.
final pendingJobsProvider = StreamProvider<List<JobModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getPendingReviewJobs();
});

// ============================================================
// ADMIN STAT PROVIDERS — live counts for admin dashboard
// ============================================================

/// Live count of jobs currently in pending_review (flagged for admin).
final adminFlaggedCountProvider = StreamProvider<int>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getPendingReviewJobs().map((list) => list.length);
});

/// Live count of users whose KYC is not yet verified.
final adminPendingKycCountProvider = StreamProvider<int>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getUnverifiedUsers().map((list) => list.length);
});

/// Live count of jobs that have been approved (auto-cleared by AI or admin).
final adminApprovedCountProvider = StreamProvider<int>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getApprovedJobs().map((list) => list.length);
});

// ============================================================
// JOB-SPECIFIC APPLICATIONS — for a single job (employer view)
// ============================================================

/// Streams applications for one specific job.
/// Pass the jobId as the provider argument.
final jobApplicationsProvider =
    StreamProvider.family<List<ApplicationModel>, String>((ref, jobId) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getApplicationsForJob(jobId);
});

// ============================================================
// SELECTED JOB — pass a JobModel through navigation
// ============================================================

/// Holds the job selected by the seeker when they tap a job card.
/// Screens read this to get the full job data without re-fetching.
final selectedJobProvider = StateProvider<JobModel?>((ref) => null);

// ============================================================
// CURRENT USER (Firebase) — convenience re-export
// ============================================================

/// Quick access to the raw Firebase User (for uid, email etc.).
final currentFirebaseUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});
