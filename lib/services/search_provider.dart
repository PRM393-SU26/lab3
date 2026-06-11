import 'package:flutter/foundation.dart';
import '../models/work.dart';
import '../models/analytics.dart';
import '../services/openalex_service.dart';
import '../utils/exceptions.dart';

enum LoadState { idle, loading, success, error }

/// Manages all search + analytics state for the app.
/// Used with Provider – wrap MaterialApp with ChangeNotifierProvider.
class SearchProvider extends ChangeNotifier {
  final OpenAlexService _service;

  SearchProvider({OpenAlexService? service})
      : _service = service ?? OpenAlexService();

  // ── Shared state ──────────────────────────────
  String _currentTopic = '';
  String get currentTopic => _currentTopic;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── 4.1 Search ────────────────────────────────
  LoadState searchState = LoadState.idle;
  List<Work> works = [];
  int totalResults = 0;
  int _currentPage = 1;
  bool get hasMore => works.length < totalResults;

  // ── 4.3 Trend ─────────────────────────────────
  LoadState trendState = LoadState.idle;
  List<YearlyCount> yearlyTrend = [];

  // ── 4.4 Top papers ────────────────────────────
  LoadState topPapersState = LoadState.idle;
  List<Work> topPapers = [];

  // ── 4.5 Top journals ──────────────────────────
  LoadState journalsState = LoadState.idle;
  List<JournalStat> topJournals = [];

  // ── 4.6 Top authors ───────────────────────────
  LoadState authorsState = LoadState.idle;
  List<AuthorStat> topAuthors = [];

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
  /// Resets all state and fetches the first page.
  Future<void> search(String topic, {
    bool openAccessOnly = false,
    int? yearFrom,
    int? yearTo,
  }) async {
    if (topic.trim().isEmpty) return;
    _currentTopic = topic.trim();
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
        openAccessOnly: openAccessOnly,
        yearFrom: yearFrom,
        yearTo: yearTo,
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
      );
      works.addAll(result.works);
      searchState = LoadState.success;
    } on OpenAlexException catch (e) {
      _currentPage--; // rollback
      _setError(e.message);
      searchState = LoadState.error;
    }
    notifyListeners();
  }

  /// Fetch full detail for a work (req 4.2).
  Future<void> loadWorkDetail(String workId) async {
    selectedWork = null;
    detailState = LoadState.loading;
    notifyListeners();

    try {
      selectedWork = await _service.getWorkDetail(workId);
      detailState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      detailState = LoadState.error;
    }
    notifyListeners();
  }

  /// Load all analytics data for the Trend Analysis screen (reqs 4.3–4.6).
  Future<void> loadTrendAnalysis() async {
    if (_currentTopic.isEmpty) return;

    trendState = LoadState.loading;
    topPapersState = LoadState.loading;
    journalsState = LoadState.loading;
    authorsState = LoadState.loading;
    notifyListeners();

    // Fire all calls in parallel
    await Future.wait([
      _loadTrend(),
      _loadTopPapers(),
      _loadTopJournals(),
      _loadTopAuthors(),
    ]);

    notifyListeners();
  }

  /// Load dashboard summary (req 4.7).
  Future<void> loadDashboard() async {
    if (_currentTopic.isEmpty) return;
    dashboardState = LoadState.loading;
    notifyListeners();

    try {
      dashboard = await _service.getDashboard(_currentTopic);
      dashboardState = LoadState.success;
    } on OpenAlexException catch (e) {
      _setError(e.message);
      dashboardState = LoadState.error;
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

  void _setError(String? msg) => _errorMessage = msg;

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
