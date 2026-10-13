import '../core/utils/api_formats.dart';
import 'task_item.dart';

/// One member on a project's team, from `GET /api/projects` / `/{code}`.
class ProjectTeamMember {
  const ProjectTeamMember({required this.userId, required this.name, required this.openTasks});

  final String userId;
  final String name;
  final int openTasks;

  factory ProjectTeamMember.fromJson(Map<String, dynamic> json) => ProjectTeamMember(
    userId: Json.str(json['userId']),
    name: Json.str(json['name']),
    openTasks: Json.intVal(json['openTasks']),
  );
}

/// A project's sprint — `GET /api/projects/sprints`, and `activeSprint` on
/// the project card. `tasks` is only filled on `GET /api/projects/{code}`.
class Sprint {
  const Sprint({
    required this.id,
    required this.name,
    this.goal = '',
    this.startDate,
    this.endDate,
    this.state = '',
    this.daysLeft,
    this.taskCount = 0,
    this.doneCount = 0,
    this.progress = 0,
    this.tasks = const <TaskItem>[],
  });

  final int id;
  final String name;
  final String goal;
  final DateTime? startDate;
  final DateTime? endDate;

  /// "Upcoming" / "Active" / "Completed", by the dates.
  final String state;

  /// Days until it starts (Upcoming) or ends (Active, `0` = today); `null`
  /// once Completed.
  final int? daysLeft;
  final int taskCount;
  final int doneCount;

  /// Closed tasks (Done/Delivered) as a percentage of this sprint's tasks.
  final int progress;
  final List<TaskItem> tasks;

  factory Sprint.fromJson(Map<String, dynamic> json) => Sprint(
    id: Json.intVal(json['id']),
    name: Json.str(json['name']),
    goal: Json.str(json['goal']),
    startDate: Json.date(json['startDate']),
    endDate: Json.date(json['endDate']),
    state: Json.str(json['state']),
    daysLeft: json['daysLeft'] == null ? null : Json.intVal(json['daysLeft']),
    taskCount: Json.intVal(json['taskCount']),
    doneCount: Json.intVal(json['doneCount']),
    progress: Json.intVal(json['progress']),
    tasks: Json.objects(json['tasks']).map(TaskItem.fromJson).toList(),
  );

  bool get isActive => state == 'Active';
  bool get isUpcoming => state == 'Upcoming';
}

/// One card of `GET /api/projects`.
class ProjectSummary {
  const ProjectSummary({
    required this.code,
    required this.name,
    this.sprintCount = 0,
    this.taskCount = 0,
    this.doneCount = 0,
    this.workingCount = 0,
    this.openCount = 0,
    this.overdueCount = 0,
    this.progress = 0,
    this.noSprintCount = 0,
    this.team = const <ProjectTeamMember>[],
    this.activeSprint,
  });

  final String code;
  final String name;
  final int sprintCount;
  final int taskCount;
  final int doneCount;
  final int workingCount;
  final int openCount;
  final int overdueCount;
  final int progress;
  final int noSprintCount;
  final List<ProjectTeamMember> team;
  final Sprint? activeSprint;

  factory ProjectSummary.fromJson(Map<String, dynamic> json) => ProjectSummary(
    code: Json.str(json['code']),
    name: Json.str(json['name']),
    sprintCount: Json.intVal(json['sprintCount']),
    taskCount: Json.intVal(json['taskCount']),
    doneCount: Json.intVal(json['doneCount']),
    workingCount: Json.intVal(json['workingCount']),
    openCount: Json.intVal(json['openCount']),
    overdueCount: Json.intVal(json['overdueCount']),
    progress: Json.intVal(json['progress']),
    noSprintCount: Json.intVal(json['noSprintCount']),
    team: Json.objects(json['team']).map(ProjectTeamMember.fromJson).toList(),
    activeSprint: json['activeSprint'] == null
        ? null
        : Sprint.fromJson(Map<String, dynamic>.from(json['activeSprint'] as Map)),
  );
}

/// `GET /api/projects/{code}` — the card fields plus every sprint (newest
/// first, each with its tasks) and the tasks outside any sprint.
class ProjectDetail {
  const ProjectDetail({
    required this.summary,
    this.sprints = const <Sprint>[],
    this.noSprintTasks = const <TaskItem>[],
    this.canManage = false,
  });

  final ProjectSummary summary;
  final List<Sprint> sprints;
  final List<TaskItem> noSprintTasks;
  final bool canManage;

  factory ProjectDetail.fromJson(Map<String, dynamic> json) => ProjectDetail(
    summary: ProjectSummary.fromJson(json),
    sprints: Json.objects(json['sprints']).map(Sprint.fromJson).toList(),
    noSprintTasks: Json.objects(json['noSprintTasks']).map(TaskItem.fromJson).toList(),
    canManage: Json.boolOrNull(json['canManage']) ?? false,
  );
}
