import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';
import 'author_detail_screen.dart';
import 'detail_screen.dart';
import 'source_detail_screen.dart';

class TrendScreen extends StatefulWidget {
  const TrendScreen({super.key});

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // ── Design tokens (match SearchScreen) ─────────────────────────
  static const _indigo     = Color(0xFF4F46E5);
  static const _indigoDark = Color(0xFF3730A3);
  static const _indigoLight= Color(0xFFEEF2FF);
  static const _emerald    = Color(0xFF059669);
  static const _emeraldLight = Color(0xFFD1FAE5);
  static const _amber      = Color(0xFFD97706);
  static const _amberLight = Color(0xFFFEF3C7);
  static const _violet     = Color(0xFF7C3AED);
  static const _violetLight= Color(0xFFF5F3FF);
  static const _slate50    = Color(0xFFF8FAFC);
  static const _slate100   = Color(0xFFF1F5F9);
  static const _slate200   = Color(0xFFE2E8F0);
  static const _slate400   = Color(0xFF94A3B8);
  static const _slate600   = Color(0xFF475569);
  static const _slate700   = Color(0xFF334155);
  static const _slate900   = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadTrendAnalysis();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();

    final isLoading = provider.trendState == LoadState.loading ||
        provider.topPapersState == LoadState.loading ||
        provider.journalsState == LoadState.loading ||
        provider.authorsState == LoadState.loading ||
        provider.countryState == LoadState.loading;

