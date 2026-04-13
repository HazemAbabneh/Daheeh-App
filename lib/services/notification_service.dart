import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles all local notifications for Dahih.
/// Primarily: anti-distraction alert when the user leaves during a Pomodoro.
class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Show immediately — used when the user leaves the app mid-session.
  Future<void> showAntiDistractionAlert() async {
    await _plugin.show(
      1,
      '🧠 دحيح ينتظرك!',
      'جلسة البوميدورو تعمل — عُد وأكمل ما بدأته. إنت أقوى من أي إلهاء.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'anti_distraction',
          'Anti-Distraction Alerts',
          channelDescription: 'Reminds you to return during a Pomodoro session',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'دحيح',
          color: const Color(0xFF7C3AED),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}
