import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static FirebaseRemoteConfig? get _remoteConfig {
    try {
      return FirebaseRemoteConfig.instance;
    } catch (_) {
      return null;
    }
  }

  /// Whether the last fetch actually pulled fresh values from the Firebase
  /// Console (true) or we're silently falling back to the hardcoded
  /// defaults below (false). Exposed so the UI (Profile screen) can show
  /// a clear "chưa đồng bộ" status instead of pretending 10/10 came from
  /// the server.
  static bool lastFetchSucceeded = false;
  static String? lastFetchError;

  static Future<void> initialize() async {
    try {
      final rc = _remoteConfig;
      if (rc == null) {
        lastFetchSucceeded = false;
        lastFetchError = "Firebase not initialized";
        return;
      }
      await rc.setDefaults(<String, dynamic>{
        'max_journals_displayed': 10,
        'max_keywords_displayed': 10,
        'max_pdf_size_kb': 512,
      });

      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // In debug builds, always fetch fresh values instead of respecting
        // the 1-hour cache — otherwise config changes made in the Firebase
        // Console won't show up while testing.
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      lastFetchSucceeded = await rc.fetchAndActivate();
      lastFetchError = null;
    } catch (e) {
      lastFetchSucceeded = false;
      lastFetchError = e.toString();
      if (kDebugMode) {
        print("Firebase Remote Config initialization failed: $e");
      }
    }
  }

  /// Manually re-fetch, e.g. from a "Refresh" button on the Profile screen.
  static Future<bool> refresh() async {
    try {
      final rc = _remoteConfig;
      if (rc == null) return false;
      final activated = await rc.fetchAndActivate();
      lastFetchSucceeded = true;
      lastFetchError = null;
      return activated;
    } catch (e) {
      lastFetchSucceeded = false;
      lastFetchError = e.toString();
      return false;
    }
  }

  static int get maxJournalsDisplayed {
    try {
      final rc = _remoteConfig;
      if (rc != null) {
        return rc.getInt('max_journals_displayed');
      }
    } catch (_) {}
    return 10;
  }

  static int get maxKeywordsDisplayed {
    try {
      final rc = _remoteConfig;
      if (rc != null) {
        return rc.getInt('max_keywords_displayed');
      }
    } catch (_) {}
    return 10;
  }

  static int get maxPdfSizeKb {
    try {
      final rc = _remoteConfig;
      if (rc != null) {
        return rc.getInt('max_pdf_size_kb');
      }
    } catch (_) {}
    return 512;
  }
}