import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dose_time/features/auth/domain/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Firebase Authentication implementation. Sessions are persisted and
/// refreshed by the Firebase SDK; no tokens or passwords are stored or logged.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final GoogleSignIn _googleSignIn;

  /// Google/Apple credential that hit an existing account with the same email.
  /// It is linked only after the user signs in to that account another way.
  AuthCredential? _pendingCredential;
  String? _pendingEmail;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth {
    if (!_firebaseReady) {
      throw AuthFailure('firebase-unavailable', authErrorMessage('firebase-unavailable'));
    }
    return FirebaseAuth.instance;
  }

  static AppUser? _map(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
      providers: user.providerData.map((p) => p.providerId).toList(),
    );
  }

  static AuthFailure _failure(FirebaseAuthException e) {
    // Only the code is logged — never the email, password or tokens.
    debugPrint('Auth error: ${e.code}');
    return AuthFailure(e.code, authErrorMessage(e.code));
  }

  @override
  Stream<AppUser?> authStateChanges() {
    if (!_firebaseReady) return Stream.value(null);
    // userChanges also fires on profile/verification updates.
    return FirebaseAuth.instance.userChanges().map(_map);
  }

  @override
  AppUser? get currentUser => _firebaseReady ? _map(FirebaseAuth.instance.currentUser) : null;

  @override
  Future<bool> isAppleSignInAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;
    try {
      return await SignInWithApple.isAvailable();
    } catch (_) {
      return false;
    }
  }

  @override
  String? get pendingLinkEmail => _pendingEmail;

  @override
  void clearPendingLink() {
    _pendingCredential = null;
    _pendingEmail = null;
  }

  /// Links a pending Google/Apple credential once the user has signed in to
  /// the existing account with the same email (proving they own it).
  Future<User> _completePendingLink(User user) async {
    final pending = _pendingCredential;
    final email = _pendingEmail;
    if (pending == null || email == null) return user;
    if (user.email?.toLowerCase() != email.toLowerCase()) return user;
    try {
      final result = await user.linkWithCredential(pending);
      clearPendingLink();
      return result.user ?? user;
    } on FirebaseAuthException catch (e) {
      clearPendingLink();
      if (e.code == 'provider-already-linked') return user;
      rethrow;
    }
  }

  Future<AppUser> _finish(UserCredential credential) async {
    var user = credential.user;
    if (user == null) throw const AuthFailure('unknown', 'Sign-in did not complete. Please try again.');
    user = await _completePendingLink(user);
    return _map(user)!;
  }

  void _rememberPendingLink(FirebaseAuthException e) {
    if (e.code == 'account-exists-with-different-credential' && e.credential != null) {
      _pendingCredential = e.credential;
      _pendingEmail = e.email;
    }
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return await _finish(result);
    } on FirebaseAuthException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<AppUser> registerWithEmail(String email, String password, {String? displayName}) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final user = result.user!;
      final name = displayName?.trim();
      if (name != null && name.isNotEmpty) await user.updateDisplayName(name);
      await user.sendEmailVerification();
      await user.reload();
      return _map(_auth.currentUser) ?? _map(user)!;
    } on FirebaseAuthException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Don't reveal whether the address has an account.
      if (e.code == 'user-not-found') return;
      throw _failure(e);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<AppUser?> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
      return _map(_auth.currentUser);
    } on FirebaseAuthException catch (e) {
      throw _failure(e);
    }
  }

  Future<OAuthCredential> _googleCredential() async {
    final GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('Google sign-in failed: ${e.runtimeType}');
      throw AuthFailure('google-sign-in-failed', authErrorMessage('google-sign-in-failed'));
    }
    if (account == null) throw const AuthCancelled();
    final tokens = await account.authentication;
    return GoogleAuthProvider.credential(idToken: tokens.idToken, accessToken: tokens.accessToken);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final auth = _auth;
    final credential = await _googleCredential();
    try {
      return await _finish(await auth.signInWithCredential(credential));
    } on FirebaseAuthException catch (e) {
      _rememberPendingLink(e);
      await _googleSignIn.signOut();
      throw _failure(e);
    }
  }

  static String _nonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Native Apple sign-in. Returns the Firebase credential plus Apple's
  /// one-time authorization code (needed to revoke tokens on deletion).
  Future<(OAuthCredential, AuthorizationCredentialAppleID)> _appleCredential() async {
    if (!await isAppleSignInAvailable()) {
      throw AuthFailure('apple-unavailable', authErrorMessage('apple-unavailable'));
    }
    final rawNonce = _nonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final AuthorizationCredentialAppleID apple;
    try {
      apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw const AuthCancelled();
      debugPrint('Apple sign-in failed: ${e.code}');
      throw const AuthFailure('apple-failed', 'Sign in with Apple didn\'t complete. Please try again.');
    }
    final credential = OAuthProvider('apple.com').credential(
      idToken: apple.identityToken,
      rawNonce: rawNonce,
      accessToken: apple.authorizationCode,
    );
    return (credential, apple);
  }

  @override
  Future<AppUser> signInWithApple() async {
    final auth = _auth;
    final (credential, apple) = await _appleCredential();
    try {
      final result = await auth.signInWithCredential(credential);
      // Apple shares the name only on the first authorization; keep it.
      final user = result.user;
      final name = [apple.givenName, apple.familyName].whereType<String>().join(' ').trim();
      if (user != null && name.isNotEmpty && (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName(name);
      }
      return await _finish(result);
    } on FirebaseAuthException catch (e) {
      _rememberPendingLink(e);
      throw _failure(e);
    }
  }

  @override
  Future<void> signOut() async {
    clearPendingLink();
    try {
      if (await _googleSignIn.isSignedIn()) await _googleSignIn.signOut();
    } catch (_) {}
    if (_firebaseReady) await FirebaseAuth.instance.signOut();
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    final auth = _auth;
    final user = auth.currentUser;
    if (user == null) return;
    final providers = user.providerData.map((p) => p.providerId).toSet();
    try {
      // Re-authenticate first so delete() never fails with requires-recent-login.
      if (providers.contains('apple.com') && await isAppleSignInAvailable()) {
        final (credential, apple) = await _appleCredential();
        await user.reauthenticateWithCredential(credential);
        // Apple requires apps to revoke tokens when an account is deleted.
        await auth.revokeTokenWithAuthorizationCode(apple.authorizationCode);
      } else if (providers.contains('password') && password != null) {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );
      } else if (providers.contains('google.com')) {
        await user.reauthenticateWithCredential(await _googleCredential());
      }
      await user.delete();
      try {
        if (providers.contains('google.com')) await _googleSignIn.disconnect();
      } catch (_) {}
      clearPendingLink();
    } on FirebaseAuthException catch (e) {
      throw _failure(e);
    }
  }
}
