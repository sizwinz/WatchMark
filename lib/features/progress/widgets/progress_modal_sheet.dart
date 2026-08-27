import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/services/progress_service.dart';

class ProgressModalSheet extends ConsumerStatefulWidget {
  final String mediaId;
  final String title;
  final int totalDurationSeconds;
  final int initialProgressSeconds;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? initialPlatform;
  final bool isMovie;

  const ProgressModalSheet({
    super.key,
    required this.mediaId,
    required this.title,
    required this.totalDurationSeconds,
    this.initialProgressSeconds = 0,
    this.seasonNumber,
    this.episodeNumber,
    this.initialPlatform,
    this.isMovie = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String mediaId,
    required String title,
    required int totalDurationSeconds,
    int initialProgressSeconds = 0,
    int? seasonNumber,
    int? episodeNumber,
    String? initialPlatform,
    bool isMovie = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
      ),
      builder: (context) => ProgressModalSheet(
        mediaId: mediaId,
        title: title,
        totalDurationSeconds: totalDurationSeconds,
        initialProgressSeconds: initialProgressSeconds,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        initialPlatform: initialPlatform,
        isMovie: isMovie,
      ),
    );
  }

  @override
  ConsumerState<ProgressModalSheet> createState() => _ProgressModalSheetState();
}

class _ProgressModalSheetState extends ConsumerState<ProgressModalSheet> {
  late int _currentSeconds;
  late String _selectedPlatform;

  final List<String> _platforms = [
    'netflix',
    'prime',
    'disney',
    'apple_tv',
    'max',
    'hulu',
    'crunchyroll',
    'youtube',
    'local',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.initialProgressSeconds.clamp(
      0,
      widget.totalDurationSeconds > 0 ? widget.totalDurationSeconds : 86400,
    );
    _selectedPlatform = widget.initialPlatform ?? 'netflix';
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _platformDisplayName(String p) {
    switch (p) {
      case 'netflix':
        return 'Netflix';
      case 'prime':
        return 'Prime Video';
      case 'disney':
        return 'Disney+';
      case 'apple_tv':
        return 'Apple TV+';
      case 'max':
        return 'Max';
      case 'hulu':
        return 'Hulu';
      case 'crunchyroll':
        return 'Crunchyroll';
      case 'youtube':
        return 'YouTube';
      case 'local':
        return 'Local Media';
      default:
        return 'Other';
    }
  }

  void _addMinutes(int minutes) {
    setState(() {
      final maxSecs = widget.totalDurationSeconds > 0 ? widget.totalDurationSeconds : 86400;
      _currentSeconds = (_currentSeconds + (minutes * 60)).clamp(0, maxSecs);
    });
  }

  Future<void> _openTimeInputDialog() async {
    final currentH = _currentSeconds ~/ 3600;
    final currentM = (_currentSeconds % 3600) ~/ 60;
    final currentS = _currentSeconds % 60;

    final hoursController = TextEditingController(text: currentH > 0 ? currentH.toString() : '');
    final minsController = TextEditingController(text: currentM.toString());
    final secsController = TextEditingController(text: currentS.toString());

    final maxSecs = widget.totalDurationSeconds > 0 ? widget.totalDurationSeconds : 86400;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enter Exact Timestamp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Hr', hintText: '0'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: minsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Min', hintText: '0'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: secsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Sec', hintText: '0'),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final h = int.tryParse(hoursController.text) ?? 0;
                final m = int.tryParse(minsController.text) ?? 0;
                final s = int.tryParse(secsController.text) ?? 0;
                final totalCalculated = (h * 3600) + (m * 60) + s;
                setState(() {
                  _currentSeconds = totalCalculated.clamp(0, maxSecs);
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProgress() async {
    final service = ref.read(progressServiceProvider);
    await service.updateProgress(
      mediaId: widget.mediaId,
      newProgressSeconds: _currentSeconds,
      seasonNumber: widget.seasonNumber,
      episodeNumber: widget.episodeNumber,
      platform: _selectedPlatform,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _markComplete() async {
    final service = ref.read(progressServiceProvider);
    if (widget.isMovie) {
      await service.markMovieWatched(
        mediaId: widget.mediaId,
        platform: _selectedPlatform,
      );
    } else if (widget.seasonNumber != null && widget.episodeNumber != null) {
      await service.markEpisodeWatched(
        mediaId: widget.mediaId,
        seasonNumber: widget.seasonNumber!,
        episodeNumber: widget.episodeNumber!,
        platform: _selectedPlatform,
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSecs = widget.totalDurationSeconds > 0 ? widget.totalDurationSeconds : 3600;
    final percentage = ((_currentSeconds / totalSecs) * 100).clamp(0, 100).toInt();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (widget.seasonNumber != null && widget.episodeNumber != null)
                          Text(
                            'Season ${widget.seasonNumber} • Episode ${widget.episodeNumber}',
                            style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Time and Percentage Labels (Tappable timestamp to edit directly)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _openTimeInputDialog,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(_currentSeconds),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit, size: 14, color: AppTheme.textMuted(context)),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textMuted(context)),
                  ),
                  Text(
                    _formatDuration(totalSecs),
                    style: TextStyle(fontSize: 16, color: AppTheme.textMuted(context)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Scrubber Slider
              Slider(
                value: _currentSeconds.toDouble().clamp(0.0, totalSecs.toDouble()),
                min: 0.0,
                max: totalSecs.toDouble(),
                activeColor: AppTheme.primary,
                onChanged: (val) {
                  setState(() {
                    _currentSeconds = val.toInt();
                  });
                },
              ),
              const SizedBox(height: 8),

              // Quick Increment Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ActionChip(
                    label: const Text('+5 min'),
                    onPressed: () => _addMinutes(5),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('+15 min'),
                    onPressed: () => _addMinutes(15),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('+30 min'),
                    onPressed: () => _addMinutes(30),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Streaming Platform Tagging
              const Text(
                'Streaming Platform',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _platforms.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final p = _platforms[index];
                    final isSelected = _selectedPlatform == p;
                    return ChoiceChip(
                      label: Text(_platformDisplayName(p)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPlatform = p;
                          });
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Actions: Save Progress and Mark Complete
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _markComplete,
                      icon: const Icon(Icons.check_circle_outline, color: AppTheme.success),
                      label: const Text('Mark Complete'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProgress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Save Progress'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
