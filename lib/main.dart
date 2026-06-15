import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/reading_list_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/search_screen.dart';
import 'services/search_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ReadingListProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const JournalTrendApp(),
    ),
  );
}

class JournalTrendApp extends StatefulWidget {
  const JournalTrendApp({super.key});

  @override
  State<JournalTrendApp> createState() => _JournalTrendAppState();
}

class _JournalTrendAppState extends State<JournalTrendApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReadingListProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'Journal Trend Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: settings.appBarColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SearchScreen(),
    );
  }
}