    return Scaffold(
      backgroundColor: _slate50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            snap: false,
            backgroundColor: _indigo,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_indigo, _indigoDark],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.bar_chart_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Trend Analysis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.currentTopic.isEmpty
                          ? 'All topics'
                          : '"${provider.currentTopic}"',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: _indigoDark,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.55),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.show_chart_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Yearly Trend'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Top Papers'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.menu_book_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Journals'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.people_alt_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Authors'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          Icon(Icons.public_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Countries'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: isLoading
            ? const _LoadingView()
            : TabBarView(
                controller: _tabController,
                children: [
                  _YearlyTrendTab(provider: provider),
                  _TopPapersTab(provider: provider),
                  _TopJournalsTab(provider: provider),
                  _TopAuthorsTab(provider: provider),
                  _CountriesTab(provider: provider),
                ],
              ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Tab: Yearly Trend
// ────────────────────────────────────────────────────────────────────────────

class _YearlyTrendTab extends StatefulWidget {
  final SearchProvider provider;

  const _YearlyTrendTab({required this.provider});

  @override
  State<_YearlyTrendTab> createState() => _YearlyTrendTabState();
}

class _YearlyTrendTabState extends State<_YearlyTrendTab> {
  static const _indigo     = Color(0xFF4F46E5);
  static const _indigoLight= Color(0xFFEEF2FF);
  static const _indigoDark = Color(0xFF3730A3);
  static const _slate50    = Color(0xFFF8FAFC);
  static const _slate100   = Color(0xFFF1F5F9);
  static const _slate200   = Color(0xFFE2E8F0);
  static const _slate400   = Color(0xFF94A3B8);
  static const _slate600   = Color(0xFF475569);
  static const _slate700   = Color(0xFF334155);
  static const _slate900   = Color(0xFF0F172A);
  static const _emerald    = Color(0xFF059669);
  static const _emeraldLight = Color(0xFFD1FAE5);
  static const _amber      = Color(0xFFD97706);
  static const _amberLight = Color(0xFFFEF3C7);

  int _currentPage = 0;
  static const int _itemsPerPage = 12;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    if (provider.yearlyTrend.isEmpty) {
      return const _EmptyTab(
        icon: Icons.show_chart_rounded,
        message: 'No yearly trend data available.',
      );
    }

    final maxCount =
        provider.yearlyTrend.map((e) => e.count).fold(0, max);
    final peakEntry = provider.yearlyTrend
        .reduce((a, b) => a.count > b.count ? a : b);
    final total =
        provider.yearlyTrend.fold(0, (sum, e) => sum + e.count);

    final int totalItems = provider.yearlyTrend.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage >= totalPages) {
      _currentPage = max(0, totalPages - 1);
    }
    
    final int startIndex = _currentPage * _itemsPerPage;
    final int endIndex = min(startIndex + _itemsPerPage, totalItems);
    final List<dynamic> currentPageData = provider.yearlyTrend.sublist(startIndex, endIndex);

    int localMaxCount = 0;
    for (var e in currentPageData) {
      if ((e.count as int) > localMaxCount) {
        localMaxCount = e.count as int;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat chips row ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Papers',
                  value: _formatNumber(total),
                  icon: Icons.article_rounded,
                  color: _indigo,
                  bgColor: _indigoLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Peak Year',
                  value: '${peakEntry.year}',
                  icon: Icons.emoji_events_rounded,
                  color: _amber,
                  bgColor: _amberLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Years Span',
                  value: '${provider.yearlyTrend.length}',
                  icon: Icons.date_range_rounded,
                  color: _emerald,
                  bgColor: _emeraldLight,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Chart section ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _slate200),
              boxShadow: [
                BoxShadow(
                  color: _slate900.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Publications per Year',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _slate900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Historical growth of publication volume on this topic.',
                            style: TextStyle(fontSize: 12, color: _slate600),
                          ),
                        ],
                      ),
                    ),
                    if (totalPages > 1)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: _currentPage > 0
                                ? () => setState(() => _currentPage--)
                                : null,
                          ),
                          Text(
                            '${_currentPage + 1} / $totalPages',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: _currentPage < totalPages - 1
                                ? () => setState(() => _currentPage++)
                                : null,
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: _BarChart(
                    data: currentPageData,
                    maxCount: localMaxCount.toInt(),
                    peakYear: peakEntry.year,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Trend summary card ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _indigoLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _indigo.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _indigo,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.insights_rounded,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Trend Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _indigoDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SummaryRow(
                  label: 'Start year',
                  value:
                      '${provider.yearlyTrend.first.year}  ·  ${provider.yearlyTrend.first.count} papers',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Peak year',
                  value:
                      '${peakEntry.year}  ·  ${peakEntry.count} papers',
                  highlight: true,
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Latest year',
                  value:
                      '${provider.yearlyTrend.last.year}  ·  ${provider.yearlyTrend.last.count} papers',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _BarChart extends StatelessWidget {
  final List<dynamic> data;
  final int maxCount;
  final int peakYear;

  static const _indigo     = Color(0xFF4F46E5);
  static const _indigoLight= Color(0xFFEEF2FF);
  static const _indigoDark = Color(0xFF3730A3);
  static const _amber      = Color(0xFFD97706);
  static const _slate200   = Color(0xFFE2E8F0);
  static const _slate400   = Color(0xFF94A3B8);

  const _BarChart({
    required this.data,
    required this.maxCount,
    required this.peakYear,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const topLabelSlot = 14.0;
        const bottomLabelSlot = 20.0;
        const verticalGaps = 8.0; // 2px above bar + 6px below bar
        final maxBarHeight = constraints.maxHeight -
            topLabelSlot -
            bottomLabelSlot -
            verticalGaps;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(data.length, (index) {
            final entry = data[index];
            final isPeak = entry.year == peakYear;
            final ratio = maxCount > 0 ? (entry.count / maxCount) : 0.0;
            final barH = max(ratio * maxBarHeight, 6.0);

            return Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: SizedBox(
                  width: 36,
                  height: constraints.maxHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                    SizedBox(
                      height: topLabelSlot,
                      child: Center(
                        child: isPeak
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${entry.count}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: _amber,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Tooltip(
                      triggerMode: TooltipTriggerMode.tap,
                      message: '${entry.year}: ${entry.count} papers',
                      child: Container(
                        width: 36,
                        height: barH,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPeak
                                ? [_amber, const Color(0xFFF59E0B)]
                                : [_indigo.withOpacity(0.6), _indigo],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: bottomLabelSlot,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${entry.year}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isPeak ? _amber : _slate400,
                              fontWeight: isPeak
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          }),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  static const _slate600   = Color(0xFF475569);
  static const _slate900   = Color(0xFF0F172A);
  static const _indigo     = Color(0xFF4F46E5);

  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: highlight ? _indigo : _slate600,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$label:  ',
          style: const TextStyle(fontSize: 12, color: _slate600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: highlight ? _indigo : _slate900,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Tab: Top Papers
// ────────────────────────────────────────────────────────────────────────────

class _TopPapersTab extends StatelessWidget {
  final SearchProvider provider;

  static const _indigo      = Color(0xFF4F46E5);
  static const _indigoLight = Color(0xFFEEF2FF);
  static const _amber       = Color(0xFFD97706);
  static const _amberLight  = Color(0xFFFEF3C7);
  static const _slate100    = Color(0xFFF1F5F9);
  static const _slate200    = Color(0xFFE2E8F0);
  static const _slate400    = Color(0xFF94A3B8);
  static const _slate600    = Color(0xFF475569);
  static const _slate700    = Color(0xFF334155);
  static const _slate900    = Color(0xFF0F172A);

  const _TopPapersTab({required this.provider});

  static const _medalColors = [
    Color(0xFFD97706), // gold
    Color(0xFF94A3B8), // silver
    Color(0xFFB45309), // bronze
  ];

  @override
  Widget build(BuildContext context) {
    if (provider.topPapers.isEmpty) {
      return const _EmptyTab(
        icon: Icons.workspace_premium_rounded,
        message: 'No influential papers found.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: provider.topPapers.length,
      itemBuilder: (context, index) {
        final paper = provider.topPapers[index];
        final isMedal = index < 3;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMedal
                  ? _medalColors[index].withOpacity(0.35)
                  : _slate200,
              width: isMedal ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _slate900.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(workId: paper.id),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rank badge
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isMedal
                            ? _medalColors[index].withOpacity(0.12)
                            : _slate100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: isMedal
                          ? Icon(
                              Icons.emoji_events_rounded,
                              color: _medalColors[index],
                              size: 18,
                            )
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _slate600,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paper.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _slate900,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _PillBadge(
                                icon: Icons.format_quote_rounded,
                                label: '${paper.citedByCount} cited',
                                color: _indigo,
                                bgColor: _indigoLight,
                              ),
                              const SizedBox(width: 6),
                              if (paper.publicationYear != null)
                                _PillBadge(
                                  icon: Icons.calendar_today_rounded,
                                  label: '${paper.publicationYear}',
                                  color: _slate600,
                                  bgColor: _slate100,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded,
                        color: _slate400, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Tab: Top Journals
// ────────────────────────────────────────────────────────────────────────────

class _TopJournalsTab extends StatelessWidget {
  final SearchProvider provider;

  static const _indigo      = Color(0xFF4F46E5);
  static const _indigoLight = Color(0xFFEEF2FF);

  const _TopJournalsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.topJournals.isEmpty) {
      return const _EmptyTab(
        icon: Icons.menu_book_rounded,
        message: 'No journal statistics available.',
      );
    }

    final maxCount =
        provider.topJournals.map((e) => e.paperCount).fold(0, max);

    return _RankedBarList(
      items: provider.topJournals
          .map((j) => _RankItem(
                id: j.sourceId,
                name: j.displayName,
                count: j.paperCount,
                subtitle: '${j.paperCount} papers',
              ))
          .toList(),
      maxCount: maxCount,
      color: _indigo,
      bgColor: _indigoLight,
      icon: Icons.menu_book_rounded,
      onItemTap: (item) {
        if (item.id == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SourceDetailScreen(
              sourceId: item.id!,
              sourceName: item.name,
            ),
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Tab: Top Authors
// ────────────────────────────────────────────────────────────────────────────

class _TopAuthorsTab extends StatelessWidget {
  final SearchProvider provider;

  static const _violet      = Color(0xFF7C3AED);
  static const _violetLight = Color(0xFFF5F3FF);

  const _TopAuthorsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.topAuthors.isEmpty) {
      return const _EmptyTab(
        icon: Icons.people_alt_rounded,
        message: 'No author statistics available.',
      );
    }

    final maxCount =
        provider.topAuthors.map((e) => e.paperCount).fold(0, max);

    return _RankedBarList(
      items: provider.topAuthors
          .map((a) => _RankItem(
                id: a.authorId,
                name: a.displayName,
                count: a.paperCount,
                subtitle: '${a.paperCount} papers',
              ))
          .toList(),
      maxCount: maxCount,
      color: _violet,
      bgColor: _violetLight,
      icon: Icons.person_rounded,
      onItemTap: (item) {
        if (item.id == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AuthorDetailScreen(
              authorId: item.id!,
              authorName: item.name,
            ),
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Tab: Countries
// ────────────────────────────────────────────────────────────────────────────

class _CountriesTab extends StatelessWidget {
  final SearchProvider provider;

  static const _emerald = Color(0xFF059669);
  static const _emeraldLight = Color(0xFFD1FAE5);

  const _CountriesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.countryBreakdown.isEmpty) {
      return const _EmptyTab(
        icon: Icons.public_rounded,
        message: 'No country statistics available.',
      );
    }

    final maxCount =
        provider.countryBreakdown.map((e) => e.paperCount).fold(0, max);

    return _RankedBarList(
      items: provider.countryBreakdown
          .map((c) => _RankItem(
                name: c.displayName,
                count: c.paperCount,
                subtitle: '${c.paperCount} papers',
              ))
          .toList(),
      maxCount: maxCount,
      color: _emerald,
      bgColor: _emeraldLight,
      icon: Icons.flag_rounded,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Shared: Ranked Bar List
// ────────────────────────────────────────────────────────────────────────────

class _RankItem {
  final String? id;
  final String name;
  final int count;
  final String subtitle;
  const _RankItem({
    this.id,
    required this.name,
    required this.count,
    required this.subtitle,
  });
}

class _RankedBarList extends StatelessWidget {
  final List<_RankItem> items;
  final int maxCount;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final void Function(_RankItem item)? onItemTap;

  static const _slate100 = Color(0xFFF1F5F9);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate400 = Color(0xFF94A3B8);
  static const _slate600 = Color(0xFF475569);
  static const _slate900 = Color(0xFF0F172A);

  const _RankedBarList({
    required this.items,
    required this.maxCount,
    required this.color,
    required this.bgColor,
    required this.icon,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final ratio = maxCount > 0 ? item.count / maxCount : 0.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onItemTap != null && item.id != null
                ? () => onItemTap!(item)
                : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _slate200),
            boxShadow: [
              BoxShadow(
                color: _slate900.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rank number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: index == 0 ? color : bgColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: index == 0 ? Colors.white : color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _slate900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Count chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (onItemTap != null && item.id != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: _slate400, size: 20),
              ],
            ],
          ),
            ),
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  static const _slate600 = Color(0xFF475569);

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _slate600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _PillBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
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

  static const _indigo      = Color(0xFF4F46E5);
  static const _indigoLight = Color(0xFFEEF2FF);
  static const _slate600    = Color(0xFF475569);

  const _EmptyTab({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _indigoLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: _indigo, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: _slate600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  static const _indigo  = Color(0xFF4F46E5);
  static const _slate600 = Color(0xFF475569);

  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _indigo, strokeWidth: 2.5),
          SizedBox(height: 18),
          Text(
            'Loading trend data…',
            style: TextStyle(color: _slate600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}