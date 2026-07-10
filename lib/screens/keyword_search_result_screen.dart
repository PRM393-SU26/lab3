import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';
import 'detail_screen.dart';
import 'source_detail_screen.dart';
import 'author_detail_screen.dart';

/// Shows journals (works) and authors relevant to a searched keyword/concept.
/// Uses Theme colors from SettingsProvider for consistency.
class KeywordSearchResultScreen extends StatelessWidget {
  const KeywordSearchResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final keyword = provider.selectedKeyword;
    final cs = Theme.of(context).colorScheme;

    if (keyword == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Keyword Results')),
        body: const Center(child: Text('No keyword selected.')),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: Builder(
        builder: (context) {
          if (provider.keywordDetailState == LoadState.loading) {
            return Scaffold(
              appBar: AppBar(title: Text(keyword.displayName)),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: cs.primary),
                    const SizedBox(height: 16),
                    Text('Loading results…',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            );
          }

          if (provider.keywordDetailState == LoadState.error) {
            return Scaffold(
              appBar: AppBar(title: Text(keyword.displayName)),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: cs.error),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ?? 'Failed to load results',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.searchKeyword(keyword),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // ── App Bar using theme ───────────────────────────
              SliverAppBar(
                expandedHeight: 130,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary,
                          cs.tertiary,
                        ],
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
                                  child: const Icon(Icons.search_rounded,
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
                                        'Search Results · ${_formatCount(keyword.paperCount)} associated works',
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
                              label: 'Works Found',
                              value: '${provider.keywordWorks.length}',
                              icon: Icons.article_rounded,
                              color: cs.primary,
                              bgColor: cs.primaryContainer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiCard(
                              label: 'Authors',
                              value: '${provider.keywordAuthors.length}',
                              icon: Icons.people_rounded,
                              color: cs.secondary,
                              bgColor: cs.secondaryContainer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _KpiCard(
                              label: 'Journals',
                              value: '${provider.keywordJournals.length}',
                              icon: Icons.menu_book_rounded,
                              color: cs.tertiary,
                              bgColor: cs.tertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ═══════════════════════════════════════
                      // RELATED WORKS
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.article_rounded,
                        title: 'Related Works',
                        color: cs.primary,
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
                                          color: cs.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                            Icons.description_outlined,
                                            color: cs.primary,
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
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: cs.onSurface,
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
                                                  color: cs.primary,
                                                ),
                                                const SizedBox(width: 8),
                                                _InfoChip(
                                                  icon: Icons
                                                      .format_quote_rounded,
                                                  label:
                                                      '${work.citedByCount} cited',
                                                  color: cs.tertiary,
                                                ),
                                              ],
                                            ),
                                            if (work.primarySource != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.menu_book_rounded,
                                                      size: 12,
                                                      color: cs.secondary),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      work.primarySource!.displayName,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: cs.onSurfaceVariant,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12,
                                          color: cs.onSurfaceVariant),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      else
                        _EmptySection(message: 'No related works found.'),
                      const SizedBox(height: 24),

                      // ═══════════════════════════════════════
                      // TOP CONTRIBUTING AUTHORS
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.people_rounded,
                        title: 'Top Contributing Authors',
                        color: cs.secondary,
                      ),
                      const SizedBox(height: 12),
                      if (provider.keywordAuthors.isNotEmpty)
                        _buildAuthorsList(context, provider, cs)
                      else
                        _EmptySection(
                            message: 'No contributing authors found.'),
                      const SizedBox(height: 24),

                      // ═══════════════════════════════════════
                      // RELATED JOURNALS
                      // ═══════════════════════════════════════
                      _SectionHeader(
                        icon: Icons.menu_book_rounded,
                        title: 'Related Journals',
                        color: cs.tertiary,
                      ),
                      const SizedBox(height: 12),
                      if (provider.keywordJournals.isNotEmpty)
                        _buildJournalsList(context, provider, cs)
                      else
                        _EmptySection(
                            message: 'No related journals found.'),
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

  Widget _buildAuthorsList(BuildContext context, SearchProvider provider, ColorScheme cs) {
    final goldColor = const Color(0xFFEAB308);
    final silverColor = cs.outline;
    final bronzeColor = const Color(0xFFCD7F32);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.keywordAuthors.length,
      itemBuilder: (context, index) {
        final author = provider.keywordAuthors[index];
        final maxPapers = provider.keywordAuthors.first.paperCount;
        final ratio = maxPapers > 0 ? author.paperCount / maxPapers : 0.0;

        Color? medalColor;
        if (index == 0) medalColor = goldColor;
        else if (index == 1) medalColor = silverColor;
        else if (index == 2) medalColor = bronzeColor;

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

  Widget _buildJournalsList(BuildContext context, SearchProvider provider, ColorScheme cs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: min(10, provider.keywordJournals.length),
      itemBuilder: (context, index) {
        final journal = provider.keywordJournals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.menu_book_rounded,
                  color: cs.tertiary, size: 18),
            ),
            title: Text(
              journal.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: cs.onSurface,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Papers: ${journal.paperCount}',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: cs.onSurfaceVariant),
            onTap: () {
              if (journal.sourceId == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SourceDetailScreen(
                    sourceId: journal.sourceId!,
                    sourceName: journal.displayName,
                  ),
                ),
              );
            },
          ),
        );
      },
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
          style: TextStyle(
            fontWeight: FontWeight.w700,
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
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
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

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              size: 32, color: cs.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
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
