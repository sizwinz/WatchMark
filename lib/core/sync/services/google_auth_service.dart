import 'dart:async';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

abstract class IGoogleAuthService {
  Stream<String?> get currentUserEmailStream;
  String? get currentUserEmail;
  String? get lastErrorMessage;
  bool get isSignedIn;
  Future<bool> signIn();
  Future<void> signOut();
  Future<auth.AuthClient?> getAuthenticatedClient();
}

class GoogleAuthService implements IGoogleAuthService {
  final GoogleSignIn _googleSignIn;
  final _emailController = StreamController<String?>.broadcast();
  String? _cachedEmail;
  String? _lastErrorMessage;

  GoogleAuthService([GoogleSignIn? googleSignIn])
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [
                drive.DriveApi.driveAppdataScope,
              ],
            ) {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _cachedEmail = account?.email;
      _emailController.add(_cachedEmail);
    });
  }

  @override
  Stream<String?> get currentUserEmailStream => _emailController.stream;

  @override
  String? get currentUserEmail => _cachedEmail ?? _googleSignIn.currentUser?.email;

  @override
  String? get lastErrorMessage => _lastErrorMessage;

  @override
  bool get isSignedIn => currentUserEmail != null;

  @override
  Future<bool> signIn() async {
    _lastErrorMessage = null;
    try {
      final account = await _googleSignIn.signIn();
      _cachedEmail = account?.email;
      _emailController.add(_cachedEmail);
      if (account == null) {
        _lastErrorMessage = 'Sign-in cancelled by user';
      }
      return account != null;
    } catch (e) {
      _lastErrorMessage = e.toString();
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _cachedEmail = null;
    _lastErrorMessage = null;
    _emailController.add(null);
  }

  @override
  Future<auth.AuthClient?> getAuthenticatedClient() async {
    try {
      return await _googleSignIn.authenticatedClient();
    } catch (e) {
      return null;
    }
  }
}

final googleAuthServiceProvider = Provider<IGoogleAuthService>((ref) {
  return GoogleAuthService();
});
