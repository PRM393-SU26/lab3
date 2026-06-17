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
}
