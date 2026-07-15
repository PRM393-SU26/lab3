import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Manages user notification preferences stored in Firestore at
/// `users/{uid}.notification_prefs`.
///
/// Provides both read and write access so the settings screen can
/// display current values and persist changes, while Cloud Functions
/// read the same document to decide whether to send notifications.
class NotificationPrefsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Default preferences for new users or when Firestore read fails.
  static const Map<String, dynamic> defaults = {
    'enabled': true,
    'trending_topics': true,
    'interest_updates': true,
    'weekly_digest': true,
    're_engagement': true,
    'quiet_hours_start': 22, // 10 PM
    'quiet_hours_end': 7, // 7 AM
    'max_per_day': 3,
  };

  /// Returns the user's current notification preferences, merged with
  /// defaults for any missing fields.
  static Future<Map<String, dynamic>> getPrefs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Map<String, dynamic>.from(defaults);

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data == null) return Map<String, dynamic>.from(defaults);

      final stored =
          data['notification_prefs'] as Map<String, dynamic>? ?? {};

      // Merge defaults with stored values so new fields are always present.
      return {...defaults, ...stored};
    } catch (e) {
      if (kDebugMode) {
        print('NotificationPrefsService.getPrefs failed: $e');
      }
      return Map<String, dynamic>.from(defaults);
    }
  }

  /// Persists a single preference change. Uses `set(merge: true)` to
  /// avoid overwriting unrelated user document fields.
  static Future<void> updatePref(String key, dynamic value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'notification_prefs': {key: value},
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('NotificationPrefsService.updatePref failed: $e');
      }
      rethrow;
    }
  }

  /// Persists multiple preference changes at once.
  static Future<void> updatePrefs(Map<String, dynamic> prefs) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'notification_prefs': prefs,
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('NotificationPrefsService.updatePrefs failed: $e');
      }
      rethrow;
    }
  }

  /// Listens to real-time changes in notification preferences.
  /// Useful if preferences are changed from another device.
  static Stream<Map<String, dynamic>> prefsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(Map<String, dynamic>.from(defaults));

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snap) {
      final data = snap.data();
      if (data == null) return Map<String, dynamic>.from(defaults);
      final stored =
          data['notification_prefs'] as Map<String, dynamic>? ?? {};
      return {...defaults, ...stored};
    });
  }
}
