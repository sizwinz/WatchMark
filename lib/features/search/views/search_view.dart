import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/features/search/controllers/search_controller.dart';
import 'package:watchmark/features/search/widgets/recent_search_chips.dart';
import 'package:watchmark/features/search/widgets/search_card.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    Future.microtask(() {
      if (mounted) {
        ref.read(searchControllerProvider.notifier).loadTrending();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);

    // Sync text controller if search state query changed externally (e.g. recent chip click)
    if (_textController.text != searchState.query && searchState.query.isNotEmpty) {
      _textController.text = searchState.query;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              onChanged: (val) {
                ref.read(searchControllerProvider.notifier).onQueryChanged(val);
              },
              decoration: InputDecoration(
                hintText: 'Search movies, TV shows...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _textController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _textController.clear();
                          ref.read(searchControllerProvider.notifier).onQueryChanged('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            if (searchState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (searchState.errorMessage != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          searchState.errorMessage!,
                          style: const TextStyle(color: Colors.grey, fontSize: 13.5, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(searchControllerProvider.notifier).onQueryChanged(_textController.text);
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (searchState.query.isEmpty)
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: RecentSearchChips(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Text(
                              searchState.trendingCategory == 'movie'
                                  ? 'Popular Movies'
                                  : searchState.trendingCategory == 'tv'
                                      ? 'Popular Series'
                                      : 'Trending Today',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const Spacer(),
                            // Discovery Category Switcher
                            Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                color: AppTheme.containerBg(context),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTheme.border(context)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildCategoryPill(context, ref, 'all', 'All', searchState.trendingCategory),
                                  _buildCategoryPill(context, ref, 'movie', 'Movies', searchState.trendingCategory),
                                  _buildCategoryPill(context, ref, 'tv', 'Series', searchState.trendingCategory),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (searchState.isLoadingTrending)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      )
                    else if (searchState.trendingResults.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.movie_filter_outlined, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                'Search for your favorite movies and series to start tracking',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textMuted(context), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = (constraints.crossAxisExtent / 160).floor().clamp(2, 6);
                          return SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 0.62,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = searchState.trendingResults[index];
                                return SearchCard(
                                  item: item,
                                  onTap: () {
                                    context.push('/title/${item.id}?type=${item.mediaType}');
                                  },
                                );
                              },
                              childCount: searchState.trendingResults.length,
                            ),
                          );
                        },
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              )
            else if (searchState.results.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'No titles found matching "${searchState.query}".',
                        style: TextStyle(color: AppTheme.textMuted(context)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = (constraints.maxWidth / 160).floor().clamp(2, 6);
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: searchState.results.length,
                      itemBuilder: (context, index) {
                        final item = searchState.results[index];
                        return SearchCard(
                          item: item,
                          onTap: () {
                            context.push(
                              '/title/${item.id}?type=${item.mediaType}',
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(BuildContext context, WidgetRef ref, String value, String label, String current) {
    final isSelected = current == value;
    return InkWell(
      onTap: () {
        ref.read(searchControllerProvider.notifier).setTrendingCategory(value);
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textMuted(context),
          ),
        ),
      ),
    );
  }
}
