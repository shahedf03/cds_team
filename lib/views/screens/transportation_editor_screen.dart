import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../models/client.dart';
import '../../models/transportation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transportation_provider.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';

/// §4 — Date, KM, Total, Notes, "+ Add Client" and the client chips list.
///
/// New record → POST; editing an existing one → PUT `/api/transportation/{trId}`.
class TransportationEditorScreen extends StatefulWidget {
  const TransportationEditorScreen({super.key, this.entry});

  final Transportation? entry;

  @override
  State<TransportationEditorScreen> createState() =>
      _TransportationEditorScreenState();
}

class _TransportationEditorScreenState
    extends State<TransportationEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _km;
  late final TextEditingController _total;
  late final TextEditingController _notes;

  late DateTime _date;
  late List<TransportationClient> _clients;

  Timer? _kmDebounce;

  bool get _isEditing => widget.entry != null && !widget.entry!.isNew;

  @override
  void initState() {
    super.initState();
    final Transportation? entry = widget.entry;

    _km = TextEditingController(text: entry?.km ?? '');
    _total = TextEditingController(text: entry?.totalAmount ?? '');
    _notes = TextEditingController(text: entry?.notes ?? '');
    _date = entry?.trDate ?? DateTime.now();
    _clients = List<TransportationClient>.from(
      entry?.clients ?? const <TransportationClient>[],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransportationProvider>().loadClients();
    });
  }

  @override
  void dispose() {
    _kmDebounce?.cancel();
    _km.dispose();
    _total.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Total is read-only: every KM edit (debounced) asks the API for it, since
  /// the per-km rate can change server-side at any time.
  void _onKmChanged(String value) {
    _kmDebounce?.cancel();
    final String km = value.trim();
    if (km.isEmpty || double.tryParse(km) == null) {
      _total.clear();
      return;
    }
    _kmDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final String total = await context
            .read<TransportationProvider>()
            .calculateTotal(km);
        // Drop stale answers if the user kept typing meanwhile.
        if (mounted && _km.text.trim() == km) _total.text = total;
      } catch (_) {
        if (mounted && _km.text.trim() == km) _total.clear();
      }
    });
  }

  /// The picker is fed by `GET /api/clients` (§5) — no hardcoded list.
  Future<void> _addClient() async {
    final TransportationProvider provider = context
        .read<TransportationProvider>();
    await provider.loadClients();

    if (!mounted) return;

    final Client? picked = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext context) => _ClientPickerSheet(
        selectedIds: _clients
            .map((TransportationClient c) => c.clientId)
            .toSet(),
      ),
    );

    if (picked == null) return;
    setState(() {
      _clients = <TransportationClient>[
        ..._clients,
        picked.toTransportationClient(),
      ];
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final AuthProvider auth = context.read<AuthProvider>();
    final String? userId = auth.user?.userId;
    if (userId == null) return;

    final Transportation payload = Transportation(
      trId: widget.entry?.trId ?? 0,
      trDate: _date,
      userId: userId,
      km: _km.text.trim(),
      notes: _notes.text.trim(),
      totalAmount: _total.text.trim(),
      // Always the full list — the API replaces rather than diffs.
      clients: _clients,
    );

    final TransportationProvider provider = context
        .read<TransportationProvider>();
    final bool ok = await provider.save(payload, userId: userId);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      showApiSnack(context, provider.error ?? 'Could not save the entry.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool saving = context.select<TransportationProvider, bool>(
      (TransportationProvider p) => p.isSaving,
    );

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  CdsAppBar(title: _isEditing ? 'Edit entry' : 'New entry'),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 30),
                      children: <Widget>[
                        GlassCard(
                          radius: 22,
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const Text('TRANSACTION', style: _eyebrow),
                              const SizedBox(height: 14),
                              _DateField(
                                label: 'Date',
                                value: ApiFormats.displayDate.format(_date),
                                onTap: _pickDate,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _NumberField(
                                      controller: _km,
                                      label: 'KM',
                                      icon: Icons.route_outlined,
                                      onChanged: _onKmChanged,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _NumberField(
                                      controller: _total,
                                      label: 'Total',
                                      icon: Icons.payments_outlined,
                                      required: true,
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _NotesField(controller: _notes),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassCard(
                          radius: 22,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Expanded(
                                    child: Text('CLIENTS', style: _eyebrow),
                                  ),
                                  TextButton.icon(
                                    onPressed: _addClient,
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: const Text(
                                      'Add Client',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.green,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_clients.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    'No clients attached to this trip yet.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 7,
                                  runSpacing: 7,
                                  children: _clients
                                      .map(
                                        (TransportationClient c) => _ClientChip(
                                          name: c.clientName,
                                          onRemove: () => setState(
                                            () => _clients.remove(c),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          disabledBackgroundColor: AppColors.green.withValues(
                            alpha: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          saving ? 'Saving…' : 'Save entry',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const TextStyle _eyebrow = TextStyle(
    fontSize: 10,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w800,
    color: AppColors.subtleText,
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _fieldDecoration(
          label: label,
          icon: Icons.calendar_month_outlined,
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
    this.required = false,
    this.readOnly = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: const TextStyle(fontSize: 13, color: AppColors.ink),
      decoration: _fieldDecoration(label: label, icon: icon),
      validator: (String? v) {
        if (!required) return null;
        if (v == null || v.trim().isEmpty) return 'Required';
        if (double.tryParse(v.trim()) == null) return 'Enter a number';
        return null;
      },
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 13, color: AppColors.ink),
      decoration: _fieldDecoration(
        label: 'Notes',
        icon: Icons.notes_rounded,
        alignTop: true,
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  bool alignTop = false,
}) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
  prefixIcon: Icon(icon, size: 18, color: AppColors.muted),
  alignLabelWithHint: alignTop,
  filled: true,
  fillColor: const Color(0x66FFFFFF),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.line),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.line),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.green, width: 1.4),
  ),
  errorStyle: const TextStyle(fontSize: 10, color: AppColors.red),
);

class _ClientChip extends StatelessWidget {
  const _ClientChip({required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 7, 5, 7),
      decoration: BoxDecoration(
        color: AppColors.blueTint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.close_rounded, size: 13, color: AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

/// Searchable list backed by `GET /api/clients`.
class _ClientPickerSheet extends StatefulWidget {
  const _ClientPickerSheet({required this.selectedIds});

  final Set<String> selectedIds;

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final TransportationProvider provider = context
        .watch<TransportationProvider>();

    final List<Client> available = provider.clients
        .where((Client c) => !widget.selectedIds.contains(c.id))
        .where(
          (Client c) =>
              _query.isEmpty ||
              c.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Add client',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (String v) => setState(() => _query = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: _fieldDecoration(
                      label: 'Search clients',
                      icon: Icons.search_rounded,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoadingClients && provider.clients.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    )
                  : available.isEmpty
                  ? StateMessage(
                      icon: Icons.business_outlined,
                      tone: ToneColor.blue,
                      title: provider.clients.isEmpty
                          ? 'No clients available'
                          : 'No matches',
                      message: provider.clients.isEmpty
                          ? 'The client list could not be loaded.'
                          : 'Try a different search term.',
                      actionLabel: provider.clients.isEmpty ? 'Retry' : null,
                      onAction: () => context
                          .read<TransportationProvider>()
                          .loadClients(force: true),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: available.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (BuildContext context, int index) {
                        final Client client = available[index];
                        return GlassCard(
                          radius: 14,
                          color: AppColors.cardSoft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          onTap: () => Navigator.of(context).pop(client),
                          child: Row(
                            children: <Widget>[
                              const IconWell(
                                icon: Icons.business_outlined,
                                tone: ToneColor.blue,
                                size: 30,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  client.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 18,
                                color: AppColors.green,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
