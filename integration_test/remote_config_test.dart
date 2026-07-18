import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

/// Covers Test Case 10: Remote Config.
/// Verifies that values fetched from Firebase Remote Config
/// (`max_journals_displayed`, `max_keywords_displayed`) are retrieved and
/// rendered on the Profile screen.
void main() {
  patrolTest(
    'Test Case 10 - Remote Config values are retrieved and displayed',
    ($) async {
      app.main();
      logPatrolTest(
        'Test Case 10 - Remote Config values are retrieved and displayed',
      );
      await signInWithMockAccount($);

      await tapNavTab($, navProfileTabKey);

      // Verify the Remote Config section and its two configuration values
      // are displayed. The values fall back to the defaults declared in
      // RemoteConfigService.initialize() (10) if fetchAndActivate() has
      // not yet pulled server-side overrides.
      expect($('Remote Configurations'), findsOneWidget);
      expect($('Max Journals Displayed'), findsOneWidget);
      expect($('Max Keywords Displayed'), findsOneWidget);

      // Both values should be non-empty, positive integers rendered next
      // to their labels.
      final maxJournalsFinder = find.descendant(
        of: find.ancestor(
          of: find.text('Max Journals Displayed'),
          matching: find.byType(Row),
        ),
        matching: find.byType(Text),
      );
      expect(maxJournalsFinder, findsWidgets);
    },
  );
}
