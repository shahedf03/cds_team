import 'package:flutter/foundation.dart';

import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import 'loadable.dart';

/// Month calendar (2026-10-08 part E) — one `GET /api/calendar` call per
/// visible month (padded to full weeks, capped at 120 days by the server).
class CalendarProvider extends ChangeNotifier with Loadable {
  CalendarProvider({required CalendarService service}) : _service = service;

  final CalendarService _service;

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  CalendarData _data = const CalendarData();
  bool _teamTasks = false;

  DateTime get month => _month;
  CalendarData get data => _data;
  bool get teamTasks => _teamTasks;

  DateTime get _gridStart {
    final DateTime first = DateTime(_month.year, _month.month, 1);
    // Sun–Sat grid: back up to the Sunday on/before the 1st.
    return first.subtract(Duration(days: first.weekday % 7));
  }

  DateTime get _gridEnd => _gridStart.add(const Duration(days: 41));

  Future<void> load() => guard(() async {
    _data = await _service.load(from: _gridStart, to: _gridEnd, teamTasks: _teamTasks);
  });

  Future<void> goToMonth(DateTime month) async {
    _month = DateTime(month.year, month.month);
    await load();
  }

  Future<void> nextMonth() => goToMonth(DateTime(_month.year, _month.month + 1));
  Future<void> previousMonth() => goToMonth(DateTime(_month.year, _month.month - 1));

  Future<void> setTeamTasks(bool value) async {
    if (_teamTasks == value) return;
    _teamTasks = value;
    await load();
  }

  List<CalendarEvent> eventsOn(DateTime day) =>
      data.events.where((CalendarEvent e) => _onDay(e.startAt, e.endAt, day)).toList();

  List<CalendarTaskDeadline> tasksOn(DateTime day) =>
      data.tasks.where((CalendarTaskDeadline t) => _sameDay(t.deadline, day)).toList();

  List<CalendarLeave> leavesOn(DateTime day) =>
      data.leaves.where((CalendarLeave l) => _onDay(l.start, l.end, day)).toList();

  bool hasAnythingOn(DateTime day) =>
      eventsOn(day).isNotEmpty || tasksOn(day).isNotEmpty || leavesOn(day).isNotEmpty;

  static bool _sameDay(DateTime? d, DateTime day) =>
      d != null && d.year == day.year && d.month == day.month && d.day == day.day;

  static bool _onDay(DateTime? start, DateTime? end, DateTime day) {
    if (start == null) return false;
    final DateTime d0 = DateTime(day.year, day.month, day.day);
    final DateTime s0 = DateTime(start.year, start.month, start.day);
    final DateTime e0 = end == null ? s0 : DateTime(end.year, end.month, end.day);
    return !d0.isBefore(s0) && !d0.isAfter(e0);
  }

  void reset() {
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _data = const CalendarData();
    _teamTasks = false;
    resetLoadState();
    notifyListeners();
  }
}
