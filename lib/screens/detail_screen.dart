import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';

class DetailScreen extends StatefulWidget {
  final String workId;
  const DetailScreen({super.key, required this.workId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadWorkDetail(widget.workId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final theme = Theme.of(context);
    final work = provider.selectedWork;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication Detail'),
      ),
      body: Builder(
        builder: (context) {
          if (provider.detailState == LoadState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.detailState == LoadState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage ?? 'Failed to load details',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SearchProvider>().loadWorkDetail(widget.workId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (work == null) {
            return const Center(child: Text('No details found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  work.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Badges row
                Row(
                  children: [
                    if (work.isOpenAccess) ...[
                      Chip(
                        label: const Text('Open Access'),
                        backgroundColor: Colors.green.shade100,
                        labelStyle: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (work.type != null) ...[
                      Chip(
                        label: Text(work.type!.replaceAll('-', ' ').toUpperCase()),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ],
                ),
                const Divider(height: 24),
                
                // Citation and Year stats row
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatTile(
                          context,
                          Icons.format_quote,
                          '${work.citedByCount}',
                          'Citations',
                        ),
                        _buildStatTile(
                          context,
                          Icons.calendar_today,
                          work.publicationYear != null ? '${work.publicationYear}' : 'N/A',
                          'Year Published',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Journal / Source Info
                if (work.primarySource != null) ...[
                  Text('Source', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.menu_book),
                    ),
                    title: Text(work.primarySource!.displayName),
                    subtitle: Text(work.primarySource!.type ?? 'Journal'),
                  ),
                  const Divider(height: 24),
                ],

                // Authors and institutions
                if (work.authorships.isNotEmpty) ...[
                  Text('Authors', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: work.authorships.length,
                    itemBuilder: (context, idx) {
                      final auth = work.authorships[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.person, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.authorName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (auth.institutionName != null)
                                    Text(
                                      auth.institutionName!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24),
                ],

                // DOI
                if (work.doi != null) ...[
                  Text('DOI', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      // Custom action or print
                    },
                    child: Text(
                      work.doi!,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                ],

                // Abstract text
                Text('Abstract', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  work.abstractText != null && work.abstractText!.trim().isNotEmpty
                      ? work.abstractText!
                      : 'No abstract available for this publication.',
                  style: const TextStyle(height: 1.5, fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, IconData icon, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
