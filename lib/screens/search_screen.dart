import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_provider.dart';
import 'detail_screen.dart';
import 'trend_screen.dart';
import 'dashboard_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _openAccessOnly = false;
  int? _yearFrom;
  int? _yearTo;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().loadMore();
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<SearchProvider>().clearSuggestions();
      context.read<SearchProvider>().search(
        query,
        openAccessOnly: _openAccessOnly,
        yearFrom: _yearFrom,
        yearTo: _yearTo,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Trend Analyzer'),
        actions: [
          if (provider.currentTopic.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Trend Analysis',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrendScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.dashboard),
              tooltip: 'Dashboard',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search topic (e.g. machine learning)',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<SearchProvider>().clearSuggestions();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                            ),
                            onChanged: (val) {
                              context.read<SearchProvider>().fetchSuggestions(val);
                              setState(() {});
                            },
                            onSubmitted: (_) {
                              context.read<SearchProvider>().clearSuggestions();
                              _performSearch();
                            },
                          ),
                          if (provider.suggestions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(12),
                                color: theme.colorScheme.surface,
                                clipBehavior: Clip.antiAlias,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 180),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: provider.suggestions.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                                    itemBuilder: (context, index) {
                                      final suggestion = provider.suggestions[index];
                                      return ListTile(
                                        dense: true,
                                        visualDensity: VisualDensity.compact,
                                        leading: const Icon(Icons.search, size: 18),
                                        title: Text(
                                          suggestion,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () {
                                          _searchController.text = suggestion;
                                          context.read<SearchProvider>().clearSuggestions();
                                          setState(() {});
                                          _performSearch();
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                      onPressed: () => setState(() => _showFilters = !_showFilters),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _performSearch,
                        child: const Text('Search'),
                      ),
                    ),
                      ],
                    ),

                    // Expandable Filters
                    if (_showFilters) ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Filters', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Open Access Only'),
                            value: _openAccessOnly,
                            onChanged: (val) => setState(() => _openAccessOnly = val),
                          ),
                          const Divider(),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Year From',
                                    hintText: 'e.g. 2018',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  initialValue: _yearFrom?.toString(),
                                  onChanged: (val) {
                                    _yearFrom = int.tryParse(val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Year To',
                                    hintText: 'e.g. 2023',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  initialValue: _yearTo?.toString(),
                                  onChanged: (val) {
                                    _yearTo = int.tryParse(val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                    ]
                  ],
                ),
              ),
            ),
          ),
          
          // Results Area
          Expanded(
            child: Column(
              children: [
                if (provider.works.isNotEmpty ||
                    (provider.searchState == LoadState.loading &&
                        provider.currentTopic.isNotEmpty))
                  _buildSortBar(provider, theme),
                Expanded(
                  child: _buildResultsList(provider, theme),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: provider.currentTopic.isNotEmpty
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('Trend Analysis'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TrendScreen()),
                        );
                      },
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.dashboard),
                      label: const Text('Dashboard'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DashboardScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildSortBar(SearchProvider provider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.sort, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Sort by:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<WorkSortOption>(
                    isExpanded: true,
                    isDense: true,
                    value: provider.sortBy,
                    items: WorkSortOption.values
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(
                              option.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: provider.searchState == LoadState.loading
                        ? null
                        : (option) {
                            if (option != null) {
                              context.read<SearchProvider>().setSortBy(option);
                            }
                          },
                  ),
                ),
              ),
            ],
          ),
          if (provider.totalResults > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 28),
              child: Text(
                '${provider.totalResults} results',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsList(SearchProvider provider, ThemeData theme) {
    if (provider.searchState == LoadState.idle && provider.works.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            const Text(
              'Search for any research topic to begin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try "artificial intelligence" or "quantum computing"',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (provider.searchState == LoadState.loading && provider.works.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.searchState == LoadState.error && provider.works.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'An error occurred while fetching data',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: provider.works.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.works.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final work = provider.works[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(workId: work.id),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          work.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (work.isOpenAccess)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OA',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (work.authorships.isNotEmpty) ...[
                    Text(
                      work.authorships.map((e) => e.authorName).join(', '),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      if (work.publicationYear != null) ...[
                        Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          '${work.publicationYear}',
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Icon(Icons.format_quote, size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        'Citations: ${work.citedByCount}',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                      if (work.primarySource?.displayName != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            work.primarySource!.displayName,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
