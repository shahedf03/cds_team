import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/network/api_exception.dart';
import '../core/storage/session_store.dart';
import '../core/utils/api_formats.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/attendance_record.dart';
import '../models/mobile_check_in.dart';
import '../services/attendance_service.dart';
import '../services/device_check_in_service.dart';
import 'loadable.dart';

/// §3 attendance history + §10 one-button fingerprint punch.
///
/// Works like the wall terminal: the day's first punch is Start, every
/// later punch moves End. There is no checked-in/out state on the client —
/// the button always does the same thing.
class AttendanceProvider extends ChangeNotifier with Loadable {
  AttendanceProvider({
    required AttendanceService service,
    required DeviceCheckInService device,
    required SessionStore sessionStore,
  }) : _service = service,
       _device = device,
       _sessionStore = sessionStore;

  final AttendanceService _service;
  final DeviceCheckInService _device;
  final SessionStore _sessionStore;

  List<AttendanceRecord> _records = const <AttendanceRecord>[];
  DateRange _range = DateRange.currentMonth();

  /// The active history tab — بصمة الجهاز / بصمة الموبايل.
  AttendanceSource _source = AttendanceSource.device;

  /// This month's attendance, merged across both sources, for
  /// [attendancePercent] — deliberately **not** [_records]: that list is
  /// scoped to whichever history tab is selected, so a day present only on
  /// the other tab would otherwise make the Home stat swing with the tab the
  /// user last had open, not with their actual attendance.
  List<AttendanceRecord> _monthRecords = const <AttendanceRecord>[];

  PunchStatus _punchStatus = PunchStatus.idle;
  String? _punchMessage;
  PunchResult? _lastResult;

  TodaySession _today = TodaySession.none;
  DateTime? _dayStart;
  DateTime? _dayEnd;
  int _pendingCount = 0;
  bool _flushing = false;

  List<AttendanceRecord> get records => _records;
  DateRange get range => _range;
  AttendanceSource get source => _source;
  int get lateCount => _records.where((AttendanceRecord r) => r.isLate).length;

  PunchStatus get punchStatus => _punchStatus;

  /// What to tell the user about the last punch attempt.
  String? get punchMessage => _punchMessage;
  PunchResult? get lastResult => _lastResult;
  bool get isPunching => _punchStatus == PunchStatus.working;

  TodaySession get today => _today;

  /// Today's Start: earliest phone punch (sent or still queued). Never the
  /// wall terminal. `null` = nothing punched today.
  DateTime? get dayStart => _dayStart;

  /// Today's End: the latest punch, once there are at least two.
  DateTime? get dayEnd => _dayEnd;

  /// One punch so far — the live "since…" timer runs.
  bool get isOpen => _dayStart != null && _dayEnd == null;

  Duration get elapsed => _dayStart == null
      ? Duration.zero
      : (_dayEnd ?? DateTime.now()).difference(_dayStart!);

  /// Verified punches still waiting for the network.
  int get pendingCount => _pendingCount;

  /// Geofence of the most recent punch today.
  bool? get withinGeofence =>
      _lastResult?.withinGeofence ?? _today.withinGeofence;

  /// Attendance rate over the current month, merged across both sources —
  /// the Home stat tile. Independent of whichever history tab is selected.
  int get attendancePercent {
    if (_monthRecords.isEmpty) return 0;
    final int present = _monthRecords
        .where((AttendanceRecord r) => r.start != null && r.start!.isNotEmpty)
        .length;
    return ((present / _monthRecords.length) * 100).round();
  }

  Future<void> load({required String userId, DateRange? range}) {
    if (range != null) _range = range;
    return guard(() async {
      _records = await _service.history(
        userId: userId,
        fromDate: _range.from,
        toDate: _range.to,
        source: _source,
      );
    });
  }

  /// Feeds [attendancePercent] on Home — always the current month, merged
  /// (no `source`), regardless of the history screen's selected tab.
  Future<void> loadMonthSummary({required String userId}) async {
    try {
      final DateRange month = DateRange.currentMonth();
      _monthRecords = await _service.history(
        userId: userId,
        fromDate: month.from,
        toDate: month.to,
      );
      notifyListeners();
    } catch (_) {
      // Keep the last known percentage rather than blanking the tile.
    }
  }

  Future<void> setRange(DateRange range, {required String userId}) {
    _range = range;
    return load(userId: userId);
  }

  /// Switches the بصمة الجهاز / بصمة الموبايل tab and reloads.
  Future<void> setSource(AttendanceSource source, {required String userId}) {
    if (source == _source) return load(userId: userId);
    _source = source;
    return load(userId: userId);
  }

