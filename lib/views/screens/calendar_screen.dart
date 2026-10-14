import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/calendar_event.dart';
import '../../providers/calendar_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/calendar_service.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/cds_dialogs.dart';
import '../widgets/common.dart';

/// Month calendar: events, task deadlines and leave. [embedded] = bottom-nav
/// tab (no back button; the shell supplies scaffold and brand bar).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selected = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CalendarProvider>().load());
  }

  void _select(DateTime day) {
    setState(() => _selected = day);
    final CalendarProvider cal = context.read<CalendarProvider>();
    if (day.month != cal.month.month || day.year != cal.month.year) cal.goToMonth(day);
  }

  void _goToday() => _select(_dateOnly(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final CalendarProvider cal = context.watch<CalendarProvider>();
    final String locale = Localizations.localeOf(context).toString();
    final DateTime today = _dateOnly(DateTime.now());
    final bool showToday = _selected != today ||
        cal.month.month != today.month ||
        cal.month.year != today.year;

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!widget.embedded) CdsAppBar(title: t.calendarTitle),
        _Toolbar(
          month: cal.month,
          showToday: showToday,
          onPrev: cal.previousMonth,
          onNext: cal.nextMonth,
          onToday: _goToday,
          onAdd: () => _openEditor(context, null),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.green,
            backgroundColor: Colors.white,
            onRefresh: cal.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 110),
              children: <Widget>[
                GlassCard(
                  radius: 22,
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
                  child: Stack(
                    children: <Widget>[
                      _MonthGrid(
                        month: cal.month,
                        cal: cal,
                        selected: _selected,
                        onSelect: _select,
                        onSwipeNext: cal.nextMonth,
                        onSwipePrev: cal.previousMonth,
                      ),
                      if (cal.isLoading)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: AppColors.green,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                    ],
                  ),
                ),
                if (cal.data.hasTeam)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text(t.calendarTeamTasks,
                            style: const TextStyle(fontSize: 11, color: AppColors.subtleText)),
                        Switch.adaptive(
                          value: cal.teamTasks,
                          activeTrackColor: AppColors.green,
                          onChanged: cal.setTeamTasks,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                ListLabel(
                  label: (_selected == today ? '${t.calendarToday} · ' : '') +
                      DateFormat('EEEE, d MMMM', locale).format(_selected),
                ),
                _DayList(
                  day: _selected,
                  cal: cal,
                  onOpenEvent: (CalendarEvent e) => _openEditor(context, e),
                  onAdd: () => _openEditor(context, null),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: body);
    }

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: body,
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, CalendarEvent? event) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool? changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _EventEditorSheet(event: event, initialDay: _selected),
    );
    if (changed == true && context.mounted) {
      showApiSnack(context, t.calendarEventSaved, isError: false);
      await context.read<CalendarProvider>().load();
    }
  }
}

