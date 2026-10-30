# Stylo Barber Connect Mobile

Aplicación Android Flutter/Dart para Tony Stylo Barbería.

**Versión:** `0.1.0+1`  
**Arquitectura:** Cliente-servidor · MVVM + Repository  
**API:** Django REST existente bajo `/api/` (no `/api/v1/`)

## Requisitos

- Flutter 3.47+ / Dart 3.13+
- Android SDK (`ANDROID_HOME`, p. ej. `%LOCALAPPDATA%\Android\Sdk`)
- NDK side-by-side `28.2.13676358` (requerido por el plugin Flutter actual)
- Java 17+ (JDK de Android Studio o OpenJDK)
- Backend Stylo Barber Connect accesible por HTTPS/HTTP

## Estructura

```text
lib/
  core/           config, network, errors, storage, theme, di
  models/         DTO según JSON real del backend
  services/       API HTTP (Catalog, Auth, Citas, Secretaría)
  repositories/   orquestación de datos
  viewmodels/     ChangeNotifier
  views/          guest, auth, client, secretary
  widgets/
  routes/
  main.dart
```

Flujo: **View → ViewModel → Repository → API Service → Django REST**

## Configuración de API (`--dart-define`)

```bash
# Emulador Android → Django local
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Dispositivo físico en LAN (HTTP solo en debug; ver network_security_config)
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000/api

# Producción (default embebido, HTTPS)
flutter run --dart-define=API_BASE_URL=https://backendstylobarberconect-lo71.onrender.com/api
```

Cleartext HTTP está permitido **solo en el manifest debug** hacia `10.0.2.2`, `localhost` y `127.0.0.1`. Release no hereda esa configuración.

## Instalación y ejecución

```bash
cd Movil
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run
```

### Nota: ruta con espacios

Si el proyecto vive bajo una carpeta con espacios (p. ej. `proyevto v2`), Gradle a veces falla al empaquetar el APK (`Could not find EOCD`). Solución local:

```powershell
cmd /c mklink /J C:\stylo_barber_movil "C:\Users\yager\Documents\INGENIERIA\proyevto v2\Movil"
cd C:\stylo_barber_movil
flutter build apk --debug
```

El junction no mueve el código; el APK sigue generándose dentro de `/Movil/build/...`.

### Compilación Android

