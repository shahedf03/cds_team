import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/calendar_event.dart';
import '../../providers/calendar_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/calendar_service.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';

/// 2026-10-08 part E — month calendar: events, task deadlines and leave.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selected = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CalendarProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final CalendarProvider cal = context.watch<CalendarProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.green,
        onPressed: () => _openEditor(context, null),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CdsAppBar(title: t.calendarTitle),
                _MonthHeader(month: cal.month, cal: cal),
                const SizedBox(height: 8),
                if (cal.data.hasTeam)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Text(t.calendarTeamTasks, style: const TextStyle(fontSize: 11, color: AppColors.subtleText)),
                      Switch(
                        value: cal.teamTasks,
                        activeThumbColor: AppColors.green,
                        onChanged: cal.setTeamTasks,
                      ),
                    ],
                  ),
                if (cal.isLoading && cal.data.events.isEmpty && cal.data.tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                  )
                else
                  _MonthGrid(
                    month: cal.month,
                    cal: cal,
                    selected: _selected,
                    onSelect: (DateTime d) => setState(() => _selected = d),
                  ),
                const SizedBox(height: 14),
                Expanded(
                  child: _DayList(
                    day: _selected,
                    cal: cal,
                    onOpenEvent: (CalendarEvent e) => _openEditor(context, e),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, CalendarEvent? event) async {
    final bool? changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => _EventEditorSheet(event: event),
    );
    if (changed == true && context.mounted) await context.read<CalendarProvider>().load();
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.cal});

  final DateTime month;
  final CalendarProvider cal;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toString();
    return Row(
      children: <Widget>[
        SoftIconButton(icon: Icons.chevron_left_rounded, onPressed: cal.previousMonth),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy', locale).format(month),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
        ),
        SoftIconButton(icon: Icons.chevron_right_rounded, onPressed: cal.nextMonth),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.cal, required this.selected, required this.onSelect});

  final DateTime month;
  final CalendarProvider cal;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final DateTime first = DateTime(month.year, month.month, 1);
    final DateTime gridStart = first.subtract(Duration(days: first.weekday % 7));
    final List<DateTime> days = List<DateTime>.generate(42, (int i) => gridStart.add(Duration(days: i)));
    final DateTime today = DateTime.now();

    return Column(
      children: <Widget>[
        Row(
          children: <String>['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((String d) => Expanded(
                    child: Center(
                      child: Text(d, style: const TextStyle(fontSize: 9, color: AppColors.faintText)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.9,
          children: days.map((DateTime day) {
            final bool inMonth = day.month == month.month;
            final bool isToday = _sameDay(day, today);
            final bool isSelected = _sameDay(day, selected);
            final bool hasEvent = cal.eventsOn(day).isNotEmpty;
            final bool hasTask = cal.tasksOn(day).isNotEmpty;
            final bool hasLeave = cal.leavesOn(day).isNotEmpty;
            return InkWell(
              onTap: () => onSelect(day),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.green : Colors.transparent,
                  border: isToday && !isSelected ? Border.all(color: AppColors.green) : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : inMonth
                                ? AppColors.ink
                                : AppColors.faintText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (hasEvent) _Dot(color: isSelected ? Colors.white : AppColors.blue),
                        if (hasTask) _Dot(color: isSelected ? Colors.white : AppColors.purple),
                        if (hasLeave) _Dot(color: isSelected ? Colors.white : AppColors.amber),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 4,
    height: 4,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _DayList extends StatelessWidget {
  const _DayList({required this.day, required this.cal, required this.onOpenEvent});

  final DateTime day;
  final CalendarProvider cal;
  final ValueChanged<CalendarEvent> onOpenEvent;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final List<CalendarEvent> events = cal.eventsOn(day);
    final List<CalendarTaskDeadline> tasks = cal.tasksOn(day);
    final List<CalendarLeave> leaves = cal.leavesOn(day);

    if (events.isEmpty && tasks.isEmpty && leaves.isEmpty) {
      return StateMessage(icon: Icons.event_available_outlined, title: t.calendarNothingThisDay);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: <Widget>[
        for (final CalendarEvent e in events)
          GlassCard(
            radius: 14,
            onTap: () => onOpenEvent(e),
            padding: const EdgeInsets.all(12),
            child: _Row(
              icon: Icons.event_rounded,
              tone: ToneColor.blue,
              title: e.title,
              subtitle: e.allDay
                  ? t.calendarAllDay
                  : e.startAt == null
                      ? ''
                      : DateFormat('HH:mm').format(e.startAt!),
            ),
          ),
        for (final CalendarTaskDeadline tk in tasks)
          GlassCard(
            radius: 14,
            padding: const EdgeInsets.all(12),
            child: _Row(
              icon: Icons.task_alt_rounded,
              tone: tk.isOverdue ? ToneColor.red : ToneColor.purple,
              title: tk.title,
              subtitle: tk.statusName,
              strike: tk.isClosed,
            ),
          ),
        for (final CalendarLeave lv in leaves)
          GlassCard(
            radius: 14,
            onTap: () => AppRoutes.openLeaveDetail(lv.transNo),
            padding: const EdgeInsets.all(12),
            child: _Row(
              icon: lv.isWorkLeaving ? Icons.directions_car_filled_outlined : Icons.beach_access_outlined,
              tone: lv.isWorkLeaving ? ToneColor.blue : ToneColor.amber,
              title: '${lv.userName} · ${lv.typeName}',
              subtitle: lv.isPending ? t.calendarPending : lv.status,
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.tone, required this.title, required this.subtitle, this.strike = false});

  final IconData icon;
  final ToneColor tone;
  final String title;
  final String subtitle;
  final bool strike;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconWell(icon: icon, tone: tone, size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  decoration: strike ? TextDecoration.lineThrough : null,
                  color: AppColors.ink,
                ),
              ),
              Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.subtleText)),
            ],
          ),
        ),
      ],
    );
  }
}

/// New/edit event form. Delete (creator only) sits next to Save when
/// editing.
class _EventEditorSheet extends StatefulWidget {
  const _EventEditorSheet({this.event});

  final CalendarEvent? event;

  @override
  State<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<_EventEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  late bool _allDay;
  late DateTime _start;
  late DateTime _end;
  Set<String> _attendeeIds = <String>{};
  List<CalendarPerson> _people = const <CalendarPerson>[];
  bool _busy = false;

  bool get _canEdit => widget.event == null || widget.event!.canEdit;

  @override
  void initState() {
    super.initState();
    final CalendarEvent? e = widget.event;
    _title = TextEditingController(text: e?.title ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _notes = TextEditingController(text: e?.description ?? '');
    _allDay = e?.allDay ?? false;
    _start = e?.startAt ?? DateTime.now();
    _end = e?.endAt ?? _start.add(const Duration(hours: 1));
    _attendeeIds = e == null ? <String>{} : e.attendees.map((EventAttendee a) => a.userId).toSet();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    final CalendarService service = context.read<CalendarService>();
    final List<CalendarPerson> p = await service.people();
    if (mounted) setState(() => _people = p);
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final DateTime initial = isStart ? _start : _end;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    DateTime result = DateTime(date.year, date.month, date.day, initial.hour, initial.minute);
    if (!_allDay) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      );
      if (time == null) return;
      result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }
    setState(() {
      if (isStart) {
        _start = result;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = result;
      }
    });
  }

  Future<void> _save() async {
    final AppLocalizations t = AppLocalizations.of(context);
    if (_title.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final CalendarService service = context.read<CalendarService>();
      if (widget.event == null) {
        await service.createEvent(
          title: _title.text.trim(),
          description: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          location: _location.text.trim().isEmpty ? null : _location.text.trim(),
          allDay: _allDay,
          start: _start,
          end: _end,
          attendees: _attendeeIds.toList(),
        );
      } else {
        await service.updateEvent(
          id: widget.event!.id,
          title: _title.text.trim(),
          description: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          location: _location.text.trim().isEmpty ? null : _location.text.trim(),
          allDay: _allDay,
          start: _start,
          end: _end,
          attendees: _attendeeIds.toList(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiSnack(context, t.calendarCouldNotSave);
      }
    }
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await context.read<CalendarService>().deleteEvent(widget.event!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiSnack(context, AppLocalizations.of(context).calendarCouldNotSave);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 14, 22, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.event == null ? t.calendarNewEvent : t.calendarEventTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              enabled: _canEdit,
              decoration: InputDecoration(labelText: t.calendarEventName),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text(t.calendarAllDay, style: const TextStyle(fontSize: 12)),
                Switch(
                  value: _allDay,
                  activeThumbColor: AppColors.green,
                  onChanged: _canEdit ? (bool v) => setState(() => _allDay = v) : null,
                ),
              ],
            ),
            _DateTimeTile(label: t.calendarStart, value: _start, allDay: _allDay, enabled: _canEdit, onTap: () => _pickDateTime(true)),
            const SizedBox(height: 8),
            _DateTimeTile(label: t.calendarEnd, value: _end, allDay: _allDay, enabled: _canEdit, onTap: () => _pickDateTime(false)),
            const SizedBox(height: 10),
            TextField(
              controller: _location,
              enabled: _canEdit,
              decoration: InputDecoration(labelText: t.calendarPlace),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notes,
              enabled: _canEdit,
              maxLines: 3,
              decoration: InputDecoration(labelText: t.calendarNotes),
            ),
            const SizedBox(height: 10),
            Text(t.calendarPeople.toUpperCase(), style: const TextStyle(fontSize: 9, letterSpacing: 1, color: AppColors.faintText)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _people
                  .map(
                    (CalendarPerson p) => FilterChip(
                      label: Text(p.name, style: const TextStyle(fontSize: 10)),
                      selected: _attendeeIds.contains(p.userId),
                      onSelected: _canEdit
                          ? (bool sel) => setState(() {
                              if (sel) {
                                _attendeeIds.add(p.userId);
                              } else {
                                _attendeeIds.remove(p.userId);
                              }
                            })
                          : null,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (_canEdit)
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: _busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(t.commonSend),
                    ),
                  ),
                  if (widget.event != null) ...<Widget>[
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _busy ? null : _delete,
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18)),
                      child: Text(t.tasksDelete),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.label, required this.value, required this.allDay, required this.enabled, required this.onTap});

  final String label;
  final DateTime value;
  final bool allDay;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String text = allDay ? DateFormat('d MMM yyyy').format(value) : DateFormat('d MMM yyyy · HH:mm').format(value);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
        child: Row(
          children: <Widget>[
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.subtleText)),
            const Spacer(),
            Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
