import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:watchmark/app/shortcuts.dart';

class AdaptiveNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdaptiveNavigationShell({
    super.key,
    required this.navigationShell,
  });

  static const double desktopBreakpoint = 720.0;

  static const List<int> _mobileBranchIndices = [0, 1, 2, 4, 6];

  int _getMobileSelectedIndex() {
    final currentBranch = navigationShell.currentIndex;
    final index = _mobileBranchIndices.indexOf(currentBranch);
    if (index != -1) {
      return index;
    }
    // If currently on a desktop-only sub-branch like Watchlist (3) or Stats (5), highlight Library (2)
    return 2;
  }

  void _onMobileDestinationSelected(int mobileIndex) {
    if (mobileIndex >= 0 && mobileIndex < _mobileBranchIndices.length) {
      final branchIndex = _mobileBranchIndices[mobileIndex];
      navigationShell.goBranch(
        branchIndex,
        initialLocation: branchIndex == navigationShell.currentIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= desktopBreakpoint;

    final Widget scaffold = isDesktop
        ? Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie_outlined, size: 28),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search),
                      label: Text('Search'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.video_library_outlined),
                      selectedIcon: Icon(Icons.video_library),
                      label: Text('Library'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bookmark_border_outlined),
                      selectedIcon: Icon(Icons.bookmark),
                      label: Text('Watchlist'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history),
                      label: Text('History'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: Text('Stats'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          )
        : Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _getMobileSelectedIndex(),
              onDestinationSelected: _onMobileDestinationSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.video_library_outlined),
                  selectedIcon: Icon(Icons.video_library),
                  label: 'Library',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          );

    return AppKeyboardShortcuts(child: scaffold);
  }
}