/// `October 2026        [Today] ‹ › [+]`
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.month,
    required this.showToday,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onAdd,
  });

  final DateTime month;
  final bool showToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                DateFormat('yyyy', locale).format(month),
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.subtleText,
                ),
              ),
              Text(
                DateFormat('MMMM', locale).format(month),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  letterSpacing: -0.6,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        if (showToday) ...<Widget>[
          TextButton(
            onPressed: onToday,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green,
              backgroundColor: AppColors.greenTint,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(t.calendarToday, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 6),
        ],
        SoftIconButton(icon: Icons.chevron_left_rounded, onPressed: onPrev),
        const SizedBox(width: 6),
        SoftIconButton(icon: Icons.chevron_right_rounded, onPressed: onNext),
        const SizedBox(width: 8),
        Tooltip(
          message: t.calendarNewEvent,
          child: Material(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.cal,
    required this.selected,
    required this.onSelect,
    required this.onSwipeNext,
    required this.onSwipePrev,
  });

  final DateTime month;
  final CalendarProvider cal;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onSwipeNext;
  final VoidCallback onSwipePrev;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toString();
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final DateTime start = CalendarProvider.gridStartFor(month);
    final int weeks = CalendarProvider.weeksFor(month);
    final DateTime now = DateTime.now();
    // 2024-01-01 is a Monday — used only to get localized narrow weekday names.
    final List<String> weekdays = List<String>.generate(
      7,
      (int i) => DateFormat('EEEEE', locale).format(DateTime(2024, 1, 1 + i)),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (DragEndDetails d) {
        final double v = d.primaryVelocity ?? 0;
        if (v.abs() < 250) return;
        final bool forward = rtl ? v > 0 : v < 0;
        forward ? onSwipeNext() : onSwipePrev();
      },
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      weekdays[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: i >= 5 ? AppColors.amber : AppColors.faintText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (int w = 0; w < weeks; w++)
            Row(
              children: <Widget>[
                for (int d = 0; d < 7; d++)
                  Expanded(
                    child: _DayCell(
                      day: DateTime(start.year, start.month, start.day + w * 7 + d),
                      month: month,
                      now: now,
                      selected: selected,
                      cal: cal,
                      onTap: onSelect,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.month,
    required this.now,
    required this.selected,
    required this.cal,
    required this.onTap,
  });

  final DateTime day;
  final DateTime month;
  final DateTime now;
  final DateTime selected;
  final CalendarProvider cal;
  final ValueChanged<DateTime> onTap;

  static bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final bool inMonth = day.month == month.month;
    final bool isToday = _same(day, now);
    final bool isSelected = _same(day, selected);
    final bool hasEvent = cal.eventsOn(day).isNotEmpty;
    final bool hasTask = cal.tasksOn(day).isNotEmpty;
    final bool hasLeave = cal.leavesOn(day).isNotEmpty;

    final Color bg = isSelected
        ? AppColors.green
        : isToday
            ? AppColors.greenTint
            : Colors.transparent;
    final Color fg = isSelected
        ? Colors.white
        : isToday
            ? AppColors.green
            : inMonth
                ? AppColors.ink
                : AppColors.faintText.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.all(2.5),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: () => onTap(DateTime(day.year, day.month, day.day)),
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            height: 42,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (hasEvent) _Dot(color: isSelected ? Colors.white : AppColors.green),
                      if (hasTask) _Dot(color: isSelected ? Colors.white : AppColors.purple),
                      if (hasLeave) _Dot(color: isSelected ? Colors.white : AppColors.amber),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
  const _DayList({required this.day, required this.cal, required this.onOpenEvent, required this.onAdd});

  final DateTime day;
  final CalendarProvider cal;
  final ValueChanged<CalendarEvent> onOpenEvent;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final List<CalendarEvent> events = cal.eventsOn(day);
    final List<CalendarTaskDeadline> tasks = cal.tasksOn(day);
    final List<CalendarLeave> leaves = cal.leavesOn(day);

    if (events.isEmpty && tasks.isEmpty && leaves.isEmpty) {
      return GlassCard(
        radius: 18,
        color: AppColors.cardSoft,
        onTap: onAdd,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: <Widget>[
            const IconWell(icon: Icons.event_available_outlined, tone: ToneColor.green, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.calendarNothingThisDay,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.subtleText),
              ),
            ),
            Text(
              t.calendarNewEvent,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.green),
            ),
            const Icon(Icons.add_rounded, size: 16, color: AppColors.green),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (final CalendarEvent e in events)
          _EventCard(
            onTap: () => onOpenEvent(e),
            color: AppColors.green,
            time: e.allDay ? null : e.startAt,
            sideLabel: e.allDay ? t.calendarAllDay : null,
            title: e.title,
            subtitle: (e.location?.isNotEmpty ?? false) ? e.location! : (e.description ?? ''),
          ),
        for (final CalendarTaskDeadline tk in tasks)
          _EventCard(
            color: tk.isOverdue ? AppColors.red : AppColors.purple,
            sideLabel: tk.statusName,
            title: tk.title,
            strike: tk.isClosed,
          ),
        for (final CalendarLeave lv in leaves)
          _EventCard(
            onTap: () => AppRoutes.openLeaveDetail(lv.transNo),
            color: lv.isWorkLeaving ? AppColors.blue : AppColors.amber,
            sideLabel: lv.isPending ? t.calendarPending : lv.status,
            title: '${lv.userName} · ${lv.typeName}',
          ),
      ],
    );
  }
}

/// Time (or a short label) · coloured bar · title + subtitle.
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.color,
    required this.title,
    this.time,
    this.sideLabel,
    this.subtitle = '',
    this.onTap,
    this.strike = false,
  });

  final Color color;
  final DateTime? time;
  final String? sideLabel;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool strike;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 16,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 52,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: time != null
                      ? <Widget>[
                          Text(
                            DateFormat('hh:mm', locale).format(time!),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                          Text(
                            DateFormat('a', locale).format(time!).toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.faintText),
                          ),
                        ]
                      : <Widget>[
                          Text(
                            sideLabel ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
                          ),
                        ],
                ),
              ),
              Container(
                width: 3,
                margin: const EdgeInsetsDirectional.only(end: 12),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: strike ? TextDecoration.lineThrough : null,
                        color: AppColors.ink,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.subtleText),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.faintText),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── Event editor ─────────────────────────────

