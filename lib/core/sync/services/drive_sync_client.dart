import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:watchmark/core/sync/models/sync_models.dart';
import 'package:watchmark/core/sync/services/google_auth_service.dart';

abstract class IDriveSyncClient {
  Future<String> uploadChunk({
    required String fileName,
    required String content,
  });

  Future<List<SyncChunk>> listRemoteChunks({required String excludeDeviceId});

  Future<String> downloadFile(String fileId);

  Future<void> deleteFile(String fileId);

  Future<void> upsertDeviceMetadata(DeviceMetadata meta);

  Future<DeviceMetadata?> getDeviceMetadata(String deviceId);
}

class DriveSyncClient implements IDriveSyncClient {
  final IGoogleAuthService authService;

  DriveSyncClient(this.authService);

  Future<drive.DriveApi?> _getApi() async {
    final client = await authService.getAuthenticatedClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  @override
  Future<String> uploadChunk({
    required String fileName,
    required String content,
  }) async {
    final api = await _getApi();
    if (api == null) throw StateError('Not authenticated with Google Drive');

    final bytes = utf8.encode(content);
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/x-ndjson',
    );

    final file = drive.File()
      ..name = fileName
      ..parents = ['appDataFolder'];

    final created = await api.files.create(
      file,
      uploadMedia: media,
      $fields: 'id, name, createdTime',
    );

    return created.id ?? '';
  }

  @override
  Future<List<SyncChunk>> listRemoteChunks({required String excludeDeviceId}) async {
    final api = await _getApi();
    if (api == null) return [];

    final fileList = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains 'chunk_' and trashed = false",
      $fields: 'files(id, name, createdTime)',
      orderBy: 'createdTime asc',
    );

    final files = fileList.files ?? [];
    final chunks = <SyncChunk>[];

    for (final f in files) {
      final name = f.name ?? '';
      if (name.startsWith('chunk_') && name.endsWith('.jsonl')) {
        // chunk_{deviceId}_{sequence}.jsonl
        final parts = name.replaceAll('.jsonl', '').split('_');
        if (parts.length >= 3) {
          final deviceId = parts[1];
          final sequence = int.tryParse(parts[2]) ?? 0;

          if (deviceId != excludeDeviceId) {
            chunks.add(
              SyncChunk(
                fileId: f.id ?? '',
                fileName: name,
                deviceId: deviceId,
                sequence: sequence,
                content: '',
                createdAt: f.createdTime ?? DateTime.now(),
              ),
            );
          }
        }
      }
    }

    return chunks;
  }

  @override
  Future<String> downloadFile(String fileId) async {
    final api = await _getApi();
    if (api == null) throw StateError('Not authenticated with Google Drive');

    final response = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (response is drive.Media) {
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }
      return utf8.decode(bytes);
    }

    return '';
  }

  @override
  Future<void> deleteFile(String fileId) async {
    final api = await _getApi();
    if (api == null) return;
    await api.files.delete(fileId);
  }

  @override
  Future<void> upsertDeviceMetadata(DeviceMetadata meta) async {
    final api = await _getApi();
    if (api == null) return;

    final fileName = 'device_${meta.deviceId}.json';
    final jsonStr = jsonEncode(meta.toJson());
    final bytes = utf8.encode(jsonStr);
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );

    // Check if device file already exists
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$fileName' and trashed = false",
      $fields: 'files(id)',
    );

    final existing = list.files?.firstOrNull;
    if (existing?.id != null) {
      await api.files.update(
        drive.File(),
        existing!.id!,
        uploadMedia: media,
      );
    } else {
      final file = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder'];
      await api.files.create(file, uploadMedia: media);
    }
  }

  @override
  Future<DeviceMetadata?> getDeviceMetadata(String deviceId) async {
    final api = await _getApi();
    if (api == null) return null;

    final fileName = 'device_$deviceId.json';
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$fileName' and trashed = false",
      $fields: 'files(id)',
    );

    final fileId = list.files?.firstOrNull?.id;
    if (fileId == null) return null;

    final content = await downloadFile(fileId);
    if (content.isEmpty) return null;

    final decoded = jsonDecode(content) as Map<String, dynamic>;
    return DeviceMetadata.fromJson(decoded);
  }
}

final driveSyncClientProvider = Provider<IDriveSyncClient>((ref) {
  final authService = ref.watch(googleAuthServiceProvider);
  return DriveSyncClient(authService);
});
