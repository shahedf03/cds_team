import 'dart:typed_data';

import '../core/network/api_client.dart';
import '../core/utils/api_formats.dart';
import '../models/transportation.dart';

/// §4 — daily transaction / expense entry (replaces `op=2/4/5/6`).
class TransportationService {
  TransportationService(this._api);

  final ApiClient _api;

  /// `GET /api/transportation?userId={string}&fromDate=&toDate=`
  Future<List<Transportation>> list({
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/transportation',
      query: <String, dynamic>{
        'userId': userId,
        'fromDate': ApiFormats.toQueryDate(fromDate),
        'toDate': ApiFormats.toQueryDate(toDate),
      },
    );
    return rows.map(Transportation.fromJson).toList()
      ..sort((Transportation a, Transportation b) {
        final DateTime da = a.trDate ?? DateTime(1900);
        final DateTime db = b.trDate ?? DateTime(1900);
        return db.compareTo(da);
      });
  }

  /// `GET /api/transportation/calculate?km=` → `{ km, ratePerKm, totalAmount }`.
  /// Returns `totalAmount` as sent by the server — the rate lives server-side.
  Future<String> calculateTotal(String km) async {
    final dynamic body = await _api.get<dynamic>(
      '/api/transportation/calculate',
      query: <String, dynamic>{'km': km},
    );
    return Json.str(Map<String, dynamic>.from(body as Map)['totalAmount']);
  }

  /// `GET /api/transportation/report?userId=&userName=&fromDate=&toDate=` →
  /// the PDF itself as bytes. Rendered fresh on every call; nothing to
  /// download from a link.
  Future<Uint8List> report({
    required String userId,
    required String userName,
    required DateTime fromDate,
    required DateTime toDate,
  }) => _api.getBytes(
    '/api/transportation/report',
    query: <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'fromDate': ApiFormats.toQueryDate(fromDate),
      'toDate': ApiFormats.toQueryDate(toDate),
    },
  );

  /// `POST /api/transportation` → 201, body is the new `trId` as a raw number.
  Future<int> create(Transportation entry) async {
    final Map<String, dynamic> body = entry.toJson()..remove('trId');
    final dynamic response = await _api.post<dynamic>(
      '/api/transportation',
      data: body,
    );
    return Json.intVal(response);
  }

  /// `PUT /api/transportation/{trId}` → 204.
  ///
  /// The whole `clients` array is sent every time: the API replaces the
  /// transaction's client list wholesale rather than diffing it.
  Future<void> update(Transportation entry) =>
      _api.put<dynamic>('/api/transportation/${entry.trId}', data: entry.toJson());

  /// `DELETE /api/transportation/{trId}` → 204.
  Future<void> delete(int trId) =>
      _api.delete<dynamic>('/api/transportation/$trId');
}
