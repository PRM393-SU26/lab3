import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/work.dart';
import '../models/analytics.dart';
import '../utils/exceptions.dart';

/// Central service for all OpenAlex API calls.
///
/// Covers every functional requirement in Lab2:
///   4.1  searchWorks()           – Topic search + pagination
///   4.2  getWorkDetail()         – Publication detail view
///   4.3  getPublicationTrend()   – Publications grouped by year (chart)
///   4.4  getTopInfluentialPapers() – Ranked by citation count
///   4.5  getTopJournals()        – Journals by paper count
///   4.6  getTopAuthors()         – Authors by paper count
///   4.7  getDashboard()          – Aggregated summary dashboard
class OpenAlexService {
  static const String _baseUrl = 'https://api.openalex.org';

  /// Set your free API key from https://openalex.org/settings/api
  /// Leave empty to use the polite pool (slower, lower rate limit).
  static const String _apiKey = '';

  /// Your app contact email for the polite pool.
  /// Required when _apiKey is empty; improves rate limits.
  static const String _email = 'your-email@example.com';

  final http.Client _client;

  OpenAlexService({http.Client? client}) : _client = client ?? http.Client();

  // ─────────────────────────────────────────────
  // INTERNAL HELPERS
  // ─────────────────────────────────────────────

  Map<String, String> get _defaultParams {
    final params = <String, String>{};
    if (_apiKey.isNotEmpty) {
      params['api_key'] = _apiKey;
    } else {
      params['mailto'] = _email;
    }
    return params;
  }

