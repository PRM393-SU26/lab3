import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:journal_trend/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'test_helpers.dart';

/// Covers:
/// - Test Case 1: Google Sign-In (via the Mock/Developer path, which drives
///   the same FirebaseAuth session used by real Google Sign-In and lets the
///   flow run reliably on CI/emulators without a live Google account).
/// - Test Case 11: Logout.
void main() {
  patrolTest(
    'Test Case 1 - Sign-In navigates to Home screen',
    ($) async {
      app.main();
      await ensureLoginScreen($);

      // On the Login screen.
      expect($('Mock/Developer Sign-In'), findsOneWidget);

      // Perform sign-in.
      await $.tap($('Mock/Developer Sign-In'));
      await $.pumpAndSettle();

      // Verify successful navigation to the Home screen.
      expect($('Journal Trend Analyzer'), findsOneWidget);
      expect($('Search topic (e.g. machine learning)'), findsOneWidget);
    },
  );

  patrolTest(
    'Test Case 11 - Logout redirects to Login screen',
    ($) async {
      app.main();
      await signInWithMockAccount($);

      // Go to Profile tab.
      await $.tap(find.byIcon(Icons.person_outline));
      await $.pumpAndSettle();

      // Perform logout.
      expect($('Sign Out'), findsOneWidget);
      await $.tap($('Sign Out'));
      await $.pumpAndSettle();

      // Verify redirection to the Login screen.
      expect($('Mock/Developer Sign-In'), findsOneWidget);
    },
  );
}
