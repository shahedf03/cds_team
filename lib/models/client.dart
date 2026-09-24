import '../core/utils/api_formats.dart';
import 'transportation.dart';

/// `GET /api/clients` → `[{ "id": "10", "name": "سامسونج" }]`
class Client {
  const Client({required this.id, required this.name});

  final String id;
  final String name;

  factory Client.fromJson(Map<String, dynamic> json) =>
      Client(id: Json.str(json['id']), name: Json.str(json['name']));

  /// Shape used inside a transportation entry's `clients[]`.
  TransportationClient toTransportationClient() =>
      TransportationClient(clientId: id, clientName: name);

  @override
  bool operator ==(Object other) => other is Client && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
