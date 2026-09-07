import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/application_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'job_provider.dart';

// ── seeker: all my applications ───────────────────────────────
// Single source of truth is job_provider.dart.
// This re-export keeps old import paths working without double-subscribing.
export 'job_provider.dart' show myApplicationsProvider;

// ── employer: applications for the selected job (by StateProvider) ────────
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
