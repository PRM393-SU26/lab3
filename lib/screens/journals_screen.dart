import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';
import '../models/analytics.dart';
import 'source_detail_screen.dart';

class JournalsScreen extends StatefulWidget {
  const JournalsScreen({super.key});

  @override
  State<JournalsScreen> createState() => _JournalsScreenState();
}

class _JournalsScreenState extends State<JournalsScreen> {
  static const _indigo      = Color(0xFF4F46E5);
  static const _indigoLight = Color(0xFFEEF2FF);
  static const _slate50    = Color(0xFFF8FAFC);
  static const _slate200    = Color(0xFFE2E8F0);
  static const _slate400    = Color(0xFF94A3B8);
  static const _slate600    = Color(0xFF475569);
  static const _slate900    = Color(0xFF0F172A);

  String _searchQuery = '';
  String? _selectedDomain;
  String? _selectedField;
  String? _selectedSubfield;
  String _sortOption = 'publication_desc';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SearchProvider>();
      provider.loadDomains();
      if (provider.topJournals.isEmpty) {
        provider.applyJournalFilter(); // Load global journals initially
      }
    });
  }

  void _showFilterSortDialog(BuildContext context) {
    final provider = context.read<SearchProvider>();
    String? tempDomain = _selectedDomain;
    String? tempField = _selectedField;
    String? tempSubfield = _selectedSubfield;
    String tempSort = _sortOption;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter & Sort'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Domain:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: tempDomain,
                      isExpanded: true,
                      hint: const Text('Select Domain'),
                      items: provider.domains.map((d) => DropdownMenuItem(value: d.id, child: Text(d.displayName))).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          tempDomain = val;
                          tempField = null;
                          tempSubfield = null;
                        });
                        if (val != null) provider.loadFields(val);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Field:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: tempField,
                      isExpanded: true,
                      hint: const Text('Select Field'),
                      items: tempDomain != null && provider.fieldsByDomain[tempDomain] != null
                          ? provider.fieldsByDomain[tempDomain]!.map((f) => DropdownMenuItem(value: f.id, child: Text(f.displayName))).toList()
                          : [],
                      onChanged: tempDomain != null
                          ? (val) {
                              setDialogState(() {
                                tempField = val;
                                tempSubfield = null;
                              });
                              if (val != null) provider.loadSubfields(val);
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    const Text('Subfield:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: tempSubfield,
                      isExpanded: true,
                      hint: const Text('Select Subfield'),
                      items: tempField != null && provider.subfieldsByField[tempField] != null
                          ? provider.subfieldsByField[tempField]!.map((sf) => DropdownMenuItem(value: sf.id, child: Text(sf.displayName))).toList()
                          : [],
                      onChanged: tempField != null
                          ? (val) {
                              setDialogState(() {
                                tempSubfield = val;
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Sort By:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: tempSort,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'publication_desc', child: Text('Publications (High to Low)')),
                        DropdownMenuItem(value: 'citation_desc', child: Text('Citations (High to Low)')),
                        DropdownMenuItem(value: 'a_z', child: Text('Name (A-Z)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => tempSort = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      tempDomain = null;
                      tempField = null;
                      tempSubfield = null;
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDomain = tempDomain;
                      _selectedField = tempField;
                      _selectedSubfield = tempSubfield;
                      _sortOption = tempSort;
                    });
                    provider.applyJournalFilter(
                      domainId: tempDomain,
                      fieldId: tempField,
                      subfieldId: tempSubfield,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _slate50,
      appBar: AppBar(
        title: const Text('Journal Analysis'),
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
      ),
      body: Builder(
        builder: (context) {
          if (provider.journalsState == LoadState.loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _indigo),
                  SizedBox(height: 16),
                  Text('Loading journals statistics...', style: TextStyle(color: _slate600)),
                ],
              ),
            );
          }

          if (provider.journalsState == LoadState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage ?? 'Failed to load journals', style: const TextStyle(color: _slate600)),
                ],
              ),
            );
          }

          if (provider.topJournals.isEmpty) {
            return const _EmptyTab(
              icon: Icons.menu_book_rounded,
              message: 'No journal statistics available for this topic.',
            );
          }

          // Apply filtering and sorting
          List<JournalStat> filteredJournals = provider.topJournals.where((j) {
            final matchesSearch = j.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
            // Note: Since JournalStat doesn't contain Domain/Field/Subfield from OpenAlex yet,
            // we skip actual filtering by Domain/Field here, just UI placeholder.
            return matchesSearch;
          }).toList();

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            filteredJournals.sort((a, b) {
              final aName = a.displayName.toLowerCase();
              final bName = b.displayName.toLowerCase();
              int scoreA = aName == q ? 3 : (aName.startsWith(q) ? 2 : 1);
              int scoreB = bName == q ? 3 : (bName.startsWith(q) ? 2 : 1);

              if (scoreA != scoreB) {
                return scoreB.compareTo(scoreA); // Higher score first
              } else {
                if (_sortOption == 'publication_desc') {
                  return b.paperCount.compareTo(a.paperCount);
                } else if (_sortOption == 'citation_desc') {
                  return b.citationCount.compareTo(a.citationCount);
                } else {
                  return aName.compareTo(bName);
                }
              }
            });
          } else {
            if (_sortOption == 'publication_desc') {
              filteredJournals.sort((a, b) => b.paperCount.compareTo(a.paperCount));
            } else if (_sortOption == 'citation_desc') {
              filteredJournals.sort((a, b) => b.citationCount.compareTo(a.citationCount));
            } else if (_sortOption == 'a_z') {
              filteredJournals.sort((a, b) => a.displayName.compareTo(b.displayName));
            }
          }

          final maxCount = provider.topJournals.map((e) => e.paperCount).fold(0, max);
          final topJournal = provider.topJournals.reduce((a, b) => a.paperCount > b.paperCount ? a : b);
          final maxHIndex = provider.topJournals.map((e) => e.hIndex).fold(0, max);

          return RefreshIndicator(
            onRefresh: () => provider.loadTrendAnalysis(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search and Filter Toolbar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search journals...',
                            prefixIcon: const Icon(Icons.search, color: _slate400),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _slate200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _slate200),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _slate200),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.filter_list, color: _indigo),
                          tooltip: 'Filter & Sort',
                          onPressed: () => _showFilterSortDialog(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // KPI cards
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Max H-Index',
                          value: '$maxHIndex',
                          icon: Icons.show_chart_rounded,
                          color: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFEF3C7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Top Journal',
                          value: topJournal.displayName,
                          icon: Icons.emoji_events_rounded,
                          color: const Color(0xFF059669),
                          bgColor: const Color(0xFFD1FAE5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bubble Chart
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
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Journal Contribution',
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
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _BubbleChart(data: filteredJournals),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Journal Rankings Title
                  const Text(
                    'Journal Rankings',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _slate900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // List of journals
                  filteredJournals.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: Text('No journals match your filters.', style: TextStyle(color: _slate600))),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredJournals.length,
                          itemBuilder: (context, index) {
                            final j = filteredJournals[index];
                            final ratio = maxCount > 0 ? j.paperCount / maxCount : 0.0;

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
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              j.displayName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: _slate900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward_ios_rounded,
                                              size: 14, color: _slate400),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Papers progress bar
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: ratio,
                                                backgroundColor: _indigoLight,
                                                valueColor: const AlwaysStoppedAnimation(_indigo),
                                                minHeight: 6,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${j.paperCount} papers',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _indigo,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'h-index: ${j.hIndex}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: _slate600,
                                            ),
                                          ),
                                          Text(
                                            'Citations: ${j.citationCount}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: _slate600,
                                            ),
                                          ),
                                        ],
                                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
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
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: _JournalsScreenState._slate600,
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
                color: _JournalsScreenState._indigoLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.search_rounded, color: _JournalsScreenState._indigo, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: _JournalsScreenState._slate600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
      const Color(0xFF0000FF),
      const Color(0xFF00FFFF),
      const Color(0xFF00FF00),
      const Color(0xFFFFFF00),
      const Color(0xFFFF0000),
    ];
    if (ratio == 0.0) return colors.first;
    if (ratio == 1.0) return colors.last;

    final double segment = 1.0 / (colors.length - 1);
    final int index = (ratio / segment).floor();
    final double localRatio = (ratio - index * segment) / segment;

    return Color.lerp(colors[index], colors[index + 1], localRatio)!;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox();

    final maxH = widget.data.map((e) => e.hIndex).fold(0, max);
    final minH = widget.data.map((e) => e.hIndex).fold(0, min);
    final maxPapers = widget.data.map((e) => e.paperCount).fold(0, max);
    final minPapers = widget.data.map((e) => e.paperCount).fold(0, min);
    final maxCite = widget.data.map((e) => e.citationCount).fold(0, max);
    final minCite = widget.data.map((e) => e.citationCount).fold(0, min);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final paddingX = w * 0.1;
        final paddingY = h * 0.1;
        final chartW = w - paddingX * 2;
        final chartH = h - paddingY * 2;

        return Stack(
          children: [
            // Grid background
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(
                  paddingX: paddingX,
                  paddingY: paddingY,
                  chartW: chartW,
                  chartH: chartH,
                ),
              ),
            ),
            // Bubble markers
            ...List.generate(widget.data.length, (idx) {
              final item = widget.data[idx];
              final xRatio = maxH == minH ? 0.5 : (item.hIndex - minH) / (maxH - minH);
              final yRatio = maxPapers == minPapers ? 0.5 : (item.paperCount - minPapers) / (maxPapers - minPapers);
              final sizeRatio = maxCite == minCite ? 0.5 : (item.citationCount - minCite) / (maxCite - minCite);

              final bubbleSize = 12.0 + sizeRatio * 20.0;
              final cx = paddingX + xRatio * chartW;
              final cy = paddingY + (1 - yRatio) * chartH;

              final color = _getRGBColor(sizeRatio);

              final isSelected = _selectedIndex == idx;

              return Positioned(
                left: cx - bubbleSize / 2,
                top: cy - bubbleSize / 2,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = isSelected ? null : idx;
                    });
                  },
                  child: Container(
                    width: bubbleSize,
                    height: bubbleSize,
                    decoration: BoxDecoration(
                      color: color.withOpacity(isSelected ? 0.9 : 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : color.withOpacity(0.9),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                  ),
                ),
              );
            }),
            // Floating label when tapped
            if (_selectedIndex != null && _selectedIndex! < widget.data.length)
              Builder(
                builder: (context) {
                  final item = widget.data[_selectedIndex!];
                  return Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.displayName}: h-index=${item.hIndex}, papers=${item.paperCount}, cites=${item.citationCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final double paddingX;
  final double paddingY;
  final double chartW;
  final double chartH;

  _GridPainter({
    required this.paddingX,
    required this.paddingY,
    required this.chartW,
    required this.chartH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw frame
    canvas.drawRect(
      Rect.fromLTWH(paddingX, paddingY, chartW, chartH),
      paint,
    );

    // Grid lines
    for (int i = 1; i < 4; i++) {
      // vertical
      final vx = paddingX + (chartW / 4) * i;
      canvas.drawLine(Offset(vx, paddingY), Offset(vx, paddingY + chartH), paint);

      // horizontal
      final vy = paddingY + (chartH / 4) * i;
      canvas.drawLine(Offset(paddingX, vy), Offset(paddingX + chartW, vy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
