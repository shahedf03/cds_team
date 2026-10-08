import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/client.dart';
import '../../models/leave_request.dart';
import '../../models/system_code.dart';
import '../../models/transportation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../widgets/common.dart';

/// What the sheet pops after a successful submit: the new request's id (from
/// the `POST /api/leave` response; `''` if the server sent none) and whether
/// it takes a medical-report attachment.
typedef LeaveSubmitted = ({String transNo, bool isSickLeave});

/// §9 create form: segmented control, From/To date+time, Type dropdown, Notes.
///
/// Dates go out as `dd-MM-yyyy HH:mm` (handled by [LeaveCreateRequest]);
/// the Type dropdown is populated from the §8 system codes.
class LeaveEditorSheet extends StatefulWidget {
  const LeaveEditorSheet({super.key, required this.initialKind});

  final LeaveKind initialKind;

  @override
  State<LeaveEditorSheet> createState() => _LeaveEditorSheetState();
}

class _LeaveEditorSheetState extends State<LeaveEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _notes = TextEditingController();

  late LeaveKind _kind;
  late DateTime _start;
  late DateTime _end;
  SystemCode? _type;
  List<TransportationClient> _selectedClients = <TransportationClient>[];

  /// §F (2026-10-05): مغادرة عمل, `vacLeaveType == "2"` under `LeaveType`.
  bool get _isWorkLeaving =>
      _kind == LeaveKind.leaving && _type?.sysCode == '2';

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;

    final DateTime now = DateTime.now();
    _start = DateTime(now.year, now.month, now.day, 9);
    _end = DateTime(now.year, now.month, now.day, 17);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<LeaveProvider>().loadSystemCodes();
      if (mounted) _syncTypeWithKind();
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  /// The Type list changes with the segmented control, so the current
  /// selection has to be revalidated whenever the kind flips.
  void _syncTypeWithKind() {
    final List<SystemCode> options = context.read<LeaveProvider>().typesFor(
      _kind,
    );
    setState(() {
      if (options.isEmpty) {
        _type = null;
      } else if (_type == null || !options.contains(_type)) {
        _type = options.first;
      }
    });
  }

  void _setKind(LeaveKind kind) {
    setState(() {
      _kind = kind;
      if (kind == LeaveKind.vacation) {
        // Whole days server-side; midnight keeps the required format valid.
        _start = DateTime(_start.year, _start.month, _start.day);
        _end = DateTime(_end.year, _end.month, _end.day);
      }
      if (kind != LeaveKind.leaving) {
        _selectedClients = <TransportationClient>[];
      }
    });
    _syncTypeWithKind();
  }

  void _setType(SystemCode? type) {
    setState(() {
      _type = type;
      if (type?.sysCode != '2') _selectedClients = <TransportationClient>[];
    });
  }

  /// The picker is fed by `GET /api/clients` (§5) — no hardcoded list, same
  /// sheet Transportation's "+ Add Client" uses.
  Future<void> _addClient() async {
    final LeaveProvider provider = context.read<LeaveProvider>();
    await provider.loadClients();

    if (!mounted) return;

    final Set<String> selectedIds = _selectedClients
        .map((TransportationClient c) => c.clientId)
        .toSet();
    final Client? picked = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext context) => Consumer<LeaveProvider>(
        builder: (BuildContext context, LeaveProvider p, Widget? _) =>
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
      _selectedClients = <TransportationClient>[
        ..._selectedClients,
        picked.toTransportationClient(),
      ];
    });
  }

  Future<void> _pickMoment({required bool isStart}) async {
    final DateTime current = isStart ? _start : _end;

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    TimeOfDay? time = TimeOfDay(hour: current.hour, minute: current.minute);

    // A vacation is truncated to whole days by the API, so only a leaving
    // asks for a time.
    if (_kind == LeaveKind.leaving) {
      time = await showTimePicker(context: context, initialTime: time);
      if (time == null || !mounted) return;
    } else {
      time = const TimeOfDay(hour: 0, minute: 0);
    }

    final DateTime value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _start = value;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _submit() async {
    final AppLocalizations t = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_type == null) {
      showApiSnack(context, t.leaveEditorChooseType);
      return;
    }

    if (_end.isBefore(_start)) {
      showApiSnack(context, t.leaveEditorEndBeforeStart);
      return;
    }

    if (_isWorkLeaving && _selectedClients.isEmpty) {
      showApiSnack(context, t.leaveChooseClientRequired);
      return;
    }

    final AuthProvider auth = context.read<AuthProvider>();
    final String? userId = auth.user?.userId;
    if (userId == null) return;

    final LeaveProvider provider = context.read<LeaveProvider>();

    // Heads-up only: teammates off in the same window never block a submit.
    final List<LeaveConflict> conflicts = await provider.conflictsFor(
      userId: userId,
      from: _start,
      to: _end,
    );
    if (!mounted) return;
    if (conflicts.isNotEmpty && !await _confirmDespiteConflicts(conflicts)) {
      return;
    }
    if (!mounted) return;

    final String? transNo = await provider.submit(
      LeaveCreateRequest(
        kind: _kind,
        userId: userId,
        start: _start,
        end: _end,
        vacLeaveType: _type!.sysCode,
        notes: _notes.text.trim(),
        clientIds: _isWorkLeaving
            ? _selectedClients
                  .map((TransportationClient c) => c.clientId)
                  .toList()
            : const <String>[],
      ),
      userId: userId,
    );

    if (!mounted) return;
    if (transNo != null) {
      Navigator.of(context).pop<LeaveSubmitted>((
        transNo: transNo,
        // Same rule as [LeaveRequest.isSickLeave].
        isSickLeave: _type!.name.contains('مرض'),
      ));
    } else {
      // 400 from a bad date format lands here with the API's own message.
      showApiSnack(context, provider.error ?? t.leaveEditorCouldNotSubmit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final LeaveProvider provider = context.watch<LeaveProvider>();
    final List<SystemCode> types = provider.typesFor(_kind);

    // Its own Scaffold so `showApiSnack`'s ScaffoldMessenger anchors here —
    // without one, the snackbar falls back to the screen behind this modal
    // bottom sheet and renders underneath it, invisible.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    t.leaveNewRequest,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: LeaveKind.values.map((LeaveKind kind) {
                      final bool active = kind == _kind;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => _setKind(kind),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.ink
                                    : const Color(0x88FFFFFF),
                                border: Border.all(
                                  color: active
                                      ? AppColors.ink
                                      : AppColors.line,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                kind.label(t),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: active
                                      ? Colors.white
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  _MomentField(
                    label: t.leaveEditorFrom,
                    value: _formatMoment(_start),
                    onTap: () => _pickMoment(isStart: true),
                  ),
                  const SizedBox(height: 12),
                  _MomentField(
                    label: t.leaveEditorTo,
                    value: _formatMoment(_end),
                    onTap: () => _pickMoment(isStart: false),
                  ),
                  const SizedBox(height: 12),
                  _TypeDropdown(
                    types: types,
                    value: _type,
                    onChanged: _setType,
                  ),
                  if (_isWorkLeaving) ...<Widget>[
                    const SizedBox(height: 12),
                    _WorkLeavingClients(
                      clients: _selectedClients,
                      onAdd: _addClient,
                      onRemove: (TransportationClient c) =>
                          setState(() => _selectedClients.remove(c)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 13, color: AppColors.ink),
                    decoration: _decoration(
                      label: t.editorNotes,
                      icon: Icons.notes_rounded,
                      alignTop: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: provider.isSaving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        disabledBackgroundColor: AppColors.green.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: provider.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        provider.isSaving
                            ? t.leaveEditorSubmitting
                            : t.leaveEditorSubmitRequest,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
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

  Future<bool> _confirmDespiteConflicts(List<LeaveConflict> conflicts) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.leaveEditorConflictsTitle,
          style: const TextStyle(fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: conflicts
              .map(
                (LeaveConflict c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    t.leaveEditorConflictLine(
                      c.userName.isEmpty ? c.userId : c.userName,
                      c.fromDateTime,
                      c.toDateTime,
                    ),
                    style: const TextStyle(fontSize: 12, color: AppColors.ink),
                  ),
                ),
              )
              .toList(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              t.commonBack,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            child: Text(t.leaveEditorSubmitAnyway),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  String _formatMoment(DateTime value) => _kind == LeaveKind.leaving
      ? ApiFormats.leaveDateTime.format(value)
      : ApiFormats.displayDate.format(value);
}

class _MomentField extends StatelessWidget {
  const _MomentField({
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
        decoration: _decoration(label: label, icon: Icons.event_outlined),
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

/// §F — "رايح عند أي عميل؟", shown only for a مغادرة عمل. Required before
/// submit; see [_LeaveEditorSheetState._submit].
class _WorkLeavingClients extends StatelessWidget {
  const _WorkLeavingClients({
    required this.clients,
    required this.onAdd,
    required this.onRemove,
  });

  final List<TransportationClient> clients;
  final VoidCallback onAdd;
  final ValueChanged<TransportationClient> onRemove;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      t.leaveWorkLeavingClientsLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    t.editorAddClient,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (clients.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: clients
                  .map(
                    (TransportationClient c) => ClientChip(
                      name: c.clientName,
                      onRemove: () => onRemove(c),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({
    required this.types,
    required this.value,
    required this.onChanged,
  });

  final List<SystemCode> types;
  final SystemCode? value;
  final ValueChanged<SystemCode?> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    if (types.isEmpty) {
      return InputDecorator(
        decoration: _decoration(
          label: t.leaveEditorType,
          icon: Icons.category_outlined,
        ),
        child: Text(
          t.leaveEditorNoTypesAvailable,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      );
    }

    return DropdownButtonFormField<SystemCode>(
      initialValue: types.contains(value) ? value : null,
      isExpanded: true,
      decoration: _decoration(
        label: t.leaveEditorType,
        icon: Icons.category_outlined,
      ),
      style: const TextStyle(fontSize: 13, color: AppColors.ink),
      dropdownColor: AppColors.cream,
      borderRadius: BorderRadius.circular(14),
      items: types
          .map(
            (SystemCode code) => DropdownMenuItem<SystemCode>(
              value: code,
              child: Text(
                code.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.ink),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (SystemCode? v) =>
          v == null ? t.leaveEditorChooseTypeValidator : null,
    );
  }
}

InputDecoration _decoration({
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
