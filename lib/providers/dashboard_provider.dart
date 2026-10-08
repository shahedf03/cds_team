import 'package:flutter/foundation.dart';

import '../models/dashboard.dart';
import '../services/dashboard_service.dart';
import 'loadable.dart';

/// 2026-10-05 — the Home screen, from the single `GET /api/dashboard` call.
class DashboardProvider extends ChangeNotifier with Loadable {
  DashboardProvider({required DashboardService service}) : _service = service;

  final DashboardService _service;

  DashboardDto? _data;
  DateTime? _loadedAt;

  DashboardDto? get data => _data;
  DateTime? get loadedAt => _loadedAt;

  Future<void> load() => guard(() async {
    _data = await _service.load();
    _loadedAt = DateTime.now();
  });

  void reset() {
    _data = null;
    _loadedAt = null;
    resetLoadState();
    notifyListeners();
  }
}
