import 'package:dose_time/features/auth/data/firebase_auth_repository.dart';
import 'package:dose_time/features/auth/domain/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Current signed-in user (null when signed out). Sign-in is optional: the
/// app and its local reminders work the same either way.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final appleSignInAvailableProvider = FutureProvider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isAppleSignInAvailable();
});

/// Shared form validation for the auth screens.
class AuthValidators {
  AuthValidators._();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? signInPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    return null;
  }

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Include both letters and numbers';
    }
    return null;
  }
}
