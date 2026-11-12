# Matriz de dispositivos Android (GH#73 · QA-016, SF-02)

Fecha: 2026-11-11. App: `develop` `e208588` (0.8.1+5, build debug contra el backend local). `minSdk` declarado: **24 (Android 7.0)**, tomado de `flutter.minSdkVersion`.

| # | Dispositivo | Android / API | Pantalla (px, dpi → dp) | Qué se probó | Resultado | Evidencia (`docs/evidencias/bateria-final-2026-11-11/img/`) |
|---|---|---|---|---|---|---|
| 1 | Emulador "Medium Phone" (`sdk_gphone64_x86_64`) | 17 / API 37 | 1080×2400, 420 dpi → 411×914 dp | Batería PM01–PM10 completa, secretaría y barbero | Aprobado | `pm*`, `sec_*` |
| 2 | Mismo emulador con pantalla forzada (`wm size 720x1280`, `wm density 320`) | 17 / API 37 | 720×1280, 320 dpi → **360×640 dp** | Inicio del cliente y reserva completa hasta el resumen | Aprobado, sin recortes; los horarios se desplazan | `pm10_360dp_*` |
| 3 | Mismo emulador con texto del sistema al 200 % (`font_scale 2.0`) | 17 / API 37 | 411×914 dp | Login, inicio y reserva pasos 1 a 4 | Aprobado (la fila de días se desplaza, corrección del PR #128) | `pm10_*_texto_200` |
| 4 | AVD "Stylo_API24_Min" (perfil Pixel 2, `google_apis`) | **7.0 / API 24 (versión mínima)** | 1080×1920, 420 dpi → 411×731 dp | Arranque, catálogo, login, Mis citas y reserva completa (`POST /api/citas/` 201) | Aprobado | `api24_*` |

## Resultados por dispositivo

- **Versión mínima declarada (API 24): probada.** La app instala, arranca y completa la reserva.
- **Otra versión compatible (API 37): probada** con la batería completa.
- **Dos tamaños de pantalla:** 411×914 dp y 360×640 dp, más 411×731 dp en API 24.
- **Sin cierres inesperados** en ningún dispositivo: la app siguió en primer plano y logcat no registró `FATAL EXCEPTION`.

## Pendiente

- **Equipo físico:** no hubo teléfono Android físico disponible en esta corrida, así que el criterio "Equipo físico identificado" sigue abierto. Para cerrarlo: instalar la versión de Play (prueba cerrada) y repetir el smoke test de GH#61, anotando modelo y versión.
