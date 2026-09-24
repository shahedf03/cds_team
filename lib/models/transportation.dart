import '../core/utils/api_formats.dart';

/// A client attached to a daily transaction (`clients[]` in §4).
class TransportationClient {
  const TransportationClient({required this.clientId, required this.clientName});

  final String clientId;
  final String clientName;

  factory TransportationClient.fromJson(Map<String, dynamic> json) =>
      TransportationClient(
        clientId: Json.str(json['clientId']),
        clientName: Json.str(json['clientName']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'clientId': clientId,
    'clientName': clientName,
  };

  @override
  bool operator ==(Object other) =>
      other is TransportationClient && other.clientId == clientId;

  @override
  int get hashCode => clientId.hashCode;
}

/// One daily transaction / expense entry — `GET|POST|PUT /api/transportation`.
///
/// `km` and `totalAmount` come back as strings from the legacy schema; they
/// are kept as strings on the wire and parsed only for display/validation.
class Transportation {
  const Transportation({
    required this.trId,
    required this.trDate,
    required this.userId,
    required this.km,
    required this.notes,
    required this.totalAmount,
    required this.clients,
  });

  final int trId;
  final DateTime? trDate;
  final String userId;
  final String km;
  final String notes;
  final String totalAmount;
  final List<TransportationClient> clients;

  bool get isNew => trId == 0;

  double get kmValue => Json.doubleVal(km);
  double get totalValue => Json.doubleVal(totalAmount);

  factory Transportation.fromJson(Map<String, dynamic> json) => Transportation(
    trId: Json.intVal(json['trId']),
    trDate: Json.date(json['trDate']),
    userId: Json.str(json['userId']),
    km: Json.str(json['km']),
    notes: Json.str(json['notes']),
    totalAmount: Json.str(json['totalAmount']),
    clients: Json.objects(json['clients'])
        .map(TransportationClient.fromJson)
        .toList(),
  );

  /// Body for create and update. The API replaces the whole client list on
  /// update (it does not diff), so `clients` is always sent in full.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'trId': trId,
    'trDate': (trDate ?? DateTime.now()).toIso8601String(),
    'userId': userId,
    'km': km,
    'notes': notes,
    'totalAmount': totalAmount,
    'clients': clients.map((TransportationClient c) => c.toJson()).toList(),
  };

  Transportation copyWith({
    int? trId,
    DateTime? trDate,
    String? userId,
    String? km,
    String? notes,
    String? totalAmount,
    List<TransportationClient>? clients,
  }) => Transportation(
    trId: trId ?? this.trId,
    trDate: trDate ?? this.trDate,
    userId: userId ?? this.userId,
    km: km ?? this.km,
    notes: notes ?? this.notes,
    totalAmount: totalAmount ?? this.totalAmount,
    clients: clients ?? this.clients,
  );

  static Transportation empty(String userId) => Transportation(
    trId: 0,
    trDate: DateTime.now(),
    userId: userId,
    km: '',
    notes: '',
    totalAmount: '',
    clients: const <TransportationClient>[],
  );

  String get dateLabel =>
      trDate == null ? '' : ApiFormats.displayDate.format(trDate!);
}
