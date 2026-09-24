/// App-wide build configuration.
///
/// The API base URL is injected at build time so dev/prod are swappable
/// without a code change:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:5170
///   flutter build apk --dart-define=API_BASE_URL=https://api.example.com
class AppConfig {
  const AppConfig._();

  /// Base URL of CdsTeam_Api. Defaults to the local dev port (5170).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.10.105:8081/CdsTeam_Api/',
  );

  /// Swagger explorer for the configured host.
  static String get swaggerUrl => '$apiBaseUrl/swagger';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Endpoints that must NOT carry an Authorization header.
  static const List<String> unauthenticatedPaths = <String>['/api/auth/login'];
}
