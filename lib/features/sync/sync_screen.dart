import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/firebase/firebase_cloud_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/site_provider.dart';
import '../../core/providers/worker_provider.dart';
import '../../core/sync/sync_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _working = false;
  bool _cloudWorking = false;
  List<String> _localAddresses = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final sync = context.read<SyncService>();
    final saved = await sync.loadServerAddress();
    if (saved != null && mounted) _addressCtrl.text = saved;
    await _refreshAddresses();
  }

  Future<void> _refreshAddresses() async {
    final sync = context.read<SyncService>();
    final addresses = sync.isRunning ? await sync.localAddresses() : <String>[];
    if (mounted) setState(() => _localAddresses = addresses);
  }

  Future<void> _toggleServer() async {
    final sync = context.read<SyncService>();
    try {
      if (sync.isRunning) {
        await sync.stopServer();
      } else {
        await sync.startServer();
      }
      await _refreshAddresses();
    } catch (e) {
      _show('Could not change sharing server: $e', isError: true);
    }
  }

  Future<void> _pull() async {
    await _runSync((sync, auth) async {
      final user = auth.currentUser;
      if (user?.id == null || user?.username == null) return;
      await sync.pullFromServer(
        address: _addressCtrl.text,
        username: user!.username,
        password: _passwordCtrl.text,
        currentUserId: user.id!,
      );
      await _reloadData();
      _show('Data copied from the server to this device.');
    });
  }

  Future<void> _push() async {
    await _runSync((sync, auth) async {
      final user = auth.currentUser;
      if (user?.id == null || user?.username == null) return;
      await sync.pushToServer(
        address: _addressCtrl.text,
        username: user!.username,
        password: _passwordCtrl.text,
        currentUserId: user.id!,
      );
      _show('This device copied its data to the server.');
    });
  }

  Future<void> _downloadFromFirebase() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user?.id == null) return;
    setState(() => _cloudWorking = true);
    try {
      final pulled = await FirebaseCloudService.instance
          .pullIntoLocalUser(user!.id!, force: true);
      await _reloadData();
      _show(pulled
          ? 'Latest Firebase data downloaded.'
          : 'No Firebase data was found yet for this account.');
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _cloudWorking = false);
    }
  }

  Future<void> _uploadToFirebase() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user?.id == null) return;
    setState(() => _cloudWorking = true);
    try {
      await FirebaseCloudService.instance.uploadLocalUser(user!.id!, reason: 'manual-upload-from-sync-screen');
      _show('This device data was uploaded to Firebase.');
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _cloudWorking = false);
    }
  }

  Future<void> _runSync(
    Future<void> Function(SyncService sync, AuthProvider auth) action,
  ) async {
    if (_addressCtrl.text.trim().isEmpty) {
      _show('Enter the server address first.', isError: true);
      return;
    }
    if (_passwordCtrl.text.isEmpty) {
      _show('Enter this account password first.', isError: true);
      return;
    }

    setState(() => _working = true);
    try {
      await action(context.read<SyncService>(), context.read<AuthProvider>());
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _reloadData() async {
    final siteProvider = context.read<SiteProvider>();
    final workerProvider = context.read<WorkerProvider>();
    await siteProvider.loadSites();
    await workerProvider.loadWorkers();
  }

  void _show(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync'),
        actions: [
          IconButton(
            onPressed: _refreshAddresses,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh addresses',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section(
            title: 'Firebase cloud',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Signed in as ${auth.currentUser?.username ?? 'Worklist user'}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _cloudWorking ? null : _downloadFromFirebase,
                        icon: _cloudWorking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.4),
                              )
                            : const Icon(Icons.cloud_download_outlined),
                        label: const Text('Download'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _cloudWorking ? null : _uploadToFirebase,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('Upload now'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Worklist now syncs this account to Firebase after sign-in and after data changes. These buttons are for manual refresh.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.62),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Section(
            title: 'Local Wi-Fi sharing',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      sync.isRunning
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_outlined,
                      color:
                          sync.isRunning ? const Color(0xFF2E7D32) : cs.outline,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sync.isRunning
                            ? 'Worklist server is online'
                            : 'Worklist server is offline',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: sync.isBusy ? null : _toggleServer,
                      icon: Icon(sync.isRunning
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline),
                      label: Text(sync.isRunning ? 'Stop' : 'Start'),
                    ),
                  ],
                ),
                if (_localAddresses.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Use one of these addresses on your other device:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ..._localAddresses.map(
                    (address) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _addressCtrl.text = address),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.router_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Section(
            title: 'Connect to another device',
            child: Column(
              children: [
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Server address',
                    hintText: '192.168.1.20:8787',
                    prefixIcon: Icon(Icons.lan_outlined),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText:
                        '${auth.currentUser?.username ?? 'Account'} password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _working ? null : _pull,
                        icon: _working
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.4),
                              )
                            : const Icon(Icons.download_rounded),
                        label: const Text('Pull data'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _working ? null : _push,
                        icon: const Icon(Icons.upload_rounded),
                        label: const Text('Push data'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Use the same username and password on both devices. Pull replaces this device data with the server data; push replaces the server data with this device data.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.62),
                      ),
                ),
              ],
            ),
          ),
          if (sync.message != null) ...[
            const SizedBox(height: 18),
            Text(sync.message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
