import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/features/custom_lists/views/custom_lists_tab.dart';
import 'package:watchmark/features/custom_lists/widgets/create_list_dialog.dart';
import 'package:watchmark/features/library/controllers/library_controller.dart';
import 'package:watchmark/features/library/widgets/library_card.dart';
import 'package:watchmark/features/library/widgets/status_filter_bar.dart';

class LibraryView extends ConsumerStatefulWidget {
  const LibraryView({super.key});

  @override
  ConsumerState<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends ConsumerState<LibraryView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildMediaTypePill(BuildContext context, String value, String label, String current, ValueChanged<String> onSelected) {
    final isSelected = current == value;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textMuted(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(libraryFilterProvider);
    final filterNotifier = ref.read(libraryFilterProvider.notifier);
    final itemsAsync = ref.watch(filteredLibraryItemsProvider);

    final isCompact = MediaQuery.of(context).size.width < 460;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Header
            Padding(
              padding: EdgeInsets.fromLTRB(isCompact ? 16 : 20, 16, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Library',
                    style: TextStyle(
                      fontSize: isCompact ? 20 : 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(width: isCompact ? 10 : 20),
                  // Segmented Mode Selector: All Media vs Custom Lists
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: AppTheme.containerBg(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderTab(context, isCompact ? 'Media' : 'All Media', 0, isCompact),
                        _buildHeaderTab(context, isCompact ? 'Lists' : 'Custom Lists', 1, isCompact),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Action Menu
                  if (_tabController.index == 0)
                    PopupMenuButton<LibrarySortOrder>(
                      icon: Container(
                        padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sort, size: 16, color: AppTheme.textMuted(context)),
                            if (!isCompact) ...[
                              const SizedBox(width: 6),
                              Text(
                                'Sort',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      tooltip: 'Sort library',
                      initialValue: filter.sortOrder,
                      onSelected: (order) => filterNotifier.setSortOrder(order),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: LibrarySortOrder.dateAddedDesc,
                          child: Text('Date Added (Newest)'),
                        ),
                        PopupMenuItem(
                          value: LibrarySortOrder.lastWatchedDesc,
                          child: Text('Last Watched'),
                        ),
                        PopupMenuItem(
                          value: LibrarySortOrder.titleAsc,
                          child: Text('Title (A-Z)'),
                        ),
                        PopupMenuItem(
                          value: LibrarySortOrder.yearDesc,
                          child: Text('Release Year (Newest)'),
                        ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => const CreateListDialog(),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(isCompact ? 'New' : 'New List', style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: ALL MEDIA
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Integrated Filter Bar: Media Type Pills + Status Chips
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Media Type Selector Capsule
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppTheme.containerBg(context),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.border(context)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildMediaTypePill(context, 'all', 'All', filter.mediaType, filterNotifier.setMediaType),
                                    _buildMediaTypePill(context, 'movie', 'Movies', filter.mediaType, filterNotifier.setMediaType),
                                    _buildMediaTypePill(context, 'tv', 'Series', filter.mediaType, filterNotifier.setMediaType),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 1,
                                height: 24,
                                color: AppTheme.border(context),
                              ),
                              const SizedBox(width: 12),
                              // Status Chips
                              const StatusFilterBar(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Grid Area
                      Expanded(
                        child: itemsAsync.when(
                          data: (items) {
                            if (items.isEmpty) {
                              return Center(
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 420),
                                  margin: const EdgeInsets.all(24),
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface(context),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.border(context)),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.movie_filter_outlined,
                                          size: 40,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        filter.status == 'all'
                                            ? 'Your library is empty'
                                            : 'No titles with status "${filter.status}"',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Search TMDB to add movies and TV series to your library, track watch progress, and log sessions.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: AppTheme.textMuted(context),
                                        ),
                                      ),
                                      const SizedBox(height: 22),
                                      ElevatedButton.icon(
                                        onPressed: () => context.go('/search'),
                                        icon: const Icon(Icons.search, size: 16),
                                        label: const Text('Search Titles'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                final crossAxisCount = width > 1400
                                    ? 7
                                    : width > 1100
                                        ? 5
                                        : width > 800
                                            ? 4
                                            : width > 500
                                                ? 3
                                                : 2;

                                return GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 0.62,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return LibraryCard(
                                      item: item,
                                      onTap: () {
                                        final tmdbId = int.tryParse(item.media.tmdbId) ?? 0;
                                        context.push('/title/$tmdbId?type=${item.media.mediaType}');
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(child: Text('Error loading library: $err')),
                        ),
                      ),
                    ],
                  ),

                  // TAB 2: CUSTOM LISTS
                  const CustomListsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTab(BuildContext context, String title, int index, [bool isCompact = false]) {
    final isSelected = _tabController.index == index;
    return InkWell(
      onTap: () {
        _tabController.animateTo(index);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 11 : 16,
          vertical: isCompact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: isCompact ? 12 : 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textMuted(context),
          ),
        ),
      ),
    );
  }
}
