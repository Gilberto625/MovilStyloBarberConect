# Kit para Google Play Console

Todo lo que pide Play Console para publicar **Stylo Barber Connect** (`com.tonystylo.stylo_barber_connect`), con lo que ya está listo en el repo y lo que hace el equipo. Tarjetas: GH#56 (AAB firmado), GH#58 (ficha, íconos y capturas), GH#60 (Internal Testing), GH#62 (envío a revisión).

| Archivo | Para qué sección de Play Console |
|---|---|
| [`FICHA.md`](FICHA.md) | Ficha de Play Store: nombre, descripciones, categoría, contacto, gráficos y capturas |
| [`SEGURIDAD_DE_LOS_DATOS.md`](SEGURIDAD_DE_LOS_DATOS.md) | Contenido de la app › Seguridad de los datos, Eliminación de cuenta y Política de privacidad |
| [`CLASIFICACION_Y_ACCESO.md`](CLASIFICACION_Y_ACCESO.md) | Contenido de la app › Clasificación de contenido, Público objetivo, Anuncios y Acceso a la app (cuenta para revisores) |
| [`PRIMERA_SUBIDA.md`](PRIMERA_SUBIDA.md) | **Paso a paso de la primera subida**: bajar el AAB firmado, crear la app, prueba interna, desofuscación, prueba cerrada y producción |
| [`FIRMA_Y_PUBLICACION.md`](FIRMA_Y_PUBLICACION.md) | Keystore de subida, secretos de GitHub, AAB firmado, pruebas interna y cerrada, y producción |
| `graficos/` | Ícono de 512×512 y gráfico destacado de 1024×500 (PR #102) |
| `capturas/` | Capturas para teléfono, ya en proporción 2:1 |

## Lista de verificación (estado al 2026-10-29)

Estados: ✅ listo · 🟡 listo al fusionar su PR · 👥 lo hace el equipo (datos, cuentas o contraseñas que Claude no maneja).

| # | Requisito de Play | Estado | Dónde |
|---|---|---|---|
| 1 | Cuenta de desarrollador | ✅ ya existe | play.google.com/console |
| 2 | Paquete único `com.tonystylo.stylo_barber_connect` | ✅ | `android/app/build.gradle.kts` |
| 3 | **SDK objetivo ≥ 36** (apps nuevas desde el 31-ago-2026) | ✅ `targetSdk=36` | `docs/evidencias/estatico-2026-10-21/` |
| 4 | Páginas de memoria de 16 KB | ✅ | mismo informe |
| 5 | AAB firmado con la clave de subida | ✅ keystore y 5 secretos cargados (29-oct); `release.yml` lo construye | `FIRMA_Y_PUBLICACION.md` |
| 6 | Versión para la prueba cerrada: `0.8.0-beta.1+4` (HITO 03) | 🟡 PR de versión hacia `release` | `pubspec.yaml` |
| 7 | Ícono 512×512 y gráfico destacado 1024×500 | ✅ | `graficos/` |
| 8 | 2 a 8 capturas de teléfono, lado mayor ≤ 2× el menor | ✅ 5 capturas 1080×2160 | `capturas/` |
| 9 | Nombre, descripción breve y completa | ✅ actualizada con reprogramar, cancelar y agenda del barbero | `FICHA.md` |
| 10 | URL de política de privacidad | ✅ pública · 👥 **faltan 2 marcadores**: `[NOMBRE O RAZÓN SOCIAL DE LA PERSONA RESPONSABLE]` y `[CORREO PARA PRIVACIDAD Y DERECHOS ARCO]` (revisado en producción el 29-oct) | `SEGURIDAD_DE_LOS_DATOS.md` |
| 11 | Eliminar la cuenta desde la app | ✅ en producción | Perfil › Privacidad › Eliminar mi cuenta |
| 12 | URL web para pedir el borrado | ✅ `https://tonystylo.vercel.app/eliminar-cuenta` responde 200 | `SEGURIDAD_DE_LOS_DATOS.md` |
| 13 | Formulario de Seguridad de los datos | ✅ respuestas | `SEGURIDAD_DE_LOS_DATOS.md` |
| 14 | Clasificación de contenido (IARC) | ✅ respuestas | `CLASIFICACION_Y_ACCESO.md` |
| 15 | Público objetivo y anuncios | ✅ respuestas | `CLASIFICACION_Y_ACCESO.md` |
| 16 | **Declaraciones obligatorias para todas las apps:** funciones financieras, apps de salud, apps del gobierno, ID de publicidad | ✅ respuestas: todas "No" | `CLASIFICACION_Y_ACCESO.md` |
| 17 | Cuenta de prueba para revisores **sin 2FA** en producción | 👥 pasos en `CLASIFICACION_Y_ACCESO.md` | — |
| 18 | Backend despierto durante la revisión | 🟡 backend PR #8 (ping cada 10 min) | `.github/workflows/mantener-activo.yml` del backend |
| 19 | Supresión de datos a los 30 días | 🟡 backend PR #8 la corre al arrancar · 👥 Cron Job diario en Render (recomendado) | `SEGURIDAD_DE_LOS_DATOS.md` |
| 20 | Informe previo al lanzamiento: accesibilidad | ✅ guías de Android (48 dp, etiquetas, contraste) en inicio, acceso, detalle de cita, reprogramar y agenda del barbero | `test/accesibilidad_guias_test.dart`, `test/guest_home_premium_test.dart` |
| 21 | Prueba interna | 👥 | `FIRMA_Y_PUBLICACION.md` |
| 22 | **Prueba cerrada: ≥ 12 testers durante 14 días seguidos** (cuentas personales) antes de pedir producción | 👥 | `FIRMA_Y_PUBLICACION.md` |

## Calendario desde hoy (29-oct-2026; entrega final: 7-dic-2026)
Manda la prueba cerrada: 14 días seguidos con 12 o más testers, más la revisión del acceso a producción (alrededor de 7 días).

| Fecha límite | Paso |
|---|---|
| 30-oct | Keystore y secretos; llenar los 2 marcadores de la política; cuenta de revisores sin 2FA; fusionar backend PR #8 |
| 31-oct | AAB firmado de `v0.4.0` en **prueba interna**; revisar el informe previo al lanzamiento |
| 1-nov | **Prueba cerrada** con 15 a 20 testers que acepten la invitación ese mismo día |
| 15-nov | Se cumplen 14 días; "Solicitar acceso a producción" |
| ~22-nov | Acceso aprobado; versión de producción a revisión (México) |
| 7-dic | Entrega final. Si Google aún no aprueba producción, se entrega con la evidencia de la prueba cerrada |
