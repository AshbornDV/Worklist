import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      await context.read<AuthProvider>().syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud data saved to Firebase.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _linkEmail() async {
    final controller = TextEditingController(
      text: context.read<AuthProvider>().cloudEmail ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link email'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (email == null || !mounted) return;
    final ok = await context.read<AuthProvider>().linkEmail(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Email linked to this Firebase account.'
            : context.read<AuthProvider>().error ?? 'Could not link email.'),
      ),
    );
  }

  void _googleNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Enable Google sign-in provider in Firebase and add the Android SHA keys to activate Google login.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withOpacity(0.3),
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: cs.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.person_rounded, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.currentUser?.username ?? 'Worklist user',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              auth.cloudEmail ?? 'No public email linked',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _StatusRow(
                    icon: Icons.cloud_done_outlined,
                    label: 'Firebase cloud',
                    value: auth.cloudSignedIn
                        ? 'Connected and auto-saving'
                        : 'Not connected',
                    color: auth.cloudSignedIn
                        ? const Color(0xFF2E7D32)
                        : cs.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your sites, workers, attendance, payments, and account data are saved to Firebase automatically after changes and loaded again when you sign in on another device.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Link email'),
                  subtitle:
                      const Text('Use an email address for this account.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: auth.isLoading ? null : _linkEmail,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.g_mobiledata_rounded),
                  title: const Text('Google login'),
                  subtitle:
                      const Text('Requires Google provider setup in Firebase.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _googleNotice,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: _syncing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.sync_rounded),
                  title: const Text('Save to cloud now'),
                  subtitle: const Text('Automatic sync is already on.'),
                  onTap: _syncing ? null : _syncNow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(value, style: TextStyle(color: color)),
      ],
    );
  }
}
