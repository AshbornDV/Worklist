import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/site_model.dart';
import '../../core/providers/site_provider.dart';

class SiteFormScreen extends StatefulWidget {
  final int? siteId;
  const SiteFormScreen({this.siteId, super.key});

  @override
  State<SiteFormScreen> createState() => _SiteFormScreenState();
}

class _SiteFormScreenState extends State<SiteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _googleMapsUrl = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _workType = TextEditingController();
  final _workArea = TextEditingController();
  final _rate = TextEditingController();
  final _cost = TextEditingController();
  final _advance = TextEditingController();
  final _notes = TextEditingController();
  String _status = AppConstants.siteStatusActive;
  DateTime? _lastPaidDate;
  bool _loading = false;
  bool _initialLoad = false;
  SiteModel? _original;

  bool get _isEditing => widget.siteId != null;

  @override
  void initState() {
    super.initState();
    _cost.addListener(_refreshPaymentPreview);
    _advance.addListener(_refreshPaymentPreview);
    if (_isEditing) _loadSite();
  }

  void _refreshPaymentPreview() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSite() async {
    setState(() => _initialLoad = true);
    final site = await context.read<SiteProvider>().getSite(widget.siteId!);
    if (site != null && mounted) {
      _original = site;
      _name.text = site.name;
      _area.text = site.area;
      _googleMapsUrl.text = site.googleMapsUrl ?? '';
      _latitude.text = site.latitude?.toString() ?? '';
      _longitude.text = site.longitude?.toString() ?? '';
      _workType.text = site.workType ?? '';
      _workArea.text = site.workArea ?? '';
      _rate.text = site.rate == 0 ? '' : site.rate.toStringAsFixed(0);
      _cost.text = site.estimatedCost.toStringAsFixed(0);
      _advance.text = site.advanceReceived.toStringAsFixed(0);
      _notes.text = site.notes ?? '';
      _lastPaidDate = site.lastPaidDate;
      _status = site.status;
    }
    if (mounted) setState(() => _initialLoad = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _googleMapsUrl.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _workType.dispose();
    _workArea.dispose();
    _rate.dispose();
    _cost.removeListener(_refreshPaymentPreview);
    _advance.removeListener(_refreshPaymentPreview);
    _cost.dispose();
    _advance.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final prov = context.read<SiteProvider>();
    final now = DateTime.now();
    bool ok;

    if (_isEditing && _original != null) {
      final updated = SiteModel(
        id: _original!.id,
        name: _name.text.trim(),
        area: _area.text.trim(),
        googleMapsUrl: _nullableText(_googleMapsUrl),
        latitude: double.tryParse(_latitude.text),
        longitude: double.tryParse(_longitude.text),
        workType: _nullableText(_workType),
        workArea: _nullableText(_workArea),
        rate: double.tryParse(_rate.text) ?? 0,
        status: _status,
        estimatedCost: double.tryParse(_cost.text) ?? 0,
        advanceReceived: double.tryParse(_advance.text) ?? 0,
        lastPaidDate: _effectiveLastPaidDate(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        createdAt: _original!.createdAt,
        updatedAt: now,
      );
      ok = await prov.updateSite(updated);
    } else {
      final site = SiteModel(
        name: _name.text.trim(),
        area: _area.text.trim(),
        googleMapsUrl: _nullableText(_googleMapsUrl),
        latitude: double.tryParse(_latitude.text),
        longitude: double.tryParse(_longitude.text),
        workType: _nullableText(_workType),
        workArea: _nullableText(_workArea),
        rate: double.tryParse(_rate.text) ?? 0,
        status: _status,
        estimatedCost: double.tryParse(_cost.text) ?? 0,
        advanceReceived: double.tryParse(_advance.text) ?? 0,
        lastPaidDate: _effectiveLastPaidDate(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      ok = await prov.addSite(site);
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Site updated!' : 'Site added!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      context.go('/sites');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? 'Failed to save site'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  DateTime? _effectiveLastPaidDate() {
    final received = double.tryParse(_advance.text) ?? 0;
    if (received <= 0) return null;
    if (_lastPaidDate != null) return _lastPaidDate;
    final originalReceived = _original?.advanceReceived ?? 0;
    return received > originalReceived ? DateTime.now() : null;
  }

  Future<void> _pickLastPaidDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPaidDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) setState(() => _lastPaidDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoad) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Site' : 'Add New Site'),
        leading: BackButton(onPressed: () => context.go('/sites')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Basic Info ──
                  _sectionTitle(context, 'Basic Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Site Name *',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Site name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _area,
                    decoration: const InputDecoration(
                      labelText: 'Site Location / Address *',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Location is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _googleMapsUrl,
                    decoration: const InputDecoration(
                      labelText: 'Google Maps Location Link',
                      hintText: 'Paste exact Google Maps link',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      final uri = Uri.tryParse(value);
                      if (uri == null || !uri.hasScheme) {
                        return 'Paste a valid map link';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitude,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            prefixIcon: Icon(Icons.my_location_outlined),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final val = double.tryParse(v);
                            if (val == null || val < -90 || val > 90) {
                              return 'Invalid latitude';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _longitude,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            prefixIcon: Icon(Icons.explore_outlined),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final val = double.tryParse(v);
                            if (val == null || val < -180 || val > 180) {
                              return 'Invalid longitude';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _workType,
                    decoration: const InputDecoration(
                      labelText: 'Type of Work',
                      prefixIcon: Icon(Icons.home_repair_service_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _workArea,
                    decoration: const InputDecoration(
                      labelText: 'Area of Work',
                      prefixIcon: Icon(Icons.square_foot_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: AppConstants.siteStatuses
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.replaceAll('_', ' ')),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Description',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 28),

                  // ── Financials ──
                  _sectionTitle(context, 'Financial Details'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cost,
                          decoration: const InputDecoration(
                            labelText: 'Estimated Cost (Rs.)',
                            prefixIcon: Icon(Icons.request_quote_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            if (double.tryParse(v) == null) {
                              return 'Invalid amount';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _advance,
                          decoration: const InputDecoration(
                            labelText: 'Advance Received (Rs.)',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final val = double.tryParse(v);
                            if (val == null) return 'Invalid amount';
                            final cost = double.tryParse(_cost.text) ?? 0;
                            if (val > cost && cost > 0) {
                              return 'Cannot exceed estimated cost';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rate,
                          decoration: const InputDecoration(
                            labelText: 'Rate',
                            prefixIcon: Icon(Icons.price_change_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            if (double.tryParse(v) == null) {
                              return 'Invalid rate';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _pickLastPaidDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Last Paid Date',
                              prefixIcon: Icon(Icons.event_available_outlined),
                            ),
                            child: Text(
                              _lastPaidDate == null
                                  ? 'Not set'
                                  : _fmtDate(_lastPaidDate!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _RemainingPreview(
                    total: double.tryParse(_cost.text) ?? 0,
                    received: double.tryParse(_advance.text) ?? 0,
                  ),
                  const SizedBox(height: 36),

                  // ── Submit ──
                  FilledButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Icon(Icons.save_rounded),
                    label: Text(_loading
                        ? 'Saving...'
                        : (_isEditing ? 'Update Site' : 'Add Site')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _RemainingPreview extends StatelessWidget {
  final double total;
  final double received;

  const _RemainingPreview({required this.total, required this.received});

  @override
  Widget build(BuildContext context) {
    final remaining = total - received;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            remaining > 0 ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              remaining > 0 ? const Color(0xFFF57C00) : const Color(0xFF2E7D32),
        ),
      ),
      child: Row(
        children: [
          Icon(
            remaining > 0
                ? Icons.notifications_active_outlined
                : Icons.check_circle_outline,
            color: remaining > 0
                ? const Color(0xFFF57C00)
                : const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              remaining > 0
                  ? 'Remaining amount: Rs. ${remaining.toStringAsFixed(0)}'
                  : 'Payment complete',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
