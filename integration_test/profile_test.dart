import 'package:patrol/patrol.dart';
import 'package:journal_trend/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

/// Covers Test Case 8: Profile Navigation.
void main() {
  patrolTest('Test Case 8 - Profile tab shows user profile information', (
    $,
  ) async {
    app.main();
    logPatrolTest('Test Case 8 - Profile tab shows user profile information');
    await signInWithMockAccount($);

    await tapNavTab($, navProfileTabKey);

    // Verify user profile information is displayed: the developer
    // display name set during Mock Sign-In, plus the account controls
    // and Firebase demo sections that live on this screen.
    expect($('Developer Account'), findsOneWidget);
    expect($('Sign Out'), findsOneWidget);
    expect($('Remote Configurations'), findsOneWidget);
    expect($('Firebase Crashlytics Demo'), findsOneWidget);
    expect($('Notification Center'), findsOneWidget);
  });
}
