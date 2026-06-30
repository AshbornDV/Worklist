import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _creatingAccount = false;
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>()..clearError();
    final ok = _creatingAccount
        ? await auth.register(_userCtrl.text.trim(), _passCtrl.text)
        : await auth.login(_userCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;
    final wide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF061A32), Color(0xFF0B3B63)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: wide ? 430 : double.infinity),
                child: Card(
                  elevation: 12,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 132,
                              height: 132,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            AppConstants.appName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.login_rounded),
                                label: Text('Sign in'),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: Icon(Icons.person_add_alt_1_rounded),
                                label: Text('New account'),
                              ),
                            ],
                            selected: {_creatingAccount},
                            onSelectionChanged: auth.isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _creatingAccount = value.first;
                                      _confirmCtrl.clear();
                                    });
                                    auth.clearError();
                                  },
                          ),
                          const SizedBox(height: 24),
                          if (auth.error != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: cs.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: TextStyle(color: cs.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (auth.cloudNotice != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.cloud_off_outlined,
                                      color: cs.secondary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.cloudNotice!,
                                      style: TextStyle(
                                        color: cs.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _userCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Username or email',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Enter your username or email';
                              }
                              if (text.contains('@')) {
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(text)) {
                                  return 'Enter a valid email address';
                                }
                              } else {
                                if (_creatingAccount && text.length < 3) {
                                  return 'Use at least 3 characters';
                                }
                                if (!RegExp(r'^[a-zA-Z0-9._-]+$')
                                    .hasMatch(text)) {
                                  return 'Use letters, numbers, dot, dash, or underscore';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            textInputAction: _creatingAccount
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onFieldSubmitted:
                                _creatingAccount ? null : (_) => _submit(),
                            validator: (value) {
                              final text = value ?? '';
                              if (text.isEmpty) return 'Enter your password';
                              if (_creatingAccount && text.length < 6) {
                                return 'Use at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          if (_creatingAccount) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: _obscure,
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: Icon(Icons.verified_user_outlined),
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (value) => value != _passCtrl.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 28),
                          FilledButton.icon(
                            onPressed: auth.isLoading ? null : _submit,
                            icon: auth.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Icon(_creatingAccount
                                    ? Icons.person_add_alt_1_rounded
                                    : Icons.login_rounded),
                            label: Text(
                              auth.isLoading
                                  ? 'Please wait...'
                                  : (_creatingAccount
                                      ? 'Create account'
                                      : 'Sign in'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: auth.isLoading
                                ? null
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Google sign-in is ready in the app UI. Enable the Google provider in Firebase, then connect the Google sign-in keys to activate it.',
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.g_mobiledata_rounded),
                            label: const Text('Continue with Google'),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _creatingAccount
                                ? 'Your new account starts with an empty private workspace.'
                                : 'Only registered Worklist accounts can open saved data.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurface.withOpacity(0.62),
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
