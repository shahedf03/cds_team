import '../core/network/api_client.dart';
import '../models/system_code.dart';

/// §8 — `GET /api/system-codes` (replaces `op=12`). Drives the Type dropdown
/// on the Leave screen; grouped client-side by `sysCodeTypeId`.
class SystemCodesService {
  SystemCodesService(this._api);

  final ApiClient _api;

  Future<List<SystemCode>> list() async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/system-codes',
    );
    return rows.map(SystemCode.fromJson).toList();
  }
}
