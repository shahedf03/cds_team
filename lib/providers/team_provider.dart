import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/team.dart';
import '../services/team_service.dart';
import 'loadable.dart';

/// §12 — who is under the logged-in manager, and today's punch board.
///
/// [hasTeam] (a non-empty members list) is the one switch for everything
/// manager-only: the "My team" tab and "Team requests".
class TeamProvider extends ChangeNotifier with Loadable {
  TeamProvider({required TeamService service}) : _service = service;

  final TeamService _service;

  List<TeamMember> _members = const <TeamMember>[];
  List<TeamMemberToday> _board = const <TeamMemberToday>[];

  List<TeamMember> get members => _members;
  List<TeamMemberToday> get board => _board;

  /// Empty list = not a manager: hide everything team-related.
  bool get hasTeam => _members.isNotEmpty;

  /// id → name, for the employee picker on "Team requests".
  Map<String, String> get employees => <String, String>{
    for (final TeamMember m in _members) m.userId: m.label,
  };

  int get punchedCount =>
      _board.where((TeamMemberToday e) => e.hasPunched).length;

  /// After login and on app resume. A failed call keeps the last known list
  /// rather than hiding the team tab over a dropped connection.
  Future<void> loadMembers() async {
    try {
      _members = await _service.members();
    } on ApiException {
      // keep what we have
    }
    notifyListeners();
  }

  /// The "My team" board.
  Future<void> loadBoard() => guard(() async {
    _board = await _service.attendanceToday();
  });

  void reset() {
    _members = const <TeamMember>[];
    _board = const <TeamMemberToday>[];
    resetLoadState();
    notifyListeners();
  }
}
