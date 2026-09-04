import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/application_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../services/firestore_service.dart';

// ── seeker: all my applications ───────────────────────────────
final myApplicationsProvider = StreamProvider<List<ApplicationModel>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final uid = authService.currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return FirestoreService.instance.getMyApplications(uid);
});

// ── employer: applications for the selected job ───────────────
final jobApplicationsForSelectedProvider =
    StreamProvider<List<ApplicationModel>>((ref) {
  final job = ref.watch(selectedJobProvider);
  if (job == null) return const Stream.empty();
  return FirestoreService.instance.getApplicationsForJob(job.id);
});

// ── admin: unverified users ───────────────────────────────────
final unverifiedUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirestoreService.instance.getUnverifiedUsers();
});
