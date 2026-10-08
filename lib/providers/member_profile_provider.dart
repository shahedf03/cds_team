import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/attendance_record.dart';
import '../models/leave_request.dart';
import '../models/task_item.dart';
import '../models/team.dart';
import '../models/transportation.dart';
import '../services/attendance_service.dart';
import '../services/leave_service.dart';
import '../services/tasks_service.dart';
import '../services/transportation_service.dart';
import 'loadable.dart';

/// One tab's worth of data with its own loading/error state, so a `403` or a
/// timeout on one tab doesn't blank the others.
class Section<T> {
  Section(this.data);

  T data;
  bool loading = false;
  bool loaded = false;
  String? error;
}

/// §12 — a team member's data: the same endpoints the "own" screens use,
/// called with their `userId`. Read-only by construction: nothing here
/// writes. Kept apart from the logged-in user's providers so opening a
/// member never overwrites the manager's own attendance, leaves or trips.
class MemberProfileProvider extends ChangeNotifier {
  MemberProfileProvider({
    required this.member,
    required AttendanceService attendance,
    required LeaveService leave,
    required TasksService tasks,
    required TransportationService transportation,
  }) : _attendance = attendance,
       _leave = leave,
       _tasks = tasks,
       _transportation = transportation;

  final TeamMember member;
  final AttendanceService _attendance;
  final LeaveService _leave;
  final TasksService _tasks;
  final TransportationService _transportation;

  DateRange _range = DateRange.currentMonth();
  bool _exportingReport = false;

  final Section<List<AttendanceRecord>> history = Section(
    const <AttendanceRecord>[],
  );
  final Section<List<LeaveRequest>> leaves = Section(const <LeaveRequest>[]);
  final Section<List<LeaveBalance>> balances = Section(
    const <LeaveBalance>[],
  );
  final Section<List<TaskItem>> tasks = Section(const <TaskItem>[]);
  final Section<List<Transportation>> trips = Section(
    const <Transportation>[],
  );

  DateRange get range => _range;
  bool get isExportingReport => _exportingReport;

  List<TaskProject> get projects => TaskProject.groupByProject(tasks.data);
  int get doneTasks => tasks.data.where((TaskItem t) => t.isDone).length;

  AttendanceRecord? _todayRecord;

  /// Today's row, phone punches only. `/api/attendance/today` is built for
  /// the logged-in user's own session (it drives the Home widget) and
  /// errors out when called with a team member's id, so this is fetched
  /// with `source: mobile` instead — never the merged [history] list, which
  /// would pull in the wall terminal (§10: Start/End are a phone-only
  /// concept everywhere, not just on Home).
  AttendanceRecord? get todayRecord => _todayRecord;

  double get totalKm => trips.data.fold<double>(
    0,
    (double sum, Transportation e) => sum + e.kmValue,
  );
  double get totalAmount => trips.data.fold<double>(
    0,
    (double sum, Transportation e) => sum + e.totalValue,
  );

  Future<void> loadAll() => Future.wait<void>(<Future<void>>[
    loadAttendance(),
    loadLeaves(),
    loadTasks(),
    loadTrips(),
  ]);

  Future<void> setRange(DateRange value) {
    _range = value;
    return Future.wait<void>(<Future<void>>[
      loadAttendance(),
      loadLeaves(),
      loadTrips(),
    ]);
  }

  /// History for the open window, plus [todayRecord] in parallel.
  Future<void> loadAttendance() => Future.wait<void>(<Future<void>>[
    _load(
      history,
      () => _attendance.history(
        userId: member.userId,
        fromDate: _range.from,
        toDate: _range.to,
      ),
    ),
    _loadTodayRecord(),
  ]);

  Future<void> _loadTodayRecord() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    try {
      final List<AttendanceRecord> rows = await _attendance.history(
        userId: member.userId,
        fromDate: today,
        toDate: today,
        source: AttendanceSource.mobile,
      );
      _todayRecord = rows.isEmpty ? null : rows.first;
    } on ApiException {
      _todayRecord = null;
    }
    notifyListeners();
  }

  /// Requests in the open window plus this year's balance.
  Future<void> loadLeaves() => Future.wait<void>(<Future<void>>[
    _load(
      leaves,
      () => _leave.list(
        userId: member.userId,
        fromDate: _range.from,
        toDate: _range.to,
      ),
    ),
    _load(
      balances,
      () => _leave.balance(userId: member.userId, year: DateTime.now().year),
    ),
  ]);

  Future<void> loadTasks() =>
      _load(tasks, () => _tasks.list(userId: member.userId));

  Future<void> loadTrips() => _load(
    trips,
    () => _transportation.list(
      userId: member.userId,
      fromDate: _range.from,
      toDate: _range.to,
    ),
  );

  /// The member's transportation PDF for the open window. Throws
  /// [ApiException] (the API's own message) on failure.
  Future<Uint8List> report() async {
    _exportingReport = true;
    notifyListeners();
    try {
      return await _transportation.report(
        userId: member.userId,
        userName: member.label,
        fromDate: _range.from,
        toDate: _range.to,
      );
    } finally {
      _exportingReport = false;
      notifyListeners();
    }
  }

  // Requests can finish after the user has left the profile.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> _load<T>(Section<T> section, Future<T> Function() fetch) async {
    section
      ..loading = true
      ..error = null;
    notifyListeners();
    try {
      section.data = await fetch();
    } on ApiException catch (e) {
      // 401 is handled globally (back to login); a 403 just shows its message.
      section.error = e.isUnauthorized ? null : e.message;
    } catch (e) {
      section.error = e.toString();
    } finally {
      section
        ..loading = false
        ..loaded = true;
      notifyListeners();
    }
  }
}