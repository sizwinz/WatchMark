import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:watchmark/core/sync/models/sync_models.dart';
import 'package:watchmark/core/sync/services/drive_sync_client.dart';
import 'package:watchmark/core/sync/services/google_auth_service.dart';

class MockGoogleAuthService implements IGoogleAuthService {
  String? _email;

  @override
  String? get currentUserEmail => _email;

  @override
  String? get lastErrorMessage => null;

  @override
  Stream<String?> get currentUserEmailStream => Stream.value(_email);

  @override
  bool get isSignedIn => _email != null;

  @override
  Future<bool> signIn() async {
    _email = 'user@example.com';
    return true;
  }

  @override
  Future<void> signOut() async {
    _email = null;
  }

  @override
  Future<auth.AuthClient?> getAuthenticatedClient() async => null;
}

class MockDriveSyncClient implements IDriveSyncClient {
  final Map<String, String> storage = {};
  DeviceMetadata? deviceMetadata;

  @override
  Future<String> uploadChunk({required String fileName, required String content}) async {
    final fileId = 'file-${storage.length + 1}';
    storage[fileName] = content;
    return fileId;
  }

  @override
  Future<List<SyncChunk>> listRemoteChunks({required String excludeDeviceId}) async {
    final chunks = <SyncChunk>[];
    for (final entry in storage.entries) {
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
    return storage.values.firstOrNull ?? '';
  }

  @override
  Future<void> deleteFile(String fileId) async {}

  @override
  Future<void> upsertDeviceMetadata(DeviceMetadata meta) async {
    deviceMetadata = meta;
  }

  @override
  Future<DeviceMetadata?> getDeviceMetadata(String deviceId) async {
    return deviceMetadata;
  }
}

void main() {
  group('Auth & Drive Sync Client Unit Tests', () {
    test('DeviceMetadata serializes to and from JSON', () {
      final meta = DeviceMetadata(
        deviceId: 'dev-123',
        deviceName: 'Pixel 8',
        platform: 'android',
        lastSeenAt: DateTime(2026, 8, 26, 12, 0),
        appVersion: '1.0.0+1',
      );

      final json = meta.toJson();
      final reconstructed = DeviceMetadata.fromJson(json);

      expect(reconstructed.deviceId, 'dev-123');
      expect(reconstructed.deviceName, 'Pixel 8');
      expect(reconstructed.platform, 'android');
      expect(reconstructed.appVersion, '1.0.0+1');
    });

    test('MockGoogleAuthService handles sign in and sign out', () async {
      final authService = MockGoogleAuthService();
      expect(authService.isSignedIn, isFalse);
      expect(authService.currentUserEmail, isNull);

      final success = await authService.signIn();
      expect(success, isTrue);
      expect(authService.isSignedIn, isTrue);
      expect(authService.currentUserEmail, 'user@example.com');

      await authService.signOut();
      expect(authService.isSignedIn, isFalse);
      expect(authService.currentUserEmail, isNull);
    });

    test('MockDriveSyncClient uploads chunks and filters remote device chunks', () async {
      final client = MockDriveSyncClient();

      await client.uploadChunk(
        fileName: 'chunk_deviceA_1.jsonl',
        content: '{"event": "1"}\n{"event": "2"}',
      );
      await client.uploadChunk(
        fileName: 'chunk_deviceB_1.jsonl',
        content: '{"event": "3"}',
      );

      // Exclude deviceA -> only deviceB chunk returned
      final remoteChunks = await client.listRemoteChunks(excludeDeviceId: 'deviceA');
      expect(remoteChunks.length, 1);
      expect(remoteChunks.first.deviceId, 'deviceB');
    });
  });
}
