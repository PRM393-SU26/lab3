import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

/// Covers:
/// - Test Case 2: Topic Search.
/// - Test Case 3: Publication Details.
void main() {
  patrolTest(
    'Test Case 2 - Topic search displays publication results',
    ($) async {
      app.main();
      await signInWithMockAccount($);

      await searchTopic($, 'machine learning');

      // Verify publication results are displayed (title + citations count
      // are rendered for every result card in the "Paper" tab).
      expect($('Citations:'), findsWidgets);
    },
  );

  patrolTest(
    'Test Case 3 - Opening a publication shows its details',
    ($) async {
      app.main();
      await signInWithMockAccount($);
      await searchTopic($, 'machine learning');

      expect($('Citations:'), findsWidgets);

      // Open the first publication from the search results.
      await $.tap(find.byType(Card).first);
      await $.pumpAndSettle();

      // Verify publication information is displayed correctly:
      // authors, DOI (link) and abstract sections should be present.
      expect($('Authors'), findsOneWidget);
      expect($('Abstract'), findsOneWidget);
    },
  );
}
