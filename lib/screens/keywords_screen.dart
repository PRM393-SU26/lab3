import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';
import '../models/analytics.dart';
import 'keyword_detail_screen.dart';

class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({super.key});

  
  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  bool _loaded = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    final keywords = provider.globalKeywords;
    final loadState = provider.globalKeywordsState;
    final headerLabel = 'Trending Research Keywords';
    final subtitleLabel =
        '${keywords.length} most popular research concepts globally';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Keyword Analysis')),
      body: _buildBody(
        context,
        provider,
        keywords,
        loadState,
        headerLabel,
        subtitleLabel));
  }

  Widget _buildBody(
    BuildContext context,
    SearchProvider provider,
    List<KeywordStat> keywords,
    LoadState loadState,
    String headerLabel,
    String subtitleLabel) {
    if (loadState == LoadState.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 16),
            Text(
              'Loading keywords…',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]));
    }

    if (loadState == LoadState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'Failed to load keywords',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.loadGlobalKeywords(),
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white)),
          ]));
    }

    if (keywords.isEmpty) {
      return _EmptyTab(
        icon: Icons.tag_outlined,
        message: 'No keyword data available.');
    }

    List<KeywordStat> filteredKeywords = keywords;
    if (_searchQuery.isNotEmpty) {
      filteredKeywords = keywords
          .where((k) => k.displayName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    final maxCount = filteredKeywords.isNotEmpty 
        ? filteredKeywords.map((e) => e.paperCount).fold(0, max) 
        : 0;
    final topKeyword = filteredKeywords.isNotEmpty 
        ? filteredKeywords.reduce((a, b) => a.paperCount > b.paperCount ? a : b)
        : null;
    final totalPapers = filteredKeywords.fold<int>(0, (s, k) => s + k.paperCount);

    // Trending: top 3 by paper count
    final trendingKeywords = List<KeywordStat>.from(filteredKeywords)
      ..sort((a, b) => b.paperCount.compareTo(a.paperCount));
    final trending = trendingKeywords.take(3).toList();

    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () => provider.loadGlobalKeywords(),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header banner ────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(
                      0.25),
                    blurRadius: 16,
                    offset: Offset(0, 6)),
                ]),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      Icons.tag_rounded, color: Colors.white,
                      size: 22)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                        SizedBox(height: 4),
                        Text(
                          subtitleLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12)),
                      ])),
                ])),
            SizedBox(height: 16),
            
            // ── Search bar ───────────────────────────────────
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search keywords...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant
                      .withOpacity(0.5),
                ),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            SizedBox(height: 16),

            if (filteredKeywords.isEmpty)
              _EmptyTab(
                icon: Icons.search_off_rounded,
                message: 'No keywords match your search.',
              )
            else ...[

            // ── KPI cards ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: 'Total Keywords',
                    value: '${filteredKeywords.length}',
                    icon: Icons.tag_outlined, color: Theme.of(context).colorScheme.primary,
                    bgColor: Theme.of(context).colorScheme.primaryContainer)),
                SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'Top Keyword',
                    value: topKeyword?.displayName ?? 'N/A',
                    icon: Icons.emoji_events_rounded, color: Theme.of(context).colorScheme.secondary,
                    bgColor: Theme.of(context).colorScheme.secondaryContainer)),
                SizedBox(width: 10),
                Expanded(
                  child: _KpiCard(
                    label: 'Total Works',
                    value: _formatCount(totalPapers),
                    icon: Icons.article_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant,
                    bgColor: Theme.of(context).colorScheme.surfaceContainerHighest)),
              ]),
            SizedBox(height: 24),

            // ── Trending keywords ────────────────────────────
            _SectionHeader(
              icon: Icons.trending_up_rounded,
              title: 'Trending Keywords', color: Theme.of(context).colorScheme.error),
            SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: trending.length,
                separatorBuilder: (_, i) => SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final kw = trending[index];
                  final colors = [
                    [Theme.of(context).colorScheme.error, Theme.of(context).colorScheme.errorContainer],
                    [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
                    [Theme.of(context).colorScheme.tertiary, Theme.of(context).colorScheme.tertiaryContainer],
                  ];
                  final pair = colors[index % colors.length];

                  return GestureDetector(
                    onTap: () => _navigateToDetail(context, provider, kw),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300 + index * 100),
                      curve: Curves.easeOut,
                      width: 180,
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: pair[1],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: pair[0].withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: pair[0].withOpacity(0.08),
                            blurRadius: 8,
                            offset: Offset(0, 3)),
                        ]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: 16, color: pair[0]),
                              SizedBox(width: 4),
                              Text(
                                '#${index + 1} Trending',
                                style: TextStyle(
                                  fontSize: 10, color: pair[0])),
                            ]),
                          SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              kw.displayName,
                              style: TextStyle(
                                fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis)),
                          SizedBox(height: 4),
                          Text(
                            '${_formatCount(kw.paperCount)} papers',
                            style: TextStyle(
                              fontSize: 11, color: pair[0])),
                        ])));
                })),
            SizedBox(height: 24),

            // ── Keyword frequency chart ──────────────────────
            _SectionHeader(
              icon: Icons.bar_chart_rounded,
              title: 'Keyword Frequency Chart', color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface
                        .withOpacity(0.03),
                    blurRadius: 10,
                    offset: Offset(0, 4)),
                ]),
              child: Column(
                children: List.generate(min(8, filteredKeywords.length), (index) {
                  final kw = filteredKeywords[index];
                  final ratio = maxCount > 0 ? kw.paperCount / maxCount : 0.0;
                  final barColors = [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary,
                    Theme.of(context).colorScheme.onSurfaceVariant,
                    Theme.of(context).colorScheme.error,
                    Theme.of(context).colorScheme.outline,
                    Theme.of(context).colorScheme.inversePrimary,
                  ];
                  final barColor = barColors[index % barColors.length];

                  return Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _navigateToDetail(context, provider, kw),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  kw.displayName,
                                  style: TextStyle(
                                    
                                    fontSize: 12, color: Theme.of(context).colorScheme
                                        .onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2),
                                decoration: BoxDecoration(
                                  color: barColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  _formatCount(kw.paperCount),
                                  style: TextStyle(
                                    fontSize: 11, color: barColor))),
                            ]),
                          SizedBox(height: 6),
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
                                  backgroundColor: barColor.withOpacity(0.08),
                                  valueColor: AlwaysStoppedAnimation(barColor));
                              })),
                        ])));
                }))),
            SizedBox(height: 24),

            // ── Keyword Statistics ───────────────────────────
            _SectionHeader(
              icon: Icons.table_chart_rounded,
              title: 'Keyword Statistics', color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface
                        .withOpacity(0.03),
                    blurRadius: 10,
                    offset: Offset(0, 4)),
                ]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.primaryContainer),
                  columnSpacing: 16,
                  horizontalMargin: 16,
                  headingTextStyle: TextStyle(
                    
                    fontSize: 12, color: Theme.of(context).colorScheme.primary),
                  dataTextStyle: TextStyle(
                    fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                  columns: [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Keyword')),
                    DataColumn(label: Text('Papers'), numeric: true),
                    DataColumn(label: Text('Share'), numeric: true),
                  ],
                  rows: List.generate(min(10, filteredKeywords.length), (index) {
                    final kw = filteredKeywords[index];
                    final share = totalPapers > 0
                        ? (kw.paperCount / totalPapers * 100)
                        : 0.0;
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '${index + 1}',
                            style: TextStyle())),
                        DataCell(
                          InkWell(
                            onTap: () =>
                                _navigateToDetail(context, provider, kw),
                            child: Text(
                              kw.displayName,
                              style: TextStyle(
                                
                                color: Theme.of(context).colorScheme.primary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis))),
                        DataCell(Text(_formatCount(kw.paperCount))),
                        DataCell(Text('${share.toStringAsFixed(1)}%')),
                      ]);
                  })))),
            SizedBox(height: 24),

            // ── Most Frequent Keywords list ──────────────────
            _SectionHeader(
              icon: Icons.list_rounded,
              title: 'Most Frequent Keywords', color: Theme.of(context).colorScheme.secondary),
            SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filteredKeywords.length,
              itemBuilder: (context, index) {
                final kw = filteredKeywords[index];
                final ratio = maxCount > 0 ? kw.paperCount / maxCount : 0.0;

                return Container(
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface
                            .withOpacity(0.02),
                        blurRadius: 6,
                        offset: Offset(0, 2)),
                    ]),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _navigateToDetail(context, provider, kw),
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary
                                      .withOpacity(0.8),
                                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                ]),
                              borderRadius: BorderRadius.circular(10)),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  
                                  fontSize: 13)))),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kw.displayName,
                                  style: TextStyle(
                                    
                                    fontSize: 13, color: Theme.of(context).colorScheme
                                        .onSurface)),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: ratio,
                                          minHeight: 5,
                                          backgroundColor: Theme.of(context).colorScheme
                                              .primaryContainer,
                                          valueColor:
                                              AlwaysStoppedAnimation(
                                                Theme.of(context).colorScheme
                                                    .primary)))),
                                    SizedBox(width: 10),
                                    Text(
                                      '${_formatCount(kw.paperCount)} papers',
                                      style: TextStyle(
                                        fontSize: 11, color: Theme.of(context).colorScheme
                                            .onSurfaceVariant)),
                                  ]),
                              ])),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14, color: Theme.of(context).colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.5)),
                        ]))));
              }),
            SizedBox(height: 32),
            ],
          ])));
  }

  void _navigateToDetail(
    BuildContext context,
    SearchProvider provider,
    KeywordStat kw) {
    if (kw.conceptId == null) return;
    provider.loadKeywordDetail(kw);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => KeywordDetailScreen()));
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
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color)),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            
            fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
      ]);
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 3)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 14)),
          SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14, color: color))),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]));
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
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ]),
                borderRadius: BorderRadius.circular(20)),
              child: Icon(
                icon, color: Theme.of(context).colorScheme.primary,
                size: 32)),
            SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          ])));
  }
}
