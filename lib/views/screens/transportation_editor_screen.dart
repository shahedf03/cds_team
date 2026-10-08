import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../l10n/gen/app_localizations.dart';
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

  /// Every KM edit (debounced) asks the API for the total, since the
  /// per-km rate can change server-side at any time. The total field stays
  /// editable so the user can override the computed value.
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

    final Set<String> selectedIds = _clients
        .map((TransportationClient c) => c.clientId)
        .toSet();
    final Client? picked = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext context) => Consumer<TransportationProvider>(
        builder: (BuildContext context, TransportationProvider p, Widget? _) =>
            ClientPickerSheet(
              clients: p.clients,
              isLoading: p.isLoadingClients,
              selectedIds: selectedIds,
              onRetry: () => p.loadClients(force: true),
            ),
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
      showApiSnack(context, provider.error ?? AppLocalizations.of(context).editorCouldNotSave);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
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
                  CdsAppBar(title: _isEditing ? t.editorEditEntry : t.editorNewEntry),
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
                              Text(t.editorTransactionLabel, style: _eyebrow),
                              const SizedBox(height: 14),
                              _DateField(
                                label: t.editorDate,
                                value: ApiFormats.displayDate.format(_date),
                                onTap: _pickDate,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _NumberField(
                                      controller: _km,
                                      label: t.editorKm,
                                      icon: Icons.route_outlined,
                                      onChanged: _onKmChanged,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _NumberField(
                                      controller: _total,
                                      label: t.editorTotal,
                                      icon: Icons.payments_outlined,
                                      required: true,
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
                                  Expanded(
                                    child: Text(t.editorClientsLabel, style: _eyebrow),
                                  ),
                                  TextButton.icon(
                                    onPressed: _addClient,
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: Text(
                                      t.editorAddClient,
                                      style: const TextStyle(
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
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    t.editorNoClients,
                                    style: const TextStyle(
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
                                        (TransportationClient c) => ClientChip(
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
                          saving ? t.editorSaving : t.editorSaveEntry,
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
    final AppLocalizations t = AppLocalizations.of(context);
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
        if (v == null || v.trim().isEmpty) return t.editorRequired;
        if (double.tryParse(v.trim()) == null) return t.editorEnterNumber;
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
        label: AppLocalizations.of(context).editorNotes,
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
