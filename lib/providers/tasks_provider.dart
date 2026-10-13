import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/task_item.dart';
import '../services/task_chat_service.dart';
import '../services/tasks_service.dart';
import 'loadable.dart';

/// §6 — tasks grouped by project. Since 2026-10-05, backed by
/// `GET /api/tasks/search` (every status at once, richer rows) with local
/// multi-select status filtering, matching the Portal's filter chips.
class TasksProvider extends ChangeNotifier with Loadable {
  TasksProvider({required TasksService service, TaskChatService? chatService})
    : _service = service,
      _chatService = chatService;

  final TasksService _service;
  final TaskChatService? _chatService;
  String? _userId;

  List<TaskItem> _tasks = const <TaskItem>[];
  List<Lookup> _statuses = const <Lookup>[];
  List<Lookup> _categories = const <Lookup>[];

  /// 2026-10-08 part C — unread chat messages per task id, from
  /// `GET /api/tasks/chat/unread`. Only tasks with any unread appear.
  Map<String, int> _chatUnread = const <String, int>{};

  /// Selected status codes; empty = "الكل" (everything shown). Opens on
  /// Open (`2`) only, per spec.
  final Set<int> selectedStatuses = <int>{2};

  /// 2026-10-08 part B — one category at a time; `null` = "الكل". Filtered
  /// locally like the status chips, over whatever's already loaded.
  int? selectedCategory;

  /// Optional "Created by" filter — one creator's `createdBy` id at a time,
  /// filtered locally like the status/category chips. `null` = "الكل".
  String? selectedCreatedBy;
  final Set<String> _updating = <String>{};

  List<TaskItem> get tasks => _tasks;
  List<Lookup> get statuses => _statuses;
  List<Lookup> get categories => _categories;

  /// Distinct creators among the loaded tasks, `(id, name)`, for the
  /// "Created by" filter chips — sorted by name.
  List<(String, String)> get creators {
    final Map<String, String> byId = <String, String>{};
    for (final TaskItem t in _tasks) {
      if (t.createdBy.isEmpty) continue;
      byId[t.createdBy] = t.createdByName.isEmpty ? t.createdBy : t.createdByName;
    }
    final List<(String, String)> list = byId.entries
        .map((MapEntry<String, String> e) => (e.key, e.value))
        .toList();
    list.sort((a, b) => a.$2.compareTo(b.$2));
    return list;
  }

  List<TaskItem> get visibleTasks {
    Iterable<TaskItem> visible = _tasks;
    if (selectedStatuses.isNotEmpty) {
      visible = visible.where(
        (TaskItem t) => selectedStatuses.contains(t.taskStatus),
      );
    }
    final int? category = selectedCategory;
    if (category != null) {
      visible = visible.where((TaskItem t) => t.taskCategory == category);
    }
    final String? createdBy = selectedCreatedBy;
    if (createdBy != null) {
      visible = visible.where((TaskItem t) => t.createdBy == createdBy);
    }
    return visible.toList();
  }

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
        final TaskLookups lookups = await _service.lookups();
        _statuses = lookups.statuses;
        _categories = lookups.categories;
      } catch (_) {
        // The chip rows just won't render; the task list itself still loaded.
      }
    }
    unawaited(refreshChatUnread());
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

  /// 2026-10-08 part B — one category at a time; tapping the active one
  /// clears it back to "الكل".
  void toggleCategory(int code) {
    selectedCategory = selectedCategory == code ? null : code;
    notifyListeners();
  }

  int countForCategory(int? code) => code == null
      ? _tasks.length
      : _tasks.where((TaskItem t) => t.taskCategory == code).length;

  /// One creator at a time; tapping the active one clears it back to "الكل".
  void toggleCreatedBy(String userId) {
    selectedCreatedBy = selectedCreatedBy == userId ? null : userId;
    notifyListeners();
  }

  int countForCreatedBy(String? userId) => userId == null
      ? _tasks.length
      : _tasks.where((TaskItem t) => t.createdBy == userId).length;

  /// Unread chat messages on this task, `0` when there are none (or the
  /// badge hasn't loaded yet).
  int unreadChatFor(String taskId) => _chatUnread[taskId] ?? 0;

  /// `GET /api/tasks/chat/unread` — refreshed after the task list loads and
  /// whenever a `task_chat` push arrives in the foreground.
  Future<void> refreshChatUnread() async {
    final TaskChatService? chat = _chatService;
    if (chat == null) return;
    try {
      _chatUnread = await chat.unreadCounts();
      notifyListeners();
    } catch (_) {
      // The badges just won't update this round.
    }
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
    _categories = const <Lookup>[];
    _chatUnread = const <String, int>{};
    selectedStatuses
      ..clear()
      ..add(2);
    selectedCategory = null;
    selectedCreatedBy = null;
    _updating.clear();
    _userId = null;
    resetLoadState();
    notifyListeners();
  }
}
