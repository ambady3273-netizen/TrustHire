import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/application_model.dart';
import '../models/job_model.dart';
import '../models/user_model.dart';
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

// ============================================================
// PENDING JOBS — for admin review
// ============================================================

final pendingJobsProvider = StreamProvider<List<JobModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getPendingJobs();
});

// ============================================================
// JOB-SPECIFIC APPLICATIONS — for a single selected job
// ============================================================

final jobApplicationsForSelectedProvider =
    StreamProvider<List<ApplicationModel>>((ref) {
  final job = ref.watch(selectedJobProvider);
  if (job == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).getApplicationsForJob(job.id);
});

// ============================================================
// ADMIN — unverified users
// ============================================================

final unverifiedUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getUnverifiedUsers();
});
