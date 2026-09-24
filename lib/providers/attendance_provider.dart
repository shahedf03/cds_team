import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/network/api_exception.dart';
import '../core/storage/session_store.dart';
import '../models/attendance_record.dart';
import '../models/mobile_check_in.dart';
import '../services/attendance_service.dart';
import '../services/device_check_in_service.dart';
import 'loadable.dart';

/// §3 attendance history + §10 fingerprint check-in.
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

  CheckInStatus _checkInStatus = CheckInStatus.idle;
  String? _checkInMessage;
  bool? _withinGeofence;
  DateTime? _checkedInAt;

  TodaySession _today = TodaySession.none;
  DateTime? _todayFetchedAt;

  TodaySession get today => _today;
  bool get hasOpenSession => _today.hasOpenSession;

  /// Server's `elapsedMinutes` plus the time since it was fetched, so the
  /// timer keeps ticking between refreshes without trusting the phone clock
  /// against the server's.
  Duration get sessionElapsed {
    if (!_today.hasOpenSession) return Duration.zero;
    final Duration sinceFetch = _todayFetchedAt == null
        ? Duration.zero
        : DateTime.now().difference(_todayFetchedAt!);
    return Duration(minutes: _today.elapsedMinutes) + sinceFetch;
  }

  List<AttendanceRecord> get records => _records;
  DateRange get range => _range;
  int get lateCount => _records.where((AttendanceRecord r) => r.isLate).length;

  CheckInStatus get checkInStatus => _checkInStatus;
  String? get checkInMessage => _checkInMessage;
  bool? get withinGeofence => _withinGeofence;
  DateTime? get checkedInAt => _checkedInAt;
  bool get isCheckingIn => _checkInStatus == CheckInStatus.working;

  /// Attendance rate over the loaded window, for the Home stat tile.
  int get attendancePercent {
    if (_records.isEmpty) return 0;
    final int present = _records
        .where((AttendanceRecord r) => r.start != null && r.start!.isNotEmpty)
        .length;
    return ((present / _records.length) * 100).round();
  }

  Future<void> load({required String userId, DateRange? range}) {
    if (range != null) _range = range;
    return guard(() async {
      _records = await _service.history(
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

  /// `GET /api/attendance/today` — refreshed on Home load/pull and after
  /// every check-in/out. Failures keep the last known state.
  Future<void> loadToday({required String userId}) async {
    try {
      _today = await _service.today(userId: userId);
      _todayFetchedAt = DateTime.now();
      notifyListeners();
    } on ApiException {
      // The card keeps showing the last known state.
    }
  }

  /// Fingerprint → GPS → `POST /api/attendance/mobile-check-in`.
  Future<void> checkIn({required String userId}) async {
    _setCheckIn(CheckInStatus.working, null);

    try {
      if (!await _device.isBiometricAvailable) {
        _setCheckIn(
          CheckInStatus.failed,
          'No fingerprint is enrolled on this device.',
        );
        return;
      }

      // Never proceed to the network on a failed on-device match.
      final bool verified = await _device.authenticate();
      if (!verified) {
        _setCheckIn(
          CheckInStatus.failed,
          'Fingerprint not recognised. Try again.',
        );
        return;
      }

      final Position position = await _device.currentPosition();
      final String deviceId = await _sessionStore.readDeviceId();

      final MobileCheckInResult result = await _service.mobileCheckIn(
        MobileCheckInRequest(
          userId: userId,
          deviceId: deviceId,
          timestamp: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
          biometricVerified: true,
        ),
      );

      _withinGeofence = result.withinGeofence;
      _checkedInAt = DateTime.now();
      _setCheckIn(CheckInStatus.success, 'Checked in successfully');
    } on LocationException catch (e) {
      _setCheckIn(CheckInStatus.failed, e.message);
    } on ApiException catch (e) {
      // The two documented 400s ("not verified", "already checked in")
      // arrive with their own message — show it as-is.
      _setCheckIn(CheckInStatus.failed, e.message);
    }
    await loadToday(userId: userId);
  }

  /// GPS → `POST /api/attendance/mobile-check-out`.
  Future<void> checkOut({required String userId}) async {
    _setCheckIn(CheckInStatus.working, null);

    try {
      final Position position = await _device.currentPosition();
      await _service.mobileCheckOut(
        MobileCheckOutRequest(
          userId: userId,
          timestamp: DateTime.now(),
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
      _checkedInAt = null;
      _setCheckIn(CheckInStatus.checkedOut, 'Checked out successfully');
    } on LocationException catch (e) {
      _setCheckIn(CheckInStatus.failed, e.message);
    } on ApiException catch (e) {
      // e.g. "No open check-in found to check out from."
      _setCheckIn(CheckInStatus.failed, e.message);
    }
    await loadToday(userId: userId);
  }

  void _setCheckIn(CheckInStatus status, String? message) {
    _checkInStatus = status;
    _checkInMessage = message;
    notifyListeners();
  }

  void resetCheckIn() {
    if (_checkInStatus == CheckInStatus.idle) return;
    _checkInStatus = CheckInStatus.idle;
    _checkInMessage = null;
    notifyListeners();
  }

  void reset() {
    _records = const <AttendanceRecord>[];
    _range = DateRange.currentMonth();
    _checkInStatus = CheckInStatus.idle;
    _checkInMessage = null;
    _withinGeofence = null;
    _checkedInAt = null;
    _today = TodaySession.none;
    _todayFetchedAt = null;
    resetLoadState();
    notifyListeners();
  }
}
