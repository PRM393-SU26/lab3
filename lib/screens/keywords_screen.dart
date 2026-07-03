import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';
import '../models/analytics.dart';
import 'keyword_detail_screen.dart';

class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  // ── Design tokens ──────────────────────────────────────────────────
  static const _indigo      = Color(0xFF4F46E5);
  static const _indigoLight = Color(0xFFEEF2FF);
  static const _violet      = Color(0xFF7C3AED);
  static const _violetLight = Color(0xFFF5F3FF);
  static const _emerald     = Color(0xFF059669);
  static const _emeraldLight= Color(0xFFD1FAE5);
  static const _amber       = Color(0xFFD97706);
  static const _amberLight  = Color(0xFFFEF3C7);
  static const _rose        = Color(0xFFE11D48);
  static const _roseLight   = Color(0xFFFFF1F2);
  static const _sky         = Color(0xFF0284C7);
  static const _skyLight    = Color(0xFFE0F2FE);
  static const _slate50     = Color(0xFFF8FAFC);
  static const _slate200    = Color(0xFFE2E8F0);
  static const _slate400    = Color(0xFF94A3B8);
  static const _slate600    = Color(0xFF475569);
  static const _slate900    = Color(0xFF0F172A);

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final provider = context.read<SearchProvider>();
      // Auto-load global keywords if none are loaded yet
      if (provider.globalKeywords.isEmpty &&
          provider.globalKeywordsState != LoadState.loading) {
        provider.loadGlobalKeywords();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();

    // Use topic-specific keywords if a topic was searched, otherwise global
    final hasTopicKeywords =
        provider.currentTopic.isNotEmpty && provider.topKeywords.isNotEmpty;
    final keywords =
        hasTopicKeywords ? provider.topKeywords : provider.globalKeywords;
    final loadState =
        hasTopicKeywords ? provider.keywordsState : provider.globalKeywordsState;
    final headerLabel = hasTopicKeywords
        ? 'Keywords for "${provider.currentTopic}"'
        : 'Trending Research Keywords';
    final subtitleLabel = hasTopicKeywords
        ? '${keywords.length} research concepts discovered'
        : '${keywords.length} most popular research concepts globally';

    return Scaffold(
      backgroundColor: KeywordsScreen._slate50,
      appBar: AppBar(
        title: const Text(
          'Keyword Analysis',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: KeywordsScreen._indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(
        context, provider, keywords, loadState, headerLabel, subtitleLabel,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SearchProvider provider,
    List<KeywordStat> keywords,
    LoadState loadState,
    String headerLabel,
    String subtitleLabel,
  ) {
    if (loadState == LoadState.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: KeywordsScreen._indigo),
            SizedBox(height: 16),
            Text('Loading keywords…',
                style: TextStyle(color: KeywordsScreen._slate600)),
          ],
        ),
      );
    }

    if (loadState == LoadState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(provider.errorMessage ?? 'Failed to load keywords',
                style: const TextStyle(color: KeywordsScreen._slate600)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.loadGlobalKeywords(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KeywordsScreen._indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (keywords.isEmpty) {
      return const _EmptyTab(
        icon: Icons.tag_outlined,
        message: 'No keyword data available.',
      );
    }

    final maxCount = keywords.map((e) => e.paperCount).fold(0, max);
    final topKeyword =
        keywords.reduce((a, b) => a.paperCount > b.paperCount ? a : b);
    final totalPapers = keywords.fold<int>(0, (s, k) => s + k.paperCount);

    // Trending: top 3 by paper count
    final trendingKeywords = List<KeywordStat>.from(keywords)
      ..sort((a, b) => b.paperCount.compareTo(a.paperCount));
    final trending = trendingKeywords.take(3).toList();

    return RefreshIndicator(
      color: KeywordsScreen._indigo,
      onRefresh: () => provider.loadGlobalKeywords(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header banner ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: KeywordsScreen._indigo.withOpacity(0.25),
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
                        Text(
                          headerLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitleLabel,
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
                    color: KeywordsScreen._indigo,
                    bgColor: KeywordsScreen._indigoLight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'Top Keyword',
                    value: topKeyword.displayName,
                    icon: Icons.emoji_events_rounded,
                    color: KeywordsScreen._emerald,
                    bgColor: KeywordsScreen._emeraldLight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'Total Works',
                    value: _formatCount(totalPapers),
                    icon: Icons.article_outlined,
                    color: KeywordsScreen._amber,
                    bgColor: KeywordsScreen._amberLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Trending keywords ────────────────────────────
            const _SectionHeader(
              icon: Icons.trending_up_rounded,
              title: 'Trending Keywords',
              color: KeywordsScreen._rose,
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
                    [KeywordsScreen._rose, KeywordsScreen._roseLight],
                    [KeywordsScreen._violet, KeywordsScreen._violetLight],
                    [KeywordsScreen._sky, KeywordsScreen._skyLight],
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
                        border:
                            Border.all(color: pair[0].withOpacity(0.3)),
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
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: pair[0],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              kw.displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: KeywordsScreen._slate900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatCount(kw.paperCount)} papers',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: pair[0],
                            ),
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
            const _SectionHeader(
              icon: Icons.bar_chart_rounded,
              title: 'Keyword Frequency Chart',
              color: KeywordsScreen._indigo,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KeywordsScreen._slate200),
                boxShadow: [
                  BoxShadow(
                    color: KeywordsScreen._slate900.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(
                  min(8, keywords.length),
                  (index) {
                    final kw = keywords[index];
                    final ratio =
                        maxCount > 0 ? kw.paperCount / maxCount : 0.0;
                    final barColors = [
                      KeywordsScreen._indigo,
                      KeywordsScreen._violet,
                      KeywordsScreen._emerald,
                      KeywordsScreen._sky,
                      KeywordsScreen._amber,
                      KeywordsScreen._rose,
                      const Color(0xFF6366F1),
                      const Color(0xFF14B8A6),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: KeywordsScreen._slate900,
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
                                      fontSize: 11,
                                      color: barColor,
                                      fontWeight: FontWeight.w800,
                                    ),
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
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Keyword Statistics ───────────────────────────
            const _SectionHeader(
              icon: Icons.table_chart_rounded,
              title: 'Keyword Statistics',
              color: KeywordsScreen._violet,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KeywordsScreen._slate200),
                boxShadow: [
                  BoxShadow(
                    color: KeywordsScreen._slate900.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(KeywordsScreen._indigoLight),
                  columnSpacing: 16,
                  horizontalMargin: 16,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: KeywordsScreen._indigo,
                  ),
                  dataTextStyle: const TextStyle(
                    fontSize: 12,
                    color: KeywordsScreen._slate900,
                  ),
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Keyword')),
                    DataColumn(label: Text('Papers'), numeric: true),
                    DataColumn(label: Text('Share'), numeric: true),
                  ],
                  rows: List.generate(
                    min(10, keywords.length),
                    (index) {
                      final kw = keywords[index];
                      final share = totalPapers > 0
                          ? (kw.paperCount / totalPapers * 100)
                          : 0.0;
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            '${index + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          )),
                          DataCell(
                            InkWell(
                              onTap: () => _navigateToDetail(
                                  context, provider, kw),
                              child: Text(
                                kw.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: KeywordsScreen._indigo,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                              Text(_formatCount(kw.paperCount))),
                          DataCell(Text(
                              '${share.toStringAsFixed(1)}%')),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Most Frequent Keywords list ──────────────────
            const _SectionHeader(
              icon: Icons.list_rounded,
              title: 'Most Frequent Keywords',
              color: KeywordsScreen._emerald,
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: keywords.length,
              itemBuilder: (context, index) {
                final kw = keywords[index];
                final ratio =
                    maxCount > 0 ? kw.paperCount / maxCount : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: KeywordsScreen._slate200),
                    boxShadow: [
                      BoxShadow(
                        color:
                            KeywordsScreen._slate900.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                                  KeywordsScreen._indigo
                                      .withOpacity(0.8),
                                  KeywordsScreen._violet
                                      .withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: KeywordsScreen._slate900,
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
                                              KeywordsScreen._indigoLight,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                  KeywordsScreen._indigo),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${_formatCount(kw.paperCount)} papers',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: KeywordsScreen._slate600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: KeywordsScreen._slate400),
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

  void _navigateToDetail(
      BuildContext context, SearchProvider provider, KeywordStat kw) {
    if (kw.conceptId == null) return;
    provider.loadKeywordDetail(kw);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KeywordDetailScreen()),
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
            color: KeywordsScreen._slate900,
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
                fontSize: 14,
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
              color: KeywordsScreen._slate600,
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
                gradient: LinearGradient(
                  colors: [
                    KeywordsScreen._indigo.withOpacity(0.1),
                    KeywordsScreen._violet.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: KeywordsScreen._indigo, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: KeywordsScreen._slate600,
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
