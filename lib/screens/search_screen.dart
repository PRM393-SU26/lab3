import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reading_list_provider.dart';
import '../services/search_provider.dart';
import 'detail_screen.dart';
import 'reading_list_screen.dart';
import 'trend_screen.dart';
import 'dashboard_screen.dart';
import 'author_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  
  bool _openAccessOnly = false;
  int? _yearFrom;
  int? _yearTo;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadGlobalTopAuthors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
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

    if (provider.globalTopAuthorsState == LoadState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SearchProvider>().loadGlobalTopAuthors();
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: provider.currentTopic.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Main',
                onPressed: () {
                  _searchController.clear();
                  context.read<SearchProvider>().resetSearch();
                },
              )
            : null,
        title: const Text('Journal Trend Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'Reading List',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReadingListScreen()),
            ),
          ),
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
                            focusNode: _searchFocusNode,
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
                          if (_searchFocusNode.hasFocus &&
                              provider.suggestions.isEmpty &&
                              provider.searchHistory.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 6.0,
                                runSpacing: 4.0,
                                children: provider.searchHistory.map((query) {
                                  return InputChip(
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    avatar: const Icon(Icons.history, size: 14),
                                    label: Text(
                                      query,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    onPressed: () {
                                      _searchController.text = query;
                                      _performSearch();
                                    },
                                  );
                                }).toList(),
                              ),
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
      final List<String> suggestedTopics = [
        'Artificial Intelligence',
        'Machine Learning',
        'Data Science',
        'Quantum Computing',
        'Cybersecurity',
        'Blockchain',
        'Internet of Things',
        'Cloud Computing',
        'Augmented Reality',
        'Bioinformatics',
      ];

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.explore_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Discover Research Trends',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search for topics or choose from suggestions below',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            if (provider.searchHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<SearchProvider>().clearHistory(),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: provider.searchHistory.map((query) {
                  return InputChip(
                    avatar: const Icon(Icons.history, size: 16),
                    label: Text(query),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => context
                        .read<SearchProvider>()
                        .removeFromHistory(query),
                    onPressed: () {
                      _searchController.text = query;
                      _performSearch();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Suggested Topics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: suggestedTopics.map((topic) {
                return ActionChip(
                  avatar: Icon(Icons.trending_up, size: 16, color: theme.colorScheme.primary),
                  label: Text(topic),
                  onPressed: () {
                    _searchController.text = topic;
                    _performSearch();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Text(
              'Top 10 Contributing Authors',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (provider.globalTopAuthorsState == LoadState.loading)
              const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.globalTopAuthorsState == LoadState.error)
              Card(
                elevation: 0,
                color: theme.colorScheme.errorContainer.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.error.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Failed to load top authors.',
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.read<SearchProvider>().loadGlobalTopAuthors(),
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              )
            else ...[
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: provider.globalTopAuthors.map((author) {
                  return ActionChip(
                    avatar: Icon(Icons.person, size: 16, color: theme.colorScheme.primary),
                    label: Text(author.displayName),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuthorDetailScreen(
                            authorId: author.id,
                            authorName: author.displayName,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
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
        final readingList = context.watch<ReadingListProvider>();
        final isSaved = readingList.contains(work.id);
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
                      IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        color: isSaved ? theme.colorScheme.primary : null,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            context.read<ReadingListProvider>().toggle(work),
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
