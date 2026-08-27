import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/storage/secure_storage_service.dart';
import 'package:watchmark/features/settings/widgets/cloud_sync_card.dart';
import 'package:watchmark/features/settings/widgets/data_storage_card.dart';
import 'package:watchmark/shared/providers/theme_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _apiKeyController = TextEditingController();
  bool _isLoadingKey = true;

  @override
  void initState() {
    super.initState();
    _loadCustomApiKey();
  }

  Future<void> _loadCustomApiKey() async {
    final storage = ref.read(secureStorageServiceProvider);
    final key = await storage.getCustomTmdbApiKey();
    if (mounted) {
      setState(() {
        _apiKeyController.text = key ?? '';
        _isLoadingKey = false;
      });
    }
  }

  Future<void> _saveCustomApiKey() async {
    final storage = ref.read(secureStorageServiceProvider);
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      await storage.clearCustomTmdbApiKey();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reverted to default bundled TMDB API key')),
        );
      }
    } else {
      await storage.setCustomTmdbApiKey(key);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom TMDB API key saved securely')),
        );
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Google Drive Cloud Sync Card
          const CloudSyncCard(),
          const SizedBox(height: 16),
          // Appearance Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Theme Mode'),
                    subtitle: Text(_getThemeModeName(themeMode)),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeMode,
                      underline: const SizedBox.shrink(),
                      onChanged: (ThemeMode? newMode) {
                        if (newMode != null) {
                          ref.read(themeModeProvider.notifier).state = newMode;
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System Default'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark Theme'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light Theme'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // TMDB API Key Override Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TMDB API Configuration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WatchMark includes a bundled TMDB key. You can optionally supply your own custom TMDB v3 API Key below.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingKey)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _apiKeyController,
                            decoration: const InputDecoration(
                              hintText: 'Enter TMDB v3 API Key (optional)',
                              prefixIcon: Icon(Icons.vpn_key_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveCustomApiKey,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Data & Storage Management Card
          const DataStorageCard(),
          const SizedBox(height: 16),
          // About & License Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie_outlined, size: 32, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WatchMark',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Version 1.0.0+1 (Cross-Platform)',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'WatchMark: Local-first, privacy-focused movie and series tracking application.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.gavel_outlined, size: 18, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text(
                        'GNU General Public License v3.0 (GPL-3.0)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'WatchMark is free, copyleft open-source software. You are free to use, study, modify, and redistribute this software under the terms of the GNU General Public License as published by the Free Software Foundation.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context), height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follows operating system settings';
      case ThemeMode.dark:
        return 'Always dark theme';
      case ThemeMode.light:
        return 'Always light theme';
    }
  }
}
