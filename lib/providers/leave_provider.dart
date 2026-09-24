import 'package:flutter/foundation.dart';

import '../models/leave_request.dart';
import '../models/system_code.dart';
import '../services/leave_service.dart';
import '../services/system_codes_service.dart';
import 'loadable.dart';

/// §9 leave/vacation requests, with the §8 system codes that drive the
/// Type dropdown.
class LeaveProvider extends ChangeNotifier with Loadable {
  LeaveProvider({
    required LeaveService service,
    required SystemCodesService systemCodesService,
  }) : _service = service,
       _systemCodesService = systemCodesService;

  final LeaveService _service;
  final SystemCodesService _systemCodesService;

  List<LeaveRequest> _requests = const <LeaveRequest>[];
  List<SystemCode> _systemCodes = const <SystemCode>[];
  DateRange _range = DateRange.currentMonth();
  bool _saving = false;
  List<LeaveBalance> _balances = const <LeaveBalance>[];
  bool _balanceLoaded = false;

  List<LeaveRequest> get requests => _requests;
  List<LeaveBalance> get balances => _balances;
  bool get balanceLoaded => _balanceLoaded;
  List<SystemCode> get systemCodes => _systemCodes;
  DateRange get range => _range;
  bool get isSaving => _saving;

  int get pendingCount =>
      _requests.where((LeaveRequest r) => r.isPending).length;

  List<LeaveRequest> ofKind(LeaveKind kind) =>
      _requests.where((LeaveRequest r) => r.kind == kind).toList();

  /// System codes grouped by `sysCodeTypeId`, exactly as the legacy screen
  /// grouped them.
  Map<String, List<SystemCode>> get codesByType {
    final Map<String, List<SystemCode>> grouped = <String, List<SystemCode>>{};
    for (final SystemCode code in _systemCodes) {
      grouped.putIfAbsent(code.sysCodeTypeId, () => <SystemCode>[]).add(code);
    }
    return grouped;
  }

  /// Options for the Type dropdown given the segmented control's position:
  /// only codes whose `sysCodeTypeId` is `LeaveType` (مغادرة) or
  /// `VacationType` (إجازة). Never falls back to the full list — that would
  /// mix leave and vacation types in one dropdown.
  List<SystemCode> typesFor(LeaveKind kind) {
    final String typeId = kind == LeaveKind.leaving
        ? SysCodeType.leaving
        : SysCodeType.vacation;
    return codesByType[typeId] ?? const <SystemCode>[];
  }

  Future<void> load({required String userId, DateRange? range}) {
    if (range != null) _range = range;
    return guard(() async {
      _requests = await _service.list(
        userId: userId,
        fromDate: _range.from,
        toDate: _range.to,
      );
    });
  }

  Future<void> setRange(DateRange range, {required String userId}) {
    _range = range;
    return load(userId: userId);
  }

  Future<void> loadSystemCodes({bool force = false}) async {
    if (_systemCodes.isNotEmpty && !force) return;
    try {
      _systemCodes = await _systemCodesService.list();
      notifyListeners();
    } catch (_) {
      // The dropdown renders its own empty state.
    }
  }

  Future<bool> submit(LeaveCreateRequest request, {required String userId}) async {
    _saving = true;
    notifyListeners();

    final bool ok = await guard(() async {
      await _service.create(request);
      _requests = await _service.list(
        userId: userId,
        fromDate: _range.from,
        toDate: _range.to,
      );
    }, silent: true);

    _saving = false;
    notifyListeners();
    return ok;
  }

  Future<bool> delete(String transNo) async {
    final List<LeaveRequest> previous = _requests;
    _requests = _requests
        .where((LeaveRequest r) => r.transNo != transNo)
        .toList(growable: false);
    notifyListeners();

    final bool ok = await guard(() => _service.delete(transNo), silent: true);
    if (!ok) {
      _requests = previous;
      notifyListeners();
    }
    return ok;
  }

  /// `GET /api/leave/balance` for the current year. Empty means "no quota
  /// configured yet", not an error — failures also land as empty.
  Future<void> loadBalance({required String userId}) async {
    try {
      _balances = await _service.balance(
        userId: userId,
        year: DateTime.now().year,
      );
    } catch (_) {
      _balances = const <LeaveBalance>[];
    } finally {
      _balanceLoaded = true;
      notifyListeners();
    }
  }

  /// Teammates off in the same window. A failed lookup returns empty — the
  /// check is a heads-up and must never stand between the user and submit.
  Future<List<LeaveConflict>> conflictsFor({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      return await _service.conflicts(
        userId: userId,
        fromDate: from,
        toDate: to,
      );
    } catch (_) {
      return const <LeaveConflict>[];
    }
  }

  /// Medical report photo for a sick-leave request.
  Future<bool> uploadAttachment(
    String transNo, {
    required String fileBase64,
    required String contentType,
  }) => guard(
    () => _service.uploadAttachment(
      transNo,
      fileBase64: fileBase64,
      contentType: contentType,
    ),
    silent: true,
  );

  void reset() {
    _requests = const <LeaveRequest>[];
    _balances = const <LeaveBalance>[];
    _balanceLoaded = false;
    _systemCodes = const <SystemCode>[];
    _range = DateRange.currentMonth();
    resetLoadState();
    notifyListeners();
  }
}
