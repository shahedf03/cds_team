import 'package:flutter/foundation.dart';

import '../models/client.dart';
import '../models/transportation.dart';
import '../services/clients_service.dart';
import '../services/transportation_service.dart';
import 'loadable.dart';

/// §4 daily transactions + §5 the client list that feeds "+ Add Client".
class TransportationProvider extends ChangeNotifier with Loadable {
  TransportationProvider({
    required TransportationService service,
    required ClientsService clientsService,
  }) : _service = service,
       _clientsService = clientsService;

  final TransportationService _service;
  final ClientsService _clientsService;

  List<Transportation> _entries = const <Transportation>[];
  List<Client> _clients = const <Client>[];
  DateRange _range = DateRange.currentMonth();
  bool _savingEntry = false;
  bool _loadingClients = false;
  bool _exportingReport = false;

  List<Transportation> get entries => _entries;
  List<Client> get clients => _clients;
  DateRange get range => _range;
  bool get isSaving => _savingEntry;
  bool get isLoadingClients => _loadingClients;
  bool get isExportingReport => _exportingReport;

  double get totalAmount => _entries.fold<double>(
    0,
    (double sum, Transportation e) => sum + e.totalValue,
  );

  double get totalKm =>
      _entries.fold<double>(0, (double sum, Transportation e) => sum + e.kmValue);

  Future<void> load({required String userId, DateRange? range}) {
    if (range != null) _range = range;
    return guard(() async {
      _entries = await _service.list(
        userId: userId,
        fromDate: _range.from,
        toDate: _range.to,
      );
    });
  }

  Future<void> setRange(DateRange range, {required String userId}) {
    _range = range;
    return load(userId: userId);
  }

  /// Client picker source (§5). Cached after the first successful fetch.
  Future<void> loadClients({bool force = false}) async {
    if (_clients.isNotEmpty && !force) return;
    _loadingClients = true;
    notifyListeners();
    try {
      _clients = await _clientsService.list();
    } catch (_) {
      // The picker shows its own empty/retry state; don't blow up the screen.
    } finally {
      _loadingClients = false;
      notifyListeners();
    }
  }

  /// Server-computed Total for a KM value (editor's read-only Total field).
  Future<String> calculateTotal(String km) => _service.calculateTotal(km);

  /// PDF of the entries in the open date window, or null on failure (the
  /// API's message is left in [error]).
  Future<Uint8List?> report({
    required String userId,
    required String userName,
  }) async {
    _exportingReport = true;
    notifyListeners();

    Uint8List? bytes;
    await guard(() async {
      bytes = await _service.report(
        userId: userId,
        userName: userName,
        fromDate: _range.from,
        toDate: _range.to,
      );
    }, silent: true);

    _exportingReport = false;
    notifyListeners();
    return bytes;
  }

  /// New record → POST, existing one → PUT `/api/transportation/{trId}`.
  Future<bool> save(Transportation entry, {required String userId}) async {
    _savingEntry = true;
    notifyListeners();

    final bool ok = await guard(() async {
      if (entry.isNew) {
        await _service.create(entry);
      } else {
        await _service.update(entry);
      }
      // The editor allows any date, but the list only fetches the open
      // window. An entry saved outside it would come back empty-handed and
      // read as "nothing was saved", so stretch the window to cover it.
      _range = _rangeCovering(entry.trDate);
      _entries = await _service.list(
        userId: userId,
        fromDate: _range.from,
        toDate: _range.to,
      );
    }, silent: true);

    _savingEntry = false;
    notifyListeners();
    return ok;
  }

  /// [_range] widened just enough to include [date]. Returns the current
  /// range untouched when the date already falls inside it.
  DateRange _rangeCovering(DateTime? date) {
    if (date == null) return _range;
    final DateTime day = DateTime(date.year, date.month, date.day);
    return DateRange(
      day.isBefore(_range.from) ? day : _range.from,
      day.isAfter(_range.to) ? day : _range.to,
    );
  }

  /// Trash icon on a saved entry.
  Future<bool> delete(int trId) async {
    final List<Transportation> previous = _entries;
    // Optimistic removal, rolled back if the API rejects it.
    _entries = _entries
        .where((Transportation e) => e.trId != trId)
        .toList(growable: false);
    notifyListeners();

    final bool ok = await guard(() => _service.delete(trId), silent: true);
    if (!ok) {
      _entries = previous;
      notifyListeners();
    }
    return ok;
  }

  void reset() {
    _entries = const <Transportation>[];
    _clients = const <Client>[];
    _range = DateRange.currentMonth();
    resetLoadState();
    notifyListeners();
  }
}
