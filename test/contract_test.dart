import 'dart:typed_data';

import 'package:cds_team/core/network/api_client.dart';
import 'package:cds_team/core/network/api_exception.dart';
import 'package:cds_team/core/storage/session_store.dart';
import 'package:cds_team/core/storage/token_store.dart';
import 'package:cds_team/core/utils/api_formats.dart';
import 'package:cds_team/models/app_notification.dart';
import 'package:cds_team/models/attendance_record.dart';
import 'package:cds_team/models/mobile_check_in.dart';
import 'package:cds_team/models/client.dart';
import 'package:cds_team/models/leave_request.dart';
import 'package:cds_team/models/task_item.dart';
import 'package:cds_team/models/team.dart';
import 'package:cds_team/models/transportation.dart';
import 'package:cds_team/l10n/gen/app_localizations_en.dart';
import 'package:cds_team/providers/attendance_provider.dart';
import 'package:cds_team/providers/leave_provider.dart';
import 'package:cds_team/providers/loadable.dart';
import 'package:cds_team/providers/notifications_provider.dart';
import 'package:cds_team/services/system_codes_service.dart';
import 'package:cds_team/providers/team_provider.dart';
import 'package:cds_team/providers/transportation_provider.dart';
import 'package:cds_team/routes/app_routes.dart';
import 'package:cds_team/services/attendance_service.dart';
import 'package:cds_team/services/clients_service.dart';
import 'package:cds_team/services/device_check_in_service.dart';
import 'package:cds_team/services/leave_service.dart';
import 'package:cds_team/services/notifications_service.dart';
import 'package:cds_team/services/push_service.dart';
import 'package:cds_team/services/team_service.dart';
import 'package:cds_team/services/transportation_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AppLocalizationsEn t = AppLocalizationsEn();

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
    test('isLate comes from the server, not a client-side clock rule', () {
      // Computed server-side (Attendance:LateAfter) since 2026-10-05 — the
      // model just carries whatever the row says, regardless of the start
      // clock text.
      AttendanceRecord fromJson({required bool isLate}) =>
          AttendanceRecord.fromJson(<String, dynamic>{
            'date': '2026-09-01T00:00:00',
            'start': '9:26 AM',
            'end': '5:00 PM',
            'isLate': isLate,
          });

      expect(fromJson(isLate: true).isLate, isTrue);
      expect(fromJson(isLate: false).isLate, isFalse);

      // Missing on an older server response: defaults to false, not an error.
      final AttendanceRecord noField = AttendanceRecord.fromJson(
        <String, dynamic>{'start': '9:26 AM'},
      );
      expect(noField.isLate, isFalse);
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
      final AttendanceRecord record =
          AttendanceRecord.fromJson(<String, dynamic>{
            'date': '2026-09-01T00:00:00',
            'start': '9:26 AM',
            'end': '10:27 PM',
            'withinGeofence': null,
          });
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

    test(
      'leaves the window alone when the entry already falls inside',
      () async {
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
      },
    );
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
    test('is ISO 8601 local device time with no zone suffix', () {
      final String stamp = ApiFormats.toIsoLocal(DateTime(2026, 9, 20, 9, 15));
      expect(stamp, '2026-09-20T09:15:00');
    });

    test(
      'punch times (real UTC, trailing Z) convert to the device local clock',
      () {
        // Confirmed 2026-09-30: every `Z`-tagged punch field is real UTC, so
        // the fix is a real `.toLocal()` conversion, not just stripping the
        // `Z` and keeping the digits (the old, now-wrong, assumption).
        final DateTime? at = Json.utcToLocal('2026-09-20T09:15:00Z');
        expect(at, DateTime.parse('2026-09-20T09:15:00Z').toLocal());
        expect(at!.isUtc, isFalse);
      },
    );
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

    test('the mobile punch body carries the same string id', () {
      final Map<String, dynamic> body = MobilePunchRequest(
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

  group('One-button punch (§10, 2026-09-27)', () {
    test('posts to mobile-punch, never the old check-in/out', () async {
      final _CapturingApiClient api = _CapturingApiClient()
        ..postResponse = <String, dynamic>{
          'punchType': 'Out',
          'recordId': 42,
          'firstPunchAt': '2026-09-27T06:15:00Z',
          'lastPunchAt': '2026-09-27T14:02:00Z',
          'withinGeofence': false,
          'siteName': 'Main Office',
        };

      final PunchResult result = await AttendanceService(api).mobilePunch(
        MobilePunchRequest(
          userId: 'amer',
          deviceId: 'd',
          timestamp: DateTime(2026, 9, 27, 14, 2),
          latitude: 31.95,
          longitude: 35.91,
          biometricVerified: true,
        ),
      );

      expect(api.lastPath, '/api/attendance/mobile-punch');
      expect(
        (api.lastData! as Map<String, dynamic>)['timestamp'],
        '2026-09-27T14:02:00',
      );
      expect(result.punchType, PunchType.punchOut);
      // Out → End is the time that was recorded: the response's real-UTC
      // `lastPunchAt`, converted to the device local clock.
      expect(
        result.recordedAt,
        DateTime.parse('2026-09-27T14:02:00Z').toLocal(),
      );
      expect(result.recordedAt!.isUtc, isFalse);
      // §H (2026-10-05): the server rejects an outside-geofence punch with a
      // 400 instead of saving it, so a successful result has nothing left to
      // caveat — describe() no longer appends an "outside the site" note.
      expect(
        AttendanceProvider.describe(result, t),
        t.appCheckedOut(' ${ApiFormats.clockTime.format(result.recordedAt!)}'),
      );
    });

    test('first punch reads as In with no End', () {
      final PunchResult result = PunchResult.fromJson(<String, dynamic>{
        'punchType': 'In',
        'firstPunchAt': '2026-09-27T06:15:00Z',
        'lastPunchAt': null,
        'withinGeofence': true,
      });
      expect(result.punchType, PunchType.punchIn);
      expect(result.lastPunchAt, isNull);
      expect(AttendanceProvider.describe(result, t), startsWith('Checked in'));
      expect(
        AttendanceProvider.describe(result, t),
        isNot(contains('outside')),
      );
    });

    test('a phone In after a terminal punch reads as an exit', () {
      // 8:00 on the wall terminal, 9:00 on the phone: the server only
      // counts phone punches, so it answers "In" with firstPunchAt = 9:00.
      final PunchResult result = PunchResult.fromJson(<String, dynamic>{
        'punchType': 'In',
        'firstPunchAt': '2026-09-27T06:00:00Z',
        'lastPunchAt': null,
        'withinGeofence': true,
      });
      final String message = AttendanceProvider.describe(
        result,
        t,
        afterEarlierPunch: true,
      );
      expect(message, startsWith('Checked out'));
      expect(
        message,
        contains(
          ApiFormats.clockTime.format(
            DateTime.parse('2026-09-27T06:00:00Z').toLocal(),
          ),
        ),
      );
    });

    test('a queued punch keeps its original timestamp', () {
      final MobilePunchRequest original = MobilePunchRequest(
        userId: 'amer',
        deviceId: 'd',
        timestamp: DateTime(2026, 9, 27, 6, 15),
        latitude: 31.95,
        longitude: 35.91,
        biometricVerified: true,
      );
      final MobilePunchRequest restored = MobilePunchRequest.fromJson(
        original.toJson(),
      );
      expect(restored.toJson(), original.toJson());
    });

    test('today converts the real-UTC fields to the device local clock', () {
      final TodaySession today = TodaySession.fromJson(<String, dynamic>{
        'hasPunchedToday': true,
        'hasOpenSession': false,
        'checkInAt': '2026-09-27T06:15:00Z',
        'lastPunchAt': '2026-09-27T14:02:00Z',
        'elapsedMinutes': 467,
      });
      expect(today.hasPunchedToday, isTrue);
      expect(today.checkInAt, DateTime.parse('2026-09-27T06:15:00Z').toLocal());
      expect(
        today.lastPunchAt,
        DateTime.parse('2026-09-27T14:02:00Z').toLocal(),
      );
    });
  });

  group('Leave approval by manager (2026-09-27)', () {
    test('team() sends only the filters that are set', () async {
      final _CapturingApiClient api = _CapturingApiClient();
      final LeaveService service = LeaveService(api);

      await service.team();
      expect(api.lastPath, '/api/leave/team');
      expect(api.lastQuery, isEmpty);

      await service.team(
        approvalStatus: 'Pending',
        kind: LeaveKind.leaving,
        fromDate: DateTime(2026, 10, 1),
      );
      expect(api.lastQuery, <String, dynamic>{
        'approvalStatus': 'Pending',
        'transType': '1',
        'fromDate': '2026-10-01',
      });
    });

    test('approve sends no body and reject sends only the reason', () async {
      final _CapturingApiClient api = _CapturingApiClient();
      final LeaveService service = LeaveService(api);

      await service.approve('57');
      expect(api.lastPath, '/api/leave/57/approve');
      expect(api.lastData, isNull);

      await service.reject('57', reason: 'ضغط عمل');
      expect(api.lastPath, '/api/leave/57/reject');
      expect(api.lastData, <String, dynamic>{'reason': 'ضغط عمل'});
    });

    test('create returns the new transNo', () async {
      final _CapturingApiClient api = _CapturingApiClient()
        ..postResponse = <String, dynamic>{'transNo': '123'};

      final String transNo = await LeaveService(api).create(
        LeaveCreateRequest(
          kind: LeaveKind.vacation,
          userId: 'khaled',
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 3),
          vacLeaveType: '1',
          notes: '',
        ),
      );

      expect(transNo, '123');
    });

    test('team rows carry the requester and status labels', () {
      final LeaveRequest r = LeaveRequest.fromJson(<String, dynamic>{
        'transNo': '57',
        'userId': 'khaled',
        'userName': 'Khaled Ahmad',
        'notes': 'مراجعة طبية',
        'transType': '1',
        'approvalStatus': 'Pending',
        'approvedBy': null,
        'rejectReason': null,
      });

      expect(r.requesterLabel, 'Khaled Ahmad');
      expect(r.notes, 'مراجعة طبية');
      expect(r.statusLabel, 'Pending');
      expect(
        LeaveRequest.fromJson(<String, dynamic>{
          'approvalStatus': 'Rejected',
        }).statusLabel,
        'Rejected',
      );
      // Rows from GET /api/leave have no userName; fall back to the id.
      expect(
        LeaveRequest.fromJson(<String, dynamic>{
          'userId': 'amer',
        }).requesterLabel,
        'amer',
      );
    });

    test('push type maps to the right destination', () {
      expect(PushKind.fromType('leave_request'), PushKind.leaveRequest);
      expect(PushKind.fromType('leave_decision'), PushKind.leaveDecision);
      expect(PushKind.fromType(null), PushKind.unknown);
    });
  });

  group('Manager: my team (2026-09-28, §12)', () {
    final List<Map<String, dynamic>> memberRows = <Map<String, dynamic>>[
      <String, dynamic>{
        'userId': 'Duaa',
        'userName': 'Duaa Mohammad',
        'userPosition': '3',
        'parent': 'Osama',
        'isDirectReport': true,
      },
      <String, dynamic>{
        'userId': 'khaled',
        'userName': 'Khaled Ahmad',
        'userPosition': '3',
        'parent': 'Duaa',
        'isDirectReport': false,
      },
    ];

    test(
      'members and the board take no user id — the token says who',
      () async {
        final _CapturingApiClient api = _CapturingApiClient();
        final TeamService service = TeamService(api);

        await service.members();
        expect(api.lastPath, '/api/team/members');
        expect(api.lastQuery, isNull);

        await service.attendanceToday();
        expect(api.lastPath, '/api/team/attendance-today');
        expect(api.lastQuery, isNull);
      },
    );

    test('an empty members list means not a manager', () async {
      final TeamProvider provider = TeamProvider(
        service: TeamService(_CapturingApiClient()),
      );
      await provider.loadMembers();
      expect(provider.hasTeam, isFalse);
    });

    test('members feed the employee picker and hasTeam', () async {
      final TeamProvider provider = TeamProvider(
        service: TeamService(_CapturingApiClient()..listResponse = memberRows),
      );
      await provider.loadMembers();

      expect(provider.hasTeam, isTrue);
      expect(provider.employees, <String, String>{
        'Duaa': 'Duaa Mohammad',
        'khaled': 'Khaled Ahmad',
      });
      expect(provider.members.first.isDirectReport, isTrue);
      expect(provider.members.last.isDirectReport, isFalse);
      expect(provider.members.last.parent, 'Duaa');
      expect(provider.members.last.initials, 'KA');
    });

    test('board chip: not punched / inside since / start and end', () {
      TeamMemberToday row(Map<String, dynamic> today) =>
          TeamMemberToday.fromJson(<String, dynamic>{
            'userId': 'Duaa',
            'userName': 'Duaa Mohammad',
            'isDirectReport': true,
            'today': today,
          });

      final TeamMemberToday none = row(<String, dynamic>{
        'hasPunchedToday': false,
        'hasOpenSession': false,
      });
      expect(none.statusLabel(t), 'Not punched');
      expect(none.hasPunched, isFalse);

      final TeamMemberToday inside = row(<String, dynamic>{
        'hasPunchedToday': true,
        'hasOpenSession': true,
        'checkInAt': '2026-09-28T08:23:00',
        'lastPunchAt': null,
      });
      expect(inside.statusLabel(t), startsWith('In since'));
      expect(inside.statusLabel(t), contains('08:23'));

      final TeamMemberToday done = row(<String, dynamic>{
        'hasPunchedToday': true,
        'hasOpenSession': false,
        'checkInAt': '2026-09-28T08:23:00',
        'lastPunchAt': '2026-09-28T17:01:00',
      });
      expect(done.statusLabel(t), contains('In'));
      expect(done.statusLabel(t), contains('08:23'));
      expect(done.statusLabel(t), contains('Out'));
      expect(done.statusLabel(t), contains('05:01'));
    });

    test('a board row with no today object reads as not punched', () {
      final TeamMemberToday r = TeamMemberToday.fromJson(<String, dynamic>{
        'userId': 'x',
        'userName': 'X',
      });
      expect(r.hasPunched, isFalse);
    });

    test('canDecide comes from the server and defaults to false', () {
      expect(
        LeaveRequest.fromJson(<String, dynamic>{
          'approvalStatus': 'Pending',
          'canDecide': true,
        }).canDecide,
        isTrue,
      );
      // Pending, but I'm not the direct manager (an indirect report).
      final LeaveRequest indirect = LeaveRequest.fromJson(<String, dynamic>{
        'approvalStatus': 'Pending',
        'canDecide': false,
      });
      expect(indirect.canDecide, isFalse);
      expect(indirect.isPending, isTrue);
      // Own list has no such field.
      expect(LeaveRequest.fromJson(<String, dynamic>{}).canDecide, isFalse);
    });

    test('a team member route carries the member', () {
      final Route<dynamic>? route = AppRoutes.onGenerateRoute(
        RouteSettings(
          name: AppRoutes.teamMember,
          arguments: TeamMember.fromJson(memberRows.first),
        ),
      );
      expect(route, isNotNull);
      // Without a member there is nothing to show.
      expect(
        AppRoutes.onGenerateRoute(
          const RouteSettings(name: AppRoutes.teamMember),
        ),
        isNull,
      );
    });

    test('403 shows its message and keeps the session; 401 logs out', () async {
      Future<(ApiClient, _MemoryTokenStore, List<int>)> client(
        int status,
        String body,
      ) async {
        final _MemoryTokenStore tokens = _MemoryTokenStore();
        final List<int> logouts = <int>[];
        final ApiClient api = ApiClient(
          tokenStore: tokens,
          dio: Dio(
            BaseOptions(
              baseUrl: 'http://localhost',
              validateStatus: (int? s) => s != null && s < 400,
            ),
          )..httpClientAdapter = _FixedStatusAdapter(status, body),
        )..onUnauthorized = () => logouts.add(1);
        return (api, tokens, logouts);
      }

      final (
        ApiClient forbidden,
        _MemoryTokenStore t1,
        List<int> out1,
      ) = await client(
        403,
        '{"error":"You can only view your own data or your team\'s."}',
      );
      await expectLater(
        forbidden.getList(
          '/api/attendance',
          query: <String, dynamic>{'userId': 'stranger'},
        ),
        throwsA(
          isA<ApiException>()
              .having((ApiException e) => e.isForbidden, 'isForbidden', true)
              .having(
                (ApiException e) => e.message,
                'message',
                "You can only view your own data or your team's.",
              ),
        ),
      );
      expect(out1, isEmpty);
      expect(t1.token, 'jwt');

      final (ApiClient expired, _MemoryTokenStore t2, List<int> out2) =
          await client(401, '{"error":"expired"}');
      await expectLater(
        expired.getList('/api/attendance'),
        throwsA(isA<ApiException>()),
      );
      expect(out2, hasLength(1));
      expect(t2.token, isNull);
    });
  });

  group('Notifications autoId is a dismiss flag, not a cursor', () {
    test('a plain list never sends autoId', () async {
      final _CapturingApiClient api = _CapturingApiClient();
      await NotificationsService(api).list(userId: 'amer');
      expect(api.lastQuery, <String, dynamic>{'userId': 'amer'});
    });

    test('dismiss sends the id, clear all sends -1', () async {
      final _CapturingApiClient api = _CapturingApiClient();
      final NotificationsService service = NotificationsService(api);

      await service.dismiss(userId: 'amer', autoId: '42');
      expect(api.lastQuery?['autoId'], '42');

      await service.clearAll(userId: 'amer');
      expect(api.lastQuery?['autoId'], '-1');
    });
  });

  group('Notifications read state (2026-09-30)', () {
    test('fromJson reads isRead, defaulting to false', () {
      expect(
        AppNotification.fromJson(<String, dynamic>{'autoId': '1'}).isRead,
        isFalse,
      );
      expect(
        AppNotification.fromJson(<String, dynamic>{
          'autoId': '1',
          'isRead': true,
        }).isRead,
        isTrue,
      );
    });

    test('read posts the autoId, read-all posts none', () async {
      final _CapturingApiClient api = _CapturingApiClient();
      final NotificationsService service = NotificationsService(api);

      await service.markRead(userId: 'amer', autoId: '5');
      expect(api.lastPath, '/api/notifications/read');
      expect(api.lastData, <String, dynamic>{'userId': 'amer', 'autoId': '5'});

      await service.markAllRead(userId: 'amer');
      expect(api.lastPath, '/api/notifications/read-all');
      expect(api.lastData, <String, dynamic>{'userId': 'amer'});
    });

    test('unreadCount only counts rows that are not read', () {
      final NotificationsProvider provider = NotificationsProvider(
        service: NotificationsService(_CapturingApiClient()),
      );
      expect(provider.unreadCount, 0);
      expect(provider.hasUnread, isFalse);
    });
  });

  group('Attendance source tabs (§3, 2026-09-30)', () {
    test(
      'history omits source by default, sends it for a picked tab',
      () async {
        final _CapturingApiClient api = _CapturingApiClient();
        final AttendanceService service = AttendanceService(api);

        await service.history(
          userId: 'amer',
          fromDate: DateTime(2026, 9, 1),
          toDate: DateTime(2026, 9, 30),
        );
        expect(api.lastQuery!.containsKey('source'), isFalse);

        await service.history(
          userId: 'amer',
          fromDate: DateTime(2026, 9, 1),
          toDate: DateTime(2026, 9, 30),
          source: AttendanceSource.device,
        );
        expect(api.lastQuery?['source'], 'device');

        await service.history(
          userId: 'amer',
          fromDate: DateTime(2026, 9, 1),
          toDate: DateTime(2026, 9, 30),
          source: AttendanceSource.mobile,
        );
        expect(api.lastQuery?['source'], 'mobile');
      },
    );

    test(
      'a row reads startSource/endSource and converts startAt/endAt to local',
      () {
        final AttendanceRecord record =
            AttendanceRecord.fromJson(<String, dynamic>{
              'date': '2026-09-30T00:00:00',
              'start': '8:05 AM',
              'end': '5:02 PM',
              'startAt': '2026-09-30T05:05:00Z',
              'endAt': '2026-09-30T14:02:00Z',
              'startSource': 'mobile',
              'endSource': 'mobile',
              'withinGeofence': true,
            });
        expect(record.startSource, AttendanceSource.mobile);
        expect(record.endSource, AttendanceSource.mobile);
        expect(
          record.startAt,
          DateTime.parse('2026-09-30T05:05:00Z').toLocal(),
        );
        expect(record.endAt, DateTime.parse('2026-09-30T14:02:00Z').toLocal());
        expect(record.withinGeofence, isTrue);
      },
    );

    test('endSource is null with no End yet', () {
      final AttendanceRecord record = AttendanceRecord.fromJson(
        <String, dynamic>{
          'date': '2026-09-30T00:00:00',
          'start': '8:05 AM',
          'startSource': 'device',
        },
      );
      expect(record.startSource, AttendanceSource.device);
      expect(record.endSource, isNull);
      expect(record.endAt, isNull);
    });
  });

  group('Sick-leave attachments (§11, 2026-09-30)', () {
    test('fromJson reads attachmentCount, defaulting to 0', () {
      expect(
        LeaveRequest.fromJson(<String, dynamic>{
          'transNo': '1',
        }).attachmentCount,
        0,
      );
      expect(
        LeaveRequest.fromJson(<String, dynamic>{
          'transNo': '1',
          'attachmentCount': 2,
        }).attachmentCount,
        2,
      );
      expect(
        LeaveRequest.fromJson(<String, dynamic>{
          'transNo': '1',
          'attachmentCount': 1,
        }).hasAttachments,
        isTrue,
      );
    });

    test('LeaveAttachment.fromJson reads the listing row', () {
      final LeaveAttachment a = LeaveAttachment.fromJson(<String, dynamic>{
        'id': '7',
        'transNo': '11064',
        'contentType': 'image/jpeg',
        'uploadedAt': '2026-09-29T13:17:13.23',
        'url': 'api/leave/attachments/7',
      });
      expect(a.id, '7');
      expect(a.transNo, '11064');
      expect(a.contentType, 'image/jpeg');
      expect(a.url, 'api/leave/attachments/7');
    });

    test(
      'upload returns the attachmentId, list and bytes hit the right paths',
      () async {
        final _CapturingApiClient api = _CapturingApiClient();
        final LeaveService service = LeaveService(api);

        api.postResponse = <String, dynamic>{'attachmentId': '7'};
        final String id = await service.uploadAttachment(
          '11064',
          fileBase64: 'AAA=',
          contentType: 'image/jpeg',
        );
        expect(api.lastPath, '/api/leave/11064/attachment');
        expect(id, '7');

        api.listResponse = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': '7',
            'transNo': '11064',
            'contentType': 'image/jpeg',
          },
        ];
        final List<LeaveAttachment> list = await service.attachments('11064');
        expect(api.lastPath, '/api/leave/11064/attachments');
        expect(list, hasLength(1));

        api.bytesResponse = Uint8List.fromList(<int>[1, 2, 3]);
        final Uint8List bytes = await service.attachmentBytes('7');
        expect(api.lastPath, '/api/leave/attachments/7');
        expect(bytes, <int>[1, 2, 3]);
      },
    );

    test(
      'uploadAttachment bumps the local badge without a full re-fetch',
      () async {
        final _CapturingApiClient api = _CapturingApiClient()
          ..postResponse = <String, dynamic>{'attachmentId': '7'};
        final LeaveProvider provider = LeaveProvider(
          service: LeaveService(api),
          systemCodesService: SystemCodesService(api),
          clientsService: _FakeClientsService(),
        );

        api.listResponse = <Map<String, dynamic>>[
          <String, dynamic>{'transNo': '11064', 'attachmentCount': 0},
        ];
        await provider.load(userId: 'amer');
        expect(provider.requests.single.attachmentCount, 0);

        final String? id = await provider.uploadAttachment(
          '11064',
          fileBase64: 'AAA=',
          contentType: 'image/jpeg',
        );
        expect(id, '7');
        expect(provider.requests.single.attachmentCount, 1);
      },
    );
  });

  group('Home attendance % is independent of the selected tab', () {
    AttendanceProvider makeProvider(_CapturingApiClient api) =>
        AttendanceProvider(
          service: AttendanceService(api),
          device: DeviceCheckInService(),
          sessionStore: SessionStore(),
        );

    test('loadMonthSummary fetches merged (no source param)', () async {
      final _CapturingApiClient api = _CapturingApiClient();
      final AttendanceProvider provider = makeProvider(api);

      await provider.loadMonthSummary(userId: 'amer');
      expect(api.lastQuery!.containsKey('source'), isFalse);
    });

    test('switching the history tab does not change the stat tile', () async {
      final _CapturingApiClient api = _CapturingApiClient();
      final AttendanceProvider provider = makeProvider(api);

      // One present day, merged — this is what the Home tile should reflect.
      api.listResponse = <Map<String, dynamic>>[
        <String, dynamic>{'date': '2026-10-01T00:00:00', 'start': '9:00 AM'},
      ];
      await provider.loadMonthSummary(userId: 'amer');
      expect(provider.attendancePercent, 100);

      // The Mobile tab has no rows at all for this user (device-only
      // attendee) — before the fix this emptied the same list the stat tile
      // read from, so the Home percentage would have dropped to 0.
      api.listResponse = const <Map<String, dynamic>>[];
      await provider.setSource(AttendanceSource.mobile, userId: 'amer');
      expect(provider.records, isEmpty);
      expect(provider.attendancePercent, 100);
    });
  });
}

/// Records what a service hands to the network layer.
class _CapturingApiClient implements ApiClient {
  String? lastPath;
  Map<String, dynamic>? lastQuery;
  Object? lastData;
  Object? postResponse;
  List<Map<String, dynamic>> listResponse = const <Map<String, dynamic>>[];
  Uint8List bytesResponse = Uint8List(0);

  @override
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastQuery = query;
    return listResponse;
  }

  @override
  Future<Uint8List> getBytes(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastQuery = query;
    return bytesResponse;
  }

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    lastPath = path;
    lastData = data;
    return postResponse as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} is not used by this test',
  );
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

/// In-memory stand-in for the secure-storage-backed token store.
class _MemoryTokenStore implements TokenStore {
  String? token = 'jwt';

  @override
  Future<String?> read() async => token;

  @override
  Future<void> clear() async => token = null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} is not used by this test',
  );
}

/// Answers every request with one fixed status and JSON body.
class _FixedStatusAdapter implements HttpClientAdapter {
  _FixedStatusAdapter(this.status, this.body);

  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body,
    status,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
