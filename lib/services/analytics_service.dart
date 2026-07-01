import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logLogin() async {
    await _analytics.logEvent(name: 'login');
  }

  static Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
  }

  static Future<void> logSearchTopic(String keyword) async {
    await _analytics.logEvent(
      name: 'search_topic',
      parameters: {
        'keyword': keyword,
      },
    );
  }

  static Future<void> logViewPublication({
    required String title,
    required int? year,
  }) async {
    await _analytics.logEvent(
      name: 'view_publication',
      parameters: {
        'publication_title': title.length > 100 ? title.substring(0, 100) : title,
        'publication_year': year ?? 0,
      },
    );
  }

  static Future<void> logViewJournal(String journalName) async {
    await _analytics.logEvent(
      name: 'view_journal',
      parameters: {
        'journal_name': journalName.length > 100 ? journalName.substring(0, 100) : journalName,
      },
    );
  }

  static Future<void> logViewKeyword(String keyword) async {
    await _analytics.logEvent(
      name: 'view_keyword',
      parameters: {
        'keyword': keyword.length > 100 ? keyword.substring(0, 100) : keyword,
      },
    );
  }

  static Future<void> logExportPdf(String topic) async {
    await _analytics.logEvent(
      name: 'export_pdf',
      parameters: {
        'topic': topic,
      },
    );
  }
}
