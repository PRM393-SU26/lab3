import 'package:patrol/patrol.dart';
import 'package:journal_trend/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Covers:
/// - Test Case 1: Google Sign-In (via the Mock/Developer path, which drives
///   the same FirebaseAuth session used by real Google Sign-In and lets the
///   flow run reliably on CI/emulators without a live Google account).
/// - Test Case 11: Logout.
void main() {
  patrolTest('Test Case 1 - Sign-In navigates to Home screen', ($) async {
    app.main();
    logPatrolTest('Test Case 1 - Sign-In navigates to Home screen');
    await ensureLoginScreen($);

    // On the Login screen.
    expect($('Mock/Developer Sign-In'), findsOneWidget);

    // Perform sign-in.
    await $.tap($('Mock/Developer Sign-In'));
    await $.pumpAndSettle();

    // Verify successful navigation to the Home screen.
    expect($('Journal Trend Analyzer'), findsOneWidget);
    expect($('Search topic (e.g. machine learning)'), findsOneWidget);
  });

  patrolTest('Test Case 11 - Logout redirects to Login screen', ($) async {
    app.main();
    logPatrolTest('Test Case 11 - Logout redirects to Login screen');
    await signInWithMockAccount($);

    // Go to Profile tab (navigate by key: the icon here swaps to the
    // signed-in user's avatar photo, so it can't be used as a finder).
    await tapNavTab($, navProfileTabKey);

    // Perform logout.
    expect($('Sign Out'), findsOneWidget);
    await $.tap($('Sign Out'));
    await $.pumpAndSettle();

    // Verify redirection to the Login screen.
    expect($('Mock/Developer Sign-In'), findsOneWidget);
  });
}
