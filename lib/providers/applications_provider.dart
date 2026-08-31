import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/application_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'jobs_provider.dart';

// ── current uid ───────────────────────────────────────────────
final _uidProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.whenOrNull(data: (User? u) => u?.uid);
});

// ── seeker: all my applications ───────────────────────────────
final myApplicationsProvider = StreamProvider<List<ApplicationModel>>((ref) {
  final uid = ref.watch(_uidProvider);
  if (uid == null) return const Stream.empty();
  return FirestoreService.instance.getSeekerApplications(uid);
});

// ── employer: applications for the selected job ───────────────
final jobApplicationsProvider =
    StreamProvider<List<ApplicationModel>>((ref) {
  final job = ref.watch(selectedJobProvider);
  if (job == null) return const Stream.empty();
  return FirestoreService.instance.getJobApplications(job.id);
});

// ── actions notifier ──────────────────────────────────────────
class ApplicationsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  String? get _uid =>
      ref.read(authProvider).whenOrNull(data: (u) => u?.uid);

  /// Submit a new application; returns error string or null on success.
  Future<String?> apply({
    required String jobId,
    required String jobTitle,
    required String companyName,
    required String seekerName,
    required String seekerEmail,
    String? coverNote,
  }) async {
    final uid = _uid;
    if (uid == null) return 'Not logged in.';
    try {
      final already = await FirestoreService.instance
          .hasApplied(jobId: jobId, seekerId: uid);
      if (already) return 'You have already applied for this job.';

      final app = ApplicationModel(
        id: '',
        jobId: jobId,
        jobTitle: jobTitle,
        companyName: companyName,
        seekerId: uid,
        seekerName: seekerName,
        seekerEmail: seekerEmail,
        status: ApplicationStatus.pending,
        coverNote: coverNote,
        appliedAt: DateTime.now(),
      );
      await FirestoreService.instance.createApplication(app);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Employer: change application status.
  Future<void> updateStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    await FirestoreService.instance
        .updateApplicationStatus(applicationId, status);
  }
}

final applicationsNotifierProvider =
    AsyncNotifierProvider<ApplicationsNotifier, void>(
  ApplicationsNotifier.new,
);

// ── unverified users (admin) ──────────────────────────────────
final unverifiedUsersProvider = StreamProvider((ref) {
  return FirestoreService.instance.getUnverifiedUsers();
});
