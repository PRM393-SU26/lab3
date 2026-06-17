import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/work.dart';
import '../models/analytics.dart';
import '../models/author_detail.dart';
import '../services/openalex_service.dart';
import '../services/search_history_service.dart';
import '../utils/exceptions.dart';

enum LoadState { idle, loading, success, error }

enum WorkSortOption {
  citationsDesc('cited_by_count:desc', 'Citations (high → low)'),
  citationsAsc('cited_by_count:asc', 'Citations (low → high)'),
  yearDesc('publication_year:desc', 'Year (newest first)'),
  yearAsc('publication_year:asc', 'Year (oldest first)');

  const WorkSortOption(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// Manages all search + analytics state for the app.
/// Used with Provider – wrap MaterialApp with ChangeNotifierProvider.
class SearchProvider extends ChangeNotifier {
  final OpenAlexService _service;
  final SearchHistoryService _historyService = SearchHistoryService();

  SearchProvider({OpenAlexService? service})
      : _service = service ?? OpenAlexService() {
    loadHistory();
    loadGlobalTopAuthors();
  }

  // ── Shared ────────────────────────────────────
  String _currentTopic = '';
  String get currentTopic => _currentTopic;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── 4.1 Search ────────────────────────────────
  LoadState searchState = LoadState.idle;
  List<Work> works = [];
  int totalResults = 0;
  int _currentPage = 1;
  bool _openAccessOnly = false;
  int? _yearFrom;
  int? _yearTo;
  WorkSortOption _sortBy = WorkSortOption.citationsDesc;
  WorkSortOption get sortBy => _sortBy;
  bool get hasMore => works.length < totalResults;

  // ── NEW: Autocomplete ─────────────────────────
  List<String> suggestions = [];
  Timer? _debounce;

  // ── Search history ────────────────────────────
  List<String> searchHistory = [];

  // ── 4.3 Trend ─────────────────────────────────
  LoadState trendState = LoadState.idle;
  List<YearlyCount> yearlyTrend = [];

  // ── 4.4 Top papers ────────────────────────────
  LoadState topPapersState = LoadState.idle;
  List<Work> topPapers = [];

  // ── 4.5 Top journals ──────────────────────────
  LoadState journalsState = LoadState.idle;
  List<JournalStat> topJournals = [];

  // ── NEW: Source detail ────────────────────────
  LoadState sourceDetailState = LoadState.idle;
  SourceDetail? selectedSource;

  // ── 4.6 Top authors ───────────────────────────
  LoadState authorsState = LoadState.idle;
  List<AuthorStat> topAuthors = [];

  // ── NEW: Author detail ────────────────────────
  LoadState authorDetailState = LoadState.idle;
  AuthorDetail? selectedAuthor;

  // ── NEW: Global Top Authors ──────────────────
  LoadState globalTopAuthorsState = LoadState.idle;
  List<SimpleAuthor> globalTopAuthors = [];

  // ── NEW: Country breakdown ────────────────────
  LoadState countryState = LoadState.idle;
  List<CountryStat> countryBreakdown = [];
  LoadState countryMatrixState = LoadState.idle;
  CountryTopicMatrix countryMatrix = CountryTopicMatrix.empty();

  // ── NEW: OA breakdown ─────────────────────────
  LoadState oaBreakdownState = LoadState.idle;
  List<OaStat> oaBreakdown = [];

  // ── NEW: Related works ────────────────────────
  LoadState relatedWorksState = LoadState.idle;
  List<Work> relatedWorks = [];

  // ── 4.7 Dashboard ─────────────────────────────
  LoadState dashboardState = LoadState.idle;
  TopicDashboard? dashboard;

  // ── 4.2 Detail ────────────────────────────────
  LoadState detailState = LoadState.idle;
  Work? selectedWork;

  // ─────────────────────────────────────────────
  // PUBLIC METHODS
  // ─────────────────────────────────────────────

  /// Called when user submits a new search query.
  Future<void> search(String topic, {
    bool openAccessOnly = false,
    int? yearFrom,
    int? yearTo,
    WorkSortOption? sortBy,
  }) async {
    if (topic.trim().isEmpty) return;
    _currentTopic = topic.trim();
    _currentPage = 1;
    _openAccessOnly = openAccessOnly;
    _yearFrom = yearFrom;
    _yearTo = yearTo;
    if (sortBy != null) _sortBy = sortBy;
    works = [];
    totalResults = 0;
    suggestions = [];
    _setError(null);

    searchState = LoadState.loading;
    notifyListeners();

    try {
      final result = await _service.searchWorks(
        topic: _currentTopic,
        page: 1,
        openAccessOnly: openAccessOnly,
        yearFrom: yearFrom,
        yearTo: yearTo,
        sort: _sortBy.apiValue,
      );
      works = result.works;
      totalResults = result.total;
      searchState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      searchState = LoadState.error;
    }
    await _historyService.add(topic);
    searchHistory = await _historyService.getAll();
    notifyListeners();
  }

  /// Load next page (infinite scroll).
  Future<void> loadMore() async {
    if (!hasMore || searchState == LoadState.loading) return;
    _currentPage++;
    searchState = LoadState.loading;
    notifyListeners();

    try {
      final result = await _service.searchWorks(
        topic: _currentTopic,
        page: _currentPage,
        openAccessOnly: _openAccessOnly,
        yearFrom: _yearFrom,
        yearTo: _yearTo,
        sort: _sortBy.apiValue,
      );
      works.addAll(result.works);
      searchState = LoadState.success;
    } on OpenAlexException catch (e) {
      _currentPage--;
      _setError(e.message);
      searchState = LoadState.error;
    }
    notifyListeners();
  }

  /// NEW: Debounced autocomplete — call from TextField.onChanged.
  /// Usage: provider.fetchSuggestions(value)
  void fetchSuggestions(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      suggestions = [];
      notifyListeners();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        suggestions = await _service.autocomplete(query);
        notifyListeners();
      } catch (_) {
        suggestions = [];
        notifyListeners();
      }
    });
  }

  void clearSuggestions() {
    _debounce?.cancel();
    suggestions = [];
    notifyListeners();
  }

  Future<void> loadHistory() async {
    searchHistory = await _historyService.getAll();
    notifyListeners();
  }

  Future<void> removeFromHistory(String query) async {
    await _historyService.remove(query);
    searchHistory = await _historyService.getAll();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _historyService.clear();
    searchHistory = [];
    notifyListeners();
  }

  /// Reset all search and analytical states to return to the main discovery screen.
  void resetSearch() {
    _currentTopic = '';
    works = [];
    totalResults = 0;
    _currentPage = 1;
    _openAccessOnly = false;
    _yearFrom = null;
    _yearTo = null;
    searchState = LoadState.idle;
    suggestions = [];
    trendState = LoadState.idle;
    yearlyTrend = [];
    topPapersState = LoadState.idle;
    topPapers = [];
    journalsState = LoadState.idle;
    topJournals = [];
    sourceDetailState = LoadState.idle;
    selectedSource = null;
    authorsState = LoadState.idle;
    topAuthors = [];
    authorDetailState = LoadState.idle;
    selectedAuthor = null;
    countryState = LoadState.idle;
    countryBreakdown = [];
    countryMatrixState = LoadState.idle;
    countryMatrix = CountryTopicMatrix.empty();
    oaBreakdownState = LoadState.idle;
    oaBreakdown = [];
    relatedWorksState = LoadState.idle;
    relatedWorks = [];
    dashboardState = LoadState.idle;
    dashboard = null;
    detailState = LoadState.idle;
    selectedWork = null;
    _setError(null);
    notifyListeners();
  }

  /// Re-fetch results with a new sort order (resets pagination).
  Future<void> setSortBy(WorkSortOption sort) async {
    if (_sortBy == sort || _currentTopic.isEmpty) return;
    _sortBy = sort;
    _currentPage = 1;
    works = [];
    totalResults = 0;
    _setError(null);

    searchState = LoadState.loading;
    notifyListeners();

    try {
      final result = await _service.searchWorks(
        topic: _currentTopic,
        page: 1,
        openAccessOnly: _openAccessOnly,
        yearFrom: _yearFrom,
        yearTo: _yearTo,
        sort: _sortBy.apiValue,
      );
      works = result.works;
      totalResults = result.total;
      searchState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      searchState = LoadState.error;
    }
    notifyListeners();
  }

  /// Fetch full detail for a work (req 4.2).
  Future<void> loadWorkDetail(String workId) async {
    selectedWork = null;
    relatedWorks = [];
    detailState = LoadState.loading;
    notifyListeners();

    try {
      selectedWork = await _service.getWorkDetail(workId);
      detailState = LoadState.success;
      try {
        relatedWorks = await _service.getRelatedWorks(workId);
      } on OpenAlexException {
        relatedWorks = [];
      }
    } on OpenAlexException catch (e) {
      _setError(e.message);
      detailState = LoadState.error;
    }
    notifyListeners();
  }

  /// Load all analytics for the Trend Analysis screen (reqs 4.3–4.6 + country).
  Future<void> loadTrendAnalysis() async {
    if (_currentTopic.isEmpty) return;

    trendState = LoadState.loading;
    topPapersState = LoadState.loading;
    journalsState = LoadState.loading;
    authorsState = LoadState.loading;
    countryState = LoadState.loading;
    countryMatrixState = LoadState.loading;
    notifyListeners();

    await _loadTrend();
    await Future.wait([_loadTopPapers(), _loadTopJournals()]);
    await Future.wait([_loadTopAuthors(), _loadCountryBreakdown()]);
    await _loadCountryTopicMatrix();

    notifyListeners();
  }

  /// Load dashboard summary (req 4.7) + OA breakdown.
  Future<void> loadDashboard() async {
    if (_currentTopic.isEmpty) return;
    dashboardState = LoadState.loading;
    oaBreakdownState = LoadState.loading;
    notifyListeners();

    await _loadDashboardData();
    await _loadOaBreakdown();

    notifyListeners();
  }

  /// NEW: Load author profile. Call when user taps an author.
  Future<void> loadAuthorDetail(String authorId) async {
    selectedAuthor = null;
    authorDetailState = LoadState.loading;
    notifyListeners();

    try {
      selectedAuthor = await _service.getAuthorDetail(authorId);
      authorDetailState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      authorDetailState = LoadState.error;
    }
    notifyListeners();
  }

  /// NEW: Load global top 10 authors from OpenAlex.
  Future<void> loadGlobalTopAuthors() async {
    globalTopAuthorsState = LoadState.loading;
    notifyListeners();

    try {
      globalTopAuthors = await _service.getGlobalTopAuthors();
      globalTopAuthorsState = LoadState.success;
    } catch (e) {
      globalTopAuthorsState = LoadState.error;
      _setError(e.toString());
    }
    notifyListeners();
  }

  /// NEW: Load journal/source profile. Call when user taps a journal.
  Future<void> loadSourceDetail(String sourceId) async {
    selectedSource = null;
    sourceDetailState = LoadState.loading;
    notifyListeners();

    try {
      selectedSource = await _service.getSourceDetail(sourceId);
      sourceDetailState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      sourceDetailState = LoadState.error;
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────

  Future<void> _loadTrend() async {
    try {
      yearlyTrend = await _service.getPublicationTrend(_currentTopic);
      trendState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      trendState = LoadState.error;
    }
  }

  Future<void> _loadTopPapers() async {
    try {
      topPapers = await _service.getTopInfluentialPapers(_currentTopic);
      topPapersState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      topPapersState = LoadState.error;
    }
  }

  Future<void> _loadTopJournals() async {
    try {
      topJournals = await _service.getTopJournals(_currentTopic);
      journalsState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      journalsState = LoadState.error;
    }
  }

  Future<void> _loadTopAuthors() async {
    try {
      topAuthors = await _service.getTopAuthors(_currentTopic);
      authorsState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      authorsState = LoadState.error;
    }
  }

  Future<void> _loadCountryBreakdown() async {
    try {
      countryBreakdown = await _service.getCountryBreakdown(_currentTopic);
      countryState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      countryState = LoadState.error;
    }
  }

  Future<void> _loadCountryTopicMatrix() async {
    try {
      if (countryBreakdown.isEmpty) {
        countryMatrix = CountryTopicMatrix.empty();
        countryMatrixState = LoadState.success;
        return;
      }
      
      final topics = [
        _currentTopic,
        ...searchHistory.where((t) => t.isNotEmpty && t != _currentTopic),
      ].take(5).toList();

      countryMatrix = await _service.getCountryTopicMatrix(topics, countryBreakdown);
      countryMatrixState = LoadState.success;
    } catch (e) {
      _setError(e.toString());
      countryMatrixState = LoadState.error;
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      dashboard = await _service.getDashboard(_currentTopic);
      dashboardState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      dashboardState = LoadState.error;
    }
  }

  Future<void> _loadOaBreakdown() async {
    try {
      oaBreakdown = await _service.getOaBreakdown(_currentTopic);
      oaBreakdownState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      oaBreakdownState = LoadState.error;
    }
  }

  void _setError(String? msg) => _errorMessage = msg;

  @override
  void dispose() {
    _debounce?.cancel();
    _service.dispose();
    super.dispose();
  }
}
