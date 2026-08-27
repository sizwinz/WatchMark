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
  });
}
