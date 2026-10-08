import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/leave_request.dart';
import '../services/leave_service.dart';
import 'loadable.dart';

/// Result of an approve/reject, mapped from the documented status codes.
enum DecisionOutcome {
  /// 204 — done, the employee has been notified.
  done,

  /// 403 — not this employee's direct manager.
  forbidden,

  /// 400 — someone already approved/rejected it.
  alreadyDecided,

  /// 404 — the request was deleted.
  notFound,

  /// Network / 5xx.
  failed,
}

/// §11 — "Team requests": the manager's inbox from `GET /api/leave/team`,
/// covering the whole team tree. The server resolves the manager from the
/// token, so no user id goes up; the employee picker comes from
/// [TeamProvider].
class TeamLeaveProvider extends ChangeNotifier with Loadable {
  TeamLeaveProvider({required LeaveService service}) : _service = service;

  final LeaveService _service;

  List<LeaveRequest> _requests = const <LeaveRequest>[];
  ApprovalFilter _status = ApprovalFilter.pending;
  LeaveKind? _kind;
  DateRange? _range;
  String? _employeeId;
  final Set<String> _deciding = <String>{};

  List<LeaveRequest> get requests => _requests;
  ApprovalFilter get status => _status;

  /// `null` = both kinds.
  LeaveKind? get kind => _kind;
  DateRange? get range => _range;
  String? get employeeId => _employeeId;

  bool isDeciding(String transNo) => _deciding.contains(transNo);

  int get pendingCount =>
      _requests.where((LeaveRequest r) => r.isPending).length;

  Future<void> load() => guard(() async {
    _requests = await _service.team(
      approvalStatus: _status.value,
      kind: _kind,
      userId: _employeeId,
      fromDate: _range?.from,
      toDate: _range?.to,
    );
  });

  Future<void> setStatus(ApprovalFilter value) {
    _status = value;
    return load();
  }

  Future<void> setKind(LeaveKind? value) {
    _kind = value;
    return load();
  }

  Future<void> setRange(DateRange? value) {
    _range = value;
    return load();
  }

  Future<void> setEmployee(String? value) {
    _employeeId = value;
    return load();
  }

  Future<(DecisionOutcome, String?)> approve(String transNo) =>
      _decide(transNo, () => _service.approve(transNo));

  Future<(DecisionOutcome, String?)> reject(
    String transNo, {
    required String reason,
  }) => _decide(transNo, () => _service.reject(transNo, reason: reason));

  /// 2026-10-07 — only with `canDecide` + `canForward`.
  Future<(DecisionOutcome, String?)> forward(
    String transNo, {
    String? note,
  }) => _decide(transNo, () => _service.forward(transNo, note: note));

  /// Runs the call, then always refreshes — on success to drop the row from
  /// the Pending view, on 400/404 because the list is stale.
  Future<(DecisionOutcome, String?)> _decide(
    String transNo,
    Future<void> Function() call,
  ) async {
    _deciding.add(transNo);
    notifyListeners();

    DecisionOutcome outcome;
    String? message;
    try {
      await call();
      outcome = DecisionOutcome.done;
    } on ApiException catch (e) {
      message = e.message;
      if (e.isForbidden) {
        outcome = DecisionOutcome.forbidden;
      } else if (e.isBadRequest) {
        outcome = DecisionOutcome.alreadyDecided;
      } else if (e.isNotFound) {
        outcome = DecisionOutcome.notFound;
      } else {
        outcome = DecisionOutcome.failed;
      }
    } finally {
      _deciding.remove(transNo);
    }

    if (outcome != DecisionOutcome.forbidden &&
        outcome != DecisionOutcome.failed) {
      await load();
    } else {
      notifyListeners();
    }
    return (outcome, message);
  }

  void reset() {
    _requests = const <LeaveRequest>[];
    _status = ApprovalFilter.pending;
    _kind = null;
    _range = null;
    _employeeId = null;
    _deciding.clear();
    resetLoadState();
    notifyListeners();
  }
}
