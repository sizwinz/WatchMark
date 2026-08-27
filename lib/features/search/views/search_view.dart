import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            else if (searchState.query.isEmpty)
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RecentSearchChips(),
                      SizedBox(height: 48),
                      Center(
                        child: Text(
                          'Search for your favorite movies and series to start tracking',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (searchState.results.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No titles found matching your search.',
                    style: TextStyle(color: Colors.grey),
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
}
