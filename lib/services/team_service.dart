import '../core/network/api_client.dart';
import '../models/team.dart';

/// §12 — the manager's view of the `Users.Parent` tree. The manager is taken
/// from the token, so neither call sends a user id.
class TeamService {
  TeamService(this._api);

  final ApiClient _api;

  /// `GET /api/team/members` — empty when the caller isn't a manager.
  Future<List<TeamMember>> members() async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/team/members',
    );
    return rows.map(TeamMember.fromJson).toList();
  }

  /// `GET /api/team/attendance-today` — today's punches for the whole team
  /// in one call.
  Future<List<TeamMemberToday>> attendanceToday() async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/team/attendance-today',
    );
    return rows.map(TeamMemberToday.fromJson).toList();
  }
}
