import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:journal_trend/main.dart';
import 'package:journal_trend/services/search_provider.dart';
import 'package:journal_trend/providers/reading_list_provider.dart';
import 'package:journal_trend/providers/settings_provider.dart';

void main() {
  testWidgets('App renders SearchScreen successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => ReadingListProvider()),
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
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SearchProvider()),
          ChangeNotifierProvider(create: (_) => ReadingListProvider()),
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

    // Tap Journals (disabled tab)
    await tester.tap(find.text('Journals'));
    await tester.pump();

    // Verify snackbar appears saying it is disabled
    expect(find.text('Journals section is currently disabled'), findsOneWidget);
  });
}
