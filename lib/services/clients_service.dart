import '../core/network/api_client.dart';
import '../models/client.dart';

/// §5 — `GET /api/clients` (replaces `op=3`). Feeds the "+ Add Client"
/// picker; nothing in the app keeps a hardcoded client list anymore.
class ClientsService {
  ClientsService(this._api);

  final ApiClient _api;

  Future<List<Client>> list() async {
    final List<Map<String, dynamic>> rows = await _api.getList('/api/clients');
    return rows.map(Client.fromJson).toList()
      ..sort((Client a, Client b) => a.name.compareTo(b.name));
  }
}
