import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/task_item.dart';
import '../services/tasks_service.dart';
import 'loadable.dart';

/// §6 — tasks grouped by project. Since 2026-10-05, backed by
/// `GET /api/tasks/search` (every status at once, richer rows) with local
/// multi-select status filtering, matching the Portal's filter chips.
class TasksProvider extends ChangeNotifier with Loadable {
  TasksProvider({required TasksService service}) : _service = service;

  final TasksService _service;
  String? _userId;

  List<TaskItem> _tasks = const <TaskItem>[];
  List<Lookup> _statuses = const <Lookup>[];

  /// Selected status codes; empty = "الكل" (everything shown). Opens on
  /// Open (`2`) only, per spec.
  final Set<int> selectedStatuses = <int>{2};
  final Set<String> _updating = <String>{};

  List<TaskItem> get tasks => _tasks;
  List<Lookup> get statuses => _statuses;

  List<TaskItem> get visibleTasks => selectedStatuses.isEmpty
      ? _tasks
      : _tasks
            .where((TaskItem t) => selectedStatuses.contains(t.taskStatus))
            .toList();

  List<TaskProject> get projects => TaskProject.groupByProject(visibleTasks);

  int get doneCount => _tasks.where((TaskItem t) => t.isDone).length;
  int get openCount => _tasks.length - doneCount;

  bool isUpdating(String taskId) => _updating.contains(taskId);

  /// Count for one status chip, from the loaded list — not a server call
  /// per chip. `null` = "الكل".
  int countFor(int? code) => code == null
      ? _tasks.length
      : _tasks.where((TaskItem t) => t.taskStatus == code).length;

  Future<void> load({required String userId}) => guard(() async {
    _userId = userId;
    _tasks = await _service.search(userId: userId);
    if (_statuses.isEmpty) {
      try {
        _statuses = (await _service.lookups()).statuses;
      } catch (_) {
        // The chip row just won't render; the task list itself still loaded.
      }
    }
  });

  /// Several statuses can be active at once (e.g. Open + Working Now).
  void toggleStatus(int code) {
    if (!selectedStatuses.remove(code)) selectedStatuses.add(code);
    notifyListeners();
  }

  /// "الكل" — clears the selection so everything shows.
  void clearStatusFilter() {
    selectedStatuses.clear();
    notifyListeners();
  }

  /// `PUT /api/tasks/{taskId}/status` then refresh. Returns the API's error
  /// message on failure, `null` on success.
  Future<String?> updateStatus(String taskId, int status) =>
      _mutate(taskId, () => _service.updateStatus(taskId, status));

  /// `DELETE /api/tasks/{taskId}` then refresh. Returns the API's error
  /// message on failure, `null` on success.
  Future<String?> delete(String taskId) =>
      _mutate(taskId, () => _service.delete(taskId));

  Future<String?> _mutate(String taskId, Future<void> Function() call) async {
    _updating.add(taskId);
    notifyListeners();
    String? message;
    try {
      await call();
    } on ApiException catch (e) {
      // A 401 is handled globally by the interceptor; don't double-report it.
      message = e.isUnauthorized ? null : e.message;
    } catch (e) {
      message = e.toString();
    } finally {
      _updating.remove(taskId);
    }

    final String? userId = _userId;
    if (message == null && userId != null) {
      await load(userId: userId);
    } else {
      notifyListeners();
    }
    return message;
  }

  void reset() {
    _tasks = const <TaskItem>[];
    _statuses = const <Lookup>[];
    selectedStatuses
      ..clear()
      ..add(2);
    _updating.clear();
    _userId = null;
    resetLoadState();
    notifyListeners();
  }
}
