import 'package:dose_time/features/auth/domain/auth_repository.dart';
import 'package:dose_time/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators', () {
    test('email requires a plausible address', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('not-an-email'), isNotNull);
      expect(AuthValidators.email('a@b'), isNotNull);
      expect(AuthValidators.email(' user@example.com '), isNull);
    });

    test('new password needs 8+ chars with letters and numbers', () {
      expect(AuthValidators.newPassword('short1'), isNotNull);
      expect(AuthValidators.newPassword('allletters'), isNotNull);
      expect(AuthValidators.newPassword('12345678'), isNotNull);
      expect(AuthValidators.newPassword('doses2024'), isNull);
    });

    test('sign-in password only needs to be non-empty', () {
      expect(AuthValidators.signInPassword(''), isNotNull);
      expect(AuthValidators.signInPassword('x'), isNull);
    });
  });

  group('authErrorMessage', () {
    test('wrong password and unknown user share one message (no account enumeration)', () {
      final wrong = authErrorMessage('wrong-password');
      expect(authErrorMessage('user-not-found'), wrong);
      expect(authErrorMessage('invalid-credential'), wrong);
    });

    test('known codes map to specific guidance', () {
      expect(authErrorMessage('email-already-in-use'), contains('already exists'));
      expect(authErrorMessage('network-request-failed'), contains('internet'));
      expect(authErrorMessage('account-exists-with-different-credential'), contains('link'));
    });

    test('unknown codes fall back to a generic message', () {
      expect(authErrorMessage('something-new'), 'Something went wrong. Please try again.');
    });
  });

  group('AppUser', () {
    test('only unverified password accounts need email verification', () {
      expect(const AppUser(uid: '1', providers: ['password']).needsEmailVerification, isTrue);
      expect(const AppUser(uid: '1', providers: ['password'], emailVerified: true).needsEmailVerification,
          isFalse);
      expect(const AppUser(uid: '1', providers: ['google.com']).needsEmailVerification, isFalse);
      expect(const AppUser(uid: '1', providers: ['password', 'apple.com']).needsEmailVerification, isFalse);
    });

    test('detects Apple private relay addresses', () {
      expect(const AppUser(uid: '1', email: 'abc123@privaterelay.appleid.com').usesApplePrivateRelay, isTrue);
      expect(const AppUser(uid: '1', email: 'me@icloud.com').usesApplePrivateRelay, isFalse);
    });
  });
}
