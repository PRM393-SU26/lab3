import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Shared helpers reused across the Patrol E2E test suites.
///
/// Every `patrolTest` starts the app from scratch, so most scenarios need
/// to repeat "sign in" and, for several screens, "search a topic" before
/// the actual scenario under test can run. Centralizing that here keeps
/// each *_test.dart file focused on the behaviour it is verifying.

Future<void> ensureLoginScreen(PatrolIntegrationTester $) async {
  for (int i = 0; i < 50; i++) {
    await $.tester.pump(const Duration(milliseconds: 100));
    if (find.text('Mock/Developer Sign-In').evaluate().isNotEmpty) {
      return;
    }
    if (find.text('Journal Trend Analyzer').evaluate().isNotEmpty) {
      await FirebaseAuth.instance.signOut();
      await $.pumpAndSettle();
      return;
    }
  }
}

/// Launches the app (already started by the caller via `app.main()`) and
/// signs in using the Mock/Developer Sign-In button on the Login screen.
/// Leaves the app on the Home (Search) screen.
Future<void> signInWithMockAccount(PatrolIntegrationTester $) async {
  await ensureLoginScreen($);

  expect($('Mock/Developer Sign-In'), findsOneWidget);
  await $.tap($('Mock/Developer Sign-In'));
  await $.pumpAndSettle();

  expect($('Journal Trend Analyzer'), findsOneWidget);
}

/// Types [topic] into the Home search field and taps the Search button.
/// Waits for the network round-trip (search + trend + dashboard) to settle.
Future<void> searchTopic(PatrolIntegrationTester $, String topic) async {
  await $.enterText($(const Key('searchField')), topic);
  await $.tap($('Search'));

  // OpenAlex calls run over the network; give them time to resolve on top
  // of pumpAndSettle's own animation-settling loop.
  await $.pumpAndSettle(timeout: const Duration(seconds: 20));
}

/// Bottom-navigation destination keys, set in `MainScreen`.
///
/// Tests must navigate through these Keys and never through the
/// destination's `icon` — the Keywords icon is `Icons.label_outlined`
/// (not `Icons.tag_outlined`), and the Profile destination's icon swaps
/// from `Icons.person_outline` to a `CircleAvatar` once the signed-in user
/// has a `photoURL` (which Mock/Developer Sign-In always sets).
const Key navHomeTabKey = Key('navHomeTab');
const Key navJournalsTabKey = Key('navJournalsTab');
const Key navKeywordsTabKey = Key('navKeywordsTab');
const Key navProfileTabKey = Key('navProfileTab');

/// Taps a bottom navigation bar destination by its stable [Key] and waits
/// for the destination screen to settle.
Future<void> tapNavTab(PatrolIntegrationTester $, Key tabKey) async {
  await $.tap($(tabKey));
  await $.pumpAndSettle();
}

void logPatrolTest(String testName) {
  print('[PATROL] running $testName');
}
