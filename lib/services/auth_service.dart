import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:morpheus/services/error_reporter.dart';

/// Centralized auth utilities for Google + Firebase.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Call once at app startup (e.g., before runApp).
  ///
  /// - `clientId`: Use on iOS/macOS, or if you have a specific client ID.
  /// - `serverClientId`: Needed only if you want a server auth code on Android.
  /// - `hostedDomain`: Restrict accounts to a domain (e.g., "example.com").
  static Future<void> initializeGoogle({
    String? clientId,
    String? serverClientId,
    String? hostedDomain,
    String? nonce,
  }) async {
    // Initialize the singleton with optional parameters.
    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId:
          "842775331840-gsso7qkcb8mmi0sj97b63upejevbku48.apps.googleusercontent.com",
      hostedDomain: hostedDomain,
      nonce: nonce,
    );
    // NOTE: We intentionally avoid auto-attempting Google auth here.
    // Root cause of the phantom "Signing you in" sheet was this init hook
    // kicking off a background flow before the user tapped anything.
    // (Comment kept for future audits of startup auth UX.)
  }

  /// Sign in with Google and Firebase.
  ///
  /// Returns a tuple of (User?, isNewUser).
  static Future<(User?, bool)> signInWithGoogle() async {
    if (kIsWeb) {
      // On web, use Firebase's popup flow with a Google provider.
      final provider = GoogleAuthProvider();
      final userCred = await _auth.signInWithPopup(provider);
      final isNew = userCred.additionalUserInfo?.isNewUser ?? false;
      return (userCred.user, isNew);
    }

    // On Android/iOS/macOS, run the interactive Google flow.
    final account = await GoogleSignIn.instance.authenticate();

    // Fetch tokens. In v7+, GoogleSignInAuthentication exposes idToken only.
    final googleAuth = account.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw StateError('Google Sign-In returned a null idToken.');
    }

    // Build Firebase credential from Google idToken.
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    // Sign in to Firebase.
    final userCred = await _auth.signInWithCredential(credential);
    final isNew = userCred.additionalUserInfo?.isNewUser ?? false;
    return (userCred.user, isNew);
  }

  /// Silent Google sign-in without UI; returns Firebase [User] if possible.
  static Future<User?> trySilentGoogleSignIn() async {
    if (kIsWeb) return null;
    try {
      // Lightweight = no blocking UI; if the platform shows UI, it is minimal.
      final maybeFuture = GoogleSignIn.instance
          .attemptLightweightAuthentication();
      final account = maybeFuture == null ? null : await maybeFuture;
      if (account == null) return null;

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return null;

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCred = await _auth.signInWithCredential(credential);
      return userCred.user;
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Silent Google sign-in failed',
      );
      // Ignore failures; caller will treat as unauthenticated.
      return null;
    }
  }

  /// Firebase auth state stream (useful for gates/navigation).
  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Sign out from both Google and Firebase.
  static Future<void> signOut() async {
    // Best-effort Google sign out (non-web).
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e, stack) {
        await ErrorReporter.recordError(
          e,
          stack,
          reason: 'Google sign-out failed',
        );
        // ignore; still sign out from Firebase below
      }
    }
    await _auth.signOut();
  }

  /// Fully disconnect (revokes authorization). Optional.
  static Future<void> disconnect() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (e, stack) {
        await ErrorReporter.recordError(
          e,
          stack,
          reason: 'Google disconnect failed',
        );
        // ignore
      }
    }
    await _auth.signOut();
  }
}
