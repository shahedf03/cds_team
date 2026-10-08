import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's display language: English or Arabic, toggled from the Profile
/// screen. Persisted across restarts the same way [SessionStore] persists
/// non-sensitive settings — plain [SharedPreferences], nothing secret here.
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'cds_locale';

  static const Locale english = Locale('en');
  static const Locale arabic = Locale('ar');

  Locale _locale = english;

  Locale get locale => _locale;
  bool get isArabic => _locale == arabic;

  /// Reads the saved choice, if any. Call once at startup, before
  /// [MaterialApp] first builds — defaults to English otherwise.
  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? code = prefs.getString(_prefKey);
    if (code == arabic.languageCode) {
      _locale = arabic;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale value) async {
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, value.languageCode);
  }

  Future<void> toggle() =>
      setLocale(isArabic ? english : arabic);
}
