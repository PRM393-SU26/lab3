import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';
import '../models/analytics.dart';
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
  static const _slate50    = Color(0xFFF8FAFC);

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
                  YearlyTrendTab(provider: provider),
                  TopPapersTab(provider: provider),
                  TopJournalsTab(provider: provider),
                  TopAuthorsTab(provider: provider),
                  CountriesTab(provider: provider),
                ],
              ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Tab: Yearly Trend
// ────────────────────────────────────────────────────────────────────────────

class YearlyTrendTab extends StatefulWidget {
  final SearchProvider provider;

  const YearlyTrendTab({super.key, required this.provider});

  @override
  State<YearlyTrendTab> createState() => _YearlyTrendTabState();
}

class _YearlyTrendTabState extends State<YearlyTrendTab> {
  static const _indigo     = Color(0xFF4F46E5);
  static const _indigoLight= Color(0xFFEEF2FF);
  static const _indigoDark = Color(0xFF3730A3);
  static const _slate200   = Color(0xFFE2E8F0);
  static const _slate600   = Color(0xFF475569);
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
                  child: _LineChart(
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

class _LineChart extends StatelessWidget {
  final List<dynamic> data;
  final int maxCount;
  final int peakYear;

  static const _indigo     = Color(0xFF4F46E5);
  static const _indigoLight= Color(0xFFEEF2FF);
  static const _indigoDark = Color(0xFF3730A3);
  static const _amber      = Color(0xFFD97706);
  static const _slate200   = Color(0xFFE2E8F0);
  static const _slate400   = Color(0xFF94A3B8);
  static const _slate600   = Color(0xFF475569);
  static const _slate900   = Color(0xFF0F172A);

  const _LineChart({
    required this.data,
    required this.maxCount,
    required this.peakYear,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        final double paddingX = 16.0;
        final double paddingY = 24.0;
        final double w = width - 2 * paddingX;
        final double h = height - 2 * paddingY;

        final double stepX = data.length > 1 ? w / (data.length - 1) : w;

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _LineChartPainter(
                  data: data,
                  maxCount: maxCount,
                  peakYear: peakYear,
                  lineColor: _indigo,
                  fillColor: _indigo,
                ),
              ),
            ),

            for (int i = 0; i < data.length; i++) ...[
              if (data[i].year == peakYear)
                Positioned(
                  left: paddingX + i * stepX - 30,
                  top: paddingY + h * (1.0 - (data[i].count / (maxCount > 0 ? maxCount : 1))) - 22,
                  child: Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _amber.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${data[i].count}',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: _amber,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
            ],

            for (int i = 0; i < data.length; i++)
              Positioned(
                left: paddingX + i * stepX - 18,
                top: paddingY,
                width: 36,
                height: h,
                child: Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  message: '${data[i].year}: ${data[i].count} papers',
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),

            for (int i = 0; i < data.length; i++)
              Positioned(
                left: paddingX + i * stepX - 20,
                bottom: 2,
                width: 40,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${data[i].year}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: data[i].year == peakYear ? FontWeight.bold : FontWeight.normal,
                        color: data[i].year == peakYear ? _amber : _slate400,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<dynamic> data;
  final int maxCount;
  final int peakYear;
  final Color lineColor;
  final Color fillColor;

  _LineChartPainter({
    required this.data,
    required this.maxCount,
    required this.peakYear,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double paddingX = 16.0;
    final double paddingY = 24.0;
    final double w = size.width - 2 * paddingX;
    final double h = size.height - 2 * paddingY;

    final double stepX = data.length > 1 ? w / (data.length - 1) : w;

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 4; i++) {
      final double y = paddingY + h * (i / 4.0);
      canvas.drawLine(Offset(paddingX, y), Offset(paddingX + w, y), gridPaint);
    }

    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      final ratio = maxCount > 0 ? entry.count / maxCount : 0.0;
      final double x = paddingX + i * stepX;
      final double y = paddingY + h * (1.0 - ratio);
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final pathFill = Path();
      pathFill.moveTo(points.first.dx, paddingY + h);
      for (final pt in points) {
        pathFill.lineTo(pt.dx, pt.dy);
      }
      pathFill.lineTo(points.last.dx, paddingY + h);
      pathFill.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fillColor.withOpacity(0.4),
            fillColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTRB(paddingX, paddingY, paddingX + w, paddingY + h))
        ..style = PaintingStyle.fill;

      canvas.drawPath(pathFill, fillPaint);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (points.length > 1) {
      final pathLine = Path();
      pathLine.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        pathLine.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(pathLine, linePaint);
    }

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final entry = data[i];
      final pt = points[i];
      final isPeak = entry.year == peakYear;

      if (isPeak) {
        final peakPaint = Paint()
          ..color = const Color(0xFFD97706)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, 6.0, peakPaint);
        canvas.drawCircle(pt, 6.0, dotPaint..color = Colors.white);
        canvas.drawCircle(pt, 6.0, dotPaint..color = const Color(0xFFD97706).withOpacity(0.2));
      } else {
        canvas.drawCircle(pt, 4.0, dotPaint..color = Colors.white);
        canvas.drawCircle(pt, 4.0, dotBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.maxCount != maxCount ||
        oldDelegate.peakYear != peakYear;
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

class TopPapersTab extends StatelessWidget {
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

  const TopPapersTab({super.key, required this.provider});

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

class TopJournalsTab extends StatelessWidget {
  final SearchProvider provider;

  static const _indigo      = Color(0xFF4F46E5);
  static const _indigoLight = Color(0xFFEEF2FF);
  static const _slate200    = Color(0xFFE2E8F0);
  static const _slate900    = Color(0xFF0F172A);
  static const _slate600    = Color(0xFF475569);

  const TopJournalsTab({super.key, required this.provider});

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

    // Find the journal with max paperCount for display
    final topJournal = provider.topJournals.reduce((a, b) => a.paperCount > b.paperCount ? a : b);
    // Find max hIndex
    final maxHIndex = provider.topJournals.map((e) => e.hIndex).fold(0, max);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat cards ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Journals',
                  value: '${provider.topJournals.length}',
                  icon: Icons.menu_book_rounded,
                  color: _indigo,
                  bgColor: _indigoLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Max H-Index',
                  value: '$maxHIndex',
                  icon: Icons.show_chart_rounded,
                  color: const Color(0xFFD97706), // amber
                  bgColor: const Color(0xFFFEF3C7), // amberLight
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Top Journal',
                  value: topJournal.displayName,
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFF059669), // emerald
                  bgColor: const Color(0xFFD1FAE5), // emeraldLight
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Bubble Chart section ───────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Journal Matrix (Bubble)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _slate900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'X: H-Index · Y: Papers · Color/Size: Citations',
                          style: TextStyle(fontSize: 11, color: _slate600),
                        ),
                      ],
                    ),
                    // Legend
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Citations',
                          style: TextStyle(fontSize: 9, color: _slate600, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Min', style: TextStyle(fontSize: 8, color: _slate600)),
                            const SizedBox(width: 4),
                            Container(
                              width: 50,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0000FF), // Blue
                                    Color(0xFF00FFFF), // Cyan
                                    Color(0xFF00FF00), // Green
                                    Color(0xFFFFFF00), // Yellow
                                    Color(0xFFFF0000), // Red
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Max', style: TextStyle(fontSize: 8, color: _slate600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 240,
                  child: _BubbleChart(data: provider.topJournals),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Journal Rankings Title ──────────────────────────────
          const Text(
            'Journal Rankings',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: _slate900,
            ),
          ),
          const SizedBox(height: 12),

          // ── Journal Rankings List ───────────────────────────────
          ...List.generate(provider.topJournals.length, (index) {
            final j = provider.topJournals[index];
            final ratio = maxCount > 0 ? j.paperCount / maxCount : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    if (j.sourceId == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SourceDetailScreen(
                          sourceId: j.sourceId!,
                          sourceName: j.displayName,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Rank number
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: index == 0 ? _indigo : _indigoLight,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: index == 0 ? Colors.white : _indigo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name + subtitle + bar
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                j.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _slate900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${j.paperCount} papers',
                                    style: const TextStyle(fontSize: 10, color: _slate600, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(width: 3, height: 3, decoration: const BoxDecoration(color: _slate600, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'H-Index: ${j.hIndex}',
                                    style: const TextStyle(fontSize: 10, color: _slate600, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(width: 3, height: 3, decoration: const BoxDecoration(color: _slate600, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Citations: ${_formatNumber(j.citationCount)}',
                                    style: const TextStyle(fontSize: 10, color: _slate600, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Progress bar
                              Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _indigoLight,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: ratio,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _indigo,
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
                        const Icon(Icons.chevron_right_rounded, color: _slate600, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _BubbleChart extends StatefulWidget {
  final List<JournalStat> data;

  const _BubbleChart({required this.data});

  @override
  State<_BubbleChart> createState() => _BubbleChartState();
}

class _BubbleChartState extends State<_BubbleChart> {
  int? _selectedIndex;

  Color _getRGBColor(double ratio) {
    ratio = ratio.clamp(0.0, 1.0);
    final colors = [
      const Color(0xFF0000FF), // Blue (0, 0, 255)
      const Color(0xFF00FFFF), // Cyan (0, 255, 255)
      const Color(0xFF00FF00), // Green (0, 255, 0)
      const Color(0xFFFFFF00), // Yellow (255, 255, 0)
      const Color(0xFFFF0000), // Red (255, 0, 0)
    ];
    if (ratio == 0.0) return colors.first;
    if (ratio == 1.0) return colors.last;

    final double segment = 1.0 / (colors.length - 1); // 0.25
    final int index = (ratio / segment).floor();
    final double localRatio = (ratio - index * segment) / segment;

    return Color.lerp(colors[index], colors[index + 1], localRatio)!;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    // Calculate ranges
    int maxHIndex = widget.data.map((e) => e.hIndex).fold(0, max);
    if (maxHIndex <= 0) maxHIndex = 50; // default minimum scale
    int maxPaperCount = widget.data.map((e) => e.paperCount).fold(0, max);
    if (maxPaperCount <= 0) maxPaperCount = 10;
    int maxCitations = widget.data.map((e) => e.citationCount).fold(0, max);
    if (maxCitations <= 0) maxCitations = 1000;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        final double paddingLeft = 32.0;
        final double paddingRight = 16.0;
        final double paddingTop = 20.0;
        final double paddingBottom = 32.0;

        final double chartWidth = width - paddingLeft - paddingRight;
        final double chartHeight = height - paddingTop - paddingBottom;

        // Map data points to positions
        final List<Offset> points = [];
        final List<double> radii = [];
        final List<Color> colors = [];

        for (var stat in widget.data) {
          final double xRatio = maxHIndex > 0 ? stat.hIndex / maxHIndex : 0.0;
          final double yRatio = maxPaperCount > 0 ? stat.paperCount / maxPaperCount : 0.0;
          final double citeRatio = maxCitations > 0 ? stat.citationCount / maxCitations : 0.0;

          final double px = paddingLeft + xRatio * chartWidth;
          final double py = paddingTop + (1.0 - yRatio) * chartHeight;

          points.add(Offset(px, py));

          // Radius between 6.0 and 20.0
          final double r = 6.0 + citeRatio * 14.0;
          radii.add(r);

          // Color based on citation count (0-255 RGB spread)
          final Color bubbleColor = _getRGBColor(citeRatio);
          colors.add(bubbleColor);
        }

        return GestureDetector(
          onTapDown: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(details.globalPosition);

            int? closestIndex;
            double minDistance = double.infinity;

            for (int i = 0; i < points.length; i++) {
              final double dist = (localPosition - points[i]).distance;
              // If tap is within the bubble radius + 15px margin
              if (dist < radii[i] + 15.0 && dist < minDistance) {
                minDistance = dist;
                closestIndex = i;
              }
            }

            setState(() {
              _selectedIndex = (_selectedIndex == closestIndex) ? null : closestIndex;
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BubbleChartPainter(
                    data: widget.data,
                    points: points,
                    radii: radii,
                    colors: colors,
                    maxHIndex: maxHIndex,
                    maxPaperCount: maxPaperCount,
                    selectedIndex: _selectedIndex,
                    paddingLeft: paddingLeft,
                    paddingRight: paddingRight,
                    paddingTop: paddingTop,
                    paddingBottom: paddingBottom,
                  ),
                ),
              ),

              // Tooltip overlay
              if (_selectedIndex != null && _selectedIndex! < widget.data.length) () {
                final stat = widget.data[_selectedIndex!];
                final pt = points[_selectedIndex!];
                final r = radii[_selectedIndex!];

                // Determine tooltip position
                final double tooltipW = 160.0;
                final double tooltipH = 80.0;
                final double tx = (pt.dx - tooltipW / 2).clamp(10.0, width - tooltipW - 10.0);
                double ty = pt.dy - r - tooltipH - 8;
                if (ty < 5.0) {
                  ty = pt.dy + r + 8;
                }

                return Positioned(
                  left: tx,
                  top: ty,
                  width: tooltipW,
                  height: tooltipH,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A), // Slate 900
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          stat.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'H-Index:',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                            ),
                            Text(
                              '${stat.hIndex}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Papers:',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                            ),
                            Text(
                              '${stat.paperCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Citations:',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                            ),
                            Text(
                              _formatNumber(stat.citationCount),
                              style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }(),
            ],
          ),
        );
      },
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _BubbleChartPainter extends CustomPainter {
  final List<JournalStat> data;
  final List<Offset> points;
  final List<double> radii;
  final List<Color> colors;
  final int maxHIndex;
  final int maxPaperCount;
  final int? selectedIndex;
  final double paddingLeft;
  final double paddingRight;
  final double paddingTop;
  final double paddingBottom;

  _BubbleChartPainter({
    required this.data,
    required this.points,
    required this.radii,
    required this.colors,
    required this.maxHIndex,
    required this.maxPaperCount,
    required this.selectedIndex,
    required this.paddingLeft,
    required this.paddingRight,
    required this.paddingTop,
    required this.paddingBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;

    // Horizontal grid lines (Y-axis ticks)
    for (int i = 0; i <= 4; i++) {
      final double y = paddingTop + chartHeight * (1.0 - i / 4.0);
      canvas.drawLine(Offset(paddingLeft, y), Offset(paddingLeft + chartWidth, y), gridPaint);

      // Y-axis labels (papers)
      final int paperVal = (maxPaperCount * i / 4).round();
      final textSpan = TextSpan(
        text: '$paperVal',
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // Vertical grid lines (X-axis ticks)
    for (int i = 0; i <= 4; i++) {
      final double x = paddingLeft + chartWidth * (i / 4.0);
      canvas.drawLine(Offset(x, paddingTop), Offset(x, paddingTop + chartHeight), gridPaint);

      // X-axis labels (h-index)
      final int hVal = (maxHIndex * i / 4).round();
      final textSpan = TextSpan(
        text: '$hVal',
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, paddingTop + chartHeight + 6),
      );
    }

    // Draw Y axis line
    canvas.drawLine(
      Offset(paddingLeft, paddingTop),
      Offset(paddingLeft, paddingTop + chartHeight),
      axisPaint,
    );

    // Draw X axis line
    canvas.drawLine(
      Offset(paddingLeft, paddingTop + chartHeight),
      Offset(paddingLeft + chartWidth, paddingTop + chartHeight),
      axisPaint,
    );

    // Axis titles
    const xTitleSpan = TextSpan(
      text: 'Journal H-Index',
      style: TextStyle(
        color: Color(0xFF475569),
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
      ),
    );
    final xTitlePainter = TextPainter(
      text: xTitleSpan,
      textDirection: TextDirection.ltr,
    );
    xTitlePainter.layout();
    xTitlePainter.paint(
      canvas,
      Offset(paddingLeft + chartWidth / 2 - xTitlePainter.width / 2, paddingTop + chartHeight + 20),
    );

    // Draw bubbles
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final r = radii[i];
      final baseColor = colors[i];
      final isSelected = selectedIndex == i;

      // Draw shadow/glow under selected bubble
      if (isSelected) {
        final glowPaint = Paint()
          ..color = baseColor.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(pt, r + 4.0, glowPaint);
      }

      // Fill
      final fillPaint = Paint()
        ..color = isSelected ? baseColor : baseColor.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, r, fillPaint);

      // Border
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : baseColor
        ..strokeWidth = isSelected ? 2.0 : 1.0;
      borderPaint.style = PaintingStyle.stroke;
      canvas.drawCircle(pt, r, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.points != points ||
        oldDelegate.radii != radii ||
        oldDelegate.colors != colors;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Tab: Top Authors
// ────────────────────────────────────────────────────────────────────────────

class TopAuthorsTab extends StatelessWidget {
  final SearchProvider provider;

  static const _violet      = Color(0xFF7C3AED);
  static const _violetLight = Color(0xFFF5F3FF);
  static const _slate900    = Color(0xFF0F172A);
  static const _slate200    = Color(0xFFE2E8F0);

  const TopAuthorsTab({super.key, required this.provider});

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
    final topAuthor = provider.topAuthors.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat cards ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Authors',
                  value: '${provider.topAuthors.length}',
                  icon: Icons.people_outline_rounded,
                  color: _violet,
                  bgColor: _violetLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Top Author',
                  value: topAuthor.displayName,
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFD97706), // amber
                  bgColor: const Color(0xFFFEF3C7), // amberLight
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Max Papers',
                  value: '${topAuthor.paperCount}',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF059669), // emerald
                  bgColor: const Color(0xFFD1FAE5), // emeraldLight
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Chart section ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
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
                const Text(
                  'Author Publication Volume',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: _slate900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Top authors ranked by publication count.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 24),
                _HorizontalBarChart(
                  data: provider.topAuthors,
                  maxCount: maxCount,
                  color: _violet,
                  bgColor: _violetLight,
                  onItemTap: (item) {
                    if (item.authorId == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuthorDetailScreen(
                          authorId: item.authorId!,
                          authorName: item.displayName,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalBarChart extends StatelessWidget {
  final List<dynamic> data; // List of AuthorStat
  final int maxCount;
  final Color color;
  final Color bgColor;
  final void Function(dynamic item) onItemTap;

  const _HorizontalBarChart({
    required this.data,
    required this.maxCount,
    required this.color,
    required this.bgColor,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Background Grid Lines (at 0%, 25%, 50%, 75%, 100%)
            Positioned.fill(
              bottom: 24, // leave space for bottom scale axis
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  return Container(
                    width: 1,
                    color: const Color(0xFFE2E8F0).withOpacity(0.6),
                  );
                }),
              ),
            ),
            
            // Chart Content (Bars, labels, and bottom scale)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...List.generate(data.length, (index) {
                  final item = data[index];
                  final ratio = maxCount > 0 ? item.paperCount / maxCount : 0.0;
                  final isMedal = index < 3;
                  
                  final medalColors = [
                    const Color(0xFFD97706), // gold
                    const Color(0xFF94A3B8), // silver
                    const Color(0xFFB45309), // bronze
                  ];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: InkWell(
                      onTap: () => onItemTap(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author name & paper count
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    // Rank Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isMedal 
                                            ? medalColors[index].withOpacity(0.12)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '#${index + 1}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isMedal ? medalColors[index] : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${item.paperCount} ${item.paperCount == 1 ? 'paper' : 'papers'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            
                            // Horizontal Bar representation
                            Row(
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      // Track background
                                      Container(
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: bgColor.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      // Filled portion
                                      FractionallySizedBox(
                                        widthFactor: ratio,
                                        child: Container(
                                          height: 12,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                color.withOpacity(0.7),
                                                color,
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: color.withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
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
                  );
                }),
                
                const SizedBox(height: 8),
                // X-Axis Baseline
                Container(
                  height: 1,
                  color: const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 4),
                // X-Axis Tick Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) {
                    final val = (maxCount * index / 4).round();
                    return Text(
                      '$val',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Tab: Countries
// ────────────────────────────────────────────────────────────────────────────

class CountriesTab extends StatelessWidget {
  final SearchProvider provider;

  static const _emerald = Color(0xFF059669);
  static const _emeraldLight = Color(0xFFD1FAE5);
  static const _slate900 = Color(0xFF0F172A);
  static const _slate600 = Color(0xFF475569);
  static const _slate200 = Color(0xFFE2E8F0);

  const CountriesTab({super.key, required this.provider});

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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Heatmap Matrix Section ──────────────────────────────
          _CountryTopicHeatmapCard(provider: provider),
          const SizedBox(height: 24),

          // ── Country Rankings Title ──────────────────────────────
          const Text(
            'Country Rankings',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: _slate900,
            ),
          ),
          const SizedBox(height: 10),

          // ── Country Rankings List (Flat layout) ─────────────────
          ...List.generate(provider.countryBreakdown.length, (index) {
            final c = provider.countryBreakdown[index];
            final ratio = maxCount > 0 ? c.paperCount / maxCount : 0.0;

            return Container(
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
                      color: index == 0 ? _emerald : _emeraldLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: index == 0 ? Colors.white : _emerald,
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
                          c.displayName,
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
                                color: _emeraldLight,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: ratio,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _emerald,
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
                      color: _emeraldLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${c.paperCount} papers',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _emerald,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CountryTopicHeatmapCard extends StatelessWidget {
  final SearchProvider provider;

  const _CountryTopicHeatmapCard({required this.provider});

  static const _emerald = Color(0xFF059669);
  static const _emeraldLight = Color(0xFFD1FAE5);
  static const _slate50 = Color(0xFFF8FAFC);
  static const _slate100 = Color(0xFFF1F5F9);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate400 = Color(0xFF94A3B8);
  static const _slate600 = Color(0xFF475569);
  static const _slate900 = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    if (provider.countryMatrixState == LoadState.loading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _slate200),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: _emerald),
        ),
      );
    }

    if (provider.countryMatrixState == LoadState.error) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _slate200),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
            const SizedBox(height: 12),
            Text(
              'Could not load Country-Topic matrix: ${provider.errorMessage ?? "Unknown error"}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _slate600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final matrix = provider.countryMatrix;
    if (matrix.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find the maximum value in the matrix for color scaling
    int maxVal = 0;
    for (final code in matrix.countryCodes) {
      for (final topic in matrix.topics) {
        final val = matrix.data[code]?[topic] ?? 0;
        if (val > maxVal) maxVal = val;
      }
    }
    if (maxVal == 0) maxVal = 1;

    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _emeraldLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.grid_on_rounded, color: _emerald, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Country-Topic Matrix',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _slate900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Searched topics by country (heatmap)',
                      style: TextStyle(fontSize: 11, color: _slate600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scrollable Matrix Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(55),
              columnWidths: {
                0: const FixedColumnWidth(115),
                for (int i = 1; i <= matrix.countryCodes.length; i++)
                  i: const FixedColumnWidth(48),
              },
              border: TableBorder.all(
                color: _slate100,
                width: 1,
                borderRadius: BorderRadius.circular(6),
              ),
              children: [
                // Header row
                TableRow(
                  decoration: const BoxDecoration(
                    color: _slate50,
                  ),
                  children: [
                    // Topic Header
                    const TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Text(
                          'Searched Topic',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _slate600,
                          ),
                        ),
                      ),
                    ),
                    // Country Headers
                    ...matrix.countryCodes.map(
                      (code) => TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _emeraldLight.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                code,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _emerald,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Data rows
                ...matrix.topics.map((topic) {
                  return TableRow(
                    children: [
                      // Topic Name Cell
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Text(
                            topic,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _slate900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Heatmap Data Cells
                      ...matrix.countryCodes.map((code) {
                        final val = matrix.data[code]?[topic] ?? 0;
                        final ratio = val / maxVal;
                        final cellBgColor = val == 0
                            ? _slate50
                            : Color.lerp(_emeraldLight.withOpacity(0.3), _emerald, ratio)!;
                        final cellTextColor = val == 0
                            ? _slate400
                            : (ratio > 0.5 ? Colors.white : _slate900);

                        return TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Tooltip(
                              message: '$val papers in $topic (${matrix.countries[matrix.countryCodes.indexOf(code)]})',
                              preferBelow: false,
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: cellBgColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  val == 0 ? '-' : '$val',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: cellTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fewer papers',
                style: TextStyle(fontSize: 9.5, color: _slate600, fontWeight: FontWeight.w500),
              ),
              Container(
                width: 120,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [_slate50, _emeraldLight, _emerald],
                  ),
                ),
              ),
              const Text(
                'More papers',
                style: TextStyle(fontSize: 9.5, color: _slate600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _slate100),
          const SizedBox(height: 10),

          // Country Codes Index Legend
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: List.generate(matrix.countryCodes.length, (idx) {
              return Text(
                '${matrix.countryCodes[idx]}: ${matrix.countries[idx]}',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: _slate600,
                ),
              );
            }),
          ),
        ],
      ),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
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