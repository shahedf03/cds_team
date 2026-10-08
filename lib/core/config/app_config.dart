/// App-wide build configuration.
///
/// The API base URL is injected at build time so dev/prod are swappable
/// without a code change:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:5170
///   flutter build apk --dart-define=API_BASE_URL=https://api.example.com
class AppConfig {
  const AppConfig._();

  /// Base URL of CdsTeam_Api. Defaults to the production host, still plain
  /// `http` (no TLS cert on that domain yet) — matched by the iOS ATS
  /// exception in `ios/Runner/Info.plist` and the Android network security
  /// config in `android/app/src/main/res/xml/network_security_config.xml`,
  /// both scoped to exactly this host. Move this to `https://` the day the
  /// server gets a certificate and drop those two exceptions in the same
  /// change.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://olives.cds.jo:8081/CdsTeam_Api/',
  );

  /// `olives.cds.jo` is split-horizon DNS: the office DNS server resolves it
  /// to this LAN IP, but a phone that picks up a public DNS server instead
  /// (e.g. Android's automatic Private DNS) resolves the public IP and then
  /// can't loop back in through the router (no NAT hairpinning) — every
  /// request times out. [ApiClient] retries on this host whenever a request
  /// to [apiBaseUrl] times out, and keeps using whichever host last worked.
  static const String apiFallbackBaseUrl = String.fromEnvironment(
    'API_FALLBACK_BASE_URL',
    defaultValue: 'http://10.0.10.105:8081/CdsTeam_Api/',
  );

  /// OneSignal App ID for push, injected the same way as the base URL:
  ///
  ///   flutter run --dart-define=ONESIGNAL_APP_ID=xxxxxxxx-xxxx-...
  ///
  /// Empty disables push; the in-app notifications list still works.
  static const String oneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
  );

  /// Swagger explorer for the configured host.
  static String get swaggerUrl => '$apiBaseUrl/swagger';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Endpoints that must NOT carry an Authorization header.
  static const List<String> unauthenticatedPaths = <String>['/api/auth/login'];
}
