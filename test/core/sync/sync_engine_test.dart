import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/storage/secure_storage_service.dart';
import 'package:watchmark/core/sync/models/sync_models.dart';
import 'package:watchmark/core/sync/services/conflict_resolver.dart';
import 'package:watchmark/core/sync/services/drive_sync_client.dart';
import 'package:watchmark/core/sync/services/google_auth_service.dart';
import 'package:watchmark/core/sync/services/sync_engine.dart';
import 'package:watchmark/core/sync/services/sync_queue_service.dart';

class MockGoogleAuthService implements IGoogleAuthService {
  String? email = 'tester@example.com';

  @override
  String? get currentUserEmail => email;

  @override
  String? get lastErrorMessage => null;

  @override
  Stream<String?> get currentUserEmailStream => Stream.value(email);

  @override
  bool get isSignedIn => email != null;

  @override
  Future<bool> signIn() async {
    email = 'tester@example.com';
    return true;
  }

  @override
  Future<void> signOut() async {
    email = null;
  }

  @override
  Future<auth.AuthClient?> getAuthenticatedClient() async => null;
}

class MockDriveClient implements IDriveSyncClient {
  final Map<String, String> remoteFiles = {};
  DeviceMetadata? lastMeta;

  @override
  Future<String> uploadChunk({required String fileName, required String content}) async {
    remoteFiles[fileName] = content;
    return 'id-$fileName';
  }

  @override
  Future<List<SyncChunk>> listRemoteChunks({required String excludeDeviceId}) async {
    final chunks = <SyncChunk>[];
    for (final entry in remoteFiles.entries) {
      if (entry.key.startsWith('chunk_')) {
        final parts = entry.key.replaceAll('.jsonl', '').split('_');
        if (parts.length >= 3 && parts[1] != excludeDeviceId) {
          chunks.add(
            SyncChunk(
              fileId: 'id-${entry.key}',
              fileName: entry.key,
              deviceId: parts[1],
              sequence: int.tryParse(parts[2]) ?? 0,
              content: entry.value,
              createdAt: DateTime.now(),
            ),
          );
        }
      }
    }
    return chunks;
  }

  @override
  Future<String> downloadFile(String fileId) async {
    final name = fileId.replaceFirst('id-', '');
    return remoteFiles[name] ?? '';
  }

  @override
  Future<void> deleteFile(String fileId) async {}

  @override
  Future<void> upsertDeviceMetadata(DeviceMetadata meta) async {
    lastMeta = meta;
  }

  @override
  Future<DeviceMetadata?> getDeviceMetadata(String deviceId) async {
    return lastMeta;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SyncQueueService queueService;
  late ConflictResolver conflictResolver;
  late MockGoogleAuthService authService;
  late MockDriveClient driveClient;
  late SyncEngine engine;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queueService = SyncQueueService(
      db: db,
      storage: SecureStorageService(),
      initialDeviceId: 'device-test-123',
    );
    conflictResolver = ConflictResolver(db);
    authService = MockGoogleAuthService();
    driveClient = MockDriveClient();

    engine = SyncEngine(
      authService: authService,
      driveClient: driveClient,
      queueService: queueService,
      conflictResolver: conflictResolver,
    );
  });

  tearDown(() async {
    engine.dispose();
    await db.close();
  });

  group('Sync Queue, Conflict Resolver & Sync Engine Unit Tests', () {
    test('SyncQueueService enqueues and retrieves pending events', () async {
      await queueService.enqueueEvent(
        entityType: 'library_entry',
        entityId: 'entry-1',
        operation: 'upsert',
        payload: {'status': 'watching', 'progressSeconds': 500},
      );

      final pending = await queueService.getPendingEvents();
      expect(pending.length, 1);
      expect(pending.first.entityType, 'library_entry');
      expect(pending.first.isUploaded, isFalse);

      await queueService.markEventsUploaded([pending.first.id]);

      final after = await queueService.getPendingEvents();
      expect(after, isEmpty);
    });

    test('ConflictResolver merges progress using furthest position rule', () async {
      // Local library entry with 30 mins progress
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value('m-1'),
          tmdbId: '100',
          mediaType: 'movie',
          title: 'Dune',
        ),
      );

      await db.libraryDao.upsertLibraryEntry(
        LibraryEntriesCompanion.insert(
          id: const drift.Value('lib-1'),
          mediaId: 'm-1',
          status: 'watching',
          progressSeconds: const drift.Value(1800), // 30m
        ),
      );

      // Remote event with 45 mins progress
      final remotePayload = {
        'id': 'lib-1',
        'mediaId': 'm-1',
        'status': 'watching',
        'progressSeconds': 2700, // 45m
        'createdAt': 1724673600000,
        'updatedAt': 1724673600000,
      };

      await conflictResolver.applyRemoteEvent(
        entityType: 'library_entry',
        operation: 'upsert',
        payload: remotePayload,
      );

      final entry = await db.libraryDao.getLibraryEntryByMediaId('m-1');
      expect(entry!.progressSeconds, 2700); // Merged to 45m (max)
    });

    test('ConflictResolver merges watch sessions using additive union', () async {
      // Create referenced title
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value('m-1'),
          tmdbId: '100',
          mediaType: 'movie',
          title: 'Dune',
        ),
      );

      final remoteSessionPayload = {
        'id': 'remote-sess-1',
        'mediaId': 'm-1',
        'startedAt': 1724673600000,
        'endedAt': 1724675400000,
        'positionBeforeSeconds': 0,
        'positionAfterSeconds': 1800,
        'provider': 'netflix',
        'entryMethod': 'manual',
        'createdAt': 1724675400000,
        'updatedAt': 1724675400000,
      };

      await conflictResolver.applyRemoteEvent(
        entityType: 'watch_session',
        operation: 'upsert',
        payload: remoteSessionPayload,
      );

      final sessions = await db.sessionsDao.getAllSessions();
      expect(sessions.length, 1);
      expect(sessions.first.id, 'remote-sess-1');
      expect(sessions.first.provider, 'netflix');
    });

    test('SyncEngine uploads local chunk and replays remote chunks', () async {
      // 1. Enqueue local event
      await queueService.enqueueEvent(
        entityType: 'library_entry',
        entityId: 'entry-local',
        operation: 'upsert',
        payload: {'status': 'watching'},
      );

      // 2. Mock a remote chunk in DriveClient
      final remoteEvent = {
        'id': 'evt-remote-1',
        'entity_type': 'media_title',
        'entity_id': 'm-remote',
        'operation': 'upsert',
        'payload': {
          'id': 'm-remote',
          'tmdbId': '777',
          'mediaType': 'movie',
          'title': 'Remote Movie',
          'createdAt': 1724673600000,
          'updatedAt': 1724673600000,
        },
      };

      driveClient.remoteFiles['chunk_deviceRemote_1.jsonl'] = jsonEncode(remoteEvent);

      // 3. Trigger syncNow()
      await engine.syncNow();

      // Verify local events uploaded
      expect(driveClient.remoteFiles.keys.any((k) => k.contains('chunk_')), isTrue);
      final pending = await queueService.getPendingEvents();
      expect(pending, isEmpty);

      // Verify remote title was replayed into local SQLite
      final titles = await db.mediaDao.getAllTitles();
      expect(titles.any((t) => t.id == 'm-remote'), isTrue);
      expect(engine.state.isSyncing, isFalse);
      expect(engine.state.lastSyncTime, isNotNull);
    });
  });
}
