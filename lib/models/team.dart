import '../core/utils/api_formats.dart';
import '../l10n/gen/app_localizations.dart';
import 'mobile_check_in.dart';

/// One row of `GET /api/team/members` — someone under the logged-in manager
/// in the `Users.Parent` tree (direct and indirect reports).
class TeamMember {
  const TeamMember({
    required this.userId,
    required this.userName,
    this.userPosition = '',
    this.parent = '',
    this.isDirectReport = false,
  });

  final String userId;
  final String userName;
  final String userPosition;

  /// Their own manager's id — the logged-in user for direct reports.
  final String parent;

  /// I'm their direct manager (so I'm also the one who approves their leave).
  final bool isDirectReport;

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    userId: Json.str(json['userId']),
    userName: Json.str(json['userName']),
    userPosition: Json.str(json['userPosition']),
    parent: Json.str(json['parent']),
    isDirectReport: Json.boolOrNull(json['isDirectReport']) ?? false,
  );

  /// Name for lists; the id if the server sent no name.
  String get label => userName.trim().isNotEmpty ? userName.trim() : userId;

  String get initials {
    final List<String> parts = label
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}

/// One row of `GET /api/team/attendance-today`: a member plus the same
/// object `GET /api/attendance/today` returns for them.
class TeamMemberToday {
  const TeamMemberToday({required this.member, required this.today});

  final TeamMember member;
  final TodaySession today;

  factory TeamMemberToday.fromJson(Map<String, dynamic> json) {
    final dynamic today = json['today'];
    return TeamMemberToday(
      member: TeamMember.fromJson(json),
      today: today is Map
          ? TodaySession.fromJson(Map<String, dynamic>.from(today))
          : TodaySession.none,
    );
  }

  bool get hasPunched => today.hasPunchedToday;

  /// The board chip: "Not punched" / "In since 08:23 AM" / "In … — Out …".
  String statusLabel(AppLocalizations t) {
    if (!today.hasPunchedToday) return t.statusNotPunched;
    final String? start = _clock(today.checkInAt);
    if (today.hasOpenSession) {
      return start == null ? t.statusIn : t.statusInSince(start);
    }
    final String? end = _clock(today.lastPunchAt);
    if (start != null && end != null) return t.statusInOut(start, end);
    return start == null ? t.statusIn : t.statusInAt(start);
  }

  static String? _clock(DateTime? value) =>
      value == null ? null : ApiFormats.clockTime.format(value);
}
