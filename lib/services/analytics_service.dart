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

  /// Logs when the user taps a personalized "Recommend for You" (For You)
  /// suggestion. [type] identifies which screen it came from
  /// ('topic', 'journal', 'keyword', 'author') and [value] is the label
  /// the user tapped.
  static Future<void> logForYouTap({
    required String type,
    required String value,
  }) async {
    await _analytics.logEvent(
      name: 'for_you_suggestion_tap',
      parameters: {
        'suggestion_type': type,
        'suggestion_value': value.length > 100 ? value.substring(0, 100) : value,
      },
    );
  }

  // ─────────────────────────────────────────────
  // NOTIFICATION-RELATED ANALYTICS EVENTS
  // ─────────────────────────────────────────────

  /// Logs when the user views the trend chart for a topic.
  static Future<void> logViewTrendChart(String topic) async {
    await _analytics.logEvent(
      name: 'view_trend_chart',
      parameters: {
        'topic': topic.length > 100 ? topic.substring(0, 100) : topic,
      },
    );
  }

  /// Logs when the user opens the research dashboard for a topic.
  static Future<void> logViewDashboard(String topic) async {
    await _analytics.logEvent(
      name: 'view_dashboard',
      parameters: {
        'topic': topic.length > 100 ? topic.substring(0, 100) : topic,
      },
    );
  }

  /// Logs when the user views an author's detail page.
  static Future<void> logViewAuthorDetail({
    required String authorId,
    required String authorName,
  }) async {
    await _analytics.logEvent(
      name: 'view_author_detail',
      parameters: {
        'author_id': authorId.length > 100 ? authorId.substring(0, 100) : authorId,
        'author_name': authorName.length > 100 ? authorName.substring(0, 100) : authorName,
      },
    );
  }

  /// Logs when the user views a journal/source detail page.
  static Future<void> logViewSourceDetail({
    required String sourceId,
    required String sourceName,
  }) async {
    await _analytics.logEvent(
      name: 'view_source_detail',
      parameters: {
        'source_id': sourceId.length > 100 ? sourceId.substring(0, 100) : sourceId,
        'source_name': sourceName.length > 100 ? sourceName.substring(0, 100) : sourceName,
      },
    );
  }

  /// Logs when a push notification is tapped / opened by the user.
  static Future<void> logNotificationTapped({
    required String type,
    String? topic,
  }) async {
    await _analytics.logEvent(
      name: 'notification_tapped',
      parameters: {
        'notification_type': type,
        if (topic != null)
          'topic': topic.length > 100 ? topic.substring(0, 100) : topic,
      },
    );
  }

  /// Logs when a push notification is dismissed without opening.
  static Future<void> logNotificationDismissed({
    required String type,
    String? topic,
  }) async {
    await _analytics.logEvent(
      name: 'notification_dismissed',
      parameters: {
        'notification_type': type,
        if (topic != null)
          'topic': topic.length > 100 ? topic.substring(0, 100) : topic,
      },
    );
  }

  /// Logs when the user changes a notification preference toggle.
  static Future<void> logNotificationPrefsChanged({
    required String setting,
    required bool newValue,
  }) async {
    await _analytics.logEvent(
      name: 'notification_prefs_changed',
      parameters: {
        'setting': setting,
        'new_value': newValue ? 'true' : 'false',
      },
    );
  }
}