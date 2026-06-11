import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/work.dart';
import '../models/analytics.dart';
import '../models/author_detail.dart';
import '../utils/exceptions.dart';

/// Central service for all OpenAlex API calls.
///
/// Covers every functional requirement in Lab2:
///   4.1  searchWorks()              – Topic search + pagination
///   4.2  getWorkDetail()            – Publication detail view
///   4.3  getPublicationTrend()      – Publications grouped by year (chart)
///   4.4  getTopInfluentialPapers()  – Ranked by citation count
///   4.5  getTopJournals()           – Journals by paper count
///   4.6  getTopAuthors()            – Authors by paper count
///   4.7  getDashboard()             – Aggregated summary dashboard
///
/// NEW (non-breaking additions):
///   autocomplete()        – Search-as-you-type topic suggestions
///   getAuthorDetail()     – Author profile (h-index, works_count, institution)
///   getSourceDetail()     – Journal profile (h-index, works_count, is_in_doaj)
///   getRelatedWorks()     – Papers that cite a given work
///   getWorksByCountry()   – group_by country_code for TrendScreen
///   getOaBreakdown()      – group_by oa_status for Dashboard pie chart
class OpenAlexService {
  static const String _baseUrl = 'https://api.openalex.org';

  /// Set your free API key from https://openalex.org/settings/api
  /// Leave empty to use the polite pool (slower, lower rate limit).
  static const String _apiKey = '';

  /// Your app contact email for the polite pool.
  static const String _email = 'your-email@example.com';

