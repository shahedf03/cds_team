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
    this.attachmentCount = 0,
    this.taskStatus,
    this.taskPriority,
    this.taskPriorityName = '',
    this.responsibleUser = '',
    this.responsibleUserName = '',
    this.createdBy = '',
    this.canEdit = false,
    this.canDelete = false,
  });

  final String taskId;
  final String taskProjectName;
  final String taskStatusName;
  final String taskTitle;
  final String taskDescription;
  final DateTime? taskDeadLine;
  final String clientName;

  /// Files attached to this task from the Portal (added 2026-10-04). `0`
  /// hides the 📎 badge; `GET /api/tasks/{taskId}/attachments` lists them.
  /// The app only views these — there's no upload/delete endpoint for it.
  final int attachmentCount;

  /// The numeric status code (2026-10-05, from `GET /api/tasks/search` and
  /// the dashboard's `recentTasks`) — `2` Open, `3` Done, `4` Delivered, the
  /// rest configured server-side (`GET /api/tasks/lookups`). Null on the
  /// older `GET /api/tasks` (§6) rows, which only carry [taskStatusName].
  final int? taskStatus;
  final int? taskPriority;
  final String taskPriorityName;
  final String responsibleUser;
  final String responsibleUserName;
  final String createdBy;

  /// `GET /api/tasks/search` only: creator, assignee or assignee's manager —
  /// drives the "تم الإنجاز" status button.
  final bool canEdit;

  /// `GET /api/tasks/search` only (part G, 2026-10-05): a Team Leader, or
  /// someone with the "DeleteTasks" permission — drives the delete button.
  /// Being the creator or assignee isn't enough on its own.
  final bool canDelete;

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
    taskId: Json.str(json['taskId']),
    taskProjectName: Json.str(json['taskProjectName']),
    taskStatusName: Json.str(json['taskStatusName']),
    taskTitle: Json.str(json['taskTitle']),
    taskDescription: Json.str(json['taskDescription']),
    taskDeadLine: Json.date(json['taskDeadLine']),
    clientName: Json.str(json['clientName']),
    attachmentCount: Json.intVal(json['attachmentCount']),
    taskStatus: json['taskStatus'] == null ? null : Json.intVal(json['taskStatus']),
    taskPriority: json['taskPriority'] == null
        ? null
        : Json.intVal(json['taskPriority']),
    taskPriorityName: Json.str(json['taskPriorityName']),
    responsibleUser: Json.str(json['responsibleUser']),
    responsibleUserName: Json.str(json['responsibleUserName']),
    createdBy: Json.str(json['createdBy']),
    canEdit: Json.boolOrNull(json['canEdit']) ?? false,
    canDelete: Json.boolOrNull(json['canDelete']) ?? false,
  );

  bool get hasAttachments => attachmentCount > 0;

  bool get isDone {
    if (taskStatus != null) return taskStatus == 3 || taskStatus == 4;
    final String s = taskStatusName.toLowerCase();
    return s.contains('done') ||
        s.contains('complete') ||
        s.contains('closed') ||
        s.contains('finish') ||
        s.contains('deliver');
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

/// One row of `GET /api/tasks/{taskId}/attachments` (added 2026-10-04) — a
/// file someone attached to the task from the Portal. View-only: there's no
/// upload/delete endpoint for the app. `canDelete` is ignored, it's for the
/// Portal. `url` is a relative path; fetch it through
/// [TasksService.attachmentBytes] rather than building the URL by hand so it
/// goes through the same authenticated client as everything else.
class TaskAttachment {
  const TaskAttachment({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.contentType,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.uploadedAt,
    required this.url,
  });

  final String id;
  final String taskId;
  final String fileName;
  final String contentType;
  final int fileSize;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime? uploadedAt;
  final String url;

  factory TaskAttachment.fromJson(Map<String, dynamic> json) =>
      TaskAttachment(
        id: Json.str(json['id']),
        taskId: Json.str(json['taskId']),
        fileName: Json.str(json['fileName']),
        contentType: Json.str(json['contentType']),
        fileSize: Json.intVal(json['fileSize']),
        uploadedBy: Json.str(json['uploadedBy']),
        uploadedByName: Json.str(json['uploadedByName']),
        uploadedAt: Json.date(json['uploadedAt']),
        url: Json.str(json['url']),
      );

  bool get isImage => contentType.toLowerCase().startsWith('image/');

  String get sizeText {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// One entry of a `GET /api/tasks/lookups` list — `{ "code": "2", "name":
/// "Open" }`. [code] is the raw server string; parse it with [int.parse]
/// wherever a [TaskItem.taskStatus]-shaped int is needed.
class Lookup {
  const Lookup({required this.code, required this.name});

  final String code;
  final String name;

  factory Lookup.fromJson(Map<String, dynamic> json) =>
      Lookup(code: Json.str(json['code']), name: Json.str(json['name']));

  int? get intCode => int.tryParse(code);
}

/// `GET /api/tasks/lookups` (2026-10-05) — the status codes drive the
/// multi-select filter chips on the Tasks screen; `projects`/`priorities`/
/// `clients` are kept for completeness even though nothing renders them yet.
class TaskLookups {
  const TaskLookups({
    this.statuses = const <Lookup>[],
    this.projects = const <Lookup>[],
    this.priorities = const <Lookup>[],
    this.clients = const <Lookup>[],
  });

  final List<Lookup> statuses;
  final List<Lookup> projects;
  final List<Lookup> priorities;
  final List<Lookup> clients;

  factory TaskLookups.fromJson(Map<String, dynamic> json) => TaskLookups(
    statuses: Json.objects(json['statuses']).map(Lookup.fromJson).toList(),
    projects: Json.objects(json['projects']).map(Lookup.fromJson).toList(),
    priorities: Json.objects(
      json['priorities'],
    ).map(Lookup.fromJson).toList(),
    clients: Json.objects(json['clients']).map(Lookup.fromJson).toList(),
  );
}
