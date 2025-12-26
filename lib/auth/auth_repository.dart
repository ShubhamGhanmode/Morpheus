import 'package:firebase_auth/firebase_auth.dart';
import 'package:morpheus/auth/auth_user.dart';
import 'package:morpheus/services/auth_service.dart';
import 'package:morpheus/services/notification_service.dart';

/// Auth data access: fetches/refreshes tokens and exposes auth state changes.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<AuthUser?> authChanges() {
    return _auth.idTokenChanges().asyncMap((user) async {
      if (user == null) return null;
      final token = await user.getIdToken();
      if (token == null) return null;
      return AuthUser.fromFirebase(user, token);
    });
  }

  /// Used on splash: reloads the current user and verifies an ID token.
  Future<AuthUser?> restoreSession() async {
    // Attempt silent Google sign-in first to capture previous sessions without UI.
    // (Root cause of phantom sheet: eager UI auth attempt. We keep this silent.)
    final user = _auth.currentUser ?? await AuthService.trySilentGoogleSignIn();
    if (user == null) return null;
    await user.reload();
    final token = await user.getIdToken(true);
    if (token == null) return null;
    return AuthUser.fromFirebase(user, token);
  }

  Future<void> signOut() async {
    await NotificationService.instance.deleteCurrentToken();
    await AuthService.signOut();
  }
}
