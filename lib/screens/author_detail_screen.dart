import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';
import '../models/work.dart';
import 'detail_screen.dart';

class AuthorDetailScreen extends StatefulWidget {
  final String authorId;
  final String authorName;

  const AuthorDetailScreen({
    super.key,
    required this.authorId,
    required this.authorName,
  });

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen> {
  // ── Design tokens (match TrendScreen / SearchScreen) ──────────────
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
  static const _slate700    = Color(0xFF334155);
  static const _slate900    = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadAuthorDetail(widget.authorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final author = provider.selectedAuthor;

    return Scaffold(
      backgroundColor: _slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _slate900,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.authorName,
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
          if (provider.authorDetailState == LoadState.loading) {
            return const Center(
              child: CircularProgressIndicator(color: _violet),
            );
          }

          if (provider.authorDetailState == LoadState.error) {
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
                      provider.errorMessage ?? 'Failed to load author profile',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _slate600, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<SearchProvider>()
                          .loadAuthorDetail(widget.authorId),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(backgroundColor: _violet),
                    ),
                  ],
                ),
              ),
            );
          }

          if (author == null) {
            return const Center(child: Text('No author data found'));
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
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_violet, _indigo],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            author.displayName.isNotEmpty
                                ? author.displayName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              author.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _slate900,
                              ),
                            ),
                            if (author.lastInstitutionName != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.business_rounded,
                                      size: 14, color: _slate400),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      author.lastInstitutionName!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _slate600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (author.lastInstitutionCountry != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      size: 14, color: _slate400),
                                  const SizedBox(width: 4),
                                  Text(
                                    author.lastInstitutionCountry!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _slate600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (author.orcid != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _emeraldLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ORCID: ${author.orcid!.replaceFirst('https://orcid.org/', '')}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _emerald,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                _SectionTitle(title: 'Research Metrics'),
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
                      value: '${author.hIndex}',
                      icon: Icons.trending_up_rounded,
                      color: _violet,
                      bgColor: _violetLight,
                    ),
                    _MetricCard(
                      label: 'i10-index',
                      value: '${author.i10Index}',
                      icon: Icons.article_rounded,
                      color: _indigo,
                      bgColor: _indigoLight,
                    ),
                    _MetricCard(
                      label: 'Works Count',
                      value: _formatNumber(author.worksCount),
                      icon: Icons.description_rounded,
                      color: _emerald,
                      bgColor: _emeraldLight,
                    ),
                    _MetricCard(
                      label: 'Total Citations',
                      value: _formatNumber(author.citedByCount),
                      icon: Icons.format_quote_rounded,
                      color: _amber,
                      bgColor: _amberLight,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── ID info ───────────────────────────────────────
                _SectionTitle(title: 'Profile Information'),
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
                        value: author.id.replaceFirst('https://openalex.org/', ''),
                      ),
                      if (author.orcid != null) ...[
                        const Divider(height: 20, color: _slate100),
                        _InfoRow(
                          icon: Icons.badge_rounded,
                          label: 'ORCID',
                          value: author.orcid!.replaceFirst('https://orcid.org/', ''),
                          valueColor: _emerald,
                        ),
                      ],
                      if (author.lastInstitutionName != null) ...[
                        const Divider(height: 20, color: _slate100),
                        _InfoRow(
                          icon: Icons.business_rounded,
                          label: 'Institution',
                          value: author.lastInstitutionName!,
                        ),
                      ],
                      if (author.lastInstitutionCountry != null) ...[
                        const Divider(height: 20, color: _slate100),
                        _InfoRow(
                          icon: Icons.public_rounded,
                          label: 'Country',
                          value: author.lastInstitutionCountry!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Publications list ─────────────────────────────
                _SectionTitle(title: 'Publications (${provider.authorWorks.length})'),
                const SizedBox(height: 10),
                if (provider.authorWorks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _slate200),
                    ),
                    child: const Center(
                      child: Text(
                        'No publications found.',
                        style: TextStyle(color: _slate600, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...provider.authorWorks.map((work) {
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
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(workId: work.id),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        work.title,
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
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _indigoLight,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.format_quote_rounded, size: 10, color: _indigo),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${work.citedByCount} cited',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _indigo,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (work.publicationYear != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _slate100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${work.publicationYear}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: _slate600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded, color: _slate400, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),

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
