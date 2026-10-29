import 'dart:async';

import 'package:dose_time/features/auth/domain/auth_repository.dart';
import 'package:dose_time/features/auth/presentation/providers/auth_providers.dart';
import 'package:dose_time/features/auth/presentation/screens/account_screen.dart';
import 'package:dose_time/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// In-memory AuthRepository for widget tests.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user, this.apple = false});

  AppUser? user;
  final bool apple;
  final _controller = StreamController<AppUser?>.broadcast();
  AuthFailure? nextFailure;
  bool googleCancels = false;
  int signOutCalls = 0;

  void _emit() => _controller.add(user);

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield user;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => user;

  @override
  Future<bool> isAppleSignInAvailable() async => apple;

  @override
  String? get pendingLinkEmail => null;

  @override
  void clearPendingLink() {}

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    if (nextFailure != null) throw nextFailure!;
    user = AppUser(uid: 'u1', email: email, providers: const ['password'], emailVerified: true);
    _emit();
    return user!;
  }

  @override
  Future<AppUser> registerWithEmail(String email, String password, {String? displayName}) async {
    user = AppUser(uid: 'u1', email: email, providers: const ['password']);
    _emit();
    return user!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AppUser?> reloadUser() async => user;

  @override
  Future<AppUser> signInWithGoogle() async {
    if (googleCancels) throw const AuthCancelled();
    user = const AppUser(uid: 'g1', email: 'g@example.com', providers: ['google.com'], emailVerified: true);
    _emit();
    return user!;
  }

  @override
  Future<AppUser> signInWithApple() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {
    signOutCalls++;
    user = null;
    _emit();
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    user = null;
    _emit();
  }
}

Widget _app(FakeAuthRepository repo, {String initial = '/settings/account/sign-in'}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SizedBox()),
      GoRoute(
        path: '/settings/account',
        builder: (_, __) => const AccountScreen(),
        routes: [
          GoRoute(path: 'sign-in', builder: (_, __) => const SignInScreen()),
          GoRoute(path: 'register', builder: (_, __) => const Scaffold(body: Text('Register'))),
          GoRoute(path: 'forgot-password', builder: (_, __) => const Scaffold(body: Text('Forgot'))),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('sign-in screen shows Google and email options, no Apple button off iOS', (tester) async {
    await tester.pumpWidget(_app(FakeAuthRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign in with Apple'), findsNothing);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('shows the Apple button when Apple sign-in is available', (tester) async {
    await tester.pumpWidget(_app(FakeAuthRepository(apple: true)));
    await tester.pumpAndSettle();
    expect(find.text('Sign in with Apple'), findsOneWidget);
  });

  testWidgets('validates the email form before calling the service', (tester) async {
    await tester.pumpWidget(_app(FakeAuthRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('password visibility can be toggled', (tester) async {
    await tester.pumpWidget(_app(FakeAuthRepository()));
    await tester.pumpAndSettle();

    EditableText field() => tester.widget<EditableText>(
        find.descendant(of: find.byType(TextFormField).at(1), matching: find.byType(EditableText)));
    expect(field().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(field().obscureText, isFalse);
  });

  testWidgets('shows a readable error for a failed email sign-in', (tester) async {
    final repo = FakeAuthRepository()..nextFailure = AuthFailure('wrong-password', authErrorMessage('wrong-password'));
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'me@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'bad');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(repo.user, isNull);
  });

  testWidgets('cancelled Google sign-in shows no error', (tester) async {
    final repo = FakeAuthRepository()..googleCancels = true;
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('went wrong'), findsNothing);
    expect(repo.user, isNull);
  });

  testWidgets('successful sign-in lands on the account screen', (tester) async {
    await tester.pumpWidget(_app(FakeAuthRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('g@example.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('unverified email accounts see the verification card', (tester) async {
    final repo = FakeAuthRepository(
      user: const AppUser(uid: 'u1', email: 'new@example.com', providers: ['password']),
    );
    await tester.pumpWidget(_app(repo, initial: '/settings/account'));
    await tester.pumpAndSettle();
    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('Resend email'), findsOneWidget);
  });

  testWidgets('sign out returns to the signed-out state', (tester) async {
    final repo = FakeAuthRepository(
      user: const AppUser(uid: 'u1', email: 'me@example.com', providers: ['password'], emailVerified: true),
    );
    await tester.pumpWidget(_app(repo, initial: '/settings/account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(repo.signOutCalls, 1);
    expect(find.text('You\'re not signed in'), findsOneWidget);
  });
}
