import 'package:flutter/foundation.dart';

import '../models/task_item.dart';
import '../services/tasks_service.dart';
import 'loadable.dart';

/// §6 — tasks grouped by project.
class TasksProvider extends ChangeNotifier with Loadable {
  TasksProvider({required TasksService service}) : _service = service;

  final TasksService _service;

  List<TaskItem> _tasks = const <TaskItem>[];

  List<TaskItem> get tasks => _tasks;
  List<TaskProject> get projects => TaskProject.groupByProject(_tasks);

  int get doneCount => _tasks.where((TaskItem t) => t.isDone).length;
  int get openCount => _tasks.length - doneCount;

  Future<void> load({required String userId}) => guard(() async {
    _tasks = await _service.list(userId: userId);
  });

  void reset() {
    _tasks = const <TaskItem>[];
    resetLoadState();
    notifyListeners();
  }
}
