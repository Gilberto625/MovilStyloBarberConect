# Kit para Google Play Console

Todo lo que pide Play Console para publicar **Stylo Barber Connect** (`com.tonystylo.stylo_barber_connect`), con lo que ya está listo en el repo y lo que hace el equipo. Tarjetas: GH#56 (AAB firmado), GH#58 (ficha, íconos y capturas), GH#60 (Internal Testing), GH#62 (envío a revisión).

| Archivo | Para qué sección de Play Console |
|---|---|
| [`FICHA.md`](FICHA.md) | Ficha de Play Store: nombre, descripciones, categoría, contacto, gráficos y capturas |
| [`SEGURIDAD_DE_LOS_DATOS.md`](SEGURIDAD_DE_LOS_DATOS.md) | Contenido de la app › Seguridad de los datos, Eliminación de cuenta y Política de privacidad |
| [`CLASIFICACION_Y_ACCESO.md`](CLASIFICACION_Y_ACCESO.md) | Contenido de la app › Clasificación de contenido, Público objetivo, Anuncios y Acceso a la app (cuenta para revisores) |
| [`FIRMA_Y_PUBLICACION.md`](FIRMA_Y_PUBLICACION.md) | Keystore de subida, secretos de GitHub, AAB firmado, pruebas interna y cerrada, y producción |
| `graficos/` | Ícono de 512×512 y gráfico destacado de 1024×500 (PR #102) |
| `capturas/` | Capturas para teléfono, ya en proporción 2:1 |

## Lista de verificación

Estados: ✅ listo en el repo · 🟡 listo cuando se fusione su PR o se despliegue · 👥 lo hace el equipo.

| # | Requisito de Play | Estado | Dónde |
|---|---|---|---|
| 1 | Cuenta de desarrollador (pago único de 25 USD; verificación de identidad) | 👥 | play.google.com/console |
| 2 | Paquete único `com.tonystylo.stylo_barber_connect` | ✅ | `android/app/build.gradle.kts` |
| 3 | **SDK objetivo ≥ 36** (obligatorio para apps nuevas desde el 31-ago-2026) | ✅ `targetSdk=36` (lo da Flutter) | `ANALISIS_ESTATICO` en `docs/evidencias/estatico-2026-10-21/` |
| 4 | Páginas de memoria de 16 KB (apps con código nativo) | ✅ | mismo informe |
| 5 | AAB firmado con la clave de subida | 👥 crear keystore y secretos → ✅ `release.yml` lo construye | `FIRMA_Y_PUBLICACION.md` |
| 6 | Versión `0.4.0+2` (el `+N` crece en cada subida) | 🟡 PR a `release` | `pubspec.yaml` |
| 7 | Ícono 512×512 y gráfico destacado 1024×500 | 🟡 PR #102 | `graficos/` |
| 8 | 2 a 8 capturas de teléfono, lado mayor ≤ 2× el menor | ✅ | `capturas/` |
| 9 | Nombre, descripción breve (≤ 80) y completa (≤ 4000) | ✅ | `FICHA.md` |
| 10 | URL de política de privacidad (pública, sin iniciar sesión) | ✅ pública · 👥 **llenar 3 marcadores** (responsable, RFC, correo ARCO) | `https://tonystylo.vercel.app/nosotros?tipo=privacidad`; ver `SEGURIDAD_DE_LOS_DATOS.md` |
| 11 | **Eliminar la cuenta desde la app** | 🟡 PR #101 + backend PR #5 | Perfil › Privacidad › Eliminar mi cuenta |
| 12 | **URL web para pedir el borrado** sin instalar la app | 🟡 página `/eliminar-cuenta` del front | `SEGURIDAD_DE_LOS_DATOS.md` |
| 13 | Formulario de Seguridad de los datos | ✅ respuestas | `SEGURIDAD_DE_LOS_DATOS.md` |
| 14 | Clasificación de contenido (cuestionario IARC) | ✅ respuestas | `CLASIFICACION_Y_ACCESO.md` |
| 15 | Público objetivo y anuncios | ✅ respuestas (decisión del equipo marcada) | `CLASIFICACION_Y_ACCESO.md` |
| 16 | Cuenta de prueba para revisores (sin 2FA) en producción | 👥 | `CLASIFICACION_Y_ACCESO.md` |
| 17 | Cron diario de `suprimir_cuentas_vencidas` en Render | 👥 tras fusionar backend PR #5 | `SEGURIDAD_DE_LOS_DATOS.md` |
| 18 | Prueba interna (hasta 100 testers, sin revisión larga) | 👥 | `FIRMA_Y_PUBLICACION.md` |
| 19 | **Prueba cerrada: ≥ 12 testers durante 14 días seguidos** (cuentas personales creadas después del 13-nov-2023) antes de pedir producción | 👥 | `FIRMA_Y_PUBLICACION.md` |

## Calendario sugerido (entrega final: 7-dic-2026)
Por el requisito de la prueba cerrada, la fecha que manda es la del **inicio de la prueba cerrada**: 14 días más la revisión del acceso a producción (Google tarda alrededor de una semana).

| Fecha límite | Paso |
|---|---|
| 26-oct | Cuenta de desarrollador creada y verificada; keystore y secretos cargados |
| 2-nov | Hito `0.4.0`: primer AAB en **prueba interna** |
| 9-nov | **Prueba cerrada** con 15 a 20 testers (holgura por si alguno sale; si bajan de 12, el conteo de 14 días se reinicia) |
| 23-nov | Termina la prueba cerrada; se pide el acceso a producción |
| 30-nov | `1.0.0-rc.1` aprobada para producción (o, si no da tiempo, se entrega con la evidencia de la prueba cerrada) |
