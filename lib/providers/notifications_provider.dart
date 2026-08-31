import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

// ──────────────────────────────────────────────────────────────
// Convenience: current Firebase UID (null when logged out)
// ──────────────────────────────────────────────────────────────
final _currentUidProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.whenOrNull(data: (User? u) => u?.uid);
});

// ──────────────────────────────────────────────────────────────
// Full notifications list stream
// ──────────────────────────────────────────────────────────────
final notificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final uid = ref.watch(_currentUidProvider);
  if (uid == null) return const Stream.empty();
  return FirestoreService.instance.getNotifications(uid);
});

// ──────────────────────────────────────────────────────────────
// Unread count — used by the bell badge in the app bar
// ──────────────────────────────────────────────────────────────
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(_currentUidProvider);
  if (uid == null) return Stream.value(0);
  return FirestoreService.instance.getUnreadCount(uid);
});

// ──────────────────────────────────────────────────────────────
// Actions notifier
// ──────────────────────────────────────────────────────────────
class NotificationsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  String? get _uid =>
      ref.read(authProvider).whenOrNull(data: (u) => u?.uid);

  /// Mark a single notification read and optionally deep-link.
  Future<void> markRead(String notifId) async {
    await FirestoreService.instance.markNotificationRead(notifId);
  }

  /// Mark every notification for this user as read.
  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    await FirestoreService.instance.markAllNotificationsRead(uid);
  }

  /// Remove one notification.
  Future<void> deleteOne(String notifId) async {
    await FirestoreService.instance.deleteNotification(notifId);
  }

  /// Remove all notifications for this user.
  Future<void> clearAll() async {
    final uid = _uid;
    if (uid == null) return;
    await FirestoreService.instance.clearAllNotifications(uid);
  }
}

final notificationsNotifierProvider =
    AsyncNotifierProvider<NotificationsNotifier, void>(
  NotificationsNotifier.new,
);