  /// `GET /api/attendance/today` for site/geofence metadata, today's
  /// `source: mobile` history row for Start/End, and any queued phone
  /// punches. Refreshed on Home load/pull, on app resume, and after every
  /// punch. Sends queued punches first.
  Future<void> loadToday({required String userId}) async {
    await flushQueue(userId: userId);

    final DateTime now = DateTime.now();
    final DateTime todayDate = DateTime(now.year, now.month, now.day);
    final List<DateTime> punches = <DateTime>[];
    void addIfToday(DateTime? value) {
      if (value != null && _isSameDay(value, todayDate)) punches.add(value);
    }

    try {
      _today = await _service.today(userId: userId);
    } on ApiException {
      // Keep the last known site/geofence metadata.
    }

    // `/api/attendance/today` blends in the wall terminal (confirmed: its
    // checkInAt can predate the "By Mobile" tab's Start for the same day),
    // so Start/End on Home are read from the same `source: mobile` history
    // query that tab uses instead — never from `_today` or the unfiltered
    // (merged) history.
    try {
      final List<AttendanceRecord> rows = await _service.history(
        userId: userId,
        fromDate: todayDate,
        toDate: todayDate,
        source: AttendanceSource.mobile,
      );
      for (final AttendanceRecord row in rows) {
        addIfToday(row.startedAt);
        addIfToday(row.endedAt);
      }
    } on ApiException {
      // Queued punches below still count even if this fails.
    }

    // Punches the server hasn't seen yet still count on the card.
    for (final MobilePunchRequest p in await _pending(userId)) {
      addIfToday(p.timestamp.toLocal());
    }

    punches.sort();
    _dayStart = punches.isEmpty ? null : punches.first;
    // A single punch can show up twice (e.g. queued and then sent).
    _dayEnd =
        punches.length > 1 &&
            punches.last.difference(punches.first).inMinutes > 0
        ? punches.last
        : null;
    notifyListeners();
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Can't verify (offline, or the endpoint failed) → an empty list, which
  /// [punch] reads as "nothing configured to check against" rather than
  /// blocking a punch it has no way to confirm.
  Future<List<Site>> _fetchSites() async {
    try {
      return await _service.sites();
    } on ApiException {
      return const <Site>[];
    }
  }

  static bool _isWithinAnySite(Position position, List<Site> sites) {
    for (final Site site in sites) {
      final double distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        site.latitude,
        site.longitude,
      );
      if (distanceMeters <= site.radiusMeters) return true;
    }
    return false;
  }

  /// Fingerprint → GPS → `POST /api/attendance/mobile-punch`. Offline, the
  /// verified punch is queued with its original timestamp.
  Future<void> punch({
    required String userId,
    required AppLocalizations t,
  }) async {
    _setPunch(PunchStatus.working, null);

    MobilePunchRequest? request;
    try {
      // Never proceed to the network on a failed on-device match.
      if (!await _device.isBiometricAvailable) {
        _setPunch(PunchStatus.failed, t.appNoFingerprintEnrolled);
        return;
      }
      if (!await _device.authenticate(reason: t.appConfirmFingerprintReason)) {
        _setPunch(PunchStatus.failed, t.appFingerprintNotRecognised);
        return;
      }

      final DateTime at = DateTime.now();
      final Position position = await _device.currentPosition();

      // Configured sites are a hard stop: a verified fingerprint outside
      // every one of them never reaches the server. No sites configured yet
      // (or the list couldn't be fetched, e.g. offline) means there's
      // nothing to check against, so the punch proceeds as before.
      final List<Site> sites = await _fetchSites();
      if (sites.isNotEmpty && !_isWithinAnySite(position, sites)) {
        _setPunch(PunchStatus.failed, t.appOutsideWorkSiteBlocked);
        return;
      }

      request = MobilePunchRequest(
        userId: userId,
        deviceId: await _sessionStore.readDeviceId(),
        timestamp: at,
        latitude: position.latitude,
        longitude: position.longitude,
        biometricVerified: true,
      );

      // The server decides In/Out from phone punches only — it never sees
      // the wall terminal. Refresh first so a terminal punch earlier today
      // makes this one read as an exit. (Also sends any queued punches
      // ahead of this one, keeping them in order.)
      await loadToday(userId: userId);
      final bool afterEarlierPunch =
          _dayStart != null &&
          _isSameDay(_dayStart!, at) &&
          at.difference(_dayStart!).inMinutes > 0;

      final PunchResult result = await _service.mobilePunch(request);
      _lastResult = result;
      _setPunch(
        PunchStatus.success,
        describe(result, t, afterEarlierPunch: afterEarlierPunch),
      );
    } on LocationException catch (e) {
      _setPunch(PunchStatus.failed, e.message);
    } on ApiException catch (e) {
      if (e.isNetworkError && request != null) {
        await _enqueue(request);
        _setPunch(PunchStatus.queued, t.appNoConnectionPunchQueued);
      } else {
        // The documented 400 ("not verified") carries its own message.
        _setPunch(PunchStatus.failed, e.message);
      }
    }
    await loadToday(userId: userId);
  }

