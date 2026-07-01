import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmNotification {
  final String title;
  final String body;
  final DateTime receivedAt;

  FcmNotification({
    required this.title,
    required this.body,
    required this.receivedAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
      };

  factory FcmNotification.fromJson(Map<String, dynamic> json) => FcmNotification(
        title: json['title'] ?? 'Notification',
        body: json['body'] ?? '',
        receivedAt: json['receivedAt'] != null
            ? DateTime.parse(json['receivedAt'])
            : DateTime.now(),
      );
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final List<FcmNotification> notifications = [];
  static ValueNotifier<int> notificationCount = ValueNotifier(0);

  static Future<void> initialize() async {
    // 1. Load stored notifications first
    await loadNotifications();

    // 2. Run FCM setup in background without blocking runApp()
    _setupFcmInBackground();

    // 3. Foreground messaging handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Alert';
      final body = message.notification?.body ?? 'New update received';
      _addNotification(title, body);
    });

    // 4. Background messaging handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Alert';
      final body = message.notification?.body ?? 'New update received';
      _addNotification(title, body);
    });
  }

  static Future<void> _setupFcmInBackground() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (!kIsWeb) {
        final token = await _messaging.getToken();
        if (kDebugMode) {
          print("FCM Token: $token");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("FCM background setup failed: $e");
      }
    }
  }

  static Future<void> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('fcm_notifications') ?? [];
      notifications.clear();
      for (final str in list) {
        try {
          notifications.add(FcmNotification.fromJson(jsonDecode(str)));
        } catch (_) {}
      }
      notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      notificationCount.value = notifications.length;
    } catch (_) {}
  }

  static Future<void> _addNotification(String title, String body) async {
    final notif = FcmNotification(
      title: title,
      body: body,
      receivedAt: DateTime.now(),
    );
    notifications.insert(0, notif);
    notificationCount.value = notifications.length;

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList('fcm_notifications', list);
    } catch (_) {}
  }

  static Future<void> clearNotifications() async {
    notifications.clear();
    notificationCount.value = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_notifications');
    } catch (_) {}
  }

  /// Helper to insert a mock notification for testing (useful when testing without play services)
  static Future<void> mockNotification(String title, String body) async {
    await _addNotification(title, body);
  }
}
