/// Signed-in user, decoupled from the Firebase SDK so UI and tests don't
/// depend on it.
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;

  /// Firebase provider ids, e.g. 'password', 'google.com', 'apple.com'.
  final List<String> providers;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = false,
    this.providers = const [],
  });

  bool get hasPassword => providers.contains('password');
  bool get hasGoogle => providers.contains('google.com');
  bool get hasApple => providers.contains('apple.com');

  /// Apple "Hide My Email" relay addresses are real, deliverable addresses.
  bool get usesApplePrivateRelay =>
      email?.toLowerCase().endsWith('@privaterelay.appleid.com') ?? false;

  /// Only password accounts need a verified email; Google and Apple
  /// addresses are verified by the provider.
  bool get needsEmailVerification => hasPassword && !emailVerified && !hasGoogle && !hasApple;
}

/// A sign-in method was cancelled by the user (not an error to show).
class AuthCancelled implements Exception {
  const AuthCancelled();
}

/// A user-facing authentication failure. [message] is safe to display.
class AuthFailure implements Exception {
  final String code;
  final String message;

  const AuthFailure(this.code, this.message);

  @override
  String toString() => 'AuthFailure($code)';
}

/// Converts Firebase Auth error codes into plain-language messages. Messages
/// deliberately don't reveal whether an email is registered.
String authErrorMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return 'That email address doesn\'t look right.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support for help.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'INVALID_LOGIN_CREDENTIALS':
      return 'Email or password is incorrect.';
    case 'email-already-in-use':
      return 'An account already exists for this email. Sign in instead, or reset your password.';
    case 'weak-password':
      return 'Choose a stronger password (at least 8 characters, with letters and numbers).';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a few minutes and try again.';
    case 'network-request-failed':
      return 'No internet connection. Check your connection and try again.';
    case 'operation-not-allowed':
      return 'This sign-in method isn\'t enabled yet. Please try another method.';
    case 'requires-recent-login':
      return 'For your security, please sign in again to continue.';
    case 'account-exists-with-different-credential':
      return 'You already have an account with this email using a different sign-in method. '
          'Sign in that way first and we\'ll link this one to it.';
    case 'credential-already-in-use':
      return 'That sign-in is already linked to a different DoseAlert account.';
    case 'provider-already-linked':
      return 'That sign-in method is already linked to your account.';
    case 'user-mismatch':
      return 'Please sign in with the same account you\'re using now.';
    case 'firebase-unavailable':
      return 'Accounts are unavailable right now. Your reminders still work offline.';
    case 'apple-unavailable':
      return 'Sign in with Apple isn\'t available on this device.';
    case 'google-sign-in-failed':
      return 'Google sign-in didn\'t complete. Please try again.';
    default:
      return 'Something went wrong. Please try again.';
  }
}

abstract class AuthRepository {
  /// Emits the current user (or null) and every change after that.
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  /// Whether Sign in with Apple can be offered (iOS with Apple support).
  Future<bool> isAppleSignInAvailable();

  /// Email of an account waiting to have a Google/Apple sign-in linked to it
  /// after the user proves ownership by signing in another way.
  String? get pendingLinkEmail;
  void clearPendingLink();

  Future<AppUser> signInWithEmail(String email, String password);

  /// Creates the account and sends a verification email.
  Future<AppUser> registerWithEmail(String email, String password, {String? displayName});

  Future<void> sendPasswordReset(String email);
  Future<void> sendEmailVerification();

  /// Refreshes the user (e.g. after they click the verification link).
  Future<AppUser?> reloadUser();

  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();

  Future<void> signOut();

  /// Re-authenticates (password needed for email accounts), revokes Apple
  /// tokens where applicable, then permanently deletes the account.
  Future<void> deleteAccount({String? password});
}
