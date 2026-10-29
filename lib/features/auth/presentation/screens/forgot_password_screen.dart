import 'package:dose_time/features/auth/domain/auth_repository.dart';
import 'package:dose_time/features/auth/presentation/providers/auth_providers.dart';
import 'package:dose_time/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      icon: Icons.lock_reset,
      title: 'Reset your password',
      subtitle: 'Enter your account email and we\'ll send you a link to choose a new password.',
      children: [
        if (_sent)
          const AuthMessage(
            isError: false,
            message: 'If an account exists for that email, a reset link is on its way. '
                'Check your inbox and spam folder.',
          ),
        if (_error != null) AuthMessage(message: _error!),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            validator: AuthValidators.email,
            onFieldSubmitted: (_) => _send(),
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
          ),
        ),
        const SizedBox(height: 24),
        LoadingButton(loading: _loading, onPressed: _send, label: _sent ? 'Send again' : 'Send reset link'),
      ],
    );
  }
}