  Uri _buildUri(String path, Map<String, String> queryParams) {
    final allParams = {..._defaultParams, ...queryParams};
    return Uri.parse('$_baseUrl$path').replace(queryParameters: allParams);
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> queryParams,
  ) async {
    final uri = _buildUri(path, queryParams);
    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 429) {
        throw RateLimitException();
      } else {
        throw OpenAlexException(
          'API error: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on OpenAlexException {
      rethrow;
    } catch (e) {
      throw NetworkException('Network error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // 4.1  TOPIC SEARCH
  // ─────────────────────────────────────────────

  /// Search publications by topic keyword.
  ///
  /// [topic]       – Free-text keyword (e.g. "machine learning")
  /// [page]        – 1-based page number for pagination
  /// [perPage]     – Results per page (max 100)
  /// [openAccessOnly] – Filter to open-access papers only
  /// [yearFrom] / [yearTo] – Optional year range filter
  ///
  /// Returns a tuple of (works, totalCount).
  Future<({List<Work> works, int total})> searchWorks({
    required String topic,
    int page = 1,
    int perPage = 20,
    bool openAccessOnly = false,
    int? yearFrom,
    int? yearTo,
  }) async {
    // Build filter string
    final filters = <String>['title_and_abstract.search:$topic'];

    if (openAccessOnly) filters.add('is_oa:true');

    if (yearFrom != null && yearTo != null) {
      filters.add('publication_year:$yearFrom-$yearTo');
    } else if (yearFrom != null) {
      filters.add('publication_year:>=$yearFrom');
    } else if (yearTo != null) {
      filters.add('publication_year:<=$yearTo');
    }

    final data = await _get('/works', {
      'filter': filters.join(','),
      'sort': 'cited_by_count:desc',
      'per_page': perPage.toString(),
      'page': page.toString(),
      'select':
          'id,title,publication_year,cited_by_count,doi,open_access,authorships,primary_location,type',
    });

    final results = (data['results'] as List? ?? [])
        .map((e) => Work.fromJson(e as Map<String, dynamic>))
        .toList();

    return (works: results, total: data['meta']?['count'] as int? ?? 0);
  }

  // ─────────────────────────────────────────────
  // 4.2  PUBLICATION DETAIL
  // ─────────────────────────────────────────────

  /// Fetch full details for a single work, including abstract.
  ///
  /// [workId] – OpenAlex ID (e.g. "W2741809807") or full URL.
  Future<Work> getWorkDetail(String workId) async {
    // Strip URL prefix if full URL was passed
    final id = workId.replaceFirst('https://openalex.org/', '');
    final data = await _get('/works/$id', {});
    return Work.fromJson(data);
  }

  // ─────────────────────────────────────────────
  // 4.3  PUBLICATION TREND (publications per year)
  // ─────────────────────────────────────────────

  /// Returns yearly publication counts for a topic.
  /// Used to render the bar/line chart on the Trend Analysis screen.
  Future<List<YearlyCount>> getPublicationTrend(String topic) async {
    final data = await _get('/works', {
      'filter': 'title_and_abstract.search:$topic',
      'group_by': 'publication_year',
      'per_page': '200', // fetch all year buckets
    });

    final groups = data['group_by'] as List? ?? [];

    final counts = groups
        .where((g) {
          final year = int.tryParse(g['key']?.toString() ?? '');
          return year != null && year >= 2000 && year <= DateTime.now().year;
        })
        .map((g) => YearlyCount(
              year: int.parse(g['key'].toString()),
              count: g['count'] as int,
            ))
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));

    return counts;
  }

  // ─────────────────────────────────────────────
  // 4.4  TOP INFLUENTIAL PAPERS
  // ─────────────────────────────────────────────

  /// Returns the top [limit] papers ranked by citation count.
  Future<List<Work>> getTopInfluentialPapers(
    String topic, {
    int limit = 10,
  }) async {
    final data = await _get('/works', {
      'filter': 'title_and_abstract.search:$topic',
      'sort': 'cited_by_count:desc',
      'per_page': limit.toString(),
      'select':
          'id,title,publication_year,cited_by_count,doi,open_access,authorships,primary_location',
    });

    return (data['results'] as List? ?? [])
        .map((e) => Work.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────
  // 4.5  TOP JOURNALS
  // ─────────────────────────────────────────────

  /// Returns the top [limit] journals by number of publications on a topic.
  Future<List<JournalStat>> getTopJournals(
    String topic, {
    int limit = 10,
  }) async {
    final data = await _get('/works', {
      'filter': 'title_and_abstract.search:$topic',
      'group_by': 'primary_location.source.id',
      'per_page': limit.toString(),
    });

    final groups = data['group_by'] as List? ?? [];
    return groups
        .where((g) =>
            g['key_display_name'] != null &&
            g['key_display_name'].toString().isNotEmpty)
        .map((g) => JournalStat(
              sourceId: g['key']?.toString(),
              displayName: g['key_display_name'].toString(),
              paperCount: g['count'] as int,
            ))
        .take(limit)
        .toList();
  }

  // ─────────────────────────────────────────────
  // 4.6  TOP AUTHORS
  // ─────────────────────────────────────────────

  /// Returns the top [limit] authors by publication count on a topic.
  Future<List<AuthorStat>> getTopAuthors(
    String topic, {
    int limit = 10,
  }) async {
    final data = await _get('/works', {
      'filter': 'title_and_abstract.search:$topic',
      'group_by': 'authorships.author.id',
      'per_page': limit.toString(),
    });

    final groups = data['group_by'] as List? ?? [];
    return groups
        .where((g) =>
            g['key_display_name'] != null &&
            g['key_display_name'].toString().isNotEmpty)
        .map((g) => AuthorStat(
              authorId: g['key']?.toString(),
              displayName: g['key_display_name'].toString(),
              paperCount: g['count'] as int,
            ))
        .take(limit)
        .toList();
  }

  // ─────────────────────────────────────────────
  // 4.7  RESEARCH DASHBOARD
  // ─────────────────────────────────────────────

  /// Aggregates data for the Research Dashboard screen.
  ///
  /// Makes 4 parallel API calls to minimise latency:
  ///   1. Meta count + avg citations (works list, 1 result)
  ///   2. Year trend  → peak year
  ///   3. Top journal
  ///   4. Top author  + most influential paper
  Future<TopicDashboard> getDashboard(String topic) async {
    // Run all calls concurrently
    final results = await Future.wait([
      _getDashboardMeta(topic),       // [0]
      getPublicationTrend(topic),     // [1]
      getTopJournals(topic, limit: 1), // [2]
      getTopAuthors(topic, limit: 1),  // [3]
      getTopInfluentialPapers(topic, limit: 1), // [4]
    ]);

    final meta = results[0] as _DashboardMeta;
    final trend = results[1] as List<YearlyCount>;
    final journals = results[2] as List<JournalStat>;
    final authors = results[3] as List<AuthorStat>;
    final topPapers = results[4] as List<Work>;

    // Find peak year
    YearlyCount? peakYear;
    for (final y in trend) {
      if (peakYear == null || y.count > peakYear.count) peakYear = y;
    }

    final topPaper = topPapers.isNotEmpty ? topPapers.first : null;

    return TopicDashboard(
      topic: topic,
      totalPublications: meta.total,
      avgCitationCount: meta.avgCitations,
      openAccessRatio: meta.openAccessRatio,
      peakYear: peakYear?.year,
      peakYearCount: peakYear?.count,
      topJournalName: journals.isNotEmpty ? journals.first.displayName : null,
      topAuthorName: authors.isNotEmpty ? authors.first.displayName : null,
      mostInfluentialTitle: topPaper?.title,
      mostInfluentialCitations: topPaper?.citedByCount,
    );
  }

  /// Private: fetch meta stats needed by the dashboard.
  Future<_DashboardMeta> _getDashboardMeta(String topic) async {
    // 1. Total count + top paper for avg citation approximation
    final worksData = await _get('/works', {
      'filter': 'title_and_abstract.search:$topic',
      'per_page': '100',
      'select': 'cited_by_count,open_access',
    });

    final total = worksData['meta']?['count'] ?? 0;
    final results = worksData['results'] as List? ?? [];

    // Approximate avg from first page (100 results)
    final citations = results
        .map((w) => (w['cited_by_count'] ?? 0) as int)
        .toList();
    final avg = citations.isEmpty
        ? 0.0
        : citations.reduce((a, b) => a + b) / citations.length;

    final oaCount = results
        .where((w) => w['open_access']?['is_oa'] == true)
        .length;
    final oaRatio = results.isEmpty ? 0.0 : oaCount / results.length;

    return _DashboardMeta(
      total: total as int,
      avgCitations: avg,
      openAccessRatio: oaRatio,
    );
  }

  void dispose() => _client.close();
}

/// Internal data class – not exported.
class _DashboardMeta {
  final int total;
  final double avgCitations;
  final double openAccessRatio;
  _DashboardMeta({
    required this.total,
    required this.avgCitations,
    required this.openAccessRatio,
  });
}