  /// "Checked in 09:15 AM" / "Checked out 05:02 PM".
  ///
  /// [afterEarlierPunch]: the user already punched today (e.g. on the wall
  /// terminal), so this is an exit even if the server — which only counts
  /// phone punches — calls it the first `In`.
  ///
  /// No outside-geofence case to describe here any more (§H, 2026-10-05):
  /// the server now rejects a punch outside every site with a `400` instead
  /// of saving it — that 400 is surfaced as-is from [punch]'s `ApiException`
  /// handler, so a call that reaches this point was always inside one.
  static String describe(
    PunchResult result,
    AppLocalizations t, {
    bool afterEarlierPunch = false,
  }) {
    final bool isOut =
        result.punchType == PunchType.punchOut || afterEarlierPunch;
    // On a server-side `In`, the only time it recorded is firstPunchAt.
    final DateTime? at = result.recordedAt ?? result.firstPunchAt;
    final String time = at == null ? '' : ' ${ApiFormats.clockTime.format(at)}';
    return isOut ? t.appCheckedOut(time) : t.appCheckedIn(time);
  }

  /// Sends this user's queued punches, oldest first. Stops at the first
  /// network failure; the server never moves End backwards, so a late
  /// older punch is safe to send.
  Future<void> flushQueue({required String userId}) async {
    if (_flushing) return;
    _flushing = true;
    try {
      final List<Map<String, dynamic>> all = await _sessionStore
          .readPendingPunches();
      final List<Map<String, dynamic>> keep = <Map<String, dynamic>>[];
      bool offline = false;
      // §H (2026-10-05): a queue punch can now come back rejected (outside
      // every site) instead of succeeding — dropped like any other 4xx, but
      // the user needs to be told why, not just have it vanish silently.
      String? droppedMessage;

      for (final Map<String, dynamic> json in all) {
        final MobilePunchRequest p = MobilePunchRequest.fromJson(json);
        // Another account's punches wait for that account's token.
        if (offline || p.userId != userId) {
          keep.add(json);
          continue;
        }
        try {
          await _service.mobilePunch(p);
        } on ApiException catch (e) {
          if (e.isNetworkError || e.isServerError) {
            offline = true;
            keep.add(json);
          } else {
            // A 4xx will never succeed on retry — drop it.
            droppedMessage = e.message;
          }
        }
      }

      if (keep.length != all.length) {
        await _sessionStore.savePendingPunches(keep);
      }
      _pendingCount = keep
          .where((Map<String, dynamic> j) => Json.str(j['userId']) == userId)
          .length;

      if (droppedMessage != null) {
        _setPunch(PunchStatus.failed, droppedMessage);
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _enqueue(MobilePunchRequest request) async {
    final List<Map<String, dynamic>> all = await _sessionStore
        .readPendingPunches();
    all.add(request.toJson());
    await _sessionStore.savePendingPunches(all);
  }

  Future<List<MobilePunchRequest>> _pending(String userId) async {
    final List<MobilePunchRequest> mine =
        (await _sessionStore.readPendingPunches())
            .map(MobilePunchRequest.fromJson)
            .where((MobilePunchRequest p) => p.userId == userId)
            .toList();
    _pendingCount = mine.length;
    return mine;
  }

  void _setPunch(PunchStatus status, String? message) {
    _punchStatus = status;
    _punchMessage = message;
    notifyListeners();
  }

  void reset() {
    _records = const <AttendanceRecord>[];
    _monthRecords = const <AttendanceRecord>[];
    _range = DateRange.currentMonth();
    _source = AttendanceSource.device;
    _punchStatus = PunchStatus.idle;
    _punchMessage = null;
    _lastResult = null;
    _today = TodaySession.none;
    _dayStart = null;
    _dayEnd = null;
    _pendingCount = 0;
    resetLoadState();
    notifyListeners();
  }
}
