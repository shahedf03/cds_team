import '../core/network/api_client.dart';
import '../core/utils/api_formats.dart';
import '../models/calendar_event.dart';

/// 2026-10-08 part E — month calendar: events, task deadlines and leave.
class CalendarService {
  CalendarService(this._api);

  final ApiClient _api;

  /// At most 120 days between [from] and [to].
  Future<CalendarData> load({
    required DateTime from,
    required DateTime to,
    bool teamTasks = false,
  }) async {
    final dynamic body = await _api.get<dynamic>(
      '/api/calendar',
      query: <String, dynamic>{
        'from': ApiFormats.toQueryDate(from),
        'to': ApiFormats.toQueryDate(to),
        'teamTasks': teamTasks,
      },
    );
    return CalendarData.fromJson(
      body is Map ? Map<String, dynamic>.from(body) : const <String, dynamic>{},
    );
  }

  Future<List<CalendarPerson>> people() async {
    final List<Map<String, dynamic>> rows = await _api.getList('/api/calendar/people');
    return rows.map(CalendarPerson.fromJson).toList();
  }

  /// `403` unless the caller created it or is on it.
  Future<CalendarEvent> event(int id) async {
    final dynamic body = await _api.get<dynamic>('/api/calendar/events/$id');
    return CalendarEvent.fromJson(
      body is Map ? Map<String, dynamic>.from(body) : const <String, dynamic>{},
    );
  }

  Future<int> createEvent({
    required String title,
    String? description,
    String? location,
    required bool allDay,
    required DateTime start,
    required DateTime end,
    required List<String> attendees,
  }) => _api
      .post<dynamic>('/api/calendar/events', data: _body(title, description, location, allDay, start, end, attendees))
      .then((dynamic id) => id is int ? id : int.parse(id.toString()));

  /// Creator only.
  Future<void> updateEvent({
    required int id,
    required String title,
    String? description,
    String? location,
    required bool allDay,
    required DateTime start,
    required DateTime end,
    required List<String> attendees,
  }) => _api.put<dynamic>(
    '/api/calendar/events/$id',
    data: _body(title, description, location, allDay, start, end, attendees),
  );

  /// Creator only.
  Future<void> deleteEvent(int id) => _api.delete<dynamic>('/api/calendar/events/$id');

  Map<String, dynamic> _body(
    String title,
    String? description,
    String? location,
    bool allDay,
    DateTime start,
    DateTime end,
    List<String> attendees,
  ) => <String, dynamic>{
    'title': title,
    'description': description,
    'location': location,
    'allDay': allDay,
    'start': allDay ? ApiFormats.toQueryDate(start) : start.toIso8601String(),
    'end': allDay ? ApiFormats.toQueryDate(end) : end.toIso8601String(),
    'attendees': attendees,
  };
}
