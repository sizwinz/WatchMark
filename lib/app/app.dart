import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/router.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/shared/providers/theme_provider.dart';

class WatchMarkApp extends ConsumerWidget {
  final RouterConfig<Object>? routerConfig;

  const WatchMarkApp({super.key, this.routerConfig});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = routerConfig ?? ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'WatchMark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemOverlayStyle(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
