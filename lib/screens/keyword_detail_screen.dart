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

  static const _indigo      = Color(0xFF4F46E5);
  static const _indigoLight = Color(0xFFEEF2FF);
  static const _slate50    = Color(0xFFF8FAFC);
  static const _slate200    = Color(0xFFE2E8F0);
  static const _slate400    = Color(0xFF94A3B8);
  static const _slate600    = Color(0xFF475569);
  static const _slate900    = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final keyword = provider.selectedKeyword;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _slate50,
      appBar: AppBar(
        title: Text(keyword?.displayName ?? 'Keyword Detail'),
        backgroundColor: Colors.white,
        foregroundColor: _slate900,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _slate200, height: 1),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (keyword == null) {
            return const Center(child: Text('No keyword selected.'));
          }

          if (provider.keywordDetailState == LoadState.loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _indigo),
                  SizedBox(height: 16),
                  Text('Loading analytical details...', style: TextStyle(color: _slate600)),
                ],
              ),
            );
          }

          if (provider.keywordDetailState == LoadState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage ?? 'Failed to load keyword analysis', style: const TextStyle(color: _slate600)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadKeywordDetail(keyword),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Compute peak year
          YearlyCount? peakYear;
          for (final y in provider.keywordTrend) {
            if (peakYear == null || y.count > peakYear.count) peakYear = y;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Keyword Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _slate200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _indigoLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.tag, color: _indigo, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              keyword.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _slate900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Topic Research Concept',
                              style: TextStyle(color: _slate600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Publication trend chart
                const Text(
                  'Publication Trend Over Time',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _slate900),
                ),
                const SizedBox(height: 10),
                if (provider.keywordTrend.isNotEmpty)
                  Container(
                    height: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _slate200),
                    ),
                    child: _TrendBarChart(trend: provider.keywordTrend),
                  )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No trend statistics available.'),
                    ),
                  ),
                const SizedBox(height: 24),

                // Top contributing authors (ranked descending)
                const Text(
                  'Top Contributing Authors',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _slate900),
                ),
                const SizedBox(height: 10),
                if (provider.keywordAuthors.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.keywordAuthors.length,
                    itemBuilder: (context, index) {
                      final author = provider.keywordAuthors[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _slate200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _indigoLight,
                            child: Text(
                              '#${index + 1}',
                              style: const TextStyle(
                                color: _indigo,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            author.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _slate900),
                          ),
                          subtitle: Text(
                            'Publications: ${author.paperCount}',
                            style: const TextStyle(fontSize: 11, color: _slate600),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _slate400),
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
                  )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No author contributions found.'),
                    ),
                  ),
                const SizedBox(height: 24),

                // Related Journals
                const Text(
                  'Related Journals',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _slate900),
                ),
                const SizedBox(height: 10),
                if (provider.keywordJournals.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: min(5, provider.keywordJournals.length),
                    itemBuilder: (context, index) {
                      final journal = provider.keywordJournals[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _slate200),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFD1FAE5), // emerald
                            child: Icon(Icons.menu_book, color: Color(0xFF059669), size: 16),
                          ),
                          title: Text(
                            journal.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _slate900),
                          ),
                          subtitle: Text(
                            'Papers in this field: ${journal.paperCount}',
                            style: const TextStyle(fontSize: 11, color: _slate600),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _slate400),
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
                  )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No related journals found.'),
                    ),
                  ),
                const SizedBox(height: 24),

                // Related Publications
                const Text(
                  'Related Publications',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _slate900),
                ),
                const SizedBox(height: 10),
                if (provider.keywordWorks.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.keywordWorks.length,
                    itemBuilder: (context, index) {
                      final work = provider.keywordWorks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: _slate200),
                        ),
                        child: ListTile(
                          title: Text(
                            work.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _slate900),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Year: ${work.publicationYear ?? "N/A"}  ·  Citations: ${work.citedByCount}',
                              style: const TextStyle(fontSize: 11, color: _slate600),
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _slate400),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(workId: work.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No related publications found.'),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrendBarChart extends StatelessWidget {
  final List<YearlyCount> trend;

  const _TrendBarChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox();

    final maxCount = trend.map((e) => e.count).fold(0, max);

    // Limit to latest 10 years for chart clarity
    final displayTrend = trend.length > 8 ? trend.sublist(trend.length - 8) : trend;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: displayTrend.map((y) {
        final ratio = maxCount > 0 ? y.count / maxCount : 0.0;
        final barHeight = ratio * 100.0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${y.count}',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: KeywordDetailScreen._indigo),
            ),
            const SizedBox(height: 4),
            Container(
              width: 16,
              height: max(2, barHeight),
              decoration: BoxDecoration(
                color: KeywordDetailScreen._indigo,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${y.year}',
              style: const TextStyle(fontSize: 8, color: KeywordDetailScreen._slate600),
            ),
          ],
        );
      }).toList(),
    );
  }
}
