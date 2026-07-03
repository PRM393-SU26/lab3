import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';
import '../models/analytics.dart';
import 'detail_screen.dart';
import 'source_detail_screen.dart';
import 'author_detail_screen.dart';

class KeywordDetailScreen extends StatelessWidget {
  const KeywordDetailScreen({super.key});

  // ── Design tokens ──────────────────────────────────────────────────
  static const _indigo      = Color(0xFF4F46E5);
  static const _indigoLight = Color(0xFFEEF2FF);
  static const _violet      = Color(0xFF7C3AED);
  static const _violetLight = Color(0xFFF5F3FF);
  static const _emerald     = Color(0xFF059669);
  static const _emeraldLight= Color(0xFFD1FAE5);
  static const _amber       = Color(0xFFD97706);
  static const _sky         = Color(0xFF0284C7);
  static const _skyLight    = Color(0xFFE0F2FE);
  static const _slate50     = Color(0xFFF8FAFC);
  static const _slate200    = Color(0xFFE2E8F0);
  static const _slate400    = Color(0xFF94A3B8);
  static const _slate600    = Color(0xFF475569);
  static const _slate900    = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final keyword = provider.selectedKeyword;

    return Scaffold(
      backgroundColor: _slate50,
      body: Builder(
        builder: (context) {
          if (keyword == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Keyword Detail')),
              body: const Center(child: Text('No keyword selected.')),
            );
          }

          if (provider.keywordDetailState == LoadState.loading) {
            return Scaffold(
              appBar: AppBar(
                title: Text(keyword.displayName),
                backgroundColor: Colors.white,
                foregroundColor: _slate900,
                elevation: 0,
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: _indigo),
                    SizedBox(height: 16),
                    Text('Loading analytical details…',
                        style: TextStyle(color: _slate600)),
                  ],
                ),
              ),
            );
          }

          if (provider.keywordDetailState == LoadState.error) {
            return Scaffold(
              appBar: AppBar(
                title: Text(keyword.displayName),
                backgroundColor: Colors.white,
                foregroundColor: _slate900,
                elevation: 0,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ??
                          'Failed to load keyword analysis',
                      style: const TextStyle(color: _slate600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.loadKeywordDetail(keyword),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Computed analytics ─────────────────────────────
          YearlyCount? peakYear;
          for (final y in provider.keywordTrend) {
            if (peakYear == null || y.count > peakYear.count) peakYear = y;
          }

          final totalAuthors = provider.keywordAuthors.length;
          final totalJournals = provider.keywordJournals.length;

          return CustomScrollView(
            slivers: [
              // ── Gradient App Bar ───────────────────────────
              SliverAppBar(
                expandedHeight: 130,
                pinned: true,
                backgroundColor: _indigo,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 20, right: 20, bottom: 16, top: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.tag_rounded,
                                      color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        keyword.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Research Concept · ${_formatCount(keyword.paperCount)} associated works',
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  collapseMode: CollapseMode.pin,
                ),
              ),

              // ── Content body ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── KPI Summary Cards ──────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _KpiCard(
                              label: 'Peak Year',
                              value: peakYear != null
                                  ? '${peakYear.year}'
                                  : 'N/A',
                              icon: Icons.calendar_today_rounded,
                              color: _indigo,
                              bgColor: _indigoLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiCard(
                              label: 'Top Authors',
                              value: '$totalAuthors',
                              icon: Icons.people_rounded,
                              color: _violet,
                              bgColor: _violetLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiCard(
                              label: 'Journals',
                              value: '$totalJournals',
                              icon: Icons.menu_book_rounded,
                              color: _emerald,
                              bgColor: _emeraldLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ═══════════════════════════════════════
                      // PUBLICATION TREND OVER TIME
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.show_chart_rounded,
                        title: 'Publication Trend Over Time',
                        color: _indigo,
                      ),
                      const SizedBox(height: 12),
                      if (provider.keywordTrend.isNotEmpty)
                        Container(
                          height: 220,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _slate200),
                            boxShadow: [
                              BoxShadow(
                                color: _slate900.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _TrendBarChart(
                              trend: provider.keywordTrend),
                        )
                      else
                        _EmptySection(
                            message: 'No trend statistics available.'),
                      const SizedBox(height: 24),

                      // ═══════════════════════════════════════
                      // TOP CONTRIBUTING AUTHORS (ranked desc)
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.people_rounded,
                        title: 'Top Contributing Authors',
                        color: _violet,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ranked by publication count (descending)',
                        style: TextStyle(
                          fontSize: 11,
                          color: _slate400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (provider.keywordAuthors.isNotEmpty) ...[
                        // ── Author ranking bar chart ─────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _slate200),
                            boxShadow: [
                              BoxShadow(
                                color: _slate900.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _AuthorRankingChart(
                            authors: provider.keywordAuthors,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Author ranking list ──────────────
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: provider.keywordAuthors.length,
                          itemBuilder: (context, index) {
                            final author = provider.keywordAuthors[index];
                            final maxAuthorPapers = provider
                                .keywordAuthors.first.paperCount;
                            final ratio = maxAuthorPapers > 0
                                ? author.paperCount / maxAuthorPapers
                                : 0.0;

                            // Medal colors for top 3
                            Color? medalColor;
                            IconData? medalIcon;
                            if (index == 0) {
                              medalColor = const Color(0xFFEAB308);
                              medalIcon = Icons.emoji_events_rounded;
                            } else if (index == 1) {
                              medalColor = _slate400;
                              medalIcon = Icons.emoji_events_rounded;
                            } else if (index == 2) {
                              medalColor = const Color(0xFFCD7F32);
                              medalIcon = Icons.emoji_events_rounded;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: index < 3
                                      ? (medalColor ?? _slate200)
                                          .withOpacity(0.4)
                                      : _slate200,
                                ),
                                boxShadow: [
                                  if (index < 3)
                                    BoxShadow(
                                      color: (medalColor ?? _slate200)
                                          .withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 4),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: index < 3
                                        ? LinearGradient(
                                            colors: [
                                              medalColor!.withOpacity(0.2),
                                              medalColor.withOpacity(0.05),
                                            ],
                                          )
                                        : null,
                                    color: index >= 3 ? _indigoLight : null,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: index < 3
                                        ? Icon(medalIcon,
                                            size: 20, color: medalColor)
                                        : Text(
                                            '#${index + 1}',
                                            style: const TextStyle(
                                              color: _indigo,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                  ),
                                ),
                                title: Text(
                                  author.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _slate900,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${author.paperCount} publications',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _slate600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(3),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(
                                              begin: 0, end: ratio),
                                          duration: Duration(
                                              milliseconds:
                                                  500 + index * 80),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, value, _) {
                                            return LinearProgressIndicator(
                                              value: value,
                                              minHeight: 4,
                                              backgroundColor: _violetLight,
                                              valueColor:
                                                  const AlwaysStoppedAnimation(
                                                      _violet),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: _slate400),
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
                        ),
                      ] else
                        _EmptySection(
                            message: 'No author contributions found.'),
                      const SizedBox(height: 24),

                      // ═══════════════════════════════════════
                      // RELATED JOURNALS
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.menu_book_rounded,
                        title: 'Related Journals',
                        color: _emerald,
                      ),
                      const SizedBox(height: 12),
                      if (provider.keywordJournals.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              min(5, provider.keywordJournals.length),
                          itemBuilder: (context, index) {
                            final journal =
                                provider.keywordJournals[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _slate200),
                                boxShadow: [
                                  BoxShadow(
                                    color: _slate900.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 4),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _emeraldLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.menu_book_rounded,
                                      color: _emerald, size: 18),
                                ),
                                title: Text(
                                  journal.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _slate900,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Papers: ${journal.paperCount}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _slate600,
                                    ),
                                  ),
                                ),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: _slate400),
                                onTap: () {
                                  if (journal.sourceId == null) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SourceDetailScreen(
                                        sourceId: journal.sourceId!,
                                        sourceName:
                                            journal.displayName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        )
                      else
                        _EmptySection(
                            message: 'No related journals found.'),
                      const SizedBox(height: 24),

                      // ═══════════════════════════════════════
                      // RELATED PUBLICATIONS
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.article_rounded,
                        title: 'Related Publications',
                        color: _sky,
                      ),
                      const SizedBox(height: 12),
                      if (provider.keywordWorks.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: provider.keywordWorks.length,
                          itemBuilder: (context, index) {
                            final work = provider.keywordWorks[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _slate200),
                                boxShadow: [
                                  BoxShadow(
                                    color: _slate900.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DetailScreen(workId: work.id),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _skyLight,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                            Icons.description_outlined,
                                            color: _sky,
                                            size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              work.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: _slate900,
                                              ),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                _InfoChip(
                                                  icon: Icons
                                                      .calendar_today_rounded,
                                                  label: work.publicationYear
                                                          ?.toString() ??
                                                      'N/A',
                                                  color: _indigo,
                                                ),
                                                const SizedBox(width: 8),
                                                _InfoChip(
                                                  icon: Icons
                                                      .format_quote_rounded,
                                                  label:
                                                      '${work.citedByCount} cited',
                                                  color: _amber,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12,
                                          color: _slate400),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      else
                        _EmptySection(
                            message: 'No related publications found.'),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
// TREND BAR CHART
// ═══════════════════════════════════════════════════════════════════════

class _TrendBarChart extends StatelessWidget {
  final List<YearlyCount> trend;

  const _TrendBarChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox();

    final maxCount = trend.map((e) => e.count).fold(0, max);
    // Show latest 10 years for chart clarity
    final displayTrend =
        trend.length > 10 ? trend.sublist(trend.length - 10) : trend;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth =
            ((constraints.maxWidth - 16) / displayTrend.length) - 6;
        final effectiveBarWidth = barWidth.clamp(12.0, 32.0);

        return Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: displayTrend.asMap().entries.map((entry) {
                  final index = entry.key;
                  final y = entry.value;
                  final ratio = maxCount > 0 ? y.count / maxCount : 0.0;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        KeywordDetailScreen._formatCount(y.count),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: KeywordDetailScreen._indigo,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration:
                            Duration(milliseconds: 500 + index * 80),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Container(
                            width: effectiveBarWidth,
                            height: max(4, value * 100),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  KeywordDetailScreen._indigo,
                                  KeywordDetailScreen._violet,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: displayTrend.map((y) {
                return SizedBox(
                  width: effectiveBarWidth + 6,
                  child: Text(
                    '${y.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: KeywordDetailScreen._slate600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AUTHOR RANKING HORIZONTAL BAR CHART
// ═══════════════════════════════════════════════════════════════════════

class _AuthorRankingChart extends StatelessWidget {
  final List<AuthorStat> authors;

  const _AuthorRankingChart({required this.authors});

  @override
  Widget build(BuildContext context) {
    final topAuthors = authors.take(5).toList();
    if (topAuthors.isEmpty) return const SizedBox();

    final maxPapers = topAuthors.first.paperCount;
    final barColors = [
      const Color(0xFFEAB308),  // gold
      KeywordDetailScreen._slate400,      // silver
      const Color(0xFFCD7F32), // bronze
      KeywordDetailScreen._violet,
      KeywordDetailScreen._sky,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Author Publication Count',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: KeywordDetailScreen._slate900,
          ),
        ),
        const SizedBox(height: 14),
        ...topAuthors.asMap().entries.map((entry) {
          final index = entry.key;
          final author = entry.value;
          final ratio =
              maxPapers > 0 ? author.paperCount / maxPapers : 0.0;
          final color = barColors[index % barColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: color,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        author.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: KeywordDetailScreen._slate900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${author.paperCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration:
                        Duration(milliseconds: 600 + index * 100),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: color.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation(color),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SHARED HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

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
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: KeywordDetailScreen._slate900,
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
        color: Colors.white,
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
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: KeywordDetailScreen._slate600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _EmptySection extends StatelessWidget {
  final String message;

  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KeywordDetailScreen._slate200),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: KeywordDetailScreen._slate600,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
