import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/job_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

// ── current uid helper (shared pattern) ──────────────────────
final _uidProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.whenOrNull(data: (User? u) => u?.uid);
});

// ── all approved jobs (job feed) ──────────────────────────────
final approvedJobsProvider = StreamProvider<List<JobModel>>((ref) {
  return FirestoreService.instance.getApprovedJobs();
});

// ── jobs posted by the current employer ──────────────────────
final employerJobsProvider = StreamProvider<List<JobModel>>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid == null) return const Stream.empty();
  return FirestoreService.instance.getEmployerJobs(uid);
});

// ── jobs pending admin review ─────────────────────────────────
final pendingJobsProvider = StreamProvider<List<JobModel>>((ref) {
  return FirestoreService.instance.getPendingReviewJobs();
});

// ── selected job (passed via state when navigating to details) ─
final selectedJobProvider = StateProvider<JobModel?>((ref) => null);