  static const Duration _requestTimeout = Duration(seconds: 45);
  static const int _maxAttempts = 3;

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

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> queryParams,
  ) async {
    final uri = _buildUri(path, queryParams);

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      if (attempt > 1) {
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }

      try {
        final response = await _client.get(uri).timeout(_requestTimeout);

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        if (response.statusCode == 429) {
          if (attempt < _maxAttempts) continue;
          throw RateLimitException();
        }
        throw OpenAlexException(
          'API error: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      } on OpenAlexException catch (e) {
        if (e is RateLimitException && attempt < _maxAttempts) continue;
        rethrow;
      } on TimeoutException {
        if (attempt < _maxAttempts) continue;
        throw NetworkException(
          'Request timed out. OpenAlex may be busy — please try again.',
        );
      } catch (e) {
        if (attempt < _maxAttempts) continue;
        throw NetworkException(
          'Unable to reach OpenAlex. Check your connection and try again.',
        );
      }
    }

    throw NetworkException(
      'Request failed after $_maxAttempts attempts. Please try again.',
    );
  }

  // ─────────────────────────────────────────────
  // 4.1  TOPIC SEARCH
  // ─────────────────────────────────────────────

  /// Search publications by topic keyword.
  /// NOTE: uses `search=` param (replaces deprecated title_and_abstract.search filter)
  Future<({List<Work> works, int total})> searchWorks({
    required String topic,
    int page = 1,
    int perPage = 20,
    bool openAccessOnly = false,
    int? yearFrom,
    int? yearTo,
    String sort = 'cited_by_count:desc',
  }) async {
    final filters = <String>[];
    if (openAccessOnly) filters.add('is_oa:true');
    if (yearFrom != null && yearTo != null) {
      filters.add('publication_year:$yearFrom-$yearTo');
    } else if (yearFrom != null) {
      filters.add('publication_year:>=$yearFrom');
    } else if (yearTo != null) {
      filters.add('publication_year:<=$yearTo');
    }

    final params = <String, String>{
      'search': topic,
      'sort': sort,
      'per_page': perPage.toString(),
      'page': page.toString(),
      'select':
          'id,title,publication_year,cited_by_count,doi,open_access,authorships,primary_location,type',
    };
    if (filters.isNotEmpty) params['filter'] = filters.join(',');

    final data = await _get('/works', params);

    final results = (data['results'] as List? ?? [])
        .map((e) => Work.fromJson(e as Map<String, dynamic>))
        .toList();

    return (works: results, total: _asInt(data['meta']?['count']));
  }

  // ─────────────────────────────────────────────
  // NEW: AUTOCOMPLETE (search-as-you-type)
  // ─────────────────────────────────────────────

  /// Returns up to 10 quick suggestions for a partial topic query.
  /// Call this on TextField onChanged (debounced ~300ms).
  Future<List<String>> autocomplete(String query) async {
    if (query.trim().isEmpty) return [];
    final data = await _get('/autocomplete/works', {'q': query});
    final results = data['results'] as List? ?? [];
    return results
        .map((r) => r['display_name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ─────────────────────────────────────────────
  // 4.2  PUBLICATION DETAIL
  // ─────────────────────────────────────────────

  Future<Work> getWorkDetail(String workId) async {
    final id = workId.replaceFirst('https://openalex.org/', '');
    final data = await _get('/works/$id', {});
    return Work.fromJson(data);
  }

  // ─────────────────────────────────────────────
  // NEW: RELATED WORKS (papers citing a work)
  // ─────────────────────────────────────────────

  /// Returns papers that cite [workId]. Use in PublicationDetail screen.
  Future<List<Work>> getRelatedWorks(String workId, {int limit = 5}) async {
    final id = workId.replaceFirst('https://openalex.org/', '');
    final data = await _get('/works', {
      'filter': 'cites:$id',
      'sort': 'cited_by_count:desc',
      'per_page': limit.toString(),
      'select':
          'id,title,publication_year,cited_by_count,open_access,authorships,primary_location',
    });
    return (data['results'] as List? ?? [])
        .map((e) => Work.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────
  // 4.3  PUBLICATION TREND
  // ─────────────────────────────────────────────

  Future<List<YearlyCount>> getPublicationTrend(String topic) async {
    final data = await _get('/works', {
      'search': topic,
      'group_by': 'publication_year',
      'per_page': '200',
    });

    final groups = data['group_by'] as List? ?? [];
    final counts = groups
        .where((g) {
          final year = int.tryParse(g['key']?.toString() ?? '');
          return year != null && year <= DateTime.now().year;
        })
        .map((g) => YearlyCount(
              year: int.parse(g['key'].toString()),
              count: _asInt(g['count']),
            ))
        .toList()
      ..sort((a, b) => a.year.compareTo(b.year));

    return counts;
  }

  // ─────────────────────────────────────────────
  // NEW: COUNTRY BREAKDOWN
  // ─────────────────────────────────────────────

  /// Returns publication count by country for a topic.
  /// Use for a "Countries" tab in TrendScreen.
  Future<List<CountryStat>> getCountryBreakdown(
    String topic, {
    int limit = 15,
  }) async {
    final data = await _get('/works', {
      'search': topic,
      'group_by': 'authorships.institutions.country_code',
      'per_page': limit.toString(),
    });

    final groups = data['group_by'] as List? ?? [];
    return groups
        .where((g) =>
            g['key_display_name'] != null &&
            g['key_display_name'].toString().isNotEmpty)
        .map((g) => CountryStat(
              countryCode: g['key']?.toString() ?? '',
              displayName: g['key_display_name'].toString(),
              paperCount: _asInt(g['count']),
            ))
        .take(limit)
        .toList();
  }

  // ─────────────────────────────────────────────
  // NEW: OA STATUS BREAKDOWN
  // ─────────────────────────────────────────────

  /// Returns breakdown by OA status: gold, green, hybrid, bronze, closed.
  /// Use in Dashboard for pie/donut chart.
  Future<List<OaStat>> getOaBreakdown(String topic) async {
    final data = await _get('/works', {
      'search': topic,
      'group_by': 'oa_status',
      'per_page': '10',
    });

    final groups = data['group_by'] as List? ?? [];
    return groups
        .map((g) => OaStat(
              status: g['key']?.toString() ?? 'unknown',
              count: _asInt(g['count']),
            ))
        .toList();
  }

  // ─────────────────────────────────────────────
  // 4.4  TOP INFLUENTIAL PAPERS
  // ─────────────────────────────────────────────

  Future<List<Work>> getTopInfluentialPapers(
    String topic, {
    int limit = 10,
  }) async {
    final data = await _get('/works', {
      'search': topic,
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

  Future<List<JournalStat>> getTopJournals(
    String topic, {
    int limit = 10,
  }) async {
    final data = await _get('/works', {
      'search': topic,
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
              paperCount: _asInt(g['count']),
            ))
        .take(limit)
        .toList();
  }

  // ─────────────────────────────────────────────
  // NEW: SOURCE (JOURNAL) DETAIL
  // ─────────────────────────────────────────────

  /// Returns journal profile: works_count, cited_by_count, h_index, is_in_doaj.
  /// Use when user taps a journal in Top Journals list.
  Future<SourceDetail> getSourceDetail(String sourceId) async {
    final id = sourceId.replaceFirst('https://openalex.org/', '');
    final data = await _get('/sources/$id', {});
    return SourceDetail.fromJson(data);
  }

  // ─────────────────────────────────────────────
  // 4.6  TOP AUTHORS
  // ─────────────────────────────────────────────

  Future<List<AuthorStat>> getTopAuthors(
    String topic, {
    int limit = 10,
  }) async {
    final data = await _get('/works', {
      'search': topic,
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
              paperCount: _asInt(g['count']),
            ))
        .take(limit)
        .toList();
  }

  // ─────────────────────────────────────────────
  // NEW: AUTHOR DETAIL
  // ─────────────────────────────────────────────

  /// Returns author profile: h_index, works_count, cited_by_count, institution.
  /// Use when user taps an author in Top Authors list.
  Future<AuthorDetail> getAuthorDetail(String authorId) async {
    final id = authorId.replaceFirst('https://openalex.org/', '');
    final data = await _get('/authors/$id', {});
    return AuthorDetail.fromJson(data);
  }

  // ─────────────────────────────────────────────
  // 4.7  RESEARCH DASHBOARD
  // ─────────────────────────────────────────────

  Future<TopicDashboard> getDashboard(String topic) async {
    // Sequential calls avoid rate-limit timeouts from burst traffic.
    final meta = await _getDashboardMeta(topic);
    final trend = await getPublicationTrend(topic);
    final journals = await getTopJournals(topic, limit: 1);
    final authors = await getTopAuthors(topic, limit: 1);
    final topPapers = await getTopInfluentialPapers(topic, limit: 1);

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

  Future<_DashboardMeta> _getDashboardMeta(String topic) async {
    final worksData = await _get('/works', {
      'search': topic,
      'per_page': '100',
      'select': 'cited_by_count,open_access',
    });

    final total = worksData['meta']?['count'] ?? 0;
    final results = worksData['results'] as List? ?? [];

    final citations = results
        .map((w) => _asInt(w['cited_by_count']))
        .toList();
    final avg = citations.isEmpty
        ? 0.0
        : citations.reduce((a, b) => a + b) / citations.length;

    final oaCount = results
        .where((w) => w['open_access']?['is_oa'] == true)
        .length;
    final oaRatio = results.isEmpty ? 0.0 : oaCount / results.length;

    return _DashboardMeta(
      total: _asInt(total),
      avgCitations: avg,
      openAccessRatio: oaRatio,
    );
  }

  void dispose() => _client.close();
}

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
