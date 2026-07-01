import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';
import '../models/analytics.dart';
import 'keyword_detail_screen.dart';

class KeywordsScreen extends StatelessWidget {
  const KeywordsScreen({super.key});

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

    return Scaffold(
      backgroundColor: _slate50,
      appBar: AppBar(
        title: const Text('Keyword Analysis'),
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
      ),
      body: Builder(
        builder: (context) {
          if (provider.currentTopic.isEmpty) {
            return const _EmptyTab(
              icon: Icons.search_rounded,
              message: 'Please search for a topic on the Home tab first.',
            );
          }

          if (provider.keywordsState == LoadState.loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _indigo),
                  SizedBox(height: 16),
                  Text('Loading keywords statistics...', style: TextStyle(color: _slate600)),
                ],
              ),
            );
          }

          if (provider.keywordsState == LoadState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage ?? 'Failed to load keywords', style: const TextStyle(color: _slate600)),
                ],
              ),
            );
          }

          if (provider.topKeywords.isEmpty) {
            return const _EmptyTab(
              icon: Icons.tag_outlined,
              message: 'No keyword statistics available for this topic.',
            );
          }

          final maxCount = provider.topKeywords.map((e) => e.paperCount).fold(0, max);
          final topKeyword = provider.topKeywords.reduce((a, b) => a.paperCount > b.paperCount ? a : b);

          return RefreshIndicator(
            onRefresh: () => provider.loadTrendAnalysis(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Total Keywords',
                          value: '${provider.topKeywords.length}',
                          icon: Icons.tag_outlined,
                          color: _indigo,
                          bgColor: _indigoLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Top Keyword',
                          value: topKeyword.displayName,
                          icon: Icons.emoji_events_rounded,
                          color: const Color(0xFF059669),
                          bgColor: const Color(0xFFD1FAE5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Keyword distribution bar chart
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _slate200),
                      boxShadow: [
                        BoxShadow(
                          color: _slate900.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keyword Frequency Chart',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _slate900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Render a simple horizontal bar chart
                        ...List.generate(min(5, provider.topKeywords.length), (index) {
                          final kw = provider.topKeywords[index];
                          final ratio = maxCount > 0 ? kw.paperCount / maxCount : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      kw.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _slate900),
                                    ),
                                    Text(
                                      '${kw.paperCount} papers',
                                      style: const TextStyle(fontSize: 11, color: _indigo, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ratio,
                                    minHeight: 8,
                                    backgroundColor: _indigoLight,
                                    valueColor: const AlwaysStoppedAnimation(_indigo),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // List of all Keywords
                  const Text(
                    'Most Frequent Keywords',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _slate900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.topKeywords.length,
                    itemBuilder: (context, index) {
                      final kw = provider.topKeywords[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _slate200),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (kw.conceptId == null) return;
                            provider.loadKeywordDetail(kw);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const KeywordDetailScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _indigoLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.tag_rounded, color: _indigo, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        kw.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: _slate900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Associated works: ${kw.paperCount}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _slate600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _slate400),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: KeywordsScreen._indigoLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: KeywordsScreen._indigo, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: KeywordsScreen._slate600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