```bash
# Debug
flutter build apk --debug
# APK: build/app/outputs/flutter-apk/app-debug.apk

# Release ofuscado (símbolos privados, no versionar)
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

Guarda `build/symbols` fuera del repo público (por versión/build).
La firma release actual usa claves debug temporalmente; no publicar en Play Store sin keystore autorizado.

### Release ofuscado

El release combina dos capas:
- **R8** (`android/app/build.gradle.kts`: `isMinifyEnabled`, `isShrinkResources`, `proguard-rules.pro`) ofusca y recorta el código Java/Kotlin y genera `mapping.txt`.
- **`--obfuscate`** renombra el código Dart dentro de `libapp.so` y deja los símbolos aparte.

```bash
# Usa la versión de pubspec.yaml en la carpeta de símbolos
flutter build apk       --release --obfuscate --split-debug-info=build/symbols/0.1.0+1
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/0.1.0+1   # Play
```

Después de cada build de release, guarda **fuera del repo** y por versión:
- `build/symbols/<versión>/` (símbolos Dart);
- `build/app/outputs/mapping/release/mapping.txt` (R8).

Un lugar privado del equipo (unidad compartida o un secreto cifrado) sirve; el repo y los artefactos de Actions no, porque el repo es público. Con eso se desofusca un crash:

```bash
flutter symbolize -i stacktrace.txt -d build/symbols/0.1.0+1/app.android-arm64.symbols
```

- La firma lee `android/key.properties` si existe; si no, usa la clave debug. El keystore lo crea el equipo.
- El release no permite HTTP sin cifrar: para probar contra el backend local usa un build debug.
- Evidencia de la verificación (strings, hashes, manifest, JADX/MobSF): `docs/evidencias/seguridad/2026-10-19/`.

## Endpoints conectados

| Área | Endpoints |
|------|-----------|
| Público | `GET /public/servicios/`, `/public/productos/`, `/public/contacto/`, `/public/legal/?tipo=privacidad` (aviso de privacidad), `/public/legal/?tipo=terminos` (términos de uso, pantalla `/terminos`; en la web es `https://tonystylo.vercel.app/nosotros?tipo=terminos`) |
| Auth | `POST /login/`, `/login/2fa/verificar/`, `/login/2fa/solicitar-codigo/`, `POST /auth/token/refresh/`, `GET /auth/me/`, `GET /perfil/` |
| Registro de cliente | `POST /register/` con `sinVerificacion: true`: Django crea la cuenta verificada y responde 201 `{ok, requiereVerificacion: false, mensaje, access, refresh, usuario}`; la app guarda la sesión igual que tras el código y entra al inicio del cliente. Un servidor anterior responde `{tempToken, destino, email_enviado, mensaje}` y la app sigue con `POST /register/2fa/verificar/` y `/reenviar-otp/`. Si `email_enviado` es `false`, no muestra "Enviado a …" (backend `feature/movil-2fa-opcional`) |
| Seguridad de la cuenta | `GET /perfil/2fa/` → `{ok, email_2fa, puede_gestionar, motivo_bloqueo, proveedor_auth}` y `PUT /perfil/2fa/` con `{email_2fa}` → `{ok, email_2fa, proveedor_auth}`. Con sesión. Apagado por defecto: el login de clientes responde `requires2fa: false` con tokens salvo que lo activen. Interruptor en Perfil › Privacidad y mis datos › Seguridad de tu cuenta |
| Cliente | `GET /barberos/`, `/disponibilidad/`, `/citas/politica-pago/`, `/mis-citas/`, `POST /citas/` |
| Cliente: cambiar su cita (S6-02, PM05) | `POST /mis-citas/{id}/cancelar/` con `{motivo?}` y `POST /mis-citas/{id}/reprogramar/` con `{fecha, hora}`. Solo citas propias en pendiente o confirmada, con 1 día de anticipación (2 si la cita cae de viernes a domingo). Reprogramar conserva servicio, barbero, precio y anticipo. `GET /mis-citas/` agrega `barbero_id`, `puede_modificar`, `motivo_no_modificable` y `limite_modificacion`: la app muestra los botones solo si `puede_modificar` es `true`. Cita ajena: 404; fuera de plazo u horario ocupado: 409 con el mensaje del servidor |
| Barbero (S7-01..03, PM06) | `GET /barbero/agenda/?fecha=` (solo sus citas activas; por defecto hoy) y `POST /barbero/citas/{id}/atencion/` con `{accion: iniciar \| terminar}`. Iniciar pasa la cita a `en_curso`; terminar la deja en curso con la marca de atención terminada para que secretaría cobre. Solo citas propias y de hoy; otro rol: 403 |
| Privacidad (ARCO) | `GET /perfil/` + `GET /mis-citas/` (Mis datos, GH#42), `PUT /perfil/` (rectificación, GH#43). `PUT` reemplaza el perfil completo: la app reenvía `avatar_url` y `direccion` actuales. `GET`/`PUT /privacidad/preferencias/` (opt-in de finalidades secundarias guardado en la cuenta, GH#41/GH#45; backend `feature/movil-arco-preferencias`). `POST /privacidad/cancelacion/` (Eliminar mi cuenta, GH#44; backend PR #5): con sesión pide `{contrasena, motivo?}`, bloquea la cuenta al momento y responde 201 `{folio, estado, fecha_supresion}`; los datos personales se suprimen a los 30 días con `manage.py suprimir_cuentas_vencidas`. Sin sesión acepta `{cuenta, contrasena}` para la página web de borrado. El personal recibe 403 |
| Secretaría | `GET /secretaria/citas/dia/`, `POST .../asistencia/`, `POST .../cobrar/` |

## Seguridad

- Tokens JWT en `flutter_secure_storage` (no se guardan contraseñas).
- Sin logs de `Authorization`, tokens u OTP.
- Logout solo local (el backend no expone logout).
- 401 → refresh; si falla, limpia sesión.
- Roles: secretaría solo si el backend reporta `secretaria` o `admin`; el barbero entra a **Mi agenda**; los demás, al panel del cliente.
- Guarda central de rutas (GH#70, `lib/routes/route_guard.dart`): cada panel revisa sesión y rol antes de dibujarse y, si no le toca, manda al acceso o al inicio de su rol.
- El ocultar botones en UI no sustituye permisos del servidor.

## Pruebas

```bash
flutter analyze
flutter test --coverage
```

Incluye ViewModels (auth, citas, secretaría), repositorios fake, widgets de home y manejo de errores/estados vacíos.

Pruebas unitarias (Actividad 3):

| Carpeta | Qué contiene |
|---|---|
| `test/unit/` | `PM-U01` (validador de correo), `fromJson` con fixtures y ViewModels con Mockito (`verify`, errores HTTP, timeout, doble toque) |
| `test/fixtures/` | JSON con la forma real de las respuestas de Django, con datos ficticios |
| `test/mocks/` | `mocks.dart` declara los mocks; `mocks.mocks.dart` es generado y se versiona para que CI no necesite `build_runner` |

Si cambia la firma de un repository, regenera los mocks y súbelos en el mismo PR:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Notas

- No es monorepo: este directorio tiene su propio `.git`.
- No modifica `/backend` ni `/FrontStyloBarberConect`.
- No hay pagos simulados ni sync offline de asistencia/cobro.
- Setup Android histórico: [docs/ANDROID_SDK_SETUP.md](docs/ANDROID_SDK_SETUP.md)
