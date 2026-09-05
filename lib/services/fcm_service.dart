import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

// ─────────────────────────────────────────────────────────────
// Background message handler — must be a top-level function.
// ─────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

// ─────────────────────────────────────────────────────────────
// FCM Service
// ─────────────────────────────────────────────────────────────

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _fcm = FirebaseMessaging.instance;

  /// Call once from main() after Firebase.initializeApp().
  /// [ref] is only used during init to read the current uid.
  /// Token refresh uses the auth service directly to avoid a stale ref.
  Future<void> init({
    required WidgetRef ref,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler);

    // Request permission (iOS + Android 13+).
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Save the initial FCM token.
    await _saveToken(ref.read(authServiceProvider).currentUser?.uid);

    // Listen for token refreshes — use authService directly (no ref needed).
    final authService = ref.read(authServiceProvider);
    _fcm.onTokenRefresh.listen((token) {
      final uid = authService.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        FirestoreService.instance.saveFcmToken(uid, token);
      }
    });

    // ── Foreground messages ────────────────────────────────
    FirebaseMessaging.onMessage.listen((message) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final notification = message.notification;
      if (notification == null) return;

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title ?? '',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (notification.body != null)
                Text(notification.body!,
                    style: const TextStyle(fontSize: 12)),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _handleTap(message.data, navigatorKey),
          ),
        ),
      );
    });

    // ── Notification tap: app in background ───────────────
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleTap(message.data, navigatorKey);
    });

    // ── Notification tap: app was terminated ──────────────
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      _handleTap(initial.data, navigatorKey);
    }
  }

  Future<void> _saveToken(String? uid) async {
    if (uid == null || uid.isEmpty) return;
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await FirestoreService.instance.saveFcmToken(uid, token);
      }
    } catch (_) {}
  }

  /// Navigate to the actionRoute embedded in the notification payload.
  void _handleTap(
    Map<String, dynamic> data,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final route = data['actionRoute'] as String?;
    if (route == null || route.isEmpty) return;
    navigatorKey.currentState?.pushNamed(route);
  }
}
