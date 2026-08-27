import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/storage/secure_storage_service.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class SyncQueueService {
  final AppDatabase db;
  final SecureStorageService storage;
  String? _cachedDeviceId;

  SyncQueueService({
    required this.db,
    required this.storage,
    String? initialDeviceId,
  }) : _cachedDeviceId = initialDeviceId;

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    _cachedDeviceId = const Uuid().v4();
    return _cachedDeviceId!;
  }

  Future<void> enqueueEvent({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final devId = await getDeviceId();
    await db.into(db.syncEvents).insert(
      SyncEventsCompanion.insert(
        id: drift.Value(generateUuidV7()),
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        deviceId: devId,
        schemaVersion: const drift.Value(1),
        payloadJson: jsonEncode(payload),
        timestamp: drift.Value(DateTime.now()),
        isUploaded: const drift.Value(false),
      ),
    );
  }

  Future<List<SyncEvent>> getPendingEvents() {
    return (db.select(db.syncEvents)
          ..where((tbl) => tbl.isUploaded.equals(false))
          ..orderBy([(tbl) => drift.OrderingTerm.asc(tbl.timestamp)]))
        .get();
  }

  Future<void> markEventsUploaded(List<String> eventIds) async {
    if (eventIds.isEmpty) return;
    await (db.update(db.syncEvents)..where((tbl) => tbl.id.isIn(eventIds))).write(
      const SyncEventsCompanion(
        isUploaded: drift.Value(true),
      ),
    );
  }

  Stream<int> watchPendingCount() {
    return (db.select(db.syncEvents)..where((tbl) => tbl.isUploaded.equals(false)))
        .watch()
        .map((events) => events.length);
  }
}

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final db = ref.watch(databaseProvider);
  final storage = ref.watch(secureStorageServiceProvider);
  return SyncQueueService(db: db, storage: storage);
});
