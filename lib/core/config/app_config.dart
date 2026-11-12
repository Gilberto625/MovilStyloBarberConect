/// Configuración de arranque por `--dart-define` (GH#68, CORE-001).
///
/// Ambientes (`APP_ENV`): `dev` (por defecto), `staging` y `prod`.
/// Detalle y comandos en `docs/AMBIENTES.md`.
///
/// ```bash
/// # dev: Django local desde el emulador (valor por defecto)
/// flutter run
/// # staging: no hay servidor propio, la URL se pasa siempre
/// flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
/// # prod: Render por HTTPS (lo usa release.yml)
/// flutter build appbundle --release --dart-define=APP_ENV=prod
/// ```
class AppConfig {
  AppConfig._();

  /// Valor crudo de `--dart-define=APP_ENV`. Sin valor, `dev`: un build sin
  /// configurar nunca apunta a producción por accidente.
  static const String appEnvDefine = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  /// Valor crudo de `--dart-define=API_BASE_URL`. Vacío = URL por defecto del
  /// ambiente.
  static const String apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');

  /// Ambiente resuelto y validado. Lanza [AmbienteInvalido] si la
  /// combinación de `APP_ENV` y `API_BASE_URL` no es válida.
  static final AmbienteConfig ambiente = AmbienteConfig.resolver(
    appEnv: appEnvDefine,
    apiBaseUrl: apiBaseUrlDefine,
  );

  /// Django REST base including `/api` (no trailing slash required).
  static String get apiBaseUrl => ambiente.apiBaseUrl;

  static const String appName = 'Stylo Barber Connect';
  static const String versionLabel = '0.8.1+5';

  static String normalizeBase(String raw) {
    var u = raw.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}

/// Ambientes de la app.
enum AppEnv {
  dev,
  staging,
  prod;

  /// Etiqueta discreta que se muestra en la UI. En `prod` no hay etiqueta.
  String? get etiqueta => switch (this) {
    AppEnv.dev => 'DEV',
    AppEnv.staging => 'STAGING',
    AppEnv.prod => null,
  };
}

/// La configuración de arranque no es válida. El mensaje dice qué corregir.
class AmbienteInvalido implements Exception {
  const AmbienteInvalido(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'AmbienteInvalido: $mensaje';
}

/// Ambiente ya resuelto: nombre y URL base de la API.
class AmbienteConfig {
  const AmbienteConfig._(this.env, this.apiBaseUrl);

  /// Django local desde el emulador Android (backend con base local).
  static const urlDev = 'http://10.0.2.2:8000/api';

  /// Backend de producción en Render (HTTPS).
  static const urlProd =
      'https://backendstylobarberconect-lo71.onrender.com/api';

  final AppEnv env;
  final String apiBaseUrl;

  bool get esProd => env == AppEnv.prod;

  /// `DEV` o `STAGING`; `null` en producción.
  String? get etiqueta => env.etiqueta;

  /// Resuelve `APP_ENV` + `API_BASE_URL`.
  ///
  /// Reglas:
  /// - `APP_ENV` vacío equivale a `dev`; un valor desconocido es un error.
  /// - Sin `API_BASE_URL`: `dev` usa [urlDev] y `prod` usa [urlProd].
  ///   `staging` no tiene servidor propio, así que la URL es obligatoria.
  /// - La URL debe ser `http` o `https` con host; `prod` exige `https`.
  static AmbienteConfig resolver({
    required String appEnv,
    required String apiBaseUrl,
  }) {
    final nombre = appEnv.trim().toLowerCase();
    final env = switch (nombre) {
      '' || 'dev' => AppEnv.dev,
      'staging' => AppEnv.staging,
      'prod' => AppEnv.prod,
      _ => throw AmbienteInvalido(
        'APP_ENV="$appEnv" no es válido. Usa dev, staging o prod '
        '(--dart-define=APP_ENV=...).',
      ),
    };

    var url = AppConfig.normalizeBase(apiBaseUrl);
    if (url.isEmpty) {
      url = switch (env) {
        AppEnv.dev => urlDev,
        AppEnv.prod => urlProd,
        AppEnv.staging => throw const AmbienteInvalido(
          'APP_ENV=staging no tiene servidor propio: pasa '
          '--dart-define=API_BASE_URL=<backend de pruebas>.',
        ),
      };
    }

    final uri = Uri.tryParse(url);
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      throw AmbienteInvalido(
        'API_BASE_URL="$url" no es una URL http(s) válida.',
      );
    }
    if (env == AppEnv.prod && uri.scheme != 'https') {
      throw AmbienteInvalido(
        'APP_ENV=prod exige HTTPS y API_BASE_URL es "$url".',
      );
    }
    return AmbienteConfig._(env, url);
  }
}
