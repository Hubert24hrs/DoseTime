import 'package:dose_time/core/theme/app_theme.dart';
import 'package:dose_time/features/auth/domain/auth_repository.dart';
import 'package:dose_time/features/auth/presentation/providers/auth_providers.dart';
import 'package:dose_time/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Manage → Account. Sign-in is optional; medication data stays on this
/// device whether or not the user is signed in.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  void _show(String message, {bool error = false}) {
    setState(() {
      _message = message;
      _messageIsError = error;
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on AuthCancelled {
      // Cancelled re-authentication — leave things as they were.
    } on AuthFailure catch (e) {
      _show(e.message, error: true);
    } catch (_) {
      _show(authErrorMessage('unknown'), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendVerification() => _guard(() async {
        await ref.read(authRepositoryProvider).sendEmailVerification();
        _show('Verification email sent. Check your inbox and spam folder.');
      });

  Future<void> _refreshVerification() => _guard(() async {
        final user = await ref.read(authRepositoryProvider).reloadUser();
        if (user?.emailVerified == true) {
          _show('Email verified. Thanks!');
        } else {
          _show('Not verified yet. Open the link in the email we sent, then try again.', error: true);
        }
      });

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your medications and reminders stay on this phone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      _show('Signed out.');
    });
  }

  Future<void> _deleteAccount(AppUser user) async {
    final passwordController = TextEditingController();
    final needsPassword = user.hasPassword && !user.hasApple;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your DoseAlert account. '
              'Medications and reminders saved on this phone are not deleted.',
            ),
            if (needsPassword) ...[
              const SizedBox(height: 16),
              PasswordField(controller: passwordController, label: 'Confirm your password'),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                user.hasApple
                    ? 'You\'ll be asked to confirm with Apple.'
                    : 'You\'ll be asked to confirm with Google.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    final password = passwordController.text;
    passwordController.dispose();
    if (confirmed != true) return;
    if (needsPassword && password.isEmpty) {
      _show('Enter your password to delete your account.', error: true);
      return;
    }
    await _guard(() async {
      await ref.read(authRepositoryProvider).deleteAccount(password: needsPassword ? password : null);
      _show('Your account has been deleted.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _signedOut(context),
        data: (user) => user == null ? _signedOut(context) : _signedIn(context, user),
      ),
    );
  }

  Widget _banner() => _message == null
      ? const SizedBox.shrink()
      : AuthMessage(message: _message!, isError: _messageIsError);

  Widget _signedOut(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _banner(),
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: brandBlue.shade50, shape: BoxShape.circle),
          child: const Icon(Icons.person_outline, size: 36, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 16),
        const Text('You\'re not signed in', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'An account is optional. DoseAlert keeps your medications and reminders on this phone '
          'and works fully offline either way.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => context.push('/settings/account/sign-in'), child: const Text('Sign in')),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: const StadiumBorder()),
          onPressed: () => context.push('/settings/account/register'),
          child: const Text('Create account'),
        ),
      ],
    );
  }

  Widget _signedIn(BuildContext context, AppUser user) {
    final providerLabels = <String>[
      if (user.hasPassword) 'Email & password',
      if (user.hasGoogle) 'Google',
      if (user.hasApple) 'Apple',
    ];
    return AbsorbPointer(
      absorbing: _busy,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _banner(),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: brandBlue.shade50,
                child: Text(
                  (user.displayName?.isNotEmpty == true ? user.displayName! : user.email ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                ),
              ),
              title: Text(
                user.displayName?.isNotEmpty == true ? user.displayName! : 'DoseAlert user',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.email != null) Text(user.email!),
                  if (user.usesApplePrivateRelay)
                    Text('Private relay address from Apple',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final p in providerLabels)
                        Chip(label: Text(p), visualDensity: VisualDensity.compact),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (user.needsEmailVerification) ...[
            const SizedBox(height: 12),
            Card(
              color: AppTheme.warningColor.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.mark_email_unread_outlined, color: AppTheme.warningColor),
                        SizedBox(width: 8),
                        Text('Verify your email', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('We sent a link to ${user.email}. Open it to confirm this address.'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(onPressed: _resendVerification, child: const Text('Resend email')),
                        TextButton(onPressed: _refreshVerification, child: const Text('I\'ve verified')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.phone_android),
                  title: Text('Your data'),
                  subtitle: Text('Medications, schedules and history are stored on this phone. '
                      'Reminders work offline.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: _signOut,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
                  title: Text('Delete account', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () => _deleteAccount(user),
                ),
              ],
            ),
          ),
          if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
