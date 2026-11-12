# Auditoría de dependencias Flutter (CORE-005, GH#72)

| Dato | Valor |
|---|---|
| Fecha | 2026-11-11 |
| Código auditado | `develop` en `b04e63c` (0.8.1+5 más el PR #125) |
| Máquina | Windows 11, Flutter local 3.47.7 |
| Comandos ejecutados | `flutter --version`, `flutter pub get`, `flutter pub outdated`, `flutter pub deps --style=compact` |
| Cambios a dependencias en este PR | **Ninguno.** `pubspec.yaml` y `pubspec.lock` no se tocaron; `git status` siguió limpio después de `pub get` |

## 1. Salida de los comandos

Se quitaron solo las rutas locales de la máquina.

### `flutter --version`

```text
Flutter 3.47.7 • channel stable • https://github.com/flutter/flutter.git
Framework • revision abaf9c5237 (5 weeks ago) • 2026-10-08 09:51:21 -0700
Engine • hash d8a2d6c768c334d53e16277f837970ffa1e2de81 (revision deb287481e) (1 months ago) • 2026-10-07 17:09:12.000Z
Tools • Dart 3.13.5 • DevTools 2.60.0
```

### `flutter pub get`

Resolvió y dejó el lock igual ("Got dependencies!"). Terminó con código 1 solo por un aviso de Windows: "Building with plugins requires symlink support. Please enable Developer Mode". Es un ajuste del sistema operativo de esta PC, no de las dependencias. En CI (Linux) no aparece.

```text
Resolving dependencies...
Downloading packages...
  _fe_analyzer_shared 110.0.0 (111.0.0 available)
  analyzer 14.6.0 (14.7.0 available)
  build 4.0.11 (5.0.0 available)
  ...
  win32 5.15.0 (6.4.0 available)
Got dependencies!
29 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Building with plugins requires symlink support.
```

### `flutter pub outdated`

```text
Package Name                               Current   Upgradable  Resolvable  Latest

direct dependencies:
cupertino_icons                            *1.0.9    *1.0.9      2.0.0       2.0.0
flutter_secure_storage                     *9.2.4    *9.2.4      11.2.0      11.2.0
google_fonts                               *6.3.3    *6.3.3      9.0.0       9.0.0

dev_dependencies:
build_runner                               *2.16.2   *2.16.2     *2.16.2     2.17.1
crypto                                     *3.0.7    3.0.8       3.0.8       3.0.8

transitive dependencies:
code_assets                                *1.2.1    2.2.0       2.2.0       2.2.0
cupertino_ui                               -         -           1.1.6       1.1.6
ffi_leak_tracker                           -         -           0.1.2       0.1.2
flutter_secure_storage_darwin              -         -           0.4.3       0.4.3
flutter_secure_storage_linux               *1.2.3    *1.2.3      3.0.3       3.0.3
flutter_secure_storage_macos               *3.1.3    *3.1.3      -           4.0.0    (discontinued)
flutter_secure_storage_platform_interface  *1.1.2    *1.1.2      2.1.1       2.1.1
flutter_secure_storage_web                 *1.2.1    *1.2.1      2.1.1       2.1.1
flutter_secure_storage_windows             *3.1.2    *3.1.2      4.2.2       4.2.2
hooks                                      *2.0.2    2.2.0       2.2.0       2.2.0
jni                                        *1.1.0    1.1.2       1.1.2       1.1.2
js                                         *0.6.7    *0.6.7      -           0.7.2    (discontinued)
material_color_utilities                   *0.13.0   *0.13.0     *0.13.0     0.13.1
material_ui                                -         -           1.11.0      1.11.0
meta                                       *1.18.3   1.19.0      1.19.0      1.19.0
objective_c                                *9.5.0    9.6.4       9.6.4       9.6.4
record_use                                 *0.6.0    1.1.1       1.1.1       1.1.1
vector_math                                *2.4.0    2.4.4       2.4.4       2.4.4
web                                        *1.1.1    1.1.2       1.1.2       1.1.2
win32                                      *5.15.0   *5.15.0     6.4.0       6.4.0

transitive dev_dependencies:
_fe_analyzer_shared                        *110.0.0  111.0.0     111.0.0     111.0.0
analyzer                                   *14.6.0   14.7.0      14.7.0      14.7.0
build                                      *4.0.11   *4.0.11     *4.0.11     5.0.0
build_config                               *1.3.3    *1.3.3      *1.3.3      1.4.0
built_collection                           *5.1.2    *5.1.2      *5.1.2      6.0.0
pubspec_parse                              *1.6.0    1.7.0       1.7.0       1.7.0
test_api                                   *0.7.12   *0.7.12     *0.7.12     0.7.15
vm_service                                 *15.3.0   15.4.0      15.4.0      15.4.0

13 upgradable dependencies are locked (in pubspec.lock) to older versions.
8  dependencies are constrained to versions that are older than a resolvable version.

flutter_secure_storage_macos
    Package flutter_secure_storage_macos has been discontinued.
js
    Package js has been discontinued.
```

`pub outdated` solo lista los paquetes que tienen una versión más nueva. Las dependencias directas que no aparecen (`http`, `provider`, `intl`, `url_launcher`, `flutter_lints`, `mockito`) ya están en su última versión.

### `flutter pub deps --style=compact` (dependencias directas)

```text
Dart SDK 3.13.5
Flutter SDK 3.47.7
stylo_barber_connect 0.8.1+5

dependencies:
- cupertino_icons 1.0.9
- flutter 0.0.0 [characters collection material_color_utilities meta vector_math sky_engine]
- flutter_localizations 0.0.0 [flutter intl path]
- flutter_secure_storage 9.2.4 [flutter flutter_secure_storage_linux flutter_secure_storage_macos flutter_secure_storage_platform_interface flutter_secure_storage_web flutter_secure_storage_windows meta]
- google_fonts 6.3.3 [crypto flutter http path_provider]
- http 1.6.0 [async http_parser meta web]
- intl 0.20.3 [clock meta path]
- provider 6.1.5+1 [collection flutter nested]
- url_launcher 6.3.3 [flutter url_launcher_android url_launcher_ios url_launcher_linux url_launcher_macos url_launcher_platform_interface url_launcher_web url_launcher_windows]

dev dependencies:
- build_runner 2.16.2 [...]
- crypto 3.0.7 [typed_data]
- flutter_lints 6.0.0 [lints]
- flutter_test 0.0.0 [...]
- integration_test 0.0.0 [flutter flutter_driver flutter_test path vm_service]
- mockito 5.8.1 [analyzer build code_builder collection dart_style matcher meta path source_gen test_api]
```

De dónde vienen los dos paquetes descontinuados (transitivos):
- `js 0.6.7` ← `flutter_secure_storage_web 1.2.1` (solo web).
- `flutter_secure_storage_macos 3.1.3` ← `flutter_secure_storage 9.2.4` (solo macOS).

La app se publica solo para Android, así que ninguno entra al APK. Desaparecen al pasar `flutter_secure_storage` a una major nueva.

## 2. Versión de Flutter: local frente a CI

| Dónde | Flutter / Dart | Fuente |
|---|---|---|
| Esta PC (auditoría) | 3.47.7 / 3.13.5 | `flutter --version` (arriba) |
| CI del PR #125, 2026-11-06 | 3.47.9 / 3.13.7 | Run [42258784727](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/42258784727): analyze limpio, 349/349 pruebas, cobertura 79.51 % |
| CI del push a `develop`, 2026-11-12 | **3.50.0** | Run [43135262264](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/43135262264): **falla** `flutter analyze` con 58 avisos `info` "'package:flutter/material.dart' is deprecated … Use package:material_ui/material_ui.dart" |
| `pubspec.yaml` / `pubspec.lock` | SDK `^3.13.5`; el lock pide `flutter >=3.44.0` | Archivos versionados |

`ci.yml` y `release.yml` instalan Flutter con `channel: stable` **sin fijar la versión**. Por eso el mismo código pasó el 6-nov y falló el 12-nov. Se registró como **ERR-18** en `REGISTRO_ERRORES.md`. Este PR no lo corrige (no toca workflows ni `lib/`); los PR de solo documentación también verán ese check en rojo hasta que se corrija.

Recomendación, en un PR propio:
1. Fijar `flutter-version: 3.47.9` en los dos workflows, para builds reproducibles.
2. Después, en otro PR con pruebas, migrar a Flutter 3.50 (`material_ui` en lugar de `package:flutter/material.dart`).

## 3. Dependencias directas: uso y decisión

"Uso" sale de buscar cada paquete en `lib/`, `test/`, `integration_test/` y `tool/`.

| Paquete | Restricción | En el lock | Última | Para qué se usa | Decisión |
|---|---|---|---|---|---|
| `flutter_localizations` (SDK) | sdk | — | — | Español de México en los componentes de Material (`lib/core/config/app_locale.dart`) | Mantener |
| `http` | `^1.2.2` | 1.6.0 | 1.6.0 | Todo el acceso a la API: `lib/core/network/api_client.dart` y `cliente_http.dart` (cliente con certificate pinning). `MockClient` en las pruebas de integración HTTP | Mantener |
| `provider` | `^6.1.2` | 6.1.5+1 | 6.1.5+1 | Inyección del `AppScope` y ViewModels con `ChangeNotifier` (`main.dart`, rutas, vistas) | Mantener |
| `intl` | `^0.20.2` | 0.20.3 | 0.20.3 | Moneda `es_MX` y fechas (`lib/widgets/common_widgets.dart`) | Mantener |
| `url_launcher` | `^6.3.3` | 6.3.3 | 6.3.3 | Botón Llamar y enlaces externos de Contacto (`lib/views/guest/guest_contacto_view.dart`) | Mantener |
| `flutter_secure_storage` | `^9.2.4` | 9.2.4 | **11.2.0** | Tokens JWT cifrados en el Keystore de Android (`lib/core/storage/secure_token_storage.dart`, `encryptedSharedPreferences: true`) | **Major pendiente que requiere pruebas.** Antes de subir: leer el CHANGELOG de 10.x y 11.x, comprobar en emulador que una sesión guardada con 9.x se sigue leyendo (o que la app pide entrar de nuevo sin errores) y repetir la evidencia de almacenamiento cifrado |
| `google_fonts` | `^6.2.1` | 6.3.3 | **9.0.0** | Solo para registrar Fraunces y Manrope empaquetadas en `assets/google_fonts/`, con `allowRuntimeFetching = false` (`lib/core/config/app_fonts.dart`, `app_theme.dart`) | **Major pendiente que requiere pruebas** (`test/app_fonts_test.dart` y revisión visual). Alternativa: declarar las fuentes en `pubspec.yaml` y quitar el paquete |
| `cupertino_icons` | `^1.0.8` | 1.0.9 | **2.0.0** | **No se usa**: no hay `CupertinoIcons` en `lib/` | **Major pendiente**; mejor candidata a **quitarla** en un PR aparte, con `flutter build apk` para confirmar |

Dependencias de desarrollo:

| Paquete | Restricción | En el lock | Última | Para qué se usa | Decisión |
|---|---|---|---|---|---|
| `flutter_test` (SDK) | sdk | — | — | Pruebas unitarias y de widget | Mantener |
| `integration_test` (SDK) | sdk | — | — | `integration_test/pi01_reserva_test.dart` en emulador | Mantener |
| `mockito` | `^5.8.1` | 5.8.1 | 5.8.1 | Mocks generados (`test/mocks/mocks.dart`) | Mantener |
| `build_runner` | `^2.16.2` | 2.16.2 | 2.17.1 | Genera `mocks.mocks.dart` | Mantener. La 2.17.1 no se puede resolver con el SDK y las demás dependencias actuales (Resolvable = 2.16.2) |
| `flutter_lints` | `^6.0.0` | 6.0.0 | 6.0.0 | Reglas de `analysis_options.yaml` | Mantener |
| `crypto` | `^3.0.7` | 3.0.7 | 3.0.8 | SHA-256 de los certificados fijados en `test/pinning_test.dart` | **Parche sin riesgo** (3.0.7 → 3.0.8), en un PR aparte con la suite completa |

## 4. Transitivas

- **Se pueden subir dentro de las restricciones** (13, columna Upgradable): `crypto`, `code_assets`, `hooks`, `jni`, `meta`, `objective_c`, `record_use`, `vector_math`, `web`, `_fe_analyzer_shared`, `analyzer`, `pubspec_parse` y `vm_service`. Lo haría `flutter pub upgrade`. No se hizo: cualquier cambio del lock va en su propio PR con la suite completa.
- **Majors que solo llegan con las majors directas:** `flutter_secure_storage_*` y `win32` (vía `flutter_secure_storage_windows`). No entran al APK de Android.
- **`material_ui`, `cupertino_ui` y `ffi_leak_tracker`** aparecen como "resolvables" porque Flutter 3.50 separa Material y Cupertino en paquetes; son parte de la migración del punto 2.

## 5. Seguridad de las dependencias

- La salida de `pub get` y `pub outdated` no muestra avisos de seguridad para las versiones del lock.
- No se corrió otro escáner (por ejemplo OSV-Scanner), así que no se afirma más que eso.
- El lock está versionado y la CI corre `flutter pub get` sobre él, así que cada build usa exactamente estas versiones (salvo el SDK, punto 2).

## 6. Resumen de decisiones

| Decisión | Paquetes |
|---|---|
| Mantener | `http`, `provider`, `intl`, `url_launcher`, `flutter_localizations`, `mockito`, `build_runner`, `flutter_lints`, `flutter_test`, `integration_test` |
| Parche sin riesgo (PR aparte) | `crypto` 3.0.7 → 3.0.8 y las 13 transitivas "Upgradable" |
| Major pendiente que requiere pruebas | `flutter_secure_storage` 9 → 11, `google_fonts` 6 → 9, `cupertino_icons` 1 → 2 (o quitarla) |
| SDK | Fijar la versión de Flutter en la CI (ERR-18) antes de cualquier actualización |
