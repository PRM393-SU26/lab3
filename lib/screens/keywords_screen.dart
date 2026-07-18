import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';
import '../models/analytics.dart';
import 'keyword_search_result_screen.dart';
import 'detail_screen.dart';
import 'author_detail_screen.dart';
import '../services/analytics_service.dart';

class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  bool _loaded = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearchMode = false;
  int _selectedFilterIndex = 0; // 0 = Journal/Works, 1 = Author

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final provider = context.read<SearchProvider>();
        if (provider.globalKeywords.isEmpty &&
            provider.globalKeywordsState != LoadState.loading) {
          provider.loadGlobalKeywords();
        }
        provider.loadPersonalizedKeywords();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _exitSearchMode() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    final provider = context.read<SearchProvider>();
    provider.clearKeywordSuggestions();
    setState(() {
      _isSearchMode = false;
      _selectedFilterIndex = 0;
    });
  }

  void _onSearchSubmit(String text) {
    if (text.trim().isEmpty) return;
    _searchFocusNode.unfocus();
    final provider = context.read<SearchProvider>();
    provider.clearKeywordSuggestions();
    provider.searchKeywordByText(text.trim());
    setState(() {
      _isSearchMode = true;
    });
  }

  void _onSuggestionSelected(KeywordStat keyword) {
    _searchController.text = keyword.displayName;
    _searchFocusNode.unfocus();
    final provider = context.read<SearchProvider>();
    provider.clearKeywordSuggestions();
    provider.searchKeyword(keyword);
    setState(() {
      _isSearchMode = true;
    });
  }

  void _navigateToDetail(
    BuildContext context,
    SearchProvider provider,
    KeywordStat kw,
  ) {
    if (kw.conceptId == null) return;
    provider.searchKeyword(kw);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KeywordSearchResultScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Keyword Analysis'),
        leading: _isSearchMode
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _exitSearchMode,
              )
            : null,
      ),
      body: Column(
        children: [
          // ── Search bar (always visible) ─────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildSearchBar(context, provider, cs),
          ),

          // ── Body content ───────────────────────────────
          Expanded(
            child: _isSearchMode
                ? _buildSearchResults(context, provider, cs)
                : _buildAnalyticsBody(context, provider, cs),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEARCH BAR WITH AUTOCOMPLETE
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSearchBar(BuildContext context, SearchProvider provider, ColorScheme cs) {
    final suggestions = provider.keywordSuggestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _searchFocusNode.hasFocus ? cs.primary : cs.outlineVariant,
              width: _searchFocusNode.hasFocus ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(
                    _searchFocusNode.hasFocus ? 0.08 : 0.03),
                blurRadius: _searchFocusNode.hasFocus ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search keywords & concepts…',
              hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withOpacity(0.5),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _searchFocusNode.hasFocus
                    ? cs.primary
                    : cs.onSurfaceVariant,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                      onPressed: () {
                        _searchController.clear();
                        provider.clearKeywordSuggestions();
                        if (_isSearchMode) {
                          _exitSearchMode();
                        } else {
                          setState(() {});
                        }
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: TextStyle(fontSize: 14, color: cs.onSurface),
            onChanged: (value) {
              provider.fetchKeywordSuggestions(value);
              setState(() {});
            },
            onSubmitted: _onSearchSubmit,
            textInputAction: TextInputAction.search,
          ),
        ),

        // ── Autocomplete suggestions dropdown ──────────────
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: cs.onSurface.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: cs.outlineVariant.withOpacity(0.5),
                ),
                itemBuilder: (context, index) {
                  final kw = suggestions[index];
                  return InkWell(
                    onTap: () => _onSuggestionSelected(kw),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.tag_rounded,
                                size: 16, color: cs.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              kw.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: cs.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEARCH RESULTS WITH JOURNAL/AUTHOR FILTER TABS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSearchResults(BuildContext context, SearchProvider provider, ColorScheme cs) {
    if (provider.keywordDetailState == LoadState.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text('Searching…', style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (provider.keywordDetailState == LoadState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'Search failed',
              style: TextStyle(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  _onSearchSubmit(_searchController.text);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final keyword = provider.selectedKeyword;

    return Column(
      children: [
        // ── Result header ─────────────────────────────
        if (keyword != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(Icons.tag_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Results for "${keyword.displayName}"',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_formatCount(keyword.paperCount)} works',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

        // ── Filter tabs ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _FilterButton(
                label: 'Journal',
                icon: Icons.menu_book_rounded,
                isSelected: _selectedFilterIndex == 0,
                onTap: () => setState(() => _selectedFilterIndex = 0),
              ),
              const SizedBox(width: 10),
              _FilterButton(
                label: 'Author',
                icon: Icons.people_rounded,
                isSelected: _selectedFilterIndex == 1,
                onTap: () => setState(() => _selectedFilterIndex = 1),
              ),
              const Spacer(),
              if (_selectedFilterIndex == 0)
                IconButton(
                  icon: Icon(Icons.sort_rounded, color: cs.primary),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.arrow_downward_rounded),
                            title: const Text('Latest (default)'),
                            onTap: () {
                              provider.changeKeywordWorksSort('publication_year:desc');
                              Navigator.pop(ctx);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.arrow_upward_rounded),
                            title: const Text('Oldest'),
                            onTap: () {
                              provider.changeKeywordWorksSort('publication_year:asc');
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        // ── Results list ─────────────────────────────
        Expanded(
          child: _selectedFilterIndex == 0
              ? _buildWorksResults(context, provider, cs)
              : _buildAuthorsResults(context, provider, cs),
        ),
      ],
    );
  }

  Widget _buildWorksResults(BuildContext context, SearchProvider provider, ColorScheme cs) {
    final works = provider.keywordWorks;

    if (works.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 48,
                color: cs.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('No related works found.',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!provider.isKeywordWorksLoadingMore && 
            provider.hasMoreKeywordWorks && 
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          provider.loadMoreKeywordWorks();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: works.length + (provider.isKeywordWorksLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == works.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final work = works[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(workId: work.id),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description_outlined,
                        color: cs.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          work.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: cs.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildInfoChip(
                              Icons.calendar_today_rounded,
                              work.publicationYear?.toString() ?? 'N/A',
                              cs.primary,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              Icons.format_quote_rounded,
                              '${work.citedByCount} cited',
                              cs.tertiary,
                            ),
                          ],
                        ),
                        if (work.primarySource != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.menu_book_rounded,
                                  size: 12, color: cs.secondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  work.primarySource!.displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildAuthorsResults(BuildContext context, SearchProvider provider, ColorScheme cs) {
    final authors = provider.keywordAuthors;

    if (authors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outlined, size: 48,
                color: cs.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('No contributing authors found.',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    final maxPapers = authors.first.paperCount;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: authors.length,
      itemBuilder: (context, index) {
        final author = authors[index];
        final ratio = maxPapers > 0 ? author.paperCount / maxPapers : 0.0;

        Color? medalColor;
        if (index == 0) medalColor = const Color(0xFFEAB308);
        else if (index == 1) medalColor = cs.outline;
        else if (index == 2) medalColor = const Color(0xFFCD7F32);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: index < 3
                  ? (medalColor ?? cs.outlineVariant).withOpacity(0.4)
                  : cs.outlineVariant,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: index < 3
                    ? medalColor!.withOpacity(0.12)
                    : cs.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: index < 3
                    ? Icon(Icons.emoji_events_rounded,
                        size: 20, color: medalColor)
                    : Text(
                        '#${index + 1}',
                        style: TextStyle(
                          color: cs.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
            title: Text(
              author.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: cs.onSurface,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${author.paperCount} publications',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: ratio),
                      duration: Duration(milliseconds: 500 + index * 80),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: cs.secondaryContainer,
                          valueColor: AlwaysStoppedAnimation(cs.secondary),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: cs.onSurfaceVariant),
            onTap: () {
              if (author.authorId == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AuthorDetailScreen(
                    authorId: author.authorId!,
                    authorName: author.displayName,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ANALYTICS BODY (when no search active)
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildAnalyticsBody(BuildContext context, SearchProvider provider, ColorScheme cs) {
    final keywords = provider.globalKeywords;
    final loadState = provider.globalKeywordsState;

    if (loadState == LoadState.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text('Loading keywords…',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (loadState == LoadState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'Failed to load keywords',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.loadGlobalKeywords(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (keywords.isEmpty) {
      return _EmptyTab(
        icon: Icons.tag_outlined,
        message: 'No keyword data available.',
      );
    }

    final maxCount = keywords.map((e) => e.paperCount).fold(0, max);
    final topKeyword = keywords.reduce(
        (a, b) => a.paperCount > b.paperCount ? a : b);
    final totalPapers = keywords.fold<int>(0, (s, k) => s + k.paperCount);
    final trendingKeywords = List<KeywordStat>.from(keywords)
      ..sort((a, b) => b.paperCount.compareTo(a.paperCount));
    final trending = trendingKeywords.take(3).toList();

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: () => provider.loadGlobalKeywords(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.personalizedKeywords.isNotEmpty) ...[
              _ForYouKeywordsSection(provider: provider),
              const SizedBox(height: 24),
            ],
            // ── Header banner ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tag_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trending Research Keywords',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${keywords.length} most popular research concepts globally',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── KPI cards ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: 'Total Keywords',
                    value: '${keywords.length}',
                    icon: Icons.tag_outlined,
                    color: cs.primary,
                    bgColor: cs.primaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'Top Keyword',
                    value: topKeyword.displayName,
                    icon: Icons.emoji_events_rounded,
                    color: cs.secondary,
                    bgColor: cs.secondaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'Total Works',
                    value: _formatCount(totalPapers),
                    icon: Icons.article_outlined,
                    color: cs.onSurfaceVariant,
                    bgColor: cs.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Trending keywords ────────────────────────────
            _SectionHeader(
              icon: Icons.trending_up_rounded,
              title: 'Trending Keywords',
              color: cs.error,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: trending.length,
                separatorBuilder: (_, i) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final kw = trending[index];
                  final colors = [
                    [cs.error, cs.errorContainer],
                    [cs.primary, cs.primaryContainer],
                    [cs.tertiary, cs.tertiaryContainer],
                  ];
                  final pair = colors[index % colors.length];

                  return GestureDetector(
                    onTap: () => _navigateToDetail(context, provider, kw),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300 + index * 100),
                      curve: Curves.easeOut,
                      width: 180,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: pair[1],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: pair[0].withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: pair[0].withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.trending_up_rounded,
                                  size: 16, color: pair[0]),
                              const SizedBox(width: 4),
                              Text(
                                '#${index + 1} Trending',
                                style: TextStyle(
                                    fontSize: 10, color: pair[0]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              kw.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatCount(kw.paperCount)} papers',
                            style: TextStyle(
                                fontSize: 11, color: pair[0]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Keyword frequency chart ──────────────────────
            _SectionHeader(
              icon: Icons.bar_chart_rounded,
              title: 'Keyword Frequency Chart',
              color: cs.primary,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                children: List.generate(min(8, keywords.length), (index) {
                  final kw = keywords[index];
                  final ratio = maxCount > 0
                      ? kw.paperCount / maxCount
                      : 0.0;
                  final barColors = [
                    cs.primary,
                    cs.primary,
                    cs.secondary,
                    cs.tertiary,
                    cs.onSurfaceVariant,
                    cs.error,
                    cs.outline,
                    cs.inversePrimary,
                  ];
                  final barColor = barColors[index % barColors.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          _navigateToDetail(context, provider, kw),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  kw.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: barColor.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _formatCount(kw.paperCount),
                                  style: TextStyle(
                                      fontSize: 11, color: barColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: ratio),
                              duration: Duration(
                                  milliseconds: 600 + index * 100),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  value: value,
                                  minHeight: 10,
                                  backgroundColor:
                                      barColor.withOpacity(0.08),
                                  valueColor:
                                      AlwaysStoppedAnimation(barColor),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // ── Most Frequent Keywords list ──────────────────
            _SectionHeader(
              icon: Icons.list_rounded,
              title: 'Most Frequent Keywords',
              color: cs.secondary,
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: keywords.length,
              itemBuilder: (context, index) {
                final kw = keywords[index];
                final ratio = maxCount > 0
                    ? kw.paperCount / maxCount
                    : 0.0;

                return Container(
                  key: ValueKey('keywordFrequentCard_$index'),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () =>
                        _navigateToDetail(context, provider, kw),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cs.primary.withOpacity(0.8),
                                  cs.primary.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kw.displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: ratio,
                                          minHeight: 5,
                                          backgroundColor:
                                              cs.primaryContainer,
                                          valueColor:
                                              AlwaysStoppedAnimation(
                                                  cs.primary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${_formatCount(kw.paperCount)} papers',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: cs.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: isSelected ? cs.primary : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? cs.primary : cs.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 14, color: color)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyTab({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: cs.primary, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Recommend for You" — surfaces the keywords/concepts the user views most
/// often plus their top contributing authors, mirroring the Home screen's
/// personalized suggestions.
class _ForYouKeywordsSection extends StatelessWidget {
  final SearchProvider provider;
  const _ForYouKeywordsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              'Recommend for You',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const SizedBox(height: 12),
        ...provider.personalizedKeywords.map((keyword) {
          final authors = provider.personalizedKeywordAuthors[keyword.conceptId] ?? [];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ActionChip(
                  avatar: Icon(Icons.local_fire_department, size: 16, color: cs.primary),
                  label: Text(keyword.displayName),
                  onPressed: () {
                    AnalyticsService.logForYouTap(type: 'keyword', value: keyword.displayName);
                    provider.searchKeyword(keyword);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KeywordSearchResultScreen(),
                      ),
                    );
                  },
                ),
                if (provider.personalizedKeywordsState == LoadState.loading && authors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (authors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: authors.map((author) {
                      return ActionChip(
                        avatar: Icon(Icons.person_outline, size: 16, color: cs.secondary),
                        label: Text(author.displayName),
                        onPressed: () {
                          if (author.authorId == null) return;
                          AnalyticsService.logForYouTap(type: 'author', value: author.displayName);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AuthorDetailScreen(
                                authorId: author.authorId!,
                                authorName: author.displayName,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}