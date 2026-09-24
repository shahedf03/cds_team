# CDS Team — Workforce App

Internal Flutter app for Cloud Data Solutions: attendance, daily expenses,
tasks, leave requests and notifications.

It talks to **CdsTeam_Api** (JWT-authenticated REST, JSON in/out). Nothing in
this codebase calls the legacy `Home.aspx?op=...` endpoints.

---

## Running it

The API base URL is injected at build time, so dev and prod are swappable
without touching code:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:5170
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

It defaults to `http://localhost:5170` if the define is omitted. Swagger lives
at `<base>/swagger`.

Debug builds allow cleartext HTTP on Android so the local API works over plain
`http`. Release builds do not.

---

## Endpoint map

| Section | Endpoint | Code |
| --- | --- | --- |
| Auth | `POST /api/auth/login` | `services/auth_service.dart` |
| Attendance history | `GET /api/attendance` | `services/attendance_service.dart` |
| Daily expenses | `GET POST PUT DELETE /api/transportation` | `services/transportation_service.dart` |
| Clients | `GET /api/clients` | `services/clients_service.dart` |
| Tasks | `GET /api/tasks` | `services/tasks_service.dart` |
| Notifications | `GET /api/notifications` | `services/notifications_service.dart` |
| System codes | `GET /api/system-codes` | `services/system_codes_service.dart` |
| Leave / vacation | `GET POST DELETE /api/leave` | `services/leave_service.dart` |
| Mobile check-in | `POST /api/attendance/mobile-check-in` | `services/attendance_service.dart` |

---

## Layout

```
lib/
  core/       config, theme, networking, storage, formatting
  models/     one class per API DTO, field names matching the JSON
  services/   one class per endpoint group, no UI concerns
  providers/  ChangeNotifier state per feature
  views/      screens and shared widgets
  routes/     named routes and the global navigator key
```

---

## Things that will bite you if changed

**The JWT is in `flutter_secure_storage`, never `SharedPreferences`.**
`SessionStore` holds only the non-sensitive user row.

**Leave dates are `dd-MM-yyyy HH:mm` strings, not ISO 8601.** The API parses
that exact format and returns 400 on anything else. Vacations are truncated to
whole days server-side but still need a time component, so midnight is sent.
Covered by tests in `test/contract_test.dart`.

**`userId` is the login name, a string, on every endpoint.** Real accounts look
like `"Amani"`, so never coerce it to a number. `/api/attendance` and the mobile
check-in used to take it as an `int` via a `userIdAsInt` helper; because
`int.tryParse("Amani")` returns null and the helper fell back to `0`, every
request went out as `userId=0` and the history page came back empty with no
error. The helper is gone — pass `AuthUser.userId` through untouched.

Swagger still declares `userId` as `integer($int32)` on `/api/attendance` and
`/api/attendance/mobile-check-in`, unlike every other endpoint. The backend
needs to widen those two to `string` before the history page can return rows.

**Saving a transportation entry always sends the full `clients` array.** The
API replaces the whole list rather than diffing it.

**"Late" is computed client-side.** The API does not flag it yet. The rule
lives in `AttendanceRecord.isLate` (start after 09:00). `withinGeofence` is
reserved for the check-in feature and is `null` on terminal records.

**A 401 anywhere clears the token and routes back to login.** Wired in
`ApiClient.onUnauthorized` and handled in `main.dart`. A 401 from the login
endpoint itself is treated as wrong credentials, not an expired session.

**The check-in endpoint returns 501 today.** That renders a "Coming soon"
state, not an error. The contract is final, so it will start working the day
the backend enables it, with no app update. No biometric data is ever sent —
only the boolean result of the on-device match, plus GPS and a timestamp.

**`MainActivity` extends `FlutterFragmentActivity`.** `local_auth` needs a
FragmentActivity to host the biometric prompt.

---

## Tests

```bash
flutter test
```

`test/contract_test.dart` covers the API contract rules that are easy to break:
the leave date format, the late-start rule, the mixed `userId` typing, the
transportation payload shape, and the check-in timestamp format.

---

## Not done yet

- `playerId` is sent as the stored value or `"0"`. Wire a real push SDK into
  `SessionStore.savePlayerId` when push is added.
- Notification polling exists (`NotificationsProvider.poll`) but nothing calls
  it on a timer yet; the list refreshes when the screen opens.
