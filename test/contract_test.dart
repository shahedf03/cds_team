import 'dart:typed_data';

import 'package:cds_team/core/network/api_client.dart';
import 'package:cds_team/core/utils/api_formats.dart';
import 'package:cds_team/models/attendance_record.dart';
import 'package:cds_team/models/mobile_check_in.dart';
import 'package:cds_team/models/client.dart';
import 'package:cds_team/models/leave_request.dart';
import 'package:cds_team/models/task_item.dart';
import 'package:cds_team/models/transportation.dart';
import 'package:cds_team/providers/loadable.dart';
import 'package:cds_team/providers/transportation_provider.dart';
import 'package:cds_team/routes/app_routes.dart';
import 'package:cds_team/services/attendance_service.dart';
import 'package:cds_team/services/clients_service.dart';
import 'package:cds_team/services/transportation_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Leave date format (§9)', () {
    test('sends dd-MM-yyyy HH:mm, never ISO 8601', () {
      final Map<String, dynamic> body = LeaveCreateRequest(
        kind: LeaveKind.leaving,
        userId: 'amer',
        start: DateTime(2026, 9, 20, 9),
        end: DateTime(2026, 9, 20, 17),
        vacLeaveType: '1',
        notes: '',
      ).toJson();

      expect(body['startDateTime'], '20-09-2026 09:00');
      expect(body['endDateTime'], '20-09-2026 17:00');
      expect(body['transType'], '1');
    });

    test('vacation truncates to whole days but keeps a time component', () {
      final Map<String, dynamic> body = LeaveCreateRequest(
        kind: LeaveKind.vacation,
        userId: 'amer',
        start: DateTime(2026, 9, 20, 14, 30),
        end: DateTime(2026, 9, 24, 18, 45),
        vacLeaveType: '2',
        notes: '',
      ).toJson();

      expect(body['startDateTime'], '20-09-2026 00:00');
      expect(body['endDateTime'], '24-09-2026 00:00');
      expect(body['transType'], isNot('1'));
    });

    test('transType "1" is Leaving, anything else is Vacation', () {
      expect(LeaveKind.fromTransType('1'), LeaveKind.leaving);
      expect(LeaveKind.fromTransType('2'), LeaveKind.vacation);
      expect(LeaveKind.fromTransType(null), LeaveKind.vacation);
    });
  });

  group('Attendance (§3)', () {
    test('parses the server clock format and flags late starts', () {
      AttendanceRecord at(String start) => AttendanceRecord(
        date: DateTime(2026, 9, 1),
        start: start,
        end: '5:00 PM',
      );

      expect(at('9:26 AM').isLate, isTrue);
      expect(at('8:42 AM').isLate, isFalse);
      expect(at('12:05 PM').isLate, isTrue);
      expect(at('12:00 AM').isLate, isFalse);
    });

    test('a missing start is not late and renders a dash', () {
      const AttendanceRecord record = AttendanceRecord(
        date: null,
        start: null,
        end: null,
      );
      expect(record.isLate, isFalse);
      expect(record.startLabel, '—');
    });

    test('withinGeofence stays null for terminal records', () {
      final AttendanceRecord record = AttendanceRecord.fromJson(
        <String, dynamic>{
          'date': '2026-09-01T00:00:00',
          'start': '9:26 AM',
          'end': '10:27 PM',
          'withinGeofence': null,
        },
      );
      expect(record.withinGeofence, isNull);
      expect(record.date, DateTime(2026, 9, 1));
    });
  });

  group('Transportation (§4)', () {
    test('create payload drops trId and keeps the full client list', () {
      const Transportation entry = Transportation(
        trId: 0,
        trDate: null,
        userId: 'amer',
        km: '22',
        notes: '',
        totalAmount: '3.3',
        clients: <TransportationClient>[
          TransportationClient(clientId: '10', clientName: 'سامسونج'),
        ],
      );

      final Map<String, dynamic> body = entry.toJson()..remove('trId');
      expect(body.containsKey('trId'), isFalse);
      expect((body['clients'] as List<dynamic>).length, 1);
      expect(entry.totalValue, 3.3);
      expect(entry.isNew, isTrue);
    });

    test('parses string-typed numbers from the legacy schema', () {
      final Transportation entry = Transportation.fromJson(<String, dynamic>{
        'trId': 123,
        'trDate': '2026-09-20T00:00:00',
        'userId': 'amer',
        'km': '22',
        'notes': '',
        'totalAmount': '3.3',
        'clients': <dynamic>[
          <String, dynamic>{'clientId': '10', 'clientName': 'سامسونج'},
        ],
      });

      expect(entry.trId, 123);
      expect(entry.kmValue, 22);
      expect(entry.clients.single.clientName, 'سامسونج');
      expect(entry.isNew, isFalse);
    });
  });

  group('Daily expenses editor route (§4)', () {
    // The screen pushes it with `pushNamed<bool>`, and Navigator casts
    // whatever onGenerateRoute returns to `Route<bool?>`. An untyped route
    // is a `Route<dynamic>`, which fails that cast and crashes the tap.
    test('is typed so pushNamed<bool> can cast it', () {
      final Route<dynamic>? route = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.transportationEditor),
      );

      expect(route, isA<Route<bool?>>());
    });

    test('still accepts a null argument for a new entry', () {
      final Route<dynamic>? route = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.transportationEditor),
      );

      expect(route, isNotNull);
      expect(route!.settings.arguments, isNull);
    });
  });

  group('Daily expenses range (§4)', () {
    Transportation entryOn(DateTime date) => Transportation(
      trId: 0,
      trDate: date,
      userId: 'amer',
      km: '10',
      notes: '',
      totalAmount: '5',
      clients: const <TransportationClient>[],
    );

    test('widens the window so a saved entry is never hidden', () async {
      final _FakeTransportationService service = _FakeTransportationService();
      final TransportationProvider provider = TransportationProvider(
        service: service,
        clientsService: _FakeClientsService(),
      );

      await provider.setRange(
        DateRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30)),
        userId: 'amer',
      );

      // Dated two months out — outside the open window.
      await provider.save(entryOn(DateTime(2026, 11, 14)), userId: 'amer');

      expect(provider.range.from, DateTime(2026, 9, 1));
      expect(provider.range.to, DateTime(2026, 11, 14));
      expect(service.lastToDate, DateTime(2026, 11, 14));
    });

    test('leaves the window alone when the entry already falls inside', () async {
      final _FakeTransportationService service = _FakeTransportationService();
      final TransportationProvider provider = TransportationProvider(
        service: service,
        clientsService: _FakeClientsService(),
      );

      await provider.setRange(
        DateRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30)),
        userId: 'amer',
      );

      await provider.save(entryOn(DateTime(2026, 9, 14)), userId: 'amer');

      expect(provider.range.from, DateTime(2026, 9, 1));
      expect(provider.range.to, DateTime(2026, 9, 30));
    });
  });

  group('Json coercion (mixed userId typing, §11)', () {
    test('reads ints whether they arrive as int or string', () {
      expect(Json.intVal(123), 123);
      expect(Json.intVal('123'), 123);
      expect(Json.intVal(null), 0);
      expect(Json.intVal('not a number'), 0);
    });

    test('reads booleans from 0/1 and true/false', () {
      expect(Json.boolOrNull(true), isTrue);
      expect(Json.boolOrNull('1'), isTrue);
      expect(Json.boolOrNull('false'), isFalse);
      expect(Json.boolOrNull(null), isNull);
    });
  });

  group('Tasks (§6)', () {
    test('groups by project name', () {
      final List<TaskItem> tasks = <TaskItem>[
        TaskItem.fromJson(<String, dynamic>{
          'taskId': '1',
          'taskProjectName': 'OSFA',
          'taskStatusName': 'In Progress',
          'taskTitle': 'Naqi',
          'taskDescription': '',
          'taskDeadLine': '2025-11-10T00:00:00',
          'clientName': 'مياه نقي - السعودية',
        }),
        TaskItem.fromJson(<String, dynamic>{
          'taskId': '2',
          'taskProjectName': 'OSFA',
          'taskStatusName': 'Done',
          'taskTitle': 'Report',
          'taskDescription': '',
          'taskDeadLine': null,
          'clientName': '',
        }),
        TaskItem.fromJson(<String, dynamic>{
          'taskId': '3',
          'taskProjectName': 'CMMS',
          'taskStatusName': 'Open',
          'taskTitle': 'Mapping',
          'taskDescription': '',
          'taskDeadLine': null,
          'clientName': 'Saudi Facilities',
        }),
      ];

      final List<TaskProject> projects = TaskProject.groupByProject(tasks);
      expect(projects.length, 2);

      final TaskProject osfa = projects.firstWhere(
        (TaskProject p) => p.name == 'OSFA',
      );
      expect(osfa.tasks.length, 2);
      expect(osfa.doneCount, 1);
      expect(osfa.clientName, 'مياه نقي - السعودية');
    });
  });

  group('Check-in timestamp (§10)', () {
    test('is ISO 8601 in UTC with a Z suffix', () {
      final String stamp = ApiFormats.toIsoUtc(
        DateTime.utc(2026, 9, 20, 9, 15),
      );
      expect(stamp, '2026-09-20T09:15:00Z');
    });
  });

  group('Attendance userId (§3)', () {
    // Regression: userId used to be coerced with Json.intVal, so a login name
    // like "Amani" became 0 and every history request came back empty.
    test('sends the login name verbatim, never a numeric coercion', () async {
      final _CapturingApiClient api = _CapturingApiClient();

      await AttendanceService(api).history(
        userId: 'Amani',
        fromDate: DateTime(2026, 9, 1),
        toDate: DateTime(2026, 9, 30),
      );

      expect(api.lastQuery?['userId'], 'Amani');
      expect(api.lastQuery?['userId'], isNot(0));
      expect(api.lastQuery?['fromDate'], '2026-09-01');
      expect(api.lastQuery?['toDate'], '2026-09-30');
    });

    test('the mobile check-in body carries the same string id', () {
      final Map<String, dynamic> body = MobileCheckInRequest(
        userId: 'Amani',
        deviceId: 'test-device',
        timestamp: DateTime.utc(2026, 9, 20, 9, 15),
        latitude: 31.95,
        longitude: 35.93,
        biometricVerified: true,
      ).toJson();

      expect(body['userId'], 'Amani');
    });
  });
}

/// Records the query map [AttendanceService] hands to the network layer.
class _CapturingApiClient implements ApiClient {
  Map<String, dynamic>? lastQuery;

  @override
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    lastQuery = query;
    return const <Map<String, dynamic>>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} is not used by this test');
}

/// Records the window `list` was asked for, so the range tests can assert
/// what the provider actually re-fetched after a save.
class _FakeTransportationService implements TransportationService {
  DateTime? lastFromDate;
  DateTime? lastToDate;

  @override
  Future<List<Transportation>> list({
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    lastFromDate = fromDate;
    lastToDate = toDate;
    return const <Transportation>[];
  }

  @override
  Future<int> create(Transportation entry) async => 1;

  @override
  Future<void> update(Transportation entry) async {}

  @override
  Future<void> delete(int trId) async {}

  @override
  Future<String> calculateTotal(String km) async => '0.00';

  @override
  Future<Uint8List> report({
    required String userId,
    required String userName,
    required DateTime fromDate,
    required DateTime toDate,
  }) async => Uint8List(0);
}

class _FakeClientsService implements ClientsService {
  @override
  Future<List<Client>> list() async => const <Client>[];
}
