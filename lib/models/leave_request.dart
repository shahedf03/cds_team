import '../l10n/gen/app_localizations.dart';
import '../core/utils/api_formats.dart';
import 'transportation.dart';

/// Leaving vs Vacation.
///
/// The API keys off `transType`: `"1"` is Leaving, anything else is Vacation.
enum LeaveKind {
  leaving('1'),
  vacation('2');

  const LeaveKind(this.transType);

  final String transType;

  static LeaveKind fromTransType(String? value) =>
      value?.trim() == '1' ? LeaveKind.leaving : LeaveKind.vacation;

  String label(AppLocalizations t) =>
      this == leaving ? t.leaveKindLeaving : t.leaveKindVacation;
}

/// One row of `GET /api/leave` (my requests) or `GET /api/leave/team` (the
/// manager's inbox — which also fills [userId], [userName] and [notes]).
class LeaveRequest {
  const LeaveRequest({
    required this.transNo,
    required this.fromDateTime,
    required this.toDateTime,
    required this.trStatus,
    required this.leavVacTypeName,
    required this.trTypeName,
    required this.duration,
    required this.transType,
    required this.vacLeaveType,
    this.approvalStatus = '',
    this.approvedBy = '',
    this.rejectReason = '',
    this.userId = '',
    this.userName = '',
    this.notes = '',
    this.canDecide = false,
    this.attachmentCount = 0,
    this.clients = const <TransportationClient>[],
    this.canForward = false,
    this.forwardToName = '',
    this.canWithdraw = false,
    this.pendingWith = '',
    this.pendingWithName = '',
  });

  final String transNo;
  final String fromDateTime;
  final String toDateTime;
  final String trStatus;
  final String leavVacTypeName;
  final String trTypeName;
  final String duration;
  final String transType;
  final String vacLeaveType;

  /// §11 workflow: `Pending` / `Approved` / `Rejected`. Supersedes the old
  /// `trStatus` ("Posted"/"Pending") string when present.
  final String approvalStatus;
  final String approvedBy;
  final String rejectReason;

  /// Requester — only sent by `GET /api/leave/team`.
  final String userId;
  final String userName;
  final String notes;

  /// Only on `GET /api/leave/team`: I'm the requester's direct manager and
  /// it's still Pending. The only thing that shows Approve / Reject.
  final bool canDecide;

  /// Medical report photos on this request (added 2026-09-30). `0` hides
  /// the 📎 badge; `GET /api/leave/{transNo}/attachments` lists them.
  final int attachmentCount;

  /// The client(s) a "work leaving" (مغادرة عمل, `vacLeaveType == "2"`) is
  /// for (part F, 2026-10-05) — same shape as a transportation trip's
  /// `clients[]`. Always empty for every other type/category.
  final List<TransportationClient> clients;

  /// 2026-10-07 — routing via `AttendanceParent ?? Parent`, forwardable up
  /// several levels. Only with [canDecide]: show "Forward to
  /// [forwardToName]".
  final bool canForward;
  final String forwardToName;

  /// The requester's own request, still Pending — shows Withdraw. Replaces
  /// the old `approvalStatus == 'Pending'` heuristic.
  final bool canWithdraw;

