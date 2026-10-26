# MATRIZ DE CUMPLIMIENTO — Instrumento Integral de Evaluación Móvil

**Proyecto:** Stylo Barber Connect Mobile (`/Movil`)  
**Versión app:** `0.1.0+1`  
**Fecha de elaboración:** 2026-10-06  
**Última revisión:** 2026-10-21, todas las filas. Cada estado se comprobó contra GitHub (PRs, protección de ramas, runs), `docs/evidencias/` y las pruebas de `develop`.  
**Fuente de criterios:** Instrumento Integral de Evaluación Móvil (octubre–noviembre 2026), según requisitos oficiales comunicados.  
**PDF adjunto en workspace:** **No encontrado** al momento de esta matriz (`[No comprobado]` búsqueda de `*Instrumento*` / PDF en `/Movil` y raíz). Los criterios se toman **literalmente** del enunciado oficial proporcionado por el profesor vía la consigna de esta fase.

**Leyenda de estado**

| Estado | Significado |
|--------|-------------|
| Cumple | Implementado **y** comprobado (código + prueba/evidencia) |
| Parcial | Hay avance real, pero falta prueba, evidencia o un subcriterio |
| Pendiente | No implementado o no ejecutado |
| Bloqueado | Depende de backend/proceso externo no autorizado aún |
| No comprobado | No se pudo verificar (falta PDF, dispositivo, cuenta Play, etc.) |
| No aplica | El criterio no aplica a la app actual; no cuenta en la puntuación |

**Capas de madurez (no confundir)**

| Capa | Definición |
|------|------------|
| Implementado | Existe código/configuración |
| Probado | Hay ejecución de prueba con resultado |
| Documentado | Descrito en README/docs |
| Evidenciado | Capturas/logs/artefactos guardados para entrega |
| Aceptado | Revisado/aprobado por el profesor (fuera de alcance del agente) |

---

## ACTIVIDAD 5 — Repositorio, versionamiento y CI/CD  
**Puntuación:** 3 puntos · **Entrega:** 22 de octubre de 2026

