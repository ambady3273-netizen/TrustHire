import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─────────────────────────────────────────────────────────────
// LocalNotificationService
//
// Shows OS-level popup notifications (like WhatsApp) without
// needing Firebase Cloud Functions or the Blaze plan.
//
// Usage:
//   await LocalNotificationService.instance.init();
//   await LocalNotificationService.instance.show(
//     title: 'New Applicant',
//     body:  'John applied for Driver role.',
//   );
// ─────────────────────────────────────────────────────────────

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance =
      LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _idCounter = 0;

  // ── Android notification channel ──────────────────────────
  static const _channelId   = 'trusthire_main';
  static const _channelName = 'TrustHire Notifications';
  static const _channelDesc = 'Job alerts, applications, and messages';

  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.high,   // heads-up banner
    priority:   Priority.high,
    icon:       '@mipmap/ic_launcher',
    playSound:  true,
    enableVibration: true,
  );

  static const _notifDetails = NotificationDetails(
    android: _androidDetails,
  );

  // ── init() — call once from main() ────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    // Create the high-importance channel on Android 8+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );

    // Request permission on Android 13+
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('[LocalNotif] Initialized.');
  }

  // ── show() — call from anywhere to pop a notification ─────
  Future<void> show({
    required String title,
    required String body,
    String?  payload, // optional route, e.g. '/myApplications'
  }) async {
    if (!_initialized) await init();
    final id = _idCounter++ % 2147483647; // keep within int32
    await _plugin.show(id, title, body, _notifDetails, payload: payload);
    debugPrint('[LocalNotif] Showed #$id — $title');
  }

  // ── Tap handler — navigated by the app via navigatorKey ───
  void _onTap(NotificationResponse response) {
    // Navigation is handled in main.dart via the navigatorKey.
    // Payload contains the route string set in show().
    debugPrint('[LocalNotif] Tapped — payload: ${response.payload}');
  }
}
