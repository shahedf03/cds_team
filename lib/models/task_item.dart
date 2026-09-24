import '../core/utils/api_formats.dart';

/// `GET /api/tasks` — stays on the legacy database, unaffected by the
/// planned DB split.
class TaskItem {
  const TaskItem({
    required this.taskId,
    required this.taskProjectName,
    required this.taskStatusName,
    required this.taskTitle,
    required this.taskDescription,
    required this.taskDeadLine,
    required this.clientName,
  });

  final String taskId;
  final String taskProjectName;
  final String taskStatusName;
  final String taskTitle;
  final String taskDescription;
  final DateTime? taskDeadLine;
  final String clientName;

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    taskId: Json.str(json['taskId']),
    taskProjectName: Json.str(json['taskProjectName']),
    taskStatusName: Json.str(json['taskStatusName']),
    taskTitle: Json.str(json['taskTitle']),
    taskDescription: Json.str(json['taskDescription']),
    taskDeadLine: Json.date(json['taskDeadLine']),
    clientName: Json.str(json['clientName']),
  );

  bool get isDone {
    final String s = taskStatusName.toLowerCase();
    return s.contains('done') ||
        s.contains('complete') ||
        s.contains('closed') ||
        s.contains('finish');
  }

  bool get isInProgress =>
      !isDone && taskStatusName.toLowerCase().contains('progress');

  bool get isOverdue =>
      !isDone &&
      taskDeadLine != null &&
      taskDeadLine!.isBefore(DateTime.now());

  String get deadlineLabel =>
      taskDeadLine == null ? 'No deadline' : ApiFormats.displayDate.format(taskDeadLine!);
}

/// Tasks grouped by project, the way the Tasks screen renders them.
class TaskProject {
  const TaskProject({
    required this.name,
    required this.clientName,
    required this.tasks,
  });

  final String name;
  final String clientName;
  final List<TaskItem> tasks;

  int get doneCount => tasks.where((TaskItem t) => t.isDone).length;

  String get initial => name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

  static List<TaskProject> groupByProject(List<TaskItem> tasks) {
    final Map<String, List<TaskItem>> buckets = <String, List<TaskItem>>{};
    for (final TaskItem task in tasks) {
      final String key = task.taskProjectName.trim().isEmpty
          ? 'Other'
          : task.taskProjectName.trim();
      buckets.putIfAbsent(key, () => <TaskItem>[]).add(task);
    }

    return buckets.entries.map((MapEntry<String, List<TaskItem>> entry) {
      final String client = entry.value
          .map((TaskItem t) => t.clientName)
          .firstWhere((String c) => c.trim().isNotEmpty, orElse: () => '');
      return TaskProject(
        name: entry.key,
        clientName: client,
        tasks: entry.value,
      );
    }).toList()..sort((TaskProject a, TaskProject b) => a.name.compareTo(b.name));
  }
}
