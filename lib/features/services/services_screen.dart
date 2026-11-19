import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/models/user_service_model.dart';
import '../../core/providers/user_service_provider.dart';
import '../../shared/widgets/shared_widgets.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserServiceProvider>().loadServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UserServiceProvider>();
    final services = prov.services;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add service',
            onPressed: () => _showAddDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : services.isEmpty
              ? const EmptyState(
                  icon: Icons.miscellaneous_services_outlined,
                  title: 'No services yet',
                  subtitle: 'Add the services you provide to use them on sites.',
                )
              : RefreshIndicator(
                  onRefresh: () => syncThenReload(context, prov.loadServices),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    addAutomaticKeepAlives: false,
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final service = services[i];
                      return _ServiceCard(
                        service: service,
                        onDelete: () => _deleteService(context, prov, service),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Service'),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Service'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Service name *',
                  prefixIcon: Icon(Icons.miscellaneous_services_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter service name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: rateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rate (price) *',
                  prefixIcon: Icon(Icons.currency_rupee),
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a rate';
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) return 'Rate must be greater than 0';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final now = DateTime.now();
              final service = UserService(
                name: nameCtrl.text.trim(),
                rate: double.parse(rateCtrl.text.trim()),
                createdAt: now,
                updatedAt: now,
              );
              final prov = context.read<UserServiceProvider>();
              await prov.addService(service);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(
      BuildContext context, UserServiceProvider prov, UserService service) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Service',
      content: 'Remove "${service.name}" from your services?',
      confirmText: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    await prov.deleteService(service.id!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${service.name} deleted')),
      );
    }
  }
}

class _ServiceCard extends StatelessWidget {
  final UserService service;
  final VoidCallback onDelete;

  const _ServiceCard({required this.service, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.miscellaneous_services_outlined, color: cs.tertiary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u20B9 ${service.rate.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error.withValues(alpha: 0.7)),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
