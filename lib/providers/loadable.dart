import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';

/// Shared loading/error plumbing for the list-backed providers, so every
/// screen can render the same four states without repeating itself.
mixin Loadable on ChangeNotifier {
  bool _loading = false;
  String? _error;
  bool _hasLoadedOnce = false;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasLoadedOnce => _hasLoadedOnce;

  /// Runs [action], surfacing the API's own `error` string on failure.
  /// Returns true when it succeeded.
  Future<bool> guard(
    Future<void> Function() action, {
    bool silent = false,
  }) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      await action();
      _error = null;
      return true;
    } on ApiException catch (e) {
      // A 401 is handled globally by the interceptor; don't double-report it.
      _error = e.isUnauthorized ? null : e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      _hasLoadedOnce = true;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Wipe state on sign-out so the next user never sees stale rows.
  @mustCallSuper
  void resetLoadState() {
    _loading = false;
    _error = null;
    _hasLoadedOnce = false;
  }
}

/// Default window the date-ranged screens open on: the current month.
class DateRange {
  const DateRange(this.from, this.to);

  final DateTime from;
  final DateTime to;

  factory DateRange.currentMonth() {
    final DateTime now = DateTime.now();
    return DateRange(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 0),
    );
  }

  DateRange copyWith({DateTime? from, DateTime? to}) =>
      DateRange(from ?? this.from, to ?? this.to);
}
