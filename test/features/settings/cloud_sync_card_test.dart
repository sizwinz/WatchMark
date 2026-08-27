import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:watchmark/core/sync/models/sync_models.dart';
import 'package:watchmark/core/sync/services/google_auth_service.dart';
import 'package:watchmark/core/sync/services/sync_engine.dart';
import 'package:watchmark/features/settings/widgets/cloud_sync_card.dart';

class FakeGoogleAuthService implements IGoogleAuthService {
  @override
  String? get currentUserEmail => 'user@gmail.com';

  @override
  String? get lastErrorMessage => null;

  @override
  Stream<String?> get currentUserEmailStream => Stream.value('user@gmail.com');

  @override
  bool get isSignedIn => true;

  @override
  Future<bool> signIn() async => true;

  @override
  Future<void> signOut() async {}

  @override
  Future<auth.AuthClient?> getAuthenticatedClient() async => null;
}

void main() {
  group('CloudSyncCard Widget Tests', () {
    testWidgets('Disconnected state renders Connect Google Drive button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncEngineProvider.overrideWith(
              (ref) => FakeSyncEngine(
                const SyncStatusState(
                  isConnected: false,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CloudSyncCard(),
            ),
          ),
        ),
      );

      expect(find.text('Cloud Sync (Google Drive)'), findsOneWidget);
      expect(find.text('Connect Google Drive'), findsOneWidget);
    });

    testWidgets('Connected state renders account, device ID, and Sync Now action', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            googleAuthServiceProvider.overrideWithValue(FakeGoogleAuthService()),
            syncEngineProvider.overrideWith(
              (ref) => FakeSyncEngine(
                const SyncStatusState(
                  isConnected: true,
                  accountEmail: 'user@gmail.com',
                  deviceId: 'device-12345678-abcd',
                  pendingCount: 0,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CloudSyncCard(),
            ),
          ),
        ),
      );

      expect(find.text('Google Drive Sync'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('user@gmail.com'), findsOneWidget);
      expect(find.text('device-1'), findsOneWidget); // substring 8
      expect(find.text('Up to date'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);
      expect(find.text('Disconnect'), findsOneWidget);
    });
  });
}

class FakeSyncEngine extends StateNotifier<SyncStatusState> implements SyncEngine {
  FakeSyncEngine(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