| # | Criterio oficial | Estado | Implementado | Probado | Documentado | Evidenciado | Archivos / evidencias | Prueba necesaria | Acción pendiente | Responsable |
|---|------------------|--------|--------------|---------|--------------------------|------------------------|------------------|------------------|-------------|---|
| 5.1 | GitFlow activo (`main`, `develop`, `feature/*`) | **Parcial** | Sí: `main`, `develop` y ramas `feature/*`, `fix/*` y `docs/*`. `develop` y `main` protegidas: 1 aprobación, checks obligatorios "Flutter quality gate" y "SAST Semgrep gate", rama al día y descarte de aprobaciones obsoletas (también para administradores en `develop`) | Sí: 20 PRs hacia `develop` (#88–#107), todos aprobados y con CI verde; `develop` → `main` en #87 (12-oct) | Sí: `ACTIVIDAD_5_GITFLOW_CICD.md`, `POLITICA_CI_SAST.md` | Sí: historial de PRs en GitHub | `gh pr list --state merged`; protección en `GET /repos/…/branches/{develop,main}/protection` | Primer ciclo `develop` → `release` → `main` con tag | Crear la rama `release`, PR de versión `0.4.0+2`, fusionar en `main` (el tag `v0.4.0` lo crea `release.yml`) y back-merge a `develop`. Hoy no hay rama `release` ni tags | Equipo |
| 5.2 | Historial colaborativo de **ambos** integrantes | **Cumple** | Sí: commits de los dos con su identidad en `develop` (`git shortlog -sne`): Gilberto Hernández (54) y Jorge Miguel Cayetano (6, del 11 y 12-oct: `24de646` GH#09, `d2d14b2`, `3b9f04e` y las fusiones de #81, #85 y #86) | Sí: CAYETANOJM aprobó los 20 PRs #88–#107 y fusionó #107 | Sí | Sí: revisiones en cada PR | Pestaña *Pull requests* (filtro `is:merged`) | — | El historial está desbalanceado: conviene que Jorge sume commits propios en las siguientes features. **No fabricar** historial | Ambos |
| 5.3 | Commits claros y estructurados | **Cumple** | Sí: Conventional Commits desde #88 (`feat(privacidad): …`, `fix(red): …`, `test(unit): …`, `ci: …`, `docs: …`), con squash y número de PR | N/A | Sí: `ACTIVIDAD_5_GITFLOW_CICD.md` | Sí | `git log --oneline origin/develop` | — | La historia anterior al 12-oct conserva mensajes genéricos ("rediseño", "first commit"); no se reescribe | Equipo |
| 5.4 | Pipeline en `.github/workflows` | **Cumple** | Sí: `ci.yml` (PR y push a `develop`, `release` y `main`), `release.yml` (AAB y APK firmados y ofuscados al fusionar en `release`/`main`) y `pinning.yml` (revisión semanal de los pines) | Sí: corre en cada PR (62 runs de PR en verde entre los últimos 100). Último run de `develop`: [39661252192](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/39661252192), 21-oct, en verde | Sí: `POLITICA_CI_SAST.md` | Sí: runs y artefactos (logs, `lcov.info`, SARIF) | `.github/workflows/*.yml` | — | `release.yml` todavía no ha corrido: falta la rama `release` y los secretos de firma (GH#53) | Dev móvil |
| 5.5 | Análisis de seguridad SAST/DAST | **Parcial** | SAST: Semgrep obligatorio en cada PR. DAST: procedimiento documentado, sin ejecutar | SAST sí: 0 hallazgos de severidad ERROR en los runs del 21-oct. Además, análisis estático del APK release (`estatico-2026-10-21`). DAST no | Sí: `DAST_PROCEDIMIENTO.md` | SAST sí; DAST no | `.semgrep.yml`, `.github/workflows/ci.yml`, `docs/evidencias/estatico-2026-10-21/` | DAST autorizado contra un ambiente de pruebas | Levantar staging (GH#68) y ejecutar el DAST de `DAST_PROCEDIMIENTO.md`. Nunca contra producción | Dev móvil + seguridad |
| 5.6 | Herramientas admitidas (SonarQube, MobSF, Semgrep, Snyk) | **Cumple** | Semgrep con `p/secrets`, `p/security-audit`, `p/owasp-top-ten` y reglas propias (TLS, log de tokens, cleartext) | Sí: en GitHub Actions en cada PR y push | Sí: `POLITICA_CI_SAST.md` | Sí: SARIF/JSON como artefacto | `.semgrep.yml` | — | MobSF queda para la Actividad 6 (GH#49) | Equipo |
| 5.7 | Ausencia de fallos críticos en análisis previo a compilación | **Cumple** | `semgrep … --severity ERROR --error`, `flutter analyze` y cobertura mínima del 55 % (`tool/coverage_gate.sh`) como checks obligatorios antes de fusionar | Sí: el último run de `develop` pasa los dos gates; la protección impide fusionar con un check en rojo | Sí | Sí: runs | Run 39661252192 | Fallo controlado: un PR de prueba con un test roto queda bloqueado | Evidenciar ese fallo controlado (captura del PR bloqueado) | Equipo |

**Resumen Actividad 5 (21-oct):** GitFlow `feature/*` → `develop` funcionando con protección real y 20 PRs revisados por el compañero; CI y SAST obligatorios en cada PR y en verde. Para cerrar la actividad faltan el primer ciclo `release` → `main` con tag (5.1) y el DAST (5.5).

---

## ACTIVIDAD 4 — Interfaces, arquitectura, patrones y pruebas  
**Puntuación:** 7 puntos · **Entrega:** 29 de octubre de 2026

| # | Criterio oficial | Estado | Implementado | Probado | Documentado | Evidenciado | Archivos / evidencias | Prueba necesaria | Acción pendiente | Responsable |
|---|------------------|--------|--------------|---------|--------------------------|------------------------|------------------|------------------|-------------|---|
| 4.1 | Pantallas Flutter funcionales | **Cumple** | Sí: invitado (inicio, servicios, detalle, productos, contacto), acceso (login, registro con código, 2FA), cliente (inicio, agendar en pasos, mis citas, tienda, pedido, perfil, privacidad) y secretaría (Hoy, detalle, Llegó, No asistió, cobro) | Sí: pruebas de widget y recorrido en emulador (Android 17) contra Django local, con 20 casos esperado/observado | Sí: `README.MD`, `DESIGN.md` | Sí: 21 capturas del rediseño y 20 del recorrido | `lib/views/**`; `docs/evidencias/rediseno-2026-10-20/`, `docs/evidencias/sprint-2026-10-20/` | — | Repetir las capturas principales en un Android físico (SF-02) | Dev móvil |
| 4.2 | Arquitectura MVVM/Clean desacoplada | **Cumple** | Sí: View → ViewModel (`ChangeNotifier`) → Repository → `*ApiService` → `ApiClient`, con DI en `AppScope` | Sí: `test/viewmodel_repository_test.dart` (ViewModels con repositorios falsos, sin red) y `test/integration/repositories_http_test.dart` (Repository → Service → `ApiClient` con `MockClient`) | Sí: `ARQUITECTURA_Y_PATRONES.md`, con diagrama | Sí | `lib/viewmodels/`, `lib/repositories/`, `lib/services/`, `lib/core/di/app_scope.dart` | — | Dividir las vistas más grandes (`client_home_view.dart`) | Arquitecto |
| 4.3a | Patrón **Singleton** | **Cumple** | Sí: `AppScope.create()` arma una sola vez el grafo (un `ApiClient`, un `SecureTokenStorage`) y `main.dart` lo comparte con `Provider` | Indirecto: las pruebas montan su propio grafo con dobles, sin estado global | Sí: `ARQUITECTURA_Y_PATRONES.md` §2, que explica por qué no hay `static instance` | Sí | `lib/core/di/app_scope.dart`, `lib/main.dart` | — | — | Arquitecto |
| 4.3b | Patrón **Factory** | **Cumple** | Sí: `*.fromJson` de los DTO, `ApiException.fromBody` y `AuthApiService.login` (crea `LoginSuccess` o `LoginRequires2FA`) | Sí: `test/unit/models_json_test.dart` con fixtures del JSON real de Django (`test/fixtures/*.json`) y `test/contacto_horarios_test.dart` | Sí: §3 | Sí | `lib/models/*`, `lib/core/errors/app_exception.dart` | — | — | Dev móvil |
| 4.3c | Patrón **Repository** | **Cumple** | Sí: `lib/repositories/*`; `CatalogRepository` es una interfaz con su implementación | Sí: repositorios falsos en las pruebas de widget y `repositories_http_test.dart` con `MockClient` | Sí: §4 | Sí | `lib/repositories/*` | — | — | Dev móvil |
| 4.3d | Patrón **Observer** | **Cumple** | Sí: cada ViewModel extiende `ChangeNotifier`; las vistas se suscriben con `Consumer`/`context.watch` | Sí: `test/client_secretary_premium_test.dart` (la búsqueda filtra en vivo la agenda) y `test/secretaria_cobro_dialogo_test.dart` (el cobro actualiza el estado) | Sí: §5 | Sí | `lib/viewmodels/*` | — | — | Dev móvil |
| 4.4 | Pruebas caja blanca: unitarias | **Cumple** | Sí: Mockito (`test/mocks/`), ViewModels (PM-U01), modelos con fixtures, validadores y privacidad en `test/unit/` | Sí: 286 pruebas en verde en CI (unitarias, de widget y de integración); cobertura de líneas 76.96 % (antes 55.44 %) | Sí | Sí: logs y cobertura en `docs/evidencias/pruebas/2026-10-19/` y artefactos de CI | `test/unit/*`, `test/mocks/*` | — | Mantener el gate de cobertura (mínimo 55 %) y subirlo por hito | QA |
| 4.5 | Pruebas de integración | **Cumple** | Sí: `test/integration/` (`ApiClient`, refresh, errores de red y repositorios contra `MockClient`) e `integration_test/pi01_reserva_test.dart` (reserva en emulador contra Django local) | Sí: PI-01 1/1 el 19 y el 20-oct; recorrido de los tres roles 1/1 el 20-oct | Sí | Sí: `pi01_*.log`, `recorrido_2026-10-20.log` | `docs/evidencias/pruebas/2026-10-19/`, `docs/evidencias/sprint-2026-10-20/` | — | Versionar el test del recorrido en `integration_test/` (hoy solo hay una copia `.txt` en la evidencia) | QA |
| 4.6 | Assertions sobre lógica interna (VM/Repo/Models) | **Cumple** | Sí | Sí: 401 → refresh → reintento, corte de red al renovar, 5xx y HTML de error, doble envío en secretaría, conflicto de horario, rol cliente rechazado en secretaría, cancelación sin folio no se da por hecha | Sí | Sí | `test/unit/viewmodels_mockito_test.dart`, `test/integration/api_client_*_test.dart`, `test/arco_cancelacion_test.dart` | — | Guarda propia contra doble envío en `ClientCitasViewModel` (ERR-06) | QA |
| 4.7 | Navegación funcional | **Cumple** | Sí: rutas con nombre, barra inferior por rol y Splash que restaura sesión y rol | Sí: `test/splash_routes_test.dart`, `test/splash_view_test.dart`; en emulador, invitado → login → cliente → logout → secretaría (PM01, PM09) | Sí | Sí: capturas `02` a `13` del recorrido | `lib/routes/app_routes.dart`; `docs/evidencias/sprint-2026-10-20/` | — | Guardas en rutas directas y deep links (GH#70) | Dev móvil |
| 4.8 | UX/UI responsiva sin errores visuales | **Parcial** | Sí: sistema de diseño con targets ≥ 48 dp y texto escalable | Sí en pruebas de widget: 360×800, 390×844, 800×1280 y 800×360, con texto al 1.3 en las pantallas nuevas. En emulador solo a 1080×2400 | Sí: `DESIGN.md` | Parcial: capturas solo a 1080×2400 | `test/client_secretary_premium_test.dart`, `test/cliente_test.dart`, `test/arco_cancelacion_test.dart` | Revisión visual a 360×800 y en tablet; TalkBack | Capturas en esos tamaños y revisión con TalkBack (GH#18, GH#19, PM10) | UX/Dev |

**Resumen Actividad 4 (21-oct):** las pantallas de los tres roles funcionan contra Django. MVVM + Repository y los cuatro patrones están documentados y probados. Hay 286 pruebas en verde, con 76.96 % de cobertura. Solo falta la revisión visual en tamaños chicos y con TalkBack (4.8).

**Patrones ya implementados (ubicación exacta, sin inventar)**

| Patrón | Justificación real | Ubicación |
|--------|--------------------|-----------|
| Repository | Aísla fuentes de datos de ViewModels | `lib/repositories/catalog_repository.dart`, `auth_repository.dart`, `citas_repository.dart`, `secretaria_repository.dart` |
| Factory | Construcción tipada desde JSON/contratos Django | `lib/models/*.dart` (`fromJson`); `ApiException.fromBody`; `AppScope.create` |
| Observer | UI reacciona a cambios de estado | `ChangeNotifier` en `lib/viewmodels/*`; consumo en Views vía `Provider`/`Consumer` |
| Singleton (composition root) | Un grafo DI por proceso | `AppScope` creado una vez en `main.dart`. **No** hay `getInstance()` clásico; el motivo está en `ARQUITECTURA_Y_PATRONES.md` §2 |

---

## ACTIVIDAD 6 — Cloud y seguridad integral  
**Puntuación:** 8 puntos · **Entrega:** 26 de noviembre de 2026

| # | Criterio oficial | Estado | Implementado | Probado | Documentado | Evidenciado | Archivos / evidencias | Prueba necesaria | Acción pendiente | Responsable |
|---|------------------|--------|--------------|---------|--------------------------|------------------------|------------------|------------------|-------------|---|
| 6.1 | API REST operativa | **Cumple** | Sí: `ApiClient` y services para catálogo público, autenticación, cliente, secretaría y privacidad | Sí: lecturas contra producción (Render) en solo lectura; escrituras (reserva, Llegó, cobro, ARCO) contra Django local con PostgreSQL | Sí: tabla de endpoints en `README.MD` | Sí: recorrido, PI-01 y log del servidor | `lib/services/*`; `docs/evidencias/sprint-2026-10-20/`, `docs/evidencias/arco/2026-10-21-cancelacion/servidor_2026-10-21.log` | — | Staging para pruebas que escriben sin depender de la base local (GH#68) | Equipo |
| 6.2 | JWT Bearer | **Cumple** | Sí: header `Authorization: Bearer` en `ApiClient`; tokens en `SecureTokenStorage` | Sí: login real contra Django local (PM01 válido e inválido) y pruebas con `MockClient` que verifican el Bearer (`test/unit/privacidad_test.dart`, `test/arco_cancelacion_test.dart`) | Sí | Sí | `lib/core/network/api_client.dart` | — | 2FA por correo real en un ambiente autorizado (GH#11) | Dev |
| 6.3 | Interceptor 401 + refresh | **Cumple** | Sí: `ApiClient._tryRefresh` → `POST /auth/token/refresh/` una vez y reintento; si el refresh falla, cierra sesión. Un corte de red al renovar ya no la cierra (ERR-12) | Sí: `test/integration/api_client_refresh_test.dart` (#91) y `test/integration/api_client_errores_red_test.dart` (#103) | Sí | Sí: logs de pruebas | `docs/evidencias/pruebas/2026-10-19/`, `docs/evidencias/red-2026-10-21/` | — | — | Dev |
| 6.4 | Certificate Pinning SHA-256 | **Cumple** | Sí: `SecurityContext` solo con 5 raíces fijadas (GTS R4 primario; GTS R1/R3 e ISRG X1/X2 de respaldo) en `cliente_http.dart` | Sí: 10 pruebas (incluye servidor TLS con certificado no permitido), backend real y emulador | Sí: `PINNING_ROTACION.md` | Sí | `docs/evidencias/pinning-2026-10-21/`, workflow semanal `pinning.yml` | — | Rotar según `PINNING_ROTACION.md` | Seguridad |
| 6.5 | Almacenamiento local cifrado Android | **Cumple** | Sí: `flutter_secure_storage` con `encryptedSharedPreferences` (nombres AES-256-SIV, valores AES-256-GCM, llave en el Android Keystore) y `allowBackup=false` | Sí: en emulador, `FlutterSecureStorage.xml` tiene 6 entradas y ninguna es legible (20-oct) | Sí | Sí | `docs/evidencias/seguridad/almacenamiento-cifrado-2026-10-20.md` | — | Repetir en un Android físico | Dev |
| 6.6 | Aviso de privacidad | **Cumple** | Sí: pantalla "Aviso de privacidad" con el texto de `GET /public/legal/?tipo=privacidad`. Es la misma política publicada en `tonystylo.vercel.app/nosotros?tipo=privacidad` | Sí: en emulador contra Django local (`10_aviso_optin_apagado.png`) y `test/privacidad_views_test.dart` | Sí: `docs/play/SEGURIDAD_DE_LOS_DATOS.md` | Sí | PR #90; `docs/evidencias/sprint-2026-10-20/` | — | Llenar los tres marcadores del texto publicado: responsable, RFC y correo ARCO (GH#59) | Equipo |
| 6.7 | Consentimiento Opt-In explícito (inicialmente desactivado) | **Cumple** | Sí: las finalidades opcionales empiezan apagadas; el consentimiento se guarda en la cuenta con fecha y versión del aviso (`GET/PUT /api/privacidad/preferencias/`, backend PR #3) | Sí: en emulador, activar y desactivar se guardan en el servidor con su fecha y versión (`11a_…`, `11b_…`); `test/unit/privacidad_test.dart` | Sí | Sí | PR #90; `docs/evidencias/sprint-2026-10-20/` | — | — | Dev |
| 6.8a | ARCO Acceso (consultar perfil) | **Cumple** | Sí: "Mis datos" con el perfil y el historial de citas del titular (`GET /perfil/`, `GET /mis-citas/`) | Sí: en emulador (`08_arco_mis_datos.png`) y con `MockClient` (si falla el historial, el perfil se muestra igual) | Sí | Sí | PR #90; `docs/evidencias/sprint-2026-10-20/` | — | Probar el aislamiento entre cuentas (PM02, depende de ERR-02 y ERR-03) | Dev |
| 6.8b | ARCO Rectificación (editar perfil) | **Parcial** | Sí: "Corregir mis datos" con `PUT /perfil/`, validaciones y reenvío de avatar y dirección (ERR-07) | Parcial: con `MockClient` (guarda una vez, un error del servidor no se da por guardado, sin doble PUT); en emulador solo se abrió el formulario | Sí | Parcial: `09_arco_corregir_datos.png` | PR #90 | Guardar un cambio real en emulador contra Django local | Capturar el antes y el después (GH#43) | Dev |
| 6.8c | ARCO Cancelación (eliminar cuenta) | **Cumple (falta el Cron en Render)** | Sí: app (Perfil › Privacidad › Eliminar mi cuenta, PR #101), `POST /api/privacidad/cancelacion/` (backend PR #5, fusionado y desplegado en Render) y página pública `/eliminar-cuenta` (front PR #3, en Vercel): bloqueo inmediato y supresión a los 30 días | Sí: 10 pruebas Django, 12 de Flutter, E2E en emulador | Sí | Sí | `docs/evidencias/arco/2026-10-21-cancelacion/` | — | Programar `python manage.py suprimir_cuentas_vencidas` como Cron Job diario en Render. Sin él, las cuentas quedan bloqueadas pero no se suprimen a los 30 días | Dev |
| 6.8d | ARCO Oposición (Opt-Out) | **Parcial** | Sí: el titular puede apagar las finalidades opcionales, incluida `acepta_analitica_perfilado` (analítica y perfilado), y el backend lo guarda con fecha y versión | Sí: desactivar se guarda en el servidor (`11b_aviso_optin_desactivado_en_backend.png`) | Sí | Sí | PR #90; backend PR #3 | Que la predicción de inasistencia y la segmentación excluyan a quien se opuso | El backend guarda la preferencia, pero los módulos de ML aún no la consultan (GH#45) | Equipo |
| 6.9 | R8/ProGuard (`minifyEnabled`, `shrinkResources`, reglas) | **Cumple** | Sí: `isMinifyEnabled`, `isShrinkResources`, `proguard-rules.pro` | Sí: 981 de 1 038 clases renombradas (95 %) en `mapping.txt` | Sí | Sí | `docs/evidencias/estatico-2026-10-21/ANALISIS_ESTATICO.md` | — | `mapping.txt` nunca se versiona; `release.yml` lo cifra | Android |
| 6.10 | Ofuscación release | **Cumple** | Sí: `--obfuscate --split-debug-info` en `release.yml` | Sí: 14 identificadores de la app pasan de 1–2 apariciones a 0 en `libapp.so`; el APK ofuscado funciona en el emulador | Sí | Sí | `docs/evidencias/estatico-2026-10-21/` | — | Símbolos cifrados con `SYMBOLS_PASSPHRASE` | Dev |
| 6.11 | Evaluación JADX/MobSF | **Parcial** | Análisis estático con aapt2, apksigner, zipalign y `tool/analisis_apk.py` (manifiesto, componentes exportados, firma, 16 KB, R8, Dart y secretos) | Sí | Sí | Sí | `docs/evidencias/estatico-2026-10-21/ANALISIS_ESTATICO.md` | Capturas de JADX-GUI y reporte MobSF | Bajar JADX/mobsfscan (decisión del equipo) | Seguridad |
| 6.12 | Pruebas caja negra E2E | **Parcial** | Sí: `integration_test` en emulador: PI-01 (reserva) y recorrido de los tres roles | Sí: 1/1 el 19 y el 20-oct, contra Django local | Sí | Sí: logs y 20 capturas | `integration_test/pi01_reserva_test.dart`, `docs/evidencias/sprint-2026-10-20/` | Aceptación con Patrol (PA-01 a PA-07) | Agregar Patrol, versionar el recorrido y correr PA-01 a PA-07 | QA |
| 6.13 | Matriz Debug/Release | **Cumple** | Sí: tabla de controles para Debug, Release sin ofuscar y Release ofuscado (GH#52) | Sí: comprobada sobre los tres APK con `aapt2` y lectura de los binarios | Sí | Sí | `docs/evidencias/seguridad/2026-10-19/README.md`, sección "Matriz Debug vs Release" | — | Repetir con `0.4.0+2` y la firma de subida | QA |
| 6.14 | Registro de errores encontrados/corregidos | **Cumple** | Sí: `docs/evaluacion/REGISTRO_ERRORES.md`, con ERR-01 a ERR-14 (cómo se encontró, estado y evidencia) | Sí: cada error marcado "Corregido" tiene su prueba en `test/` | Sí | Sí | `REGISTRO_ERRORES.md`; evidencias en `docs/evidencias/pruebas/2026-10-19/`, `arco/2026-10-21-cancelacion/`, `red-2026-10-21/` y `encuadre-fotos-2026-10-21/` | — | Siguen abiertos ERR-02 y ERR-03 (backend, PM02), ERR-05, ERR-06 y ERR-14 (backend, doble reserva simultánea, PM04) | QA |

**Resumen Actividad 6 (21-oct):** API, JWT con refresh, certificate pinning, almacenamiento cifrado, R8 y ofuscación, aviso con opt-in y ARCO de Acceso y Cancelación están comprobados.

Faltan:
- Guardar una rectificación en el emulador (6.8b).
- Que el ML respete la oposición (6.8d).
- Las capturas de JADX y el reporte de MobSF (6.11).
- La aceptación con Patrol (6.12).
- El Cron de supresión en Render (6.8c).

---

## ACTIVIDAD 7 — Publicación Google Play  
**Puntuación:** 2 puntos · **Entrega:** 26 de noviembre de 2026

| # | Criterio oficial | Estado | Implementado | Probado | Documentado | Evidenciado | Archivos / evidencias | Prueba necesaria | Acción pendiente | Responsable |
|---|------------------|--------|--------------|---------|--------------------------|------------------------|------------------|------------------|-------------|---|
| 7.1 | App en revisión o publicada | **Pendiente** | No | No | Sí: pasos de prueba interna, prueba cerrada y producción en `docs/play/FIRMA_Y_PUBLICACION.md` §3 | No | `docs/play/` | Versión en Prueba interna de Play | Crear la cuenta de Play Console y la app, y subir el AAB firmado. Con cuenta personal, prueba cerrada con al menos 12 testers durante 14 días antes de pedir producción | Product Owner |
| 7.2 | APK/AAB firmado correctamente | **Parcial** | Sí: `release.yml` compila AAB y APK ofuscados, los firma con el keystore de los secretos y **falla** si quedan firmados con la clave debug (#92) | Parcial: APK release normal y ofuscado del 21-oct, con firma v2 válida pero con la clave debug; instalados en emulador | Sí: `FIRMA_Y_PUBLICACION.md` §2 | Sí: `ANALISIS_ESTATICO.md` | `.github/workflows/release.yml`, `docs/evidencias/estatico-2026-10-21/` | AAB firmado por `release.yml` | Crear el keystore y los secretos (GH#53) y después la rama `release` | Android |
| 7.3 | Firma de publicación (no debug) | **Bloqueado** | Sí: el `signingConfig` de release lee `android/key.properties` (#88); en CI, el keystore sale de los secretos | No: todavía no existe la clave de subida | Sí: `FIRMA_Y_PUBLICACION.md` §1 | No | `android/app/build.gradle.kts` | Build firmado con la clave de subida | El equipo crea el keystore con `keytool` y carga los 5 secretos (GH#53, GH#54); la clave y sus contraseñas no salen del equipo | Equipo |
| 7.4 | Permisos Android justificados | **Cumple** | Sí: solo `INTERNET` | Sí: manifiesto del APK release leído con `aapt2` | Sí: `docs/evaluacion/PERMISOS_Y_DATOS.md` y `docs/play/SEGURIDAD_DE_LOS_DATOS.md` | Sí: `ANALISIS_ESTATICO.md` | `android/app/src/main/AndroidManifest.xml` | — | Si se agrega un permiso, justificarlo en esos dos documentos | Dev |
| 7.5 | Diálogos runtime de permisos | **No aplica** | No hay permisos peligrosos: `INTERNET` es normal y no pide diálogo | Sí: verificado en el manifiesto del APK release | Sí: `PERMISOS_Y_DATOS.md` | Sí | `ANALISIS_ESTATICO.md` | — | Si se agregan cámara o ubicación, pedirlos en tiempo de ejecución con una explicación previa | Dev |
| 7.6 | Evidencias Google Play Console | **Pendiente** | No | No | Sí: kit de la ficha (`FICHA.md`, ícono, gráfico destacado y 5 capturas) | No | `docs/play/` | Capturas de la consola | Tomarlas al crear la app y subir la versión | Product Owner |

**Resumen Actividad 7 (21-oct):** el kit de Play y el pipeline de firma están listos. Falta lo que depende del equipo: keystore, cuenta de Play Console, marcadores de la política (GH#59) y la prueba cerrada.

---

## Puntuación potencial (autodiagnóstico honesto)

Cálculo: cada criterio vale 1 si Cumple, 0.5 si es Parcial y 0 si está Pendiente o Bloqueado; "No aplica" no cuenta. El resultado se prorratea con los puntos de cada actividad.

| Actividad | Puntos | Criterios (Cumple / Parcial / Pendiente o Bloqueado) | Estimación al 21-oct | Qué falta |
|-----------|--------|------------------------------------------------------|----------------------|-----------|
| 5 | 3 | 5 / 2 / 0 | ≈ 2.6 (86 %) | Ciclo `release` → `main` con tag y DAST |
| 4 | 7 | 10 / 1 / 0 | ≈ 6.7 (95 %) | Revisión visual a 360×800 y en tablet, y TalkBack |
| 6 | 8 | 13 / 4 / 0 | ≈ 7.1 (88 %) | Patrol, capturas de JADX y reporte de MobSF, guardar una rectificación en emulador y que el ML respete la oposición |
| 7 | 2 | 1 / 1 / 3 (más 1 que no aplica) | ≈ 0.6 (30 %) | Keystore, AAB firmado, cuenta de Play Console, prueba interna y cerrada |
| **Total** | **20** | **29 / 8 / 3** | **≈ 17 (85 %)**; sin la Actividad 7, ≈ 16.3 de 18 (91 %) | |

**Nota:** Estimación ≠ calificación del profesor. Nada se marca “Aceptado”.