  /// Pending only: who has to decide it right now — "بانتظار:
  /// [pendingWithName]".
  final String pendingWith;
  final String pendingWithName;

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
    transNo: Json.str(json['transNo']),
    fromDateTime: Json.str(json['fromDateTime']),
    toDateTime: Json.str(json['toDateTime']),
    trStatus: Json.str(json['trStatus']),
    leavVacTypeName: Json.str(json['leavVacTypeName']),
    trTypeName: Json.str(json['trTypeName']),
    duration: Json.str(json['duration']),
    transType: Json.str(json['transType']),
    vacLeaveType: Json.str(json['vacLeaveType']),
    approvalStatus: Json.str(json['approvalStatus']),
    approvedBy: Json.str(json['approvedBy']),
    rejectReason: Json.str(json['rejectReason']),
    userId: Json.str(json['userId']),
    userName: Json.str(json['userName']),
    notes: Json.str(json['notes']),
    canDecide: Json.boolOrNull(json['canDecide']) ?? false,
    attachmentCount: Json.intVal(json['attachmentCount']),
    clients: Json.objects(json['clients'])
        .map(TransportationClient.fromJson)
        .toList(),
    canForward: Json.boolOrNull(json['canForward']) ?? false,
    forwardToName: Json.str(json['forwardToName']),
    canWithdraw: Json.boolOrNull(json['canWithdraw']) ?? false,
    pendingWith: Json.str(json['pendingWith']),
    pendingWithName: Json.str(json['pendingWithName']),
  );

  /// Local-only bump after a successful upload, so the 📎 badge updates
  /// without a full re-fetch.
  LeaveRequest withOneMoreAttachment() => LeaveRequest(
    transNo: transNo,
    fromDateTime: fromDateTime,
    toDateTime: toDateTime,
    trStatus: trStatus,
    leavVacTypeName: leavVacTypeName,
    trTypeName: trTypeName,
    duration: duration,
    transType: transType,
    vacLeaveType: vacLeaveType,
    approvalStatus: approvalStatus,
    approvedBy: approvedBy,
    rejectReason: rejectReason,
    userId: userId,
    userName: userName,
    notes: notes,
    canDecide: canDecide,
    attachmentCount: attachmentCount + 1,
    clients: clients,
    canForward: canForward,
    forwardToName: forwardToName,
    canWithdraw: canWithdraw,
    pendingWith: pendingWith,
    pendingWithName: pendingWithName,
  );

  bool get hasAttachments => attachmentCount > 0;

  LeaveKind get kind => LeaveKind.fromTransType(transType);

  DateTime? get from => ApiFormats.tryParse(fromDateTime);
  DateTime? get to => ApiFormats.tryParse(toDateTime);

  /// What the status chip shows.
  String get statusLabel =>
      approvalStatus.trim().isNotEmpty ? approvalStatus.trim() : trStatus;

  bool get isPending => statusLabel.toLowerCase().contains('pending');
  bool get isApproved => statusLabel.toLowerCase().contains('approve');
  bool get isRejected =>
      statusLabel.toLowerCase().contains('reject') ||
      statusLabel.toLowerCase().contains('decline');

  /// [statusLabel] translated for display; falls back to the raw server
  /// value for any status the app doesn't specifically recognise.
  String displayStatus(AppLocalizations t) {
    if (isApproved) return t.statusApproved;
    if (isRejected) return t.statusRejected;
    if (isPending) return t.statusPending;
    return statusLabel;
  }

  /// The requester, for the manager's list.
  String get requesterLabel => userName.trim().isNotEmpty ? userName : userId;

  /// "بانتظار: {name}" — only meaningful while [isPending].
  bool get hasPendingWith => pendingWithName.trim().isNotEmpty;

  /// The only type that takes a medical-report attachment. Matched against
  /// the Arabic type name the API sends (`"إجازة مرضية"` — "sick leave"); the
  /// system codes themselves are configured server-side and stay Arabic
  /// regardless of the app's display language, so this literal can't be
  /// translated without a matching backend change.
  bool get isSickLeave => leavVacTypeName.contains('مرض');

  /// Hours for a leaving, days for a vacation.
  String durationLabel(AppLocalizations t) {
    final double value = Json.doubleVal(duration);
    final num count = value == value.roundToDouble() ? value.round() : value;
    return kind == LeaveKind.leaving
        ? t.durationHours(count)
        : t.durationDays(count);
  }
}

/// `approvalStatus` filter on `GET /api/leave/team`.
enum ApprovalFilter {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected'),
  all(null);

  const ApprovalFilter(this.value);

  /// Query value; `null` omits the param.
  final String? value;

  String label(AppLocalizations t) => switch (this) {
    ApprovalFilter.pending => t.statusPending,
    ApprovalFilter.approved => t.statusApproved,
    ApprovalFilter.rejected => t.statusRejected,
    ApprovalFilter.all => t.filterAll,
  };
}

/// One row of `GET /api/leave/balance` — whole-day vacation types only.
class LeaveBalance {
  const LeaveBalance({
    required this.vacLeaveType,
    required this.typeName,
    required this.totalDays,
    required this.usedDays,
    required this.remainingDays,
  });

  final String vacLeaveType;
  final String typeName;
  final double totalDays;
  final double usedDays;
  final double remainingDays;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
    vacLeaveType: Json.str(json['vacLeaveType']),
    typeName: Json.str(json['typeName']),
    totalDays: Json.doubleVal(json['totalDays']),
    usedDays: Json.doubleVal(json['usedDays']),
    remainingDays: Json.doubleVal(json['remainingDays']),
  );
}

/// One row of `GET /api/leave/conflicts` — a teammate off in the same window.
class LeaveConflict {
  const LeaveConflict({
    required this.userId,
    required this.userName,
    required this.fromDateTime,
    required this.toDateTime,
  });

  final String userId;
  final String userName;
  final String fromDateTime;
  final String toDateTime;

  factory LeaveConflict.fromJson(Map<String, dynamic> json) => LeaveConflict(
    userId: Json.str(json['userId']),
    userName: Json.str(json['userName']),
    fromDateTime: Json.str(json['fromDateTime']),
    toDateTime: Json.str(json['toDateTime']),
  );
}

