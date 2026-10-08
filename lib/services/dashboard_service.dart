import '../core/network/api_client.dart';
import '../models/dashboard.dart';

/// 2026-10-05 — `GET /api/dashboard`, one call for the whole Home screen.
class DashboardService {
  DashboardService(this._api);

  final ApiClient _api;

  Future<DashboardDto> load() async {
    final dynamic body = await _api.get<dynamic>('/api/dashboard');
    return DashboardDto.fromJson(
      body is Map ? Map<String, dynamic>.from(body) : const <String, dynamic>{},
    );
  }
}
