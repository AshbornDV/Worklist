import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/site_model.dart';
import '../../core/providers/site_provider.dart';
import '../../core/providers/user_service_provider.dart';

const _areaUnits = [
  'sqft',
  'sqm',
  'sq yard',
  'acre',
  'hectare',
  'sq foot',
  'sq meter'
];

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
  final _workTypeCtrl = TextEditingController();
  final _workAreaCtrl = TextEditingController();
  final _rate = TextEditingController();
  final _cost = TextEditingController();
  final _finalCost = TextEditingController();
  final _advance = TextEditingController();
  final _budget = TextEditingController();
  final _manager = TextEditingController();
  final _notes = TextEditingController();
  String _status = AppConstants.siteStatusActive;
  String _workAreaUnit = 'sqft';
  double? _mapLat;
  double? _mapLng;
  DateTime? _lastPaidDate;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;
  bool _initialLoad = false;
  SiteModel? _original;
  double _workTypeRate = 0;

  bool get _isEditing => widget.siteId != null;

  @override
  void initState() {
    super.initState();
    _cost.addListener(_refreshPaymentPreview);
    _advance.addListener(_refreshPaymentPreview);
    _finalCost.addListener(_refreshPaymentPreview);
    if (_isEditing) _loadSite();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserServiceProvider>().loadServices();
    });
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
      _mapLat = site.latitude;
      _mapLng = site.longitude;
      _workTypeCtrl.text = site.workType ?? '';
      _workAreaCtrl.text = site.workArea ?? '';
      _workAreaUnit = site.workAreaUnit ?? 'sqft';
      _workTypeRate = site.workTypeRate ?? 0;
      _rate.text = site.rate == 0 ? '' : site.rate.toStringAsFixed(0);
      _cost.text = site.estimatedCost.toStringAsFixed(0);
      _finalCost.text = site.finalCost?.toStringAsFixed(0) ?? '';
      _advance.text = site.advanceReceived.toStringAsFixed(0);
      _budget.text = site.budget?.toStringAsFixed(0) ?? '';
      _manager.text = site.manager ?? '';
      _notes.text = site.notes ?? '';
      _lastPaidDate = site.lastPaidDate;
      _startDate = site.startDate;
      _endDate = site.endDate;
      _status = site.status;
    }
    if (mounted) setState(() => _initialLoad = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _workTypeCtrl.dispose();
    _workAreaCtrl.dispose();
    _rate.dispose();
    _cost.removeListener(_refreshPaymentPreview);
    _advance.removeListener(_refreshPaymentPreview);
    _finalCost.removeListener(_refreshPaymentPreview);
    _cost.dispose();
    _advance.dispose();
    _finalCost.dispose();
    _budget.dispose();
    _manager.dispose();
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
        googleMapsUrl: null,
        latitude: _mapLat,
        longitude: _mapLng,
        workType: _workTypeCtrl.text.trim().isEmpty
            ? null
            : _workTypeCtrl.text.trim(),
        workArea: _workAreaCtrl.text.trim().isEmpty
            ? null
            : _workAreaCtrl.text.trim(),
        workAreaUnit: _workAreaUnit,
        workTypeRate: _workTypeRate > 0 ? _workTypeRate : null,
        finalCost: double.tryParse(_finalCost.text),
        rate: double.tryParse(_rate.text) ?? 0,
        status: _status,
        estimatedCost: double.tryParse(_cost.text) ?? 0,
        advanceReceived: double.tryParse(_advance.text) ?? 0,
        lastPaidDate: _effectiveLastPaidDate(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        budget: double.tryParse(_budget.text),
        manager: _manager.text.trim().isEmpty ? null : _manager.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        createdAt: _original!.createdAt,
        updatedAt: now,
      );
      ok = await prov.updateSite(updated);
    } else {
      final site = SiteModel(
        name: _name.text.trim(),
        area: _area.text.trim(),
        googleMapsUrl: null,
        latitude: _mapLat,
        longitude: _mapLng,
        workType: _workTypeCtrl.text.trim().isEmpty
            ? null
            : _workTypeCtrl.text.trim(),
        workArea: _workAreaCtrl.text.trim().isEmpty
            ? null
            : _workAreaCtrl.text.trim(),
        workAreaUnit: _workAreaUnit,
        workTypeRate: _workTypeRate > 0 ? _workTypeRate : null,
        finalCost: double.tryParse(_finalCost.text),
        rate: double.tryParse(_rate.text) ?? 0,
        status: _status,
        estimatedCost: double.tryParse(_cost.text) ?? 0,
        advanceReceived: double.tryParse(_advance.text) ?? 0,
        lastPaidDate: _effectiveLastPaidDate(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        budget: double.tryParse(_budget.text),
        manager: _manager.text.trim().isEmpty ? null : _manager.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _openMapPicker() async {
    // Get current location
    LatLng startPoint;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
        startPoint = LatLng(pos.latitude, pos.longitude);
      } else {
        startPoint = LatLng(_mapLat ?? 12.9716, _mapLng ?? 77.5946);
      }
    } catch (_) {
      startPoint = LatLng(_mapLat ?? 12.9716, _mapLng ?? 77.5946);
    }

    if (!mounted) return;
    final result = await showDialog<LatLng>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MapPickerDialog(initialCenter: startPoint),
    );
    if (result != null) {
      setState(() {
        _mapLat = result.latitude;
        _mapLng = result.longitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoad) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalCost =
        double.tryParse(_finalCost.text) ?? double.tryParse(_cost.text) ?? 0;
    final advance = double.tryParse(_advance.text) ?? 0;

    return Scaffold(
      // Keep the focused field visible above the on-screen keyboard.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Site' : 'Add New Site'),
        leading: BackButton(onPressed: () => context.go('/sites')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  _sectionTitle(context, 'GPS Location'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Pick Location on Map'),
                    ),
                  ),
                  if (_mapLat != null && _mapLng != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          'Location set: ${_mapLat!.toStringAsFixed(4)}, ${_mapLng!.toStringAsFixed(4)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  _sectionTitle(context, 'Work Information'),
                  const SizedBox(height: 12),
                  Consumer<UserServiceProvider>(
                    builder: (context, svcProv, _) {
                      final services = svcProv.services;

                      return DropdownButtonFormField<String>(
                        initialValue: _workTypeCtrl.text.isNotEmpty
                            ? _workTypeCtrl.text
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Type of Work',
                          prefixIcon: Icon(Icons.home_repair_service_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None selected'),
                          ),
                          ...services.map((s) => DropdownMenuItem(
                                value: s.name,
                                child: Text(
                                    '${s.name} (\u20B9${s.rate.toStringAsFixed(0)})'),
                              )),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _workTypeCtrl.text = v ?? '';
                            if (v != null) {
                              final match = services.where((s) => s.name == v);
                              _workTypeRate =
                                  match.isNotEmpty ? match.first.rate : 0;
                            }
                          });
                        },
                      );
                    },
                  ),
                  if (_workTypeCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Work Rate (per site)',
                        prefixIcon: Icon(Icons.price_change_outlined),
                        hintText: '0',
                      ),
                      initialValue: _workTypeRate > 0
                          ? _workTypeRate.toStringAsFixed(0)
                          : '',
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _workTypeRate = double.tryParse(v) ?? 0;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final workAreaField = TextFormField(
                        controller: _workAreaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Work Area',
                          prefixIcon: Icon(Icons.square_foot_outlined),
                          hintText: '0',
                        ),
                        keyboardType: TextInputType.number,
                      );
                      final unitField = DropdownButtonFormField<String>(
                        initialValue: _workAreaUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          prefixIcon: Icon(Icons.straighten_outlined),
                        ),
                        items: _areaUnits
                            .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _workAreaUnit = v);
                        },
                      );
                      if (constraints.maxWidth < 420) {
                        return Column(
                          children: [
                            workAreaField,
                            const SizedBox(height: 12),
                            unitField,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: workAreaField),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: unitField),
                        ],
                      );
                    },
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
                    controller: _manager,
                    decoration: const InputDecoration(
                      labelText: 'Manager',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _budget,
                    decoration: const InputDecoration(
                      labelText: 'Budget (Rs.)',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickStartDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              _startDate == null ? 'Not set' : _fmtDate(_startDate!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _pickEndDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Date',
                              prefixIcon: Icon(Icons.event_outlined),
                            ),
                            child: Text(
                              _endDate == null ? 'Not set' : _fmtDate(_endDate!),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                          controller: _finalCost,
                          decoration: const InputDecoration(
                            labelText: 'Final Cost (Rs.)',
                            prefixIcon: Icon(Icons.price_check_outlined),
                            hintText: 'Same as estimated',
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
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
                            final tot = double.tryParse(_finalCost.text) ??
                                double.tryParse(_cost.text) ??
                                0;
                            if (val > tot && tot > 0) {
                              return 'Cannot exceed total cost';
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
                      Expanded(child: Container()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _RemainingPreview(
                    total: totalCost,
                    received: advance,
                    hasFinalCost: _finalCost.text.trim().isNotEmpty,
                  ),
                  const SizedBox(height: 36),
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

// ────────────── Map Picker Dialog ──────────────

class _MapPickerDialog extends StatefulWidget {
  final LatLng initialCenter;
  const _MapPickerDialog({required this.initialCenter});

  @override
  State<_MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<_MapPickerDialog> {
  late MapController _mapCtrl;
  late LatLng _marker;

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    _marker = widget.initialCenter;
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  void _onTap(TapPosition pos, LatLng point) {
    setState(() => _marker = point);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pick Location'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _marker),
              child: const Text('Confirm'),
            ),
          ],
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: _marker,
                initialZoom: 14.0,
                onTap: _onTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.worklist.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _marker,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: cs.error,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap on the map to place the marker',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.7)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_marker.latitude.toStringAsFixed(4)}, ${_marker.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemainingPreview extends StatelessWidget {
  final double total;
  final double received;
  final bool hasFinalCost;

  const _RemainingPreview({
    required this.total,
    required this.received,
    this.hasFinalCost = false,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = total - received;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasFinalCost)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Final cost set — using final as total',
              style: TextStyle(
                  fontSize: 11, color: cs.primary, fontWeight: FontWeight.w500),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: remaining > 0
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: remaining > 0
                  ? const Color(0xFFF57C00)
                  : const Color(0xFF2E7D32),
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
                      ? 'Remaining: Rs. ${remaining.toStringAsFixed(0)}'
                      : 'Payment complete',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        if (total > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Total: Rs. ${total.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
      ],
    );
  }
}
