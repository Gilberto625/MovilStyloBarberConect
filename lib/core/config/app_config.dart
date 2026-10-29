/// Runtime configuration via `--dart-define`.
///
/// Example:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
/// flutter run --dart-define=API_BASE_URL=https://backendstylobarberconect-lo71.onrender.com/api
/// ```
class AppConfig {
  AppConfig._();

  /// Django REST base including `/api` (no trailing slash required).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backendstylobarberconect-lo71.onrender.com/api',
  );

  static const String appName = 'Stylo Barber Connect';
  static const String versionLabel = '0.8.0-beta.1+4';

  static String normalizeBase(String raw) {
    var u = raw.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
