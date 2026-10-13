import '../core/utils/api_formats.dart';

/// Someone on a calendar event.
class EventAttendee {
  const EventAttendee({required this.userId, required this.name});

  final String userId;
  final String name;

  factory EventAttendee.fromJson(Map<String, dynamic> json) =>
      EventAttendee(userId: Json.str(json['userId']), name: Json.str(json['name']));
}

/// `GET /api/calendar/people` — every active employee, for the people picker.
class CalendarPerson {
  const CalendarPerson({required this.userId, required this.name});

  final String userId;
  final String name;

  factory CalendarPerson.fromJson(Map<String, dynamic> json) =>
      CalendarPerson(userId: Json.str(json['userId']), name: Json.str(json['name']));
}

/// One calendar event.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startAt,
    required this.endAt,
    this.allDay = false,
    this.createdBy = '',
    this.createdByName = '',
    this.attendees = const <EventAttendee>[],
    this.canEdit = false,
  });

  final int id;
  final String title;
  final String? description;
  final String? location;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool allDay;
  final String createdBy;
  final String createdByName;
  final List<EventAttendee> attendees;

  /// Creator only.
  final bool canEdit;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: Json.intVal(json['id']),
    title: Json.str(json['title']),
    description: json['description']?.toString(),
    location: json['location']?.toString(),
    startAt: Json.date(json['startAt']),
    endAt: Json.date(json['endAt']),
    allDay: Json.boolOrNull(json['allDay']) ?? false,
    createdBy: Json.str(json['createdBy']),
    createdByName: Json.str(json['createdByName']),
    attendees: Json.objects(json['attendees']).map(EventAttendee.fromJson).toList(),
    canEdit: Json.boolOrNull(json['canEdit']) ?? false,
  );
}

/// A task deadline shown on the calendar.
class CalendarTaskDeadline {
  const CalendarTaskDeadline({
    required this.taskId,
    required this.title,
    this.deadline,
    this.status = '',
    this.statusName = '',
    this.isClosed = false,
    this.isOverdue = false,
    this.responsibleUser = '',
    this.responsibleUserName = '',
    this.projectName = '',
  });

  final String taskId;
  final String title;
  final DateTime? deadline;
  final String status;
  final String statusName;
  final bool isClosed;
  final bool isOverdue;
  final String responsibleUser;
  final String responsibleUserName;
  final String projectName;

  factory CalendarTaskDeadline.fromJson(Map<String, dynamic> json) => CalendarTaskDeadline(
    taskId: Json.str(json['taskId']),
    title: Json.str(json['title']),
    deadline: Json.date(json['deadline']),
    status: Json.str(json['status']),
    statusName: Json.str(json['statusName']),
    isClosed: Json.boolOrNull(json['isClosed']) ?? false,
    isOverdue: Json.boolOrNull(json['isOverdue']) ?? false,
    responsibleUser: Json.str(json['responsibleUser']),
    responsibleUserName: Json.str(json['responsibleUserName']),
    projectName: Json.str(json['projectName']),
  );
}

/// One leave/vacation/work-leaving row on the calendar.
class CalendarLeave {
  const CalendarLeave({
    required this.transNo,
    required this.userId,
    required this.userName,
    required this.kind,
    this.typeName = '',
    this.start,
    this.end,
    this.allDay = false,
    this.status = '',
    this.clients = const <String>[],
    this.isMine = false,
  });

  final String transNo;
  final String userId;
  final String userName;

  /// `"Vacation"` / `"Leaving"` / `"WorkLeaving"`.
  final String kind;
  final String typeName;
  final DateTime? start;
  final DateTime? end;
  final bool allDay;

  /// `"Pending"` / `"Approved"`.
  final String status;
  final List<String> clients;
  final bool isMine;

  factory CalendarLeave.fromJson(Map<String, dynamic> json) => CalendarLeave(
    transNo: Json.str(json['transNo']),
    userId: Json.str(json['userId']),
    userName: Json.str(json['userName']),
    kind: Json.str(json['kind']),
    typeName: Json.str(json['typeName']),
    start: Json.date(json['start']),
    end: Json.date(json['end']),
    allDay: Json.boolOrNull(json['allDay']) ?? false,
    status: Json.str(json['status']),
    clients: (json['clients'] as List?)?.map((Object? e) => e.toString()).toList() ?? const <String>[],
    isMine: Json.boolOrNull(json['isMine']) ?? false,
  );

  bool get isWorkLeaving => kind == 'WorkLeaving';
  bool get isPending => status == 'Pending';
}

/// `GET /api/calendar?from=&to=&teamTasks=` — one call for the month.
class CalendarData {
  const CalendarData({
    this.events = const <CalendarEvent>[],
    this.tasks = const <CalendarTaskDeadline>[],
    this.leaves = const <CalendarLeave>[],
    this.showsTeamLeave = false,
    this.hasTeam = false,
  });

  final List<CalendarEvent> events;
  final List<CalendarTaskDeadline> tasks;
  final List<CalendarLeave> leaves;
  final bool showsTeamLeave;
  final bool hasTeam;

  factory CalendarData.fromJson(Map<String, dynamic> json) => CalendarData(
    events: Json.objects(json['events']).map(CalendarEvent.fromJson).toList(),
    tasks: Json.objects(json['tasks']).map(CalendarTaskDeadline.fromJson).toList(),
    leaves: Json.objects(json['leaves']).map(CalendarLeave.fromJson).toList(),
    showsTeamLeave: Json.boolOrNull(json['showsTeamLeave']) ?? false,
    hasTeam: Json.boolOrNull(json['hasTeam']) ?? false,
  );
}
