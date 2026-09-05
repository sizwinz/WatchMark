import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/app/theme.dart';

void main() {
  group('AppTheme Tests', () {
    test('Dark theme color tokens match WatchMark brand palette', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.colorScheme.primary, const Color(0xFF7C5CFC));
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF0D0F14));
      expect(darkTheme.colorScheme.surface, const Color(0xFF171A21));
    });

    test('Light theme color tokens match WatchMark brand palette', () {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.colorScheme.primary, const Color(0xFF7C5CFC));
      expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF7F8FA));
      expect(lightTheme.colorScheme.surface, const Color(0xFFFFFFFF));
    });

    test('Component dimensions adhere to design decisions', () {
      expect(AppTheme.cardRadius, 12.0);
      expect(AppTheme.buttonRadius, 8.0);
      expect(AppTheme.inputRadius, 8.0);
    });

    test('Light theme configures dark status bar icons for high contrast', () {
      final lightTheme = AppTheme.lightTheme;
      final overlay = lightTheme.appBarTheme.systemOverlayStyle;
      expect(overlay, isNotNull);
      expect(overlay!.statusBarIconBrightness, Brightness.dark);
      expect(overlay.statusBarBrightness, Brightness.light);
      expect(overlay.statusBarColor, Colors.transparent);
      expect(overlay.systemNavigationBarColor, AppTheme.lightBackground);
      expect(overlay.systemNavigationBarIconBrightness, Brightness.dark);

      expect(AppTheme.lightOverlayStyle.statusBarIconBrightness, Brightness.dark);
      expect(AppTheme.lightOverlayStyle.statusBarBrightness, Brightness.light);
    });

    test('Dark theme configures light status bar icons for high contrast', () {
      final darkTheme = AppTheme.darkTheme;
      final overlay = darkTheme.appBarTheme.systemOverlayStyle;
      expect(overlay, isNotNull);
      expect(overlay!.statusBarIconBrightness, Brightness.light);
      expect(overlay.statusBarBrightness, Brightness.dark);
      expect(overlay.statusBarColor, Colors.transparent);
      expect(overlay.systemNavigationBarColor, AppTheme.darkBackground);
      expect(overlay.systemNavigationBarIconBrightness, Brightness.light);

      expect(AppTheme.darkOverlayStyle.statusBarIconBrightness, Brightness.light);
      expect(AppTheme.darkOverlayStyle.statusBarBrightness, Brightness.dark);
    });
  });
}
