import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:journal_trend/main.dart';
import 'package:journal_trend/models/work.dart';
import 'package:journal_trend/services/search_provider.dart';
import 'package:journal_trend/providers/reading_list_provider.dart';
import 'package:journal_trend/providers/settings_provider.dart';
import 'package:journal_trend/providers/auth_view_model.dart';

class MockAuthViewModel extends ChangeNotifier implements AuthViewModel {
  final AuthState _state = AuthState.authenticated;
  
  @override
  AuthState get state => _state;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  User? get currentUser => null;

  @override
  void checkAuthState() {}

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<bool> signInMock() async => true;
}

class MockReadingListProvider extends ChangeNotifier implements ReadingListProvider {
  @override
  List<Work> get items => [];

  @override
  bool get isLoaded => true;

  @override
  Future<void> load() async {}

  @override
  Future<void> toggle(Work work) async {}

  @override
  Future<void> remove(String workId) async {}

  @override
  bool contains(String workId) => false;
}

void main() {
  testWidgets('App renders SearchScreen successfully', (WidgetTester tester) async {
    final mockAuth = MockAuthViewModel();
    final mockReadingList = MockReadingListProvider();
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>(create: (_) => mockAuth),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider<ReadingListProvider>(create: (_) => mockReadingList),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const JournalTrendApp(),
      ),
    );

    // Verify that the title is rendered.
    expect(find.text('Journal Trend Analyzer'), findsOneWidget);
    expect(find.text('Discover Research Trends'), findsOneWidget);
  });

  testWidgets('Bottom Navigation Bar is rendered with 4 sections', (WidgetTester tester) async {
    final mockAuth = MockAuthViewModel();
    final mockReadingList = MockReadingListProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>(create: (_) => mockAuth),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider<ReadingListProvider>(create: (_) => mockReadingList),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const JournalTrendApp(),
      ),
    );

    // Find the NavigationBar
    expect(find.byType(NavigationBar), findsOneWidget);

    // Check tabs are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Journals'), findsOneWidget);
    expect(find.text('Keywords'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Tap Journals
    await tester.tap(find.text('Journals'));
    await tester.pump();

    // Verify Journals screen appears by searching for its title
    expect(find.text('Journal Analysis'), findsOneWidget);
  });
}

