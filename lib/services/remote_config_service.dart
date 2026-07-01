import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults(<String, dynamic>{
        'max_journals_displayed': 10,
        'max_keywords_displayed': 10,
      });

      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      if (kDebugMode) {
        print("Firebase Remote Config initialization failed: $e");
      }
    }
  }

  static int get maxJournalsDisplayed {
    return _remoteConfig.getInt('max_journals_displayed');
  }

  static int get maxKeywordsDisplayed {
    return _remoteConfig.getInt('max_keywords_displayed');
  }
}
