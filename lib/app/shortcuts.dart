import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SearchIntent extends Intent {
  const SearchIntent();
}

class NavigateTabIntent extends Intent {
  final int branchIndex;
  const NavigateTabIntent(this.branchIndex);
}

class AppKeyboardShortcuts extends StatelessWidget {
  final Widget child;

  const AppKeyboardShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.slash): const SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit1): const NavigateTabIntent(0),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit1): const NavigateTabIntent(0),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit2): const NavigateTabIntent(1),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit2): const NavigateTabIntent(1),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit3): const NavigateTabIntent(2),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit3): const NavigateTabIntent(2),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit4): const NavigateTabIntent(4),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit4): const NavigateTabIntent(4),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit5): const NavigateTabIntent(6),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit5): const NavigateTabIntent(6),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) {
              final router = GoRouter.of(context);
              router.go('/search');
              return null;
            },
          ),
          NavigateTabIntent: CallbackAction<NavigateTabIntent>(
            onInvoke: (intent) {
              final router = GoRouter.of(context);
              switch (intent.branchIndex) {
                case 0:
                  router.go('/');
                  break;
                case 1:
                  router.go('/search');
                  break;
                case 2:
                  router.go('/library');
                  break;
                case 4:
                  router.go('/history');
                  break;
                case 6:
                  router.go('/settings');
                  break;
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}
