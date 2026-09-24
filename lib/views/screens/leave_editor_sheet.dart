import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../models/leave_request.dart';
import '../../models/system_code.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../widgets/common.dart';

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
    });
    _syncTypeWithKind();
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
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_type == null) {
      showApiSnack(context, 'Choose a type for this request.');
      return;
    }

    if (_end.isBefore(_start)) {
      showApiSnack(context, 'The end date cannot be before the start date.');
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

    final bool ok = await provider.submit(
      LeaveCreateRequest(
        kind: _kind,
        userId: userId,
        start: _start,
        end: _end,
        vacLeaveType: _type!.sysCode,
        notes: _notes.text.trim(),
      ),
      userId: userId,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      // 400 from a bad date format lands here with the API's own message.
      showApiSnack(context, provider.error ?? 'Could not submit the request.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final LeaveProvider provider = context.watch<LeaveProvider>();
    final List<SystemCode> types = provider.typesFor(_kind);

    return Padding(
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
                const Text(
                  'New request',
                  style: TextStyle(
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
                                color: active ? AppColors.ink : AppColors.line,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${kind.labelEn} · ${kind.labelAr}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: active ? Colors.white : AppColors.muted,
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
                  label: 'From',
                  value: _formatMoment(_start),
                  onTap: () => _pickMoment(isStart: true),
                ),
                const SizedBox(height: 12),
                _MomentField(
                  label: 'To',
                  value: _formatMoment(_end),
                  onTap: () => _pickMoment(isStart: false),
                ),
                const SizedBox(height: 12),
                _TypeDropdown(
                  types: types,
                  value: _type,
                  onChanged: (SystemCode? value) =>
                      setState(() => _type = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                  decoration: _decoration(
                    label: 'Notes',
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
                      provider.isSaving ? 'Submitting…' : 'Submit request',
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
    );
  }

  Future<bool> _confirmDespiteConflicts(List<LeaveConflict> conflicts) async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Teammates off at the same time',
          style: TextStyle(fontSize: 16),
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: conflicts
                .map(
                  (LeaveConflict c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '${c.userName.isEmpty ? c.userId : c.userName} بإجازة '
                      'بنفس الفترة (${c.fromDateTime} → ${c.toDateTime})',
                      style: const TextStyle(fontSize: 12, color: AppColors.ink),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Back', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            child: const Text('Submit anyway'),
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
        decoration: _decoration(
          label: label,
          icon: Icons.event_outlined,
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
    if (types.isEmpty) {
      return InputDecorator(
        decoration: _decoration(label: 'Type', icon: Icons.category_outlined),
        child: const Text(
          'No types available',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      );
    }

    return DropdownButtonFormField<SystemCode>(
      initialValue: types.contains(value) ? value : null,
      isExpanded: true,
      decoration: _decoration(label: 'Type', icon: Icons.category_outlined),
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
      validator: (SystemCode? v) => v == null ? 'Choose a type' : null,
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
