import 'package:flutter/foundation.dart';

import '../models/client.dart';
import '../models/leave_request.dart';
import '../models/system_code.dart';
import '../services/clients_service.dart';
import '../services/leave_service.dart';
import '../services/system_codes_service.dart';
import 'loadable.dart';

/// §9 leave/vacation requests, with the §8 system codes that drive the
/// Type dropdown and the §5 client list for a "work leaving"'s client(s).
class LeaveProvider extends ChangeNotifier with Loadable {
  LeaveProvider({
    required LeaveService service,
    required SystemCodesService systemCodesService,
    required ClientsService clientsService,
  }) : _service = service,
       _systemCodesService = systemCodesService,
       _clientsService = clientsService;

  final LeaveService _service;
  final SystemCodesService _systemCodesService;
  final ClientsService _clientsService;

  List<LeaveRequest> _requests = const <LeaveRequest>[];
  List<SystemCode> _systemCodes = const <SystemCode>[];
  List<Client> _clients = const <Client>[];
  DateRange _range = DateRange.currentMonth();
  bool _saving = false;
  bool _loadingClients = false;
  List<LeaveBalance> _balances = const <LeaveBalance>[];
  bool _balanceLoaded = false;

  List<LeaveRequest> get requests => _requests;
  List<LeaveBalance> get balances => _balances;
  bool get balanceLoaded => _balanceLoaded;
  List<SystemCode> get systemCodes => _systemCodes;
  List<Client> get clients => _clients;
  bool get isLoadingClients => _loadingClients;
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
  /// only codes whose `sysCodeTypeId` is `LeaveType` or `VacationType`.
  /// Never falls back to the full list — that would mix leave and vacation
  /// types in one dropdown.
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

  /// "+ إضافة" picker source on the work-leaving client field (part F).
  /// Cached after the first successful fetch.
  Future<void> loadClients({bool force = false}) async {
    if (_clients.isNotEmpty && !force) return;
    _loadingClients = true;
    notifyListeners();
    try {
      _clients = await _clientsService.list();
    } catch (_) {
      // The picker shows its own empty/retry state; don't blow up the screen.
    } finally {
      _loadingClients = false;
      notifyListeners();
    }
  }

  /// Returns the new request's `transNo` (`''` if the server sent none), or
  /// `null` on failure with [error] set.
  Future<String?> submit(
    LeaveCreateRequest request, {
    required String userId,
  }) async {
    _saving = true;
    notifyListeners();

    String transNo = '';
    final bool ok = await guard(() async {
      transNo = await _service.create(request);
      _requests = await _service.list(
        userId: userId,
        fromDate: _range.from,
        toDate: _range.to,
      );
    }, silent: true);

    _saving = false;
    notifyListeners();
    return ok ? transNo : null;
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

  /// Medical report photo for a sick-leave request. Returns the new
  /// `attachmentId` (never empty on success — a genuinely empty string from
  /// the server still counts as success, guard's `ok` is what matters), or
  /// `null` on failure with [error] set — never swallowed.
  Future<String?> uploadAttachment(
    String transNo, {
    required String fileBase64,
    required String contentType,
  }) async {
    String attachmentId = '';
    final bool ok = await guard(() async {
      attachmentId = await _service.uploadAttachment(
        transNo,
        fileBase64: fileBase64,
        contentType: contentType,
      );
    }, silent: true);
    if (!ok) return null;

    // Bumps the 📎 badge immediately without a full re-fetch.
    _requests = <LeaveRequest>[
      for (final LeaveRequest r in _requests)
        if (r.transNo == transNo) r.withOneMoreAttachment() else r,
    ];
    notifyListeners();
    return attachmentId;
  }

  void reset() {
    _requests = const <LeaveRequest>[];
    _balances = const <LeaveBalance>[];
    _balanceLoaded = false;
    _systemCodes = const <SystemCode>[];
    _clients = const <Client>[];
    _range = DateRange.currentMonth();
    resetLoadState();
    notifyListeners();
  }
}
