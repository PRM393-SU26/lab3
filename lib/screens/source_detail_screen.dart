import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';
import 'detail_screen.dart';

class SourceDetailScreen extends StatefulWidget {
  final String sourceId;
  final String sourceName;

  const SourceDetailScreen({
    super.key,
    required this.sourceId,
    required this.sourceName,
  });

  @override
  State<SourceDetailScreen> createState() => _SourceDetailScreenState();
}

class _SourceDetailScreenState extends State<SourceDetailScreen> {
  // ── Design tokens ─────────────────────────────────────────────────
  static const _indigo      = Color(0xFF4F46E5);
  static const _indigoLight = Color(0xFFEEF2FF);
  static const _violet      = Color(0xFF7C3AED);
  static const _violetLight = Color(0xFFF5F3FF);
  static const _emerald     = Color(0xFF059669);
  static const _emeraldLight= Color(0xFFD1FAE5);
  static const _amber       = Color(0xFFD97706);
  static const _amberLight  = Color(0xFFFEF3C7);
  static const _slate50     = Color(0xFFF8FAFC);
  static const _slate100    = Color(0xFFF1F5F9);
  static const _slate200    = Color(0xFFE2E8F0);
  static const _slate400    = Color(0xFF94A3B8);
  static const _slate600    = Color(0xFF475569);
  static const _slate900    = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadSourceDetail(widget.sourceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final source = provider.selectedSource;

    return Scaffold(
      backgroundColor: _slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _slate900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.sourceName,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _slate900,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _slate200, height: 1),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (provider.sourceDetailState == LoadState.loading) {
            return const Center(
              child: CircularProgressIndicator(color: _indigo),
            );
          }

          if (provider.sourceDetailState == LoadState.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.error_outline_rounded,
                          size: 32, color: Colors.red.shade400),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ?? 'Failed to load journal profile',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _slate600, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<SearchProvider>()
                          .loadSourceDetail(widget.sourceId),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(backgroundColor: _indigo),
                    ),
                  ],
                ),
              ),
            );
          }

          if (source == null) {
            return const Center(child: Text('No journal data found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header card ───────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_indigo, Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source.displayName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _slate900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (source.type != null)
                                  _Badge(
                                    label: _formatType(source.type!),
                                    color: _indigo,
                                    bgColor: _indigoLight,
                                  ),
                                if (source.isOa)
                                  const _Badge(
                                    label: 'Open Access',
                                    color: _emerald,
                                    bgColor: _emeraldLight,
                                  ),
                                if (source.isInDoaj)
                                  const _Badge(
                                    label: 'DOAJ',
                                    color: _amber,
                                    bgColor: _amberLight,
                                  ),
                              ],
                            ),
                            if (source.countryCode != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.public_rounded,
                                      size: 14, color: _slate400),
                                  const SizedBox(width: 4),
                                  Text(
                                    source.countryCode!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _slate600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stats grid ────────────────────────────────────
                const _SectionTitle(title: 'Journal Metrics'),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _MetricCard(
                      label: 'h-index',
                      value: '${source.hIndex}',
                      icon: Icons.trending_up_rounded,
                      color: _indigo,
                      bgColor: _indigoLight,
                    ),
                    _MetricCard(
                      label: 'Works Count',
                      value: _formatNumber(source.worksCount),
                      icon: Icons.description_rounded,
                      color: _violet,
                      bgColor: _violetLight,
                    ),
                    _MetricCard(
                      label: 'Total Citations',
                      value: _formatNumber(source.citedByCount),
                      icon: Icons.format_quote_rounded,
                      color: _emerald,
                      bgColor: _emeraldLight,
                    ),
                    _MetricCard(
                      label: 'Avg Citations',
                      value: source.worksCount > 0 
                          ? (source.citedByCount / source.worksCount).toStringAsFixed(1)
                          : '0.0',
                      icon: Icons.analytics_outlined,
                      color: Colors.pink,
                      bgColor: Colors.pink.shade50,
                    ),
                    _MetricCard(
                      label: 'Open Access',
                      value: source.isOa ? 'Yes' : 'No',
                      icon: Icons.lock_open_rounded,
                      color: Colors.cyan,
                      bgColor: Colors.cyan.shade50,
                    ),
                    _MetricCard(
                      label: 'In DOAJ',
                      value: source.isInDoaj ? 'Yes' : 'No',
                      icon: Icons.verified_rounded,
                      color: source.isInDoaj ? _amber : _slate400,
                      bgColor: source.isInDoaj ? _amberLight : _slate100,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Access info ───────────────────────────────────
                const _SectionTitle(title: 'Access & Profile'),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _slate200),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.fingerprint_rounded,
                        label: 'OpenAlex ID',
                        value: source.id.replaceFirst('https://openalex.org/', ''),
                      ),
                      if (source.type != null) ...[
                        const Divider(height: 20, color: _slate100),
                        _InfoRow(
                          icon: Icons.category_rounded,
                          label: 'Type',
                          value: _formatType(source.type!),
                        ),
                      ],
                      const Divider(height: 20, color: _slate100),
                      _InfoRow(
                        icon: Icons.lock_open_rounded,
                        label: 'Open Access',
                        value: source.isOa ? 'Yes' : 'No',
                        valueColor: source.isOa ? _emerald : null,
                      ),
                      const Divider(height: 20, color: _slate100),
                      _InfoRow(
                        icon: Icons.verified_outlined,
                        label: 'DOAJ Listed',
                        value: source.isInDoaj ? 'Yes' : 'No',
                        valueColor: source.isInDoaj ? _amber : null,
                      ),
                      if (source.countryCode != null) ...[
                        const Divider(height: 20, color: _slate100),
                        _InfoRow(
                          icon: Icons.public_rounded,
                          label: 'Country',
                          value: source.countryCode!,
                        ),
                      ],
                      if (source.homepageUrl != null) ...[
                        const Divider(height: 20, color: _slate100),
                        _InfoRow(
                          icon: Icons.link_rounded,
                          label: 'Homepage',
                          value: source.homepageUrl!,
                          valueColor: _indigo,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Related Publications'),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    if (provider.journalWorksState == LoadState.loading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: _indigo),
                        ),
                      );
                    }
                    if (provider.journalWorksState == LoadState.error) {
                      return Card(
                        elevation: 0,
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Failed to load related publications.',
                            style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                          ),
                        ),
                      );
                    }
                    if (provider.journalWorks.isEmpty) {
                      return const Card(
                        elevation: 0,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No related publications found.', style: TextStyle(color: _slate600, fontSize: 13)),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.journalWorks.length,
                      itemBuilder: (context, index) {
                        final work = provider.journalWorks[index];
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: _slate200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              work.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _slate900),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
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
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _formatType(String type) {
    return type
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// ─────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF334155),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
