import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend/main.dart' as app;

void main() {
  patrolTest(
    'E2E flow test: login, search topic, and navigate bottom navigation bar',
    ($) async {
      // 1. Start app
      app.main();
      await $.pumpAndSettle();

      // 2. We should be on the Login screen. Verify there is a Mock Sign-In button
      expect($('Mock/Developer Sign-In'), findsOneWidget);
      
      // 3. Tap Mock Sign-In
      await $.tap($('Mock/Developer Sign-In'));
      await $.pumpAndSettle();

      // 4. Verify we are logged in and see Search screen
      expect($('Journal Trend Analyzer'), findsOneWidget);

      // 5. Search a topic (e.g. machine learning)
      await $.enterText($('Search topic (e.g. machine learning)'), 'machine learning');
      await $.tap($('Search'));
      await $.pumpAndSettle();

      // 6. Verify results are loaded
      expect($('Citations:'), findsWidgets);

      // 7. Click Journals tab on Bottom Nav
      await $.tap(find.byIcon(Icons.menu_book_outlined));
      await $.pumpAndSettle();

      // 8. Verify Journals tab loads content
      expect($('Journal Analysis'), findsOneWidget);
      expect($('Total Journals'), findsOneWidget);

      // 9. Click Keywords tab on Bottom Nav
      await $.tap(find.byIcon(Icons.tag_outlined));
      await $.pumpAndSettle();

      // 10. Verify Keywords tab loads content
      expect($('Keyword Analysis'), findsOneWidget);

      // 11. Click Profile tab
      await $.tap(find.byIcon(Icons.person_outline));
      await $.pumpAndSettle();

      // 12. Verify Profile tab loads content and click Sign Out
      expect($('Remote Configurations'), findsOneWidget);
      await $.tap($('Sign Out'));
      await $.pumpAndSettle();

      // 13. Verify we are back to LoginScreen
      expect($('Mock/Developer Sign-In'), findsOneWidget);
    },
  );
}
