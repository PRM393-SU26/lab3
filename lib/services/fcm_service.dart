import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

    // 5. Listen for token refresh and update Firestore.
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
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
        // Persist the token to Firestore so Cloud Functions can target
        // this device when sending personalized notifications.
        if (token != null) {
          await _saveTokenToFirestore(token);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("FCM background setup failed: $e");
      }
    }
  }

  /// Saves the FCM token to `users/{uid}/fcm_tokens/{tokenHash}`.
  /// Uses the last 12 chars of the token as the document ID to keep it
  /// short but unique per device.  Also updates the user's `lastActiveAt`
  /// timestamp so the re-engagement Cloud Function knows when the user
  /// was last online.
  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final tokenId = token.length > 12
          ? token.substring(token.length - 12)
          : token;
      final platform = kIsWeb
          ? 'web'
          : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');

      final userRef = _firestore.collection('users').doc(user.uid);

      // Update the user document's last active timestamp.
      await userRef.set({
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Write or refresh the token document.
      await userRef.collection('fcm_tokens').doc(tokenId).set({
        'token': token,
        'platform': platform,
        'createdAt': FieldValue.serverTimestamp(),
        'lastRefreshedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('FCM token saved to Firestore for user ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save FCM token to Firestore: $e');
      }
    }
  }

  /// Call this on app resume or after login to refresh the token's
  /// `lastRefreshedAt` and the user's `lastActiveAt`.
  static Future<void> refreshToken() async {
    try {
      if (!kIsWeb) {
        final token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToFirestore(token);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM token refresh failed: $e');
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
