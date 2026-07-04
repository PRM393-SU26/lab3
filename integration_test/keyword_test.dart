import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

/// Covers:
/// - Test Case 6: Keywords Navigation.
/// - Test Case 7: Keyword Details.
void main() {
  patrolTest(
    'Test Case 6 - Keywords tab shows keyword statistics and keyword list',
    ($) async {
      app.main();
      await signInWithMockAccount($);
      await searchTopic($, 'machine learning');

      await $.tap(find.byIcon(Icons.tag_outlined));
      await $.pumpAndSettle();

      // Verify keyword statistics and keyword list are displayed.
      expect($('Keyword Analysis'), findsOneWidget);
      expect($('Total Keywords'), findsOneWidget);
      expect($('Most Frequent Keywords'), findsOneWidget);
    },
  );

  patrolTest(
    'Test Case 7 - Opening a keyword shows its analysis',
    ($) async {
      app.main();
      await signInWithMockAccount($);
      await searchTopic($, 'machine learning');

      await $.tap(find.byIcon(Icons.tag_outlined));
      await $.pumpAndSettle();
      expect($('Most Frequent Keywords'), findsOneWidget);

      // Open the first keyword from the list.
      await $.tap(find.byType(InkWell).first);
      await $.pumpAndSettle(timeout: const Duration(seconds: 15));

      // Verify keyword analysis information is displayed: trend over time,
      // top contributing authors (ranked by publication count), related
      // journals and related publications.
      expect($('Publication Trend Over Time'), findsOneWidget);
      expect($('Top Contributing Authors'), findsOneWidget);
      expect($('Related Journals'), findsOneWidget);
      expect($('Related Publications'), findsOneWidget);
    },
  );
}
