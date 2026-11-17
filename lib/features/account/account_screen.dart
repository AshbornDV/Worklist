import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _pullFromCloud() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from cloud?'),
        content: const Text('This will replace ALL local data with the cloud backup.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) return;

    setState(() => _syncing = true);
    try {
      final pulled = await context.read<AuthProvider>().pullFromCloud();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pulled ? 'Data restored from cloud.' : 'No cloud data found.')),
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

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isGoogleSignInConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.googleSignInStatus)),
      );
      return;
    }

    setState(() => _syncing = true);
    try {
      final ok = await context.read<AuthProvider>().signInWithGoogle();
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in with Google.')),
        );
      } else {
        final error = context.read<AuthProvider>().error;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
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
                    icon: auth.cloudSignedIn
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    label: 'Firebase cloud',
                    value: auth.cloudSignedIn
                        ? 'Connected'
                        : 'Not connected',
                    color: auth.cloudSignedIn
                        ? const Color(0xFF2E7D32)
                        : cs.outline,
                  ),
                  if (auth.lastSyncedAt != null) ...[
                    const SizedBox(height: 6),
                    _StatusRow(
                      icon: Icons.schedule,
                      label: 'Last synced',
                      value: _formatTime(auth.lastSyncedAt!),
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                  if (auth.cloudNotice != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      auth.cloudNotice!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'All your data is saved to this device. Changes are automatically backed up to Firebase when connected.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          if (!auth.cloudSignedIn) ...[
            const SizedBox(height: 12),
            _DebugTokenCard(),
          ],
          if (auth.isGoogleLinked) ...[
            const SizedBox(height: 12),
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
                          child: const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connected with Google',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                auth.googleEmail ?? auth.cloudEmail ??
                                    'Google account',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your Google account is linked. You can sign in with '
                      'Google on any device.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
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
                    title: const Text('Sign in with Google'),
                    subtitle: Text(auth.googleSignInStatus),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: auth.isLoading ||
                            _syncing ||
                            !auth.isGoogleSignInConfigured
                        ? null
                        : _signInWithGoogle,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: _syncing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    title: const Text('Save to cloud now'),
                    subtitle: Text(auth.lastSyncedAt != null
                        ? 'Last synced ${_formatTime(auth.lastSyncedAt!)}'
                        : 'Upload your data to Firebase'),
                    onTap: _syncing ? null : _syncNow,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_download_rounded),
                    title: const Text('Restore from cloud'),
                    subtitle: const Text('Replace local data with cloud backup'),
                    onTap: _syncing ? null : _pullFromCloud,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DebugTokenCard extends StatefulWidget {
  @override
  State<_DebugTokenCard> createState() => _DebugTokenCardState();
}

class _DebugTokenCardState extends State<_DebugTokenCard> {
  final _tokens = <String, String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _tokens['Android'] =
        prefs.getString('worklist_android_app_check_debug_token') ?? '';
    _tokens['Windows'] =
        prefs.getString('worklist_windows_app_check_debug_token') ?? '';
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final entries = _tokens.entries.where((e) => e.value.isNotEmpty).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.developer_mode, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text('Register App Check Debug Tokens',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Go to Firebase Console → App Check → Manage debug tokens and add each token below:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final entry in entries) ...[
              if (entry != entries.first) const SizedBox(height: 10),
              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: entry.value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${entry.key} token copied')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
