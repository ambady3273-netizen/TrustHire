import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import 'auth_provider.dart';

// ── Current UID ────────────────────────────────────────────────
final _currentUidProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth.whenOrNull(data: (User? u) => u?.uid);
});

// ── Notifications stream ───────────────────────────────────────
final notificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final uid = ref.watch(_currentUidProvider);
  if (uid == null) return const Stream.empty();
  final fs = ref.watch(firestoreServiceProvider);
  return fs.getNotifications(uid);
});

// ── Unread count ───────────────────────────────────────────────
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(_currentUidProvider);
  if (uid == null) return Stream.value(0);
  final fs = ref.watch(firestoreServiceProvider);
  return fs.getUnreadCount(uid);
});

// ── Actions notifier ───────────────────────────────────────────
class NotificationsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  String? get _uid =>
      ref.read(authProvider).whenOrNull(data: (u) => u?.uid);

  Future<void> markRead(String notifId) async {
    await ref.read(firestoreServiceProvider).markNotificationRead(notifId);
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    await ref.read(firestoreServiceProvider).markAllNotificationsRead(uid);
  }

  Future<void> deleteOne(String notifId) async {
    await ref.read(firestoreServiceProvider).deleteNotification(notifId);
  }

  Future<void> clearAll() async {
    final uid = _uid;
    if (uid == null) return;
    await ref.read(firestoreServiceProvider).clearAllNotifications(uid);
  }
}

final notificationsNotifierProvider =
    AsyncNotifierProvider<NotificationsNotifier, void>(
  NotificationsNotifier.new,
);
