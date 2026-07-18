import 'package:patrol/patrol.dart';
import 'package:journal_trend/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Covers Test Case 9: PDF Export.
/// Generates a dashboard report, uploads it to Firebase Storage, and
/// verifies the resulting download URL is shown on screen.
void main() {
  patrolTest(
    'Test Case 9 - Export generates a PDF and uploads it to Firebase Storage',
    ($) async {
      app.main();
      logPatrolTest(
        'Test Case 9 - Export generates a PDF and uploads it to Firebase Storage',
      );
      await signInWithMockAccount($);

      // A topic must be searched first so a dashboard exists to export.
      await searchTopic($, 'machine learning');

      await tapNavTab($, navProfileTabKey);

      expect($('Export & Upload PDF'), findsOneWidget);
      await $.tap($('Export & Upload PDF'));

      // PDF generation + Firebase Storage upload happens over the network,
      // so allow extra time before asserting on the result.
      await $.pumpAndSettle(timeout: const Duration(seconds: 30));

      // Verify successful upload: a Storage download URL is displayed.
      expect($('Successfully Uploaded to Storage:'), findsOneWidget);
    },
  );
}
