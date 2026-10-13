import '../core/network/api_client.dart';
import '../core/utils/api_formats.dart';
import '../models/project.dart';

/// 2026-10-08 part D — projects split into sprints.
class ProjectsService {
  ProjectsService(this._api);

  final ApiClient _api;

  Future<List<ProjectSummary>> list() async {
    final List<Map<String, dynamic>> rows = await _api.getList('/api/projects');
    return rows.map(ProjectSummary.fromJson).toList();
  }

  Future<ProjectDetail> detail(String code) async {
    final dynamic body = await _api.get<dynamic>('/api/projects/$code');
    return ProjectDetail.fromJson(
      body is Map ? Map<String, dynamic>.from(body) : const <String, dynamic>{},
    );
  }

  /// `GET /api/projects/sprints?projectCode=` — sprints only, for a picker.
  /// Omit [projectCode] for all.
  Future<List<Sprint>> sprints({String? projectCode}) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/projects/sprints',
      query: projectCode == null ? null : <String, dynamic>{'projectCode': projectCode},
    );
    return rows.map(Sprint.fromJson).toList();
  }

  /// `403` unless [ProjectDetail.canManage].
  Future<int> createSprint({
    required String projectCode,
    required String name,
    String? goal,
    required DateTime startDate,
    required DateTime endDate,
  }) => _api.post<dynamic>(
    '/api/projects/sprints',
    data: <String, dynamic>{
      'projectCode': projectCode,
      'name': name,
      'goal': goal,
      'startDate': ApiFormats.toQueryDate(startDate),
      'endDate': ApiFormats.toQueryDate(endDate),
    },
  ).then((dynamic id) => id is int ? id : int.parse(id.toString()));

  Future<void> updateSprint({
    required int id,
    required String projectCode,
    required String name,
    String? goal,
    required DateTime startDate,
    required DateTime endDate,
  }) => _api.put<dynamic>(
    '/api/projects/sprints/$id',
    data: <String, dynamic>{
      'projectCode': projectCode,
      'name': name,
      'goal': goal,
      'startDate': ApiFormats.toQueryDate(startDate),
      'endDate': ApiFormats.toQueryDate(endDate),
    },
  );

  /// Its tasks stay in the project, outside any sprint.
  Future<void> deleteSprint(int id) => _api.delete<dynamic>('/api/projects/sprints/$id');
}
