import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/application_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'job_provider.dart';

// â”€â”€ seeker: all my applications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final myApplicationsProvider = StreamProvider<List<ApplicationModel>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final uid = authService.currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return FirestoreService.instance.getMyApplications(uid);
});

// â”€â”€ employer: applications for the selected job â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final jobApplicationsForSelectedProvider =
    StreamProvider<List<ApplicationModel>>((ref) {
  final job = ref.watch(selectedJobProvider);
  if (job == null) return const Stream.empty();
  return FirestoreService.instance.getApplicationsForJob(job.id);
});

// â”€â”€ admin: unverified users â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
final unverifiedUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirestoreService.instance.getUnverifiedUsers();
});
