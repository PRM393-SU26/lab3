import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/author_detail.dart';
import '../services/search_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final theme = Theme.of(context);
    final db = provider.dashboard;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard: ${provider.currentTopic}'),
      ),
      body: Builder(
        builder: (context) {
          if (provider.dashboardState == LoadState.loading ||
              provider.oaBreakdownState == LoadState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.dashboardState == LoadState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage ?? 'Failed to load dashboard',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SearchProvider>().loadDashboard();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (db == null) {
            return const Center(child: Text('No dashboard data available'));
          }

          final oaPercentage = (db.openAccessRatio * 100).toStringAsFixed(1);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Grid of KPI cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildKpiCard(
                      context,
                      'Total Publications',
                      '${db.totalPublications}',
                      Icons.article_outlined,
                      theme.colorScheme.primary,
                    ),
                    _buildKpiCard(
                      context,
                      'Avg Citations',
                      db.avgCitationCount.toStringAsFixed(1),
                      Icons.format_quote_outlined,
                      theme.colorScheme.secondary,
                    ),
                    _buildKpiCard(
                      context,
                      'Open Access Ratio',
                      '$oaPercentage%',
                      Icons.lock_open_outlined,
                      Colors.green,
                    ),
                    _buildKpiCard(
                      context,
                      'Peak Year',
                      db.peakYear != null ? '${db.peakYear}' : 'N/A',
                      Icons.trending_up,
                      Colors.amber.shade800,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Key Contributors',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Contributors Cards
                _buildInfoRowCard(
                  theme,
                  Icons.menu_book,
                  'Top Journal/Source',
                  db.topJournalName ?? 'No journal data',
                  theme.colorScheme.primaryContainer,
                ),
                const SizedBox(height: 10),
                _buildInfoRowCard(
                  theme,
                  Icons.person,
                  'Top Author',
                  db.topAuthorName ?? 'No author data',
                  theme.colorScheme.secondaryContainer,
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Most Influential Paper',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                if (db.mostInfluentialTitle != null)
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            db.mostInfluentialTitle!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.format_quote, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${db.mostInfluentialCitations ?? 0} Citations',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No paper details found'),
                    ),
                  ),

                if (provider.oaBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Open Access Breakdown',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          for (var i = 0; i < provider.oaBreakdown.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            _OaBreakdownRow(
                              stat: provider.oaBreakdown[i],
                              total: provider.oaBreakdown
                                  .fold(0, (sum, s) => sum + s.count),
                              theme: theme,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _oaStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'gold':
        return Colors.amber.shade700;
      case 'green':
        return Colors.green.shade600;
      case 'hybrid':
        return Colors.blue.shade600;
      case 'bronze':
        return Colors.orange.shade700;
      case 'closed':
        return Colors.grey.shade600;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildInfoRowCard(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
    Color containerColor,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: containerColor,
          child: Icon(icon, color: theme.colorScheme.onSurface),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _OaBreakdownRow extends StatelessWidget {
  final OaStat stat;
  final int total;
  final ThemeData theme;

  const _OaBreakdownRow({
    required this.stat,
    required this.total,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? stat.count / total : 0.0;
    final color = _DashboardScreenState._oaStatusColor(stat.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                stat.status.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Text(
              '${stat.count} (${(ratio * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceVariant,
            color: color,
          ),
        ),
      ],
    );
  }
}
