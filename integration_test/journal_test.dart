import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

/// Covers:
/// - Test Case 4: Journals Navigation.
/// - Test Case 5: Journal Details.
void main() {
  patrolTest(
    'Test Case 4 - Journals tab shows journal statistics and journal list',
    ($) async {
      app.main();
      await signInWithMockAccount($);
      await searchTopic($, 'machine learning');

      await $.tap(find.byIcon(Icons.menu_book_outlined));
      await $.pumpAndSettle();

      // Verify journal statistics and journal list are displayed.
      expect($('Journal Analysis'), findsOneWidget);
      expect($('Total Journals'), findsOneWidget);
      expect($('Journal Rankings'), findsOneWidget);
    },
  );

  patrolTest(
    'Test Case 5 - Opening a journal shows its details',
    ($) async {
      app.main();
      await signInWithMockAccount($);
      await searchTopic($, 'machine learning');

      await $.tap(find.byIcon(Icons.menu_book_outlined));
      await $.pumpAndSettle();
      expect($('Journal Rankings'), findsOneWidget);

      // Open the first journal from the list.
      await $.tap(find.byType(InkWell).first);
      await $.pumpAndSettle(timeout: const Duration(seconds: 15));

      // Verify journal details are displayed correctly.
      expect($('Journal Metrics'), findsOneWidget);
      expect($('Works Count'), findsOneWidget);
      expect($('Total Citations'), findsOneWidget);
      expect($('Related Publications'), findsOneWidget);
    },
  );
}
