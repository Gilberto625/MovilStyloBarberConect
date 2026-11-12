# Análisis JADX: APK debug contra APK release (GH#48 · SEC-011)

Fecha: 2026-11-11. Herramienta: **jadx 1.5.6** (CLI, `jadx -d <salida> --no-res -j 4 <apk>`), con el JDK de Android Studio. Las salidas del análisis no se versionan, porque contienen código descompilado de librerías de terceros.

## APK evaluados

| APK | Origen | SHA-256 |
|---|---|---|
| `stylo-barber-connect-0.8.1+5.apk` (release, R8 + `--obfuscate`) | Release v0.8.1 de GitHub (`gh release download v0.8.1`) | `98fbde17e96e756ce943958cf5eba9ebdd67a6e3c96a5966b4ea9f163b32a896`. Coincide con `SHA256SUMS.txt` del release |
| `app-debug.apk` (debug, sin ofuscar) | `flutter build apk --debug` sobre `develop` (`b04e63c`, versión 0.8.1+5) | `fec65955865918b0bfa808e66b4211811aed4e24df88989454f287e8845f59bc` |

Los dos tienen la misma versión funcional (0.8.1+5). El debug incluye además la corrección del PR #125, que no cambia nada de lo que se analiza aquí.

## Resultados

| Comprobación | Debug | Release | Lectura |
|---|---|---|---|
| Clases Java/Kotlin descompiladas | 4680 | 858 | R8 elimina el código que no se usa |
| Clases renombradas por R8 (paquete `defpackage`, nombres `a0`, `a1`…) | 0 | 796 | R8 ofusca los nombres de clases y métodos de las librerías Android |
| Paquetes legibles | `androidx`, `com.google`, `com.squareup`, `io.flutter`, `kotlinx`, `junit`… | `androidx`, `io.flutter`, `kotlin`, `com.tonystylo` (solo `MainActivity`) | En el release solo quedan legibles los puntos de entrada que Android exige |
| Código Dart de la app | En `assets/flutter_assets/kernel_blob.bin` (85.5 MB) | Compilado AOT en `lib/<abi>/libapp.so` (6.3 MB arm64) | El APK debug lleva el kernel de Dart; el release solo lleva código máquina |
| Nombres de clases Dart (`SecretariaApiService`, `CitasRepository`, `SecureTokenStorage`) | Aparecen 5, 8 y 9 veces en `kernel_blob.bin` | **0** apariciones en `libapp.so` | `--obfuscate` borra los identificadores Dart |
| URL del backend (`onrender.com`) y rutas (`/secretaria/citas/dia/`) | Visibles | Visibles (1 vez cada una) | Las cadenas **no** se ofuscan. Es lo esperado y no son secretos: la API es pública y la protegen el JWT y los permisos por rol en el servidor |
| Secretos (API keys, contraseñas o tokens asignados como texto) | No se encontraron | No se encontraron | Búsqueda con `grep` sobre las fuentes descompiladas |

## Conclusión y límites

- El release publicado está ofuscado: R8 renombra las clases Java y `--obfuscate` quita los nombres de las clases Dart del binario.
- Siguen legibles las cadenas: la URL de la API, las rutas y los textos de la interfaz. Por eso no debe haber secretos en el código; hoy no hay ninguno.
- **Esto no hace imposible la ingeniería inversa.** El binario AOT se puede analizar con herramientas especializadas, y la seguridad real depende del backend.
- No hay hallazgos críticos abiertos para el release.
