# Análisis estático del APK release ofuscado (2026-10-21)

Tarjetas: GH#47–GH#49 (ofuscación, R8, ingeniería inversa) y requisitos técnicos de Play (GH#56).

## Cómo se hizo
- **Código:** `develop` en `67e04ab`, versión `0.1.0+1`.
- **Dos builds release:**
  - "Sin ofuscar": `flutter build apk --release`. R8 sí corre, porque está en `build.gradle.kts`.
  - "Ofuscado": `flutter build apk --release --obfuscate --split-debug-info=build/symbols/0.1.0+1`.
  - Los símbolos (`build/symbols/`) y `mapping.txt` se quedaron fuera del repo.
- **Herramientas oficiales del Android SDK:** `aapt2`, `apksigner` y `zipalign` (build-tools 36.0.0). Además, `tool/analisis_apk.py`, que solo lee los APK: encabezados ELF, `mapping.txt` y búsqueda de identificadores y secretos.
- Salida completa: `analisis_apk_2026-10-21.txt`. Para repetirlo con otra versión: `python -I tool/analisis_apk.py <carpeta> <build-tools> <salida>`.

## Resultados

| Revisión | Resultado | Lectura |
|---|---|---|
| SDK objetivo | `targetSdk=36`, `minSdk=24`, `compileSdk=36` | Cumple el requisito de Play para apps nuevas (API 36 desde el 31-ago-2026) |
| Permisos | Solo `INTERNET` (más el permiso interno `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, propio del paquete, que agrega AndroidX) | Sin permisos peligrosos |
| `debuggable` | No declarado; en release vale `false` | OK |
| `allowBackup` | `false` | La sesión no sale en respaldos |
| Tráfico HTTP | `usesCleartextTraffic` no declarado en release; el cleartext solo existe en el manifiesto de debug | OK |
| Componentes exportados | `MainActivity` (launcher, obligatorio) y `ProfileInstallReceiver` de AndroidX | El receptor está protegido por el permiso `DUMP` del sistema; es estándar e informativo |
| Firma | v2 válida | En la PC queda firmada con la clave debug porque no hay `key.properties`. `release.yml` **falla** si eso pasa en CI |
| Páginas de 16 KB | `zipalign -c -P 16`: OK. Segmentos LOAD de `libapp.so`, `libflutter.so` y `libdartjni.so` a 16 o 64 KB en los tres ABI | Cumple el requisito de 16 KB de Android 15+ |
| **R8 (Java/Kotlin)** | 1 038 clases en `mapping.txt`; **981 renombradas (95 %)** | `io.flutter.*` renombra 228 de 247; las que quedan las mantienen las reglas `-keep` del motor y los plugins. La lógica de la app no está aquí: está en `libapp.so` |
| **Dart (`libapp.so`)** | 7.41 MB → **6.16 MB**. Los 14 identificadores revisados (`AuthViewModel`, `ApiClient`, `SecureTokenStorage`, `loadPerfil`, `verify2fa`…) aparecen 1–2 veces sin ofuscar y **0 veces** ofuscado | Nombres de clases y métodos reemplazados |
| Cadenas en claro | Las rutas de la API y el host del backend siguen legibles | Es lo esperado: `--obfuscate` no cifra cadenas. Por eso no hay secretos en el binario |
| **Búsqueda de secretos** en todo el APK | Ninguna clave privada PEM, AWS, `sk_live`/`pk_live`, Google API key, JWT ni clave de Brevo | OK |
| **Funciona ofuscado** | El APK release ofuscado abre en el emulador contra producción (solo lectura): Inicio y Servicios cargan, sin excepciones en logcat | `release_ofuscado_inicio.png`, `release_ofuscado_servicios.png` |

## Pendiente (decisión del equipo)
- **JADX-GUI y MobSF:** dan capturas "antes y después" más visuales. No están instalados y requieren bajar ejecutables: JADX desde `github.com/skylot/jadx/releases` (usa el Java de Android Studio) y `mobsfscan` por `pip`. Los resultados de arriba ya cubren lo que medirían: nombres renombrados, permisos, componentes exportados y secretos.
- **Repetir con `0.4.0+2`** cuando `release.yml` genere el AAB firmado. Con el pinning fusionado (PR #104), el host del backend seguirá en claro. Los certificados raíz que agrega ese PR son públicos y no son secretos.
