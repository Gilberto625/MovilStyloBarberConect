# Evidencia: R8 y `--obfuscate` (GH#46, GH#47, GH#52) — 2026-10-19

Rama `feature/security-r8-obfuscation`. Versión `0.1.0+1`, firmada con la clave **debug** (no hay keystore de subida todavía, GH#53/54).

## Qué se compiló

Se usó la misma versión del código para las tres variantes, con Flutter 3.47.7 en Windows:

| Variante | Comando | APK |
|---|---|---|
| Debug | `flutter build apk --debug` | `app-debug.apk` |
| Release sin `--obfuscate` (R8 activo) | `flutter build apk --release` | `app-release-plain.apk` |
| Release ofuscado (R8 + Dart) | `flutter build apk --release --obfuscate --split-debug-info=build/symbols/0.1.0+1` | `app-release-obf.apk` |

`build/app/outputs/mapping/release/mapping.txt` se generó en los dos release. Los símbolos Dart quedaron en `build/symbols/0.1.0+1/app.android-{arm,arm64,x64}.symbols`. **Ninguno se sube al repo**: está ignorado en `.gitignore` y el repo es público.

## Resultados

Archivos de este directorio:
- `strings_libapp.txt`: búsqueda de nombres de clase y método en `lib/arm64-v8a/libapp.so`.
- `apks_sha256_mapping.txt`: tamaños, SHA-256 y conteo de clases renombradas por R8.
- `manifest_flags.txt`: atributos del manifest compilado y flags del paquete instalado.
- `apk-ofuscado_01_inicio-catalogo.png` y `apk-ofuscado_02_login.png`: el APK ofuscado instalado en el emulador.

### Matriz Debug vs Release (GH#52)

| Control | Debug | Release sin `--obfuscate` | Release ofuscado | Cómo se comprobó |
|---|---|---|---|---|
| Nombres Dart en `libapp.so` (`AuthViewModel`, `SecretariaGestionViewModel`, `_tryRefresh`, `ClientCitasViewModel`) | — (JIT/kernel) | 2 / 2 / 1 / 2 coincidencias | **0 / 0 / 0 / 0** | `strings_libapp.txt` |
| Tamaño de `libapp.so` (arm64) | — | 6 226 824 B | 5 243 784 B (−16 %) | `strings_libapp.txt` |
| Clases Java/Kotlin renombradas por R8 | No (sin R8) | Sí | **951 de 1007** | `mapping.txt` |
| `android:debuggable` | `true` | ausente (false) | ausente (false) | `aapt2 dump xmltree` |
| `android:allowBackup` | `false` | `false` | `false` | `aapt2` y `dumpsys package` (sin `ALLOW_BACKUP`) |
| Tráfico HTTP sin cifrar | Solo a `10.0.2.2`/`localhost` (`network_security_config` de debug) | No permitido | No permitido | `aapt2` (`usesCleartextTraffic` solo en debug) |
| Tamaño del APK | 185.7 MB | 54.0 MB | 50.7 MB | `apks_sha256_mapping.txt` |
| La app funciona | — | — | Arranca, carga el catálogo real y abre el login | Capturas del emulador (Android 17, x86_64) |

### Prueba funcional del APK ofuscado (paso 7 del Prompt 3)

- **Hecho:** instalado en el emulador, arranca sin errores en logcat, carga el catálogo público de producción (solo lectura) y navega al login.
- **Pendiente: login y logout.** El release prohíbe HTTP sin cifrar, así que no puede apuntar al backend local (`http://10.0.2.2:8000`). Contra producción, el login necesita una cuenta real y la debe escribir una persona del equipo. Para completarlo, en el emulador con este APK: entrar con una cuenta de prueba, revisar Inicio y Citas, cerrar sesión y confirmar que vuelve al inicio. Después, agregar la captura aquí.
- La lógica de login, refresh y logout sí se prueba de forma automática en `test/integration/api_client_refresh_test.dart` y en las pruebas de ViewModel, pero sin ofuscar.

## Para el equipo: JADX (GH#48) y MobSF (GH#49)

Usen los APK de esta misma compilación. Están fuera del repo; los hashes de arriba sirven para confirmar que es el mismo archivo.

**JADX (GH#48)**
1. Descarga JADX-GUI desde `github.com/skylot/jadx/releases` y abre `app-release-plain.apk` y `app-release-obf.apk` en dos ventanas.
2. En el árbol `Source code`, compara `com.tonystylo.stylo_barber_connect` y el resto de paquetes: en release las clases propias de Java/Kotlin aparecen como `a.b.c`. `MainActivity` conserva su nombre porque el manifest la nombra. `io.flutter.*` y los plugins conservan parte de sus nombres por sus propias reglas de consumidor.
3. Captura: el árbol de paquetes de los dos APK y la búsqueda de texto (`Navigation → Text search`) de `AuthViewModel` (no aparece en Java en ninguno: la lógica Dart vive en `lib/<abi>/libapp.so`).
4. Explica en el reporte que JADX no ve el código Dart. Eso se compara con `strings` (archivo `strings_libapp.txt`).

**MobSF (GH#49)**
1. `docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf:latest` (o la instalación local). Usa otro puerto si el backend local ocupa el 8000, por ejemplo `-p 8010:8000`.
2. Sube `app-debug.apk` y `app-release-obf.apk` por separado.
3. Captura de cada uno: el *Security Score*, la sección *Manifest Analysis* (`debuggable`, `allowBackup`, `usesCleartextTraffic`) y *Certificate* (los dos usan la clave debug por ahora: es un hallazgo esperado hasta GH#53/54).
4. Anota la diferencia entre debug y release en la matriz de arriba.

## Límites (para el reporte)
- La ofuscación sube el costo de la ingeniería inversa, no la impide. La seguridad real sigue en el servidor: permisos por rol y que la app nunca confirme pagos.
- Los textos de la UI y la URL de la API siguen visibles en `libapp.so` (1 coincidencia de la URL en ambos release). No son secretos: no hay API keys ni contraseñas en el binario.
- Firma debug: un release firmado con la clave de subida necesita el keystore del equipo y los secretos de GitHub. `build.gradle.kts` ya lee `android/key.properties` si existe.
