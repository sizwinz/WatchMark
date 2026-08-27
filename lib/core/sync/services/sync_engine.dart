import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/sync/models/sync_models.dart';
import 'package:watchmark/core/sync/services/conflict_resolver.dart';
import 'package:watchmark/core/sync/services/drive_sync_client.dart';
import 'package:watchmark/core/sync/services/google_auth_service.dart';
import 'package:watchmark/core/sync/services/sync_queue_service.dart';

class SyncEngine extends StateNotifier<SyncStatusState> {
  final IGoogleAuthService authService;
  final IDriveSyncClient driveClient;
  final SyncQueueService queueService;
  final ConflictResolver conflictResolver;
  final Connectivity _connectivity;

  Timer? _debounceTimer;
  StreamSubscription? _authSub;
  StreamSubscription? _pendingSub;

  SyncEngine({
    required this.authService,
    required this.driveClient,
    required this.queueService,
    required this.conflictResolver,
    Connectivity? connectivity,
  })  : _connectivity = connectivity ?? Connectivity(),
        super(const SyncStatusState()) {
    _init();
  }

  Future<void> _init() async {
    final devId = await queueService.getDeviceId();
    if (!mounted) return;
    state = state.copyWith(
      deviceId: devId,
      isConnected: authService.isSignedIn,
      accountEmail: authService.currentUserEmail,
    );

    _authSub = authService.currentUserEmailStream.listen((email) {
      if (!mounted) return;
      state = state.copyWith(
        isConnected: email != null,
        accountEmail: email,
      );
    });

    _pendingSub = queueService.watchPendingCount().listen((count) {
      if (!mounted) return;
      state = state.copyWith(pendingCount: count);
      if (count > 0 && authService.isSignedIn) {
        _scheduleAutoSync();
      }
    });
  }

  void _scheduleAutoSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        syncNow();
      }
    });
  }

  Future<void> syncNow() async {
    if (!mounted || !authService.isSignedIn || state.isSyncing) return;

    // Check connectivity
    try {
      final connResults = await _connectivity.checkConnectivity();
      if (connResults.contains(ConnectivityResult.none)) {
        if (mounted) {
          state = state.copyWith(errorMessage: 'Offline: Sync paused');
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      state = state.copyWith(isSyncing: true, errorMessage: null);
    }

    try {
      final devId = await queueService.getDeviceId();

      // Step 1: Upload Local Pending Events
      final pending = await queueService.getPendingEvents();
      if (pending.isNotEmpty) {
        final buffer = StringBuffer();
        final eventIds = <String>[];

        for (final e in pending) {
          eventIds.add(e.id);
          final eventMap = {
            'id': e.id,
            'entity_type': e.entityType,
            'entity_id': e.entityId,
            'operation': e.operation,
            'device_id': e.deviceId,
            'timestamp': e.timestamp.toUtc().toIso8601String(),
            'payload': jsonDecode(e.payloadJson),
          };
          buffer.writeln(jsonEncode(eventMap));
        }

        final fileName = 'chunk_${devId}_${DateTime.now().millisecondsSinceEpoch}.jsonl';
        await driveClient.uploadChunk(
          fileName: fileName,
          content: buffer.toString(),
        );

        await queueService.markEventsUploaded(eventIds);
      }

      // Step 2: Download and Replay Remote Chunks
      final remoteChunks = await driveClient.listRemoteChunks(excludeDeviceId: devId);
      for (final chunk in remoteChunks) {
        final content = chunk.content.isNotEmpty ? chunk.content : await driveClient.downloadFile(chunk.fileId);
        if (content.isNotEmpty) {
          final lines = const LineSplitter().convert(content);
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            try {
              final eventMap = jsonDecode(line) as Map<String, dynamic>;
              final entityType = eventMap['entity_type'] as String;
              final operation = eventMap['operation'] as String;
              final payload = eventMap['payload'] as Map<String, dynamic>;

              await conflictResolver.applyRemoteEvent(
                entityType: entityType,
                operation: operation,
                payload: payload,
              );
            } catch (_) {}
          }
        }
      }

      // Step 3: Register Device Metadata
      await driveClient.upsertDeviceMetadata(
        DeviceMetadata(
          deviceId: devId,
          deviceName: 'WatchMark Client',
          platform: 'flutter',
          lastSeenAt: DateTime.now(),
        ),
      );

      final newPendingCount = (await queueService.getPendingEvents()).length;
      if (mounted) {
        state = state.copyWith(
          isSyncing: false,
          pendingCount: newPendingCount,
          lastSyncTime: DateTime.now(),
          errorMessage: null,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isSyncing: false,
          errorMessage: 'Sync error: $e',
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _authSub?.cancel();
    _pendingSub?.cancel();
    super.dispose();
  }
}

final syncEngineProvider = StateNotifierProvider<SyncEngine, SyncStatusState>((ref) {
  final authService = ref.watch(googleAuthServiceProvider);
  final driveClient = ref.watch(driveSyncClientProvider);
  final queueService = ref.watch(syncQueueServiceProvider);
  final conflictResolver = ref.watch(conflictResolverProvider);

  return SyncEngine(
    authService: authService,
    driveClient: driveClient,
    queueService: queueService,
    conflictResolver: conflictResolver,
  );
});
