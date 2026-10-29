import 'package:dose_time/core/theme/app_theme.dart';
import 'package:dose_time/features/auth/domain/auth_repository.dart';
import 'package:dose_time/features/auth/presentation/providers/auth_providers.dart';
import 'package:dose_time/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _busy; // 'email' | 'google' | 'apple'
  String? _error;

  @override
  void initState() {
    super.initState();
    final pending = ref.read(authRepositoryProvider).pendingLinkEmail;
    if (pending != null) _email.text = pending;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(String method, Future<AppUser> Function() action) async {
    if (_busy != null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = method;
      _error = null;
    });
    try {
      final user = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed in as ${user.email ?? user.displayName ?? 'your account'}')),
      );
      context.go('/settings/account');
    } on AuthCancelled {
      // User backed out of the Google/Apple sheet — nothing to show.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = authErrorMessage('unknown'));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _signInWithEmail() {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(authRepositoryProvider);
    _run('email', () => repo.signInWithEmail(_email.text, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(authRepositoryProvider);
    final appleAvailable = ref.watch(appleSignInAvailableProvider).valueOrNull ?? false;
    final pendingEmail = repo.pendingLinkEmail;

    return AuthScaffold(
      icon: Icons.account_circle_outlined,
      title: 'Sign in to DoseAlert',
      subtitle: 'Optional — your reminders keep working on this phone with or without an account.',
      children: [
        if (pendingEmail != null)
          AuthMessage(
            isError: false,
            message: 'You already have an account for $pendingEmail. Sign in with the method you used before '
                'and we\'ll link your new sign-in to it.',
          ),
        if (_error != null) AuthMessage(message: _error!),
        GoogleSignInButton(
          onPressed: _busy != null ? null : () => _run('google', repo.signInWithGoogle),
        ),
        if (appleAvailable) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: SignInWithAppleButton(
              text: 'Sign in with Apple',
              borderRadius: const BorderRadius.all(Radius.circular(26)),
              style: Theme.of(context).brightness == Brightness.dark
                  ? SignInWithAppleButtonStyle.white
                  : SignInWithAppleButtonStyle.black,
              onPressed: () => _run('apple', repo.signInWithApple),
            ),
          ),
        ],
        const OrDivider(),
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: AuthValidators.email,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 12),
                PasswordField(
                  controller: _password,
                  validator: AuthValidators.signInPassword,
                  onSubmitted: (_) => _signInWithEmail(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/settings/account/forgot-password', extra: _email.text.trim()),
                    child: const Text('Forgot password?'),
                  ),
                ),
                LoadingButton(loading: _busy == 'email', onPressed: _signInWithEmail, label: 'Sign in'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('New to DoseAlert?', style: TextStyle(color: Colors.grey.shade700)),
            TextButton(
              onPressed: () => context.push('/settings/account/register'),
              child: const Text('Create account',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
            ),
          ],
        ),
      ],
    );
  }
}
