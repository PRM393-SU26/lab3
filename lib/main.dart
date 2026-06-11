import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/search_screen.dart';
import 'services/search_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SearchProvider(),
      child: const JournalTrendApp(),
    ),
  );
}

class JournalTrendApp extends StatelessWidget {
  const JournalTrendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journal Trend Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F6E56),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SearchScreen(),
    );
  }
}