/// Body for `POST /api/leave`.
class LeaveCreateRequest {
  const LeaveCreateRequest({
    required this.kind,
    required this.userId,
    required this.start,
    required this.end,
    required this.vacLeaveType,
    required this.notes,
    this.clientIds = const <String>[],
  });

  final LeaveKind kind;
  final String userId;
  final DateTime start;
  final DateTime end;
  final String vacLeaveType;
  final String notes;

  /// Only for a "work leaving" (مغادرة عمل, part F, 2026-10-05) — the
  /// client(s) the employee is going to. Must stay empty for every other
  /// type/category: the API 400s if `clientIds` is sent anywhere else.
  final List<String> clientIds;

  /// `startDateTime`/`endDateTime` must be `dd-MM-yyyy HH:mm` — the API
  /// 400s on ISO 8601. Vacations are truncated to whole days server-side but
  /// still need a time component, so midnight is sent.
  Map<String, dynamic> toJson() {
    final DateTime startValue = kind == LeaveKind.vacation
        ? DateTime(start.year, start.month, start.day)
        : start;
    final DateTime endValue = kind == LeaveKind.vacation
        ? DateTime(end.year, end.month, end.day)
        : end;

    return <String, dynamic>{
      'transType': kind.transType,
      'userId': userId,
      'startDateTime': ApiFormats.toLeaveDateTime(startValue),
      'endDateTime': ApiFormats.toLeaveDateTime(endValue),
      'vacLeaveType': vacLeaveType,
      'notes': notes,
      if (clientIds.isNotEmpty) 'clientIds': clientIds,
    };
  }
}

/// One row of `GET /api/leave/{transNo}/attachments` (added 2026-09-30) — a
/// medical report photo. `url` is a relative path; fetch it through
/// [LeaveService.attachmentBytes] rather than building the URL by hand so it
/// goes through the same authenticated client as everything else.
class LeaveAttachment {
  const LeaveAttachment({
    required this.id,
    required this.transNo,
    required this.contentType,
    required this.uploadedAt,
    required this.url,
  });

  final String id;
  final String transNo;
  final String contentType;
  final DateTime? uploadedAt;
  final String url;

  factory LeaveAttachment.fromJson(Map<String, dynamic> json) =>
      LeaveAttachment(
        id: Json.str(json['id']),
        transNo: Json.str(json['transNo']),
        contentType: Json.str(json['contentType']),
        uploadedAt: Json.date(json['uploadedAt']),
        url: Json.str(json['url']),
      );
}

/// One entry of a `GET /api/leave/{transNo}` timeline (2026-10-07).
enum LeaveStepAction {
  submitted,
  forwarded,
  approved,
  rejected,
  unknown;

  static LeaveStepAction fromJson(dynamic value) =>
      switch (Json.str(value).toLowerCase()) {
        'submitted' => submitted,
        'forwarded' => forwarded,
        'approved' => approved,
        'rejected' => rejected,
        _ => unknown,
      };
}

/// One row of the `steps` timeline on `GET /api/leave/{transNo}` —
/// `reason` is the rejection reason or the forward note, whichever applies.
class LeaveStep {
  const LeaveStep({
    required this.action,
    required this.byUser,
    required this.byName,
    required this.toUser,
    required this.toName,
    required this.reason,
    required this.actionAt,
  });

  final LeaveStepAction action;
  final String byUser;
  final String byName;
  final String toUser;
  final String toName;
  final String reason;
  final DateTime? actionAt;

  factory LeaveStep.fromJson(Map<String, dynamic> json) => LeaveStep(
    action: LeaveStepAction.fromJson(json['action']),
    byUser: Json.str(json['byUser']),
    byName: Json.str(json['byName']),
    toUser: Json.str(json['toUser']),
    toName: Json.str(json['toName']),
    reason: Json.str(json['reason']),
    actionAt: Json.date(json['actionAt']),
  );

  String get byLabel => byName.trim().isNotEmpty ? byName.trim() : byUser;
  String get toLabel => toName.trim().isNotEmpty ? toName.trim() : toUser;

  String get timeLabel =>
      actionAt == null ? '' : ApiFormats.clockTime.format(actionAt!);
}

/// `GET /api/leave/{transNo}` (2026-10-07) — the request plus its full
/// approval/forward timeline, for the request-detail screen.
class LeaveDetail {
  const LeaveDetail({required this.request, required this.steps});

  final LeaveRequest request;
  final List<LeaveStep> steps;

  factory LeaveDetail.fromJson(Map<String, dynamic> json) => LeaveDetail(
    request: LeaveRequest.fromJson(
      json['request'] is Map
          ? Map<String, dynamic>.from(json['request'] as Map)
          : const <String, dynamic>{},
    ),
    steps: Json.objects(json['steps']).map(LeaveStep.fromJson).toList(),
  );
}