class _EventEditorSheet extends StatefulWidget {
  const _EventEditorSheet({this.event, required this.initialDay});

  final CalendarEvent? event;
  final DateTime initialDay;

  @override
  State<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends State<_EventEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  final TextEditingController _search = TextEditingController();
  late bool _allDay;
  late DateTime _start;
  late DateTime _end;
  late Set<String> _attendeeIds;
  List<CalendarPerson> _people = const <CalendarPerson>[];
  bool _busy = false;
  bool _titleMissing = false;
  String? _error;

  bool get _isNew => widget.event == null;
  bool get _canEdit => _isNew || widget.event!.canEdit;

  bool get _endBeforeStart => _allDay
      ? DateUtils.dateOnly(_end).isBefore(DateUtils.dateOnly(_start))
      : !_end.isAfter(_start);

  @override
  void initState() {
    super.initState();
    final CalendarEvent? e = widget.event;
    _title = TextEditingController(text: e?.title ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _notes = TextEditingController(text: e?.description ?? '');
    _allDay = e?.allDay ?? false;
    if (e?.startAt != null) {
      _start = e!.startAt!;
    } else {
      // Next whole hour on the day the user was looking at.
      final DateTime now = DateTime.now();
      final DateTime d = widget.initialDay;
      _start = DateTime(d.year, d.month, d.day, (now.hour + 1).clamp(0, 23));
    }
    _end = e?.endAt ?? _start.add(const Duration(hours: 1));
    _attendeeIds = e == null ? <String>{} : e.attendees.map((EventAttendee a) => a.userId).toSet();
    _search.addListener(() => setState(() {}));
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    try {
      final List<CalendarPerson> p = await context.read<CalendarService>().people();
      if (mounted) setState(() => _people = p);
    } catch (_) {
      // People are optional — the event can still be saved without them.
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isStart) async {
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
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (time == null || !mounted) return;
      result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }
    setState(() {
      _error = null;
      if (isStart) {
        final Duration length = _end.difference(_start);
        _start = result;
        // Keep the event's length when the start moves.
        _end = result.add(length.isNegative ? const Duration(hours: 1) : length);
      } else {
        _end = result;
      }
    });
  }

  Future<void> _save() async {
    final AppLocalizations t = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    final bool titleMissing = _title.text.trim().isEmpty;
    setState(() {
      _titleMissing = titleMissing;
      _error = titleMissing
          ? t.calendarTitleRequired
          : _endBeforeStart
              ? t.calendarEndBeforeStart
              : null;
    });
    if (_error != null) return;

    setState(() => _busy = true);
    final CalendarService service = context.read<CalendarService>();
    final String? notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final String? place = _location.text.trim().isEmpty ? null : _location.text.trim();
    try {
      if (_isNew) {
        await service.createEvent(
          title: _title.text.trim(),
          description: notes,
          location: place,
          allDay: _allDay,
          start: _start,
          end: _end,
          attendees: _attendeeIds.toList(),
        );
      } else {
        await service.updateEvent(
          id: widget.event!.id,
          title: _title.text.trim(),
          description: notes,
          location: place,
          allDay: _allDay,
          start: _start,
          end: _end,
          attendees: _attendeeIds.toList(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      // Shown inside the sheet — a SnackBar would sit hidden behind it.
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is ApiException ? e.message : t.calendarCouldNotSave;
        });
      }
    }
  }

  Future<void> _delete() async {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool ok = await showCdsConfirm(
      context,
      icon: Icons.delete_outline_rounded,
      tone: ToneColor.red,
      title: t.calendarDeleteTitle,
      details: <String>[widget.event!.title],
      confirmLabel: t.tasksDelete,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<CalendarService>().deleteEvent(widget.event!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is ApiException ? e.message : t.calendarCouldNotSave;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final DateFormat fmt = _allDay ? DateFormat('EEE, d MMM yyyy', locale) : DateFormat('EEE, d MMM · HH:mm', locale);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 16, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _isNew ? t.calendarNewEvent : t.calendarEventTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
                SoftIconButton(
                  icon: Icons.close_rounded,
                  tooltip: t.commonCancel,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Group(
                    borderColor: _titleMissing ? AppColors.red : null,
                    children: <Widget>[
                      _InputRow(
                        controller: _title,
                        hint: t.calendarEventName,
                        enabled: _canEdit,
                        large: true,
                        autofocus: _isNew,
                        onChanged: (_) {
                          if (_titleMissing) setState(() => _titleMissing = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Group(
                    children: <Widget>[
                      _TileRow(
                        icon: Icons.wb_sunny_outlined,
                        label: t.calendarAllDay,
                        trailing: Switch.adaptive(
                          value: _allDay,
                          activeTrackColor: AppColors.green,
                          onChanged: _canEdit ? (bool v) => setState(() => _allDay = v) : null,
                        ),
                      ),
                      _TileRow(
                        icon: Icons.play_circle_outline_rounded,
                        label: t.calendarStart,
                        value: fmt.format(_start),
                        onTap: _canEdit ? () => _pick(true) : null,
                      ),
                      _TileRow(
                        icon: Icons.stop_circle_outlined,
                        label: t.calendarEnd,
                        value: fmt.format(_end),
                        valueColor: _endBeforeStart ? AppColors.red : null,
                        onTap: _canEdit ? () => _pick(false) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Group(
                    children: <Widget>[
                      _InputRow(
                        controller: _location,
                        hint: t.calendarPlace,
                        icon: Icons.place_outlined,
                        enabled: _canEdit,
                      ),
                      _InputRow(
                        controller: _notes,
                        hint: t.calendarNotes,
                        icon: Icons.notes_rounded,
                        enabled: _canEdit,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ListLabel(
                    label: t.calendarPeople,
                    trailing: _attendeeIds.isEmpty ? null : t.calendarSelectedCount(_attendeeIds.length),
                  ),
                  _PeoplePicker(
                    people: _people,
                    selectedIds: _attendeeIds,
                    search: _search,
                    enabled: _canEdit,
                    onToggle: (String id) => setState(() {
                      if (!_attendeeIds.remove(id)) _attendeeIds.add(id);
                    }),
                  ),
                ],
              ),
            ),
          ),
          if (_canEdit)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              decoration: const BoxDecoration(
                color: AppColors.cream,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.red),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: <Widget>[
                      if (!_isNew) ...<Widget>[
                        SizedBox(
                          height: 50,
                          width: 50,
                          child: OutlinedButton(
                            onPressed: _busy ? null : _delete,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: AppColors.red,
                              side: const BorderSide(color: AppColors.redTint, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: _busy ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(t.calendarSave, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// White rounded block with hairline dividers between its rows.
class _Group extends StatelessWidget {
  const _Group({required this.children, this.borderColor});

  final List<Widget> children;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppColors.line, width: borderColor == null ? 1 : 1.5),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, thickness: 1, indent: 48, color: AppColors.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 10, 4),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: AppColors.subtleText),
              const SizedBox(width: 14),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
              const Spacer(),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.green),
                ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.controller,
    required this.hint,
    this.icon,
    this.enabled = true,
    this.large = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool enabled;
  final bool large;
  final bool autofocus;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(14, large ? 6 : 2, 14, large ? 6 : 2),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
              child: Icon(icon, size: 20, color: AppColors.subtleText),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              autofocus: autofocus,
              minLines: 1,
              maxLines: maxLines,
              onChanged: onChanged,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                fontSize: large ? 17 : 13,
                fontWeight: large ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: large ? 17 : 13,
                  fontWeight: large ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.faintText,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selected people as removable chips + a search box that lists matches,
/// instead of a wall of every employee.
class _PeoplePicker extends StatelessWidget {
  const _PeoplePicker({
    required this.people,
    required this.selectedIds,
    required this.search,
    required this.enabled,
    required this.onToggle,
  });

  final List<CalendarPerson> people;
  final Set<String> selectedIds;
  final TextEditingController search;
  final bool enabled;
  final ValueChanged<String> onToggle;

  static String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+')).where((String s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String q = search.text.trim().toLowerCase();
    final List<CalendarPerson> selected = people.where((CalendarPerson p) => selectedIds.contains(p.userId)).toList();
    final List<CalendarPerson> matches = q.isEmpty
        ? const <CalendarPerson>[]
        : people
            .where((CalendarPerson p) => !selectedIds.contains(p.userId) && p.name.toLowerCase().contains(q))
            .take(6)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (selected.isNotEmpty) ...<Widget>[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final CalendarPerson p in selected)
                InputChip(
                  avatar: CircleAvatar(
                    backgroundColor: AppColors.green,
                    child: Text(_initials(p.name),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  label: Text(p.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.greenTint,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onDeleted: enabled ? () => onToggle(p.userId) : null,
                  deleteIconColor: AppColors.green,
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (enabled)
          _Group(
            children: <Widget>[
              _InputRow(controller: search, hint: t.calendarSearchPeople, icon: Icons.search_rounded),
              for (final CalendarPerson p in matches)
                InkWell(
                  onTap: () {
                    onToggle(p.userId);
                    search.clear();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: AppColors.greenTint,
                          child: Text(_initials(p.name),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.green)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(p.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        ),
                        const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.green),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
