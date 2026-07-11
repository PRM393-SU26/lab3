import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'package:journal_trend/providers/reading_list_provider.dart';
import 'package:journal_trend/providers/settings_provider.dart';
import 'package:journal_trend/providers/auth_view_model.dart';
import 'package:journal_trend/screens/main_screen.dart';
import 'package:journal_trend/screens/search_screen.dart';
import 'package:journal_trend/screens/login_screen.dart';
import 'package:journal_trend/services/search_provider.dart';
import 'package:journal_trend/services/fcm_service.dart';
import 'package:journal_trend/services/remote_config_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:journal_trend/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Firebase Crashlytics setup ────────────────────────────────
  // Without this, uncaught Flutter/Dart errors never reach Crashlytics —
  // only errors manually passed to recordError() would show up, and
  // FirebaseCrashlytics.instance.crash() would crash the app locally
  // without necessarily being flagged for upload on next launch.
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    // Ensure crash reports are actually collected/uploaded, including in
    // debug builds (Crashlytics can otherwise default to disabled locally).
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }
  
  // Initialize Google Sign In exactly once at startup
  try {
    await GoogleSignIn.instance.initialize(
      serverClientId: DefaultFirebaseOptions.currentPlatform.androidClientId,
    );
  } catch (e) {
    debugPrint("Google Sign In init failed: $e");
  }

  // Initialize Lab3 Firebase backend configurations
  await RemoteConfigService.initialize();
  await FcmService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ReadingListProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
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
      home: Consumer2<AuthViewModel, SearchProvider>(
        builder: (context, authProvider, searchProvider, child) {
          if (authProvider.state == AuthState.initial && !searchProvider.isDeveloperMode) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (authProvider.state == AuthState.authenticated || searchProvider.isDeveloperMode) {
            return const MainScreen();
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}