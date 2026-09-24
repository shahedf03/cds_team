import '../core/utils/api_formats.dart';

/// Leaving (مغادرة) vs Vacation (إجازة).
///
/// The API keys off `transType`: `"1"` is Leaving, anything else is Vacation.
enum LeaveKind {
  leaving('1', 'Leaving', 'مغادرة'),
  vacation('2', 'Vacation', 'إجازة');

  const LeaveKind(this.transType, this.labelEn, this.labelAr);

  final String transType;
  final String labelEn;
  final String labelAr;

  static LeaveKind fromTransType(String? value) =>
      value?.trim() == '1' ? LeaveKind.leaving : LeaveKind.vacation;
}

/// One row of `GET /api/leave`.
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
  );

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

  /// مرضية — the only type that takes a medical-report attachment.
  bool get isSickLeave => leavVacTypeName.contains('مرض');

  /// Hours for a leaving, days for a vacation.
  String get durationLabel {
    final double value = Json.doubleVal(duration);
    final String number = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    if (kind == LeaveKind.leaving) {
      return '$number ${value == 1 ? 'hour' : 'hours'}';
    }
    return '$number ${value == 1 ? 'day' : 'days'}';
  }
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
  });

  final LeaveKind kind;
  final String userId;
  final DateTime start;
  final DateTime end;
  final String vacLeaveType;
  final String notes;

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
    };
  }
}
