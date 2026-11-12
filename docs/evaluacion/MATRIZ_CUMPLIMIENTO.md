# Matriz de cumplimiento: Instrumento Integral de Evaluación Móvil (GH#75)

| Dato | Valor |
|---|---|
| Proyecto | Stylo Barber Connect Mobile (`Gilberto625/MovilStyloBarberConect`) |
| Versión de la app | **0.8.1+5** (`pubspec.yaml`), tag `v0.8.1`, AAB firmado por `release.yml` (run [41021801630](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/41021801630)). En `develop` hay cambios posteriores sin publicar: PR #125 a #128 y, en revisión, el PR #129 |
| Elaborada | 2026-10-06 |
| Última revisión | **2026-11-11**, todas las filas. Cada estado se comprobó contra GitHub (PRs, protección de ramas, runs, releases), `docs/evidencias/` y los documentos de `docs/evaluacion/` |
| Fuente de criterios | Instrumento Integral de Evaluación Móvil (octubre–noviembre 2026), según la consigna del profesor. El PDF no está en el repo; los criterios se copian del enunciado |

## Cómo leer la matriz

**Estado**

| Estado | Significado |
|---|---|
| Cumple | Implementado **y** comprobado (código + prueba o evidencia) |
| Parcial | Hay avance real, pero falta una prueba, una evidencia o un subcriterio |
| Pendiente | No implementado o no ejecutado |
| Bloqueado | Depende de un proceso externo o de otra persona |
| No aplica | El criterio no aplica a la app actual; no cuenta en la puntuación |

**Capas de madurez:** cada fila dice por separado si está **implementado** (existe el código o la configuración), **probado** (hay una ejecución con resultado) y **evidenciado** (el log, la captura o el run están guardados). La capa **aceptado** (visto bueno del profesor) no se marca en ninguna fila: ocurre al firmar `ACTA_ACEPTACION.md`.

**Issue:** número del Issue de GitHub (`GH#NN`) que replica la tarjeta del tablero. Una fila puede tener varios.

---

## Alcance de la app (GH#08, S1-01)

La versión 1 cubre **cuatro roles**: invitado, cliente, secretaría y barbero. El rol lo da Django y la app lleva a cada quien a su panel. Fuera de la app, en la web: administración, reportes, inventario, ventas, pagos con Clip y corte de caja.

| Rol | Qué hace en la app | Evidencia |
|---|---|---|
| Invitado | Catálogo de servicios y productos, contacto, aviso de privacidad y registro | `docs/manual/MANUAL_CLIENTE.md`; capturas `inv_*` y `reg_*` en `docs/manual/img/` |
| Cliente | Reservar en 4 pasos, Mis citas, reprogramar y cancelar su cita, tienda y pedidos, perfil, privacidad (ARCO) y código por correo opcional | `MANUAL_CLIENTE.md`; batería PM01–PM10 (`BATERIA_FINAL_PM.md`) |
| Secretaría | Agenda del día, Cliente llegó, No asistió, cobro, clientes, nueva cita, cliente de paso y reprogramar | `docs/manual/MANUAL_SECRETARIA_BARBERO.md`; batería del 11-nov, sección Secretaría |
| Barbero | Su agenda; "Pasó a la silla" y "Terminé el servicio" en las citas de hoy | `MANUAL_SECRETARIA_BARBERO.md`; PM06 del 11-nov |

- **Decisión:** `DECISION_ALCANCE_ROLES.md` (2026-10-23), tomada por el equipo.
- **Visto bueno del docente: pendiente.** No consta en el repo ni en el Issue #8, que sigue abierto.
- La Actividad 1 planteaba Visitante, Cliente y Barbero. La app agrega Secretaría porque la operación del día (llegada, inasistencia y cobro) la hace recepción. El barbero no marca "No asistió", porque esa acción penaliza al cliente.

---

## ACTIVIDAD 5: Repositorio, versionamiento y CI/CD

**Puntuación:** 3 puntos · **Entrega:** 22 de octubre de 2026

| # | Criterio oficial | Issue | Estado | Implementado | Probado | Evidenciado | Evidencia (ruta o PR) | Pendiente |
|---|---|---|---|---|---|---|---|---|
| 5.1 | GitFlow activo (`main`, `develop`, `feature/*`) | GH#01, GH#29, GH#30, GH#67 | **Cumple** | Sí: `main`, `release`, `develop` y ramas `feature/*`, `fix/*`, `docs/*`, `chore/*`. `develop` y `main` protegidas: 1 aprobación, checks "Flutter quality gate" y "SAST Semgrep gate", rama al día, también para administradores | Sí: tres ciclos completos `develop` → `release` → `main` con tag y back-merge: 0.4.0 (PR #111, #112, #113), 0.8.0-beta.1 (#115 a #119) y 0.8.1 (#121 a #124) | Sí | Tags `v0.4.0`, `v0.8.0-beta.1` y `v0.8.1`; protección en `POLITICA_CI_SAST.md` | `release` no tiene protección de rama |
| 5.2 | Historial colaborativo de **ambos** integrantes | GH#05, GH#37 | **Cumple** | Sí: commits de los dos en `develop` (`git shortlog -sne origin/develop`): Gilberto Hernández 78 y Jorge Cayetano 8 | Sí: los 41 PR fusionados del #88 al #128 tienen aprobación; Jorge (CAYETANOJM) es el revisor de los PR de la app | Sí: revisiones en cada PR | Pestaña Pull requests (`is:merged`) | El historial sigue desbalanceado. No se fabrica historial |
| 5.3 | Commits claros y estructurados | GH#06 | **Cumple** | Sí: Conventional Commits desde #88 (`feat(…)`, `fix(…)`, `docs(…)`, `chore(ci)`), con squash y número de PR | No aplica | Sí | `git log --oneline origin/develop`; `ACTIVIDAD_5_GITFLOW_CICD.md` | La historia anterior al 12-oct conserva mensajes genéricos; no se reescribe |
| 5.4 | Pipeline en `.github/workflows` | GH#02, GH#31, GH#33 | **Cumple** | Sí: `ci.yml` (PR y push a `develop`, `release` y `main`), `release.yml` (AAB y APK firmados y ofuscados) y `pinning.yml` (pines cada semana). Flutter fijo en 3.47.9 (PR #127) | Sí: `release.yml` corrió en `release` y `main` para 0.8.1 (run 41021801630, en verde). CI en verde en los PR #128 y #129 | Sí: runs y artefactos (logs, `lcov.info`, SARIF) | Runs [43146040237](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/43146040237) y [43154349514](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/43154349514); `POLITICA_CI_SAST.md` | — |
| 5.5 | Análisis de seguridad SAST/DAST | GH#03, GH#04, GH#34, GH#36 | **Cumple** | SAST: Semgrep obligatorio en cada PR. DAST: OWASP ZAP 2.17.0 con y sin sesión | SAST: 0 hallazgos ERROR en los runs del 11-nov. DAST: 2026-11-11 contra el backend local; sin críticos ni altos confirmados (un "alto" fue falso positivo verificado a mano) | Sí | `.semgrep.yml`; `DAST_RESULTADOS.md`; `docs/evidencias/dast-zap-2026-11-11/` | DAST sin flujos que escriben datos. Staging no existe como servidor propio: el backend local hace sus veces |
| 5.6 | Herramientas admitidas (SonarQube, MobSF, Semgrep, Snyk) | GH#03, GH#34 | **Cumple** | Semgrep con `p/secrets`, `p/security-audit`, `p/owasp-top-ten` y 3 reglas propias (TLS, log de tokens, cleartext) | Sí: en cada PR y push | Sí: JSON y SARIF como artefacto | `.semgrep.yml`, `.github/workflows/ci.yml` | MobSF no se ejecutó (6.11) |
| 5.7 | Ausencia de fallos críticos en análisis previo a compilación | GH#32 | **Cumple** | `flutter analyze`, pruebas, cobertura mínima del 55 % y `semgrep --severity ERROR --error` como checks obligatorios | Sí: run 43154349514 (PR #129): analyze limpio, 539/539, cobertura 81.15 %, 0 hallazgos ERROR. El run 43135262264 muestra el gate fallando (ERR-18) | Sí | `POLITICA_CI_SAST.md` | Fallo controlado dentro de un PR (captura del PR bloqueado). Clasificar 27 hallazgos no bloqueantes de Semgrep del PR #129 |

**Resumen Actividad 5:** GitFlow completo con tres versiones etiquetadas, CI y SAST obligatorios y DAST ejecutado contra un ambiente autorizado. Quedan detalles: proteger `release` y capturar un PR bloqueado a propósito.

---

## ACTIVIDAD 4: Interfaces, arquitectura, patrones y pruebas

**Puntuación:** 7 puntos · **Entrega:** 29 de octubre de 2026

| # | Criterio oficial | Issue | Estado | Implementado | Probado | Evidenciado | Evidencia (ruta o PR) | Pendiente |
|---|---|---|---|---|---|---|---|---|
| 4.1 | Pantallas Flutter funcionales | GH#09, GH#10, GH#11, GH#12, GH#13 | **Cumple** | Sí: invitado, acceso (login, registro, código opcional), cliente (reserva, Mis citas, reprogramar, cancelar, tienda, perfil, privacidad), secretaría (Hoy, detalle, Llegó, No asistió, cobro, clientes, nueva cita, cliente de paso, reprogramar) y barbero (Mi agenda) | Sí: pruebas de widget y batería PM01–PM10 en emulador contra Django local (2026-11-11) | Sí: 63 capturas de 0.8.1 y 53 de la batería | `lib/views/**`; `docs/manual/img/`; `docs/evidencias/bateria-final-2026-11-11/` | Capturas en un Android físico (SF-02) |
| 4.2 | Arquitectura MVVM/Clean desacoplada | GH#07 | **Cumple** | Sí: View → ViewModel (`ChangeNotifier`) → Repository → `*ApiService` → `ApiClient`, con DI en `AppScope` | Sí: `test/viewmodel_repository_test.dart` y `test/integration/repositories_http_test.dart` | Sí | `ARQUITECTURA_Y_PATRONES.md`; `lib/core/di/app_scope.dart` | Dividir las vistas más grandes (`client_home_view.dart`) |
| 4.3a | Patrón **Singleton** | GH#07 | **Cumple** | Sí: `AppScope.create()` arma una sola vez el grafo y `main.dart` lo comparte con `Provider` | Indirecto: las pruebas montan su propio grafo con dobles | Sí | `ARQUITECTURA_Y_PATRONES.md` §2 | — |
| 4.3b | Patrón **Factory** | GH#07, GH#15 | **Cumple** | Sí: `*.fromJson`, `ApiException.fromBody` y `AuthApiService.login` | Sí: `test/unit/models_json_test.dart` con fixtures | Sí | `ARQUITECTURA_Y_PATRONES.md` §3 | — |
| 4.3c | Patrón **Repository** | GH#07, GH#15 | **Cumple** | Sí: `lib/repositories/*` | Sí: repositorios falsos y `repositories_http_test.dart` | Sí | `ARQUITECTURA_Y_PATRONES.md` §4 | — |
| 4.3d | Patrón **Observer** | GH#07 | **Cumple** | Sí: ViewModels con `ChangeNotifier`, vistas con `Consumer`/`context.watch` | Sí: `test/client_secretary_premium_test.dart`, `test/secretaria_cobro_dialogo_test.dart` | Sí | `ARQUITECTURA_Y_PATRONES.md` §5 | — |
| 4.4 | Pruebas caja blanca: unitarias | GH#14, GH#15 | **Cumple** | Sí: Mockito, ViewModels, modelos con fixtures, validadores y privacidad | Sí: 539 de 539 en CI con cobertura de líneas del 81.15 % (run 43154349514, PR #129) | Sí: logs en los artefactos de CI y en `docs/evidencias/pruebas/` | `test/unit/*`, `test/mocks/*`; `CATALOGO_PRUEBAS.md` §1 | Subir el mínimo de cobertura del gate (sigue en 55 %) |
| 4.5 | Pruebas de integración | GH#16, GH#17 | **Cumple** | Sí: `test/integration/` (29 pruebas HTTP con `MockClient`) e `integration_test/pi01_reserva_test.dart` | Sí: HTTP en cada CI; PI-01 1/1 el 19 y el 20-oct | Sí | `CATALOGO_PRUEBAS.md` §3 | PI-01 no se volvió a correr sobre 0.8.1. El recorrido de tres roles solo existe como copia `.txt` en la evidencia |
| 4.6 | Assertions sobre lógica interna (VM/Repo/Models) | GH#14, GH#69 | **Cumple** | Sí | Sí: 401 → refresh → reintento, corte de red al renovar, 5xx y HTML, 409, 403, doble envío, `ok:false` | Sí | `CONTRATO_ERRORES_HTTP.md`; `test/integration/api_client_*_test.dart` | — |
| 4.7 | Navegación funcional | GH#70 | **Cumple** | Sí: rutas con nombre, barra inferior por rol, Splash que restaura sesión y guarda de rutas por rol (`lib/routes/route_guard.dart`) | Sí: `test/splash_routes_test.dart`; PM09 del 11-nov (cambio de cuenta y de rol) | Sí | `docs/evidencias/bateria-final-2026-11-11/img/pm09_*` | Deep links: la app no los declara |
| 4.8 | UX/UI responsiva sin errores visuales | GH#18, GH#19 | **Parcial** | Sí: objetivos ≥ 48 dp, texto escalable, corrección de la fila de días con texto al 200 % (PR #128) | Sí: 176 pruebas de accesibilidad (texto ×1.3 y ×2.0, 360×640); en emulador, 360×640 dp, texto al 200 % y API 24 | Sí: `docs/evidencias/accesibilidad-2026-11-11/`, `MATRIZ_DISPOSITIVOS.md` | ERR-17 abierto (etiqueta "Productos" en dos líneas con texto al 130 %). TalkBack: falta el recorrido con gestos hecho por una persona |

**Resumen Actividad 4:** las pantallas de los cuatro roles funcionan contra Django. MVVM, Repository y los cuatro patrones están documentados y probados. 539 pruebas en verde y 81.15 % de cobertura. Falta cerrar ERR-17 y el recorrido de TalkBack con gestos (4.8).

**Patrones ya implementados**

| Patrón | Justificación | Ubicación |
|---|---|---|
| Repository | Aísla las fuentes de datos de los ViewModels | `lib/repositories/*.dart` |
| Factory | Construcción tipada desde el JSON de Django | `lib/models/*.dart` (`fromJson`); `ApiException.fromBody`; `AppScope.create` |
| Observer | La UI reacciona a cambios de estado | `ChangeNotifier` en `lib/viewmodels/*`; `Provider`/`Consumer` en las vistas |
| Singleton (composition root) | Un grafo de dependencias por proceso | `AppScope` creado una vez en `main.dart`. No hay `getInstance()` clásico; el motivo está en `ARQUITECTURA_Y_PATRONES.md` §2 |

---

## ACTIVIDAD 6: Cloud y seguridad integral

**Puntuación:** 8 puntos · **Entrega:** 26 de noviembre de 2026

| # | Criterio oficial | Issue | Estado | Implementado | Probado | Evidenciado | Evidencia (ruta o PR) | Pendiente |
|---|---|---|---|---|---|---|---|---|
| 6.1 | API REST operativa | GH#68 | **Cumple** | Sí: `ApiClient` y services de catálogo, auth, cliente, secretaría, barbero y privacidad. Ambientes dev, staging y prod por `APP_ENV` (PR #128) | Sí: escrituras contra Django local (batería del 11-nov); lecturas públicas de producción en solo lectura (`RENDIMIENTO.md`) | Sí | `README.MD` (tabla de endpoints); `docs/evidencias/ambientes-2026-11-11/` | Staging no existe como servidor propio |
| 6.2 | JWT Bearer | GH#11, GH#40 | **Cumple** | Sí: `Authorization: Bearer` en `ApiClient`; tokens en `SecureTokenStorage` | Sí: PM01 del 11-nov (login inválido y válido) y pruebas con `MockClient` que verifican el Bearer | Sí | `lib/core/network/api_client.dart`; `pm01_*` | — |
| 6.3 | Interceptor 401 + refresh | GH#69 | **Cumple** | Sí: un `POST /auth/token/refresh/` y reintento; si el refresh falla, cierra sesión. Un corte de red al renovar no la cierra (ERR-12) | Sí: `api_client_refresh_test.dart` (7) y `api_client_errores_red_test.dart` (6) | Sí | `CONTRATO_ERRORES_HTTP.md`; PR #91 y #103 | Sesión vencida real (sin simular) no se esperó en dispositivo |
| 6.4 | Certificate Pinning SHA-256 | GH#38, GH#39 | **Cumple** | Sí: `SecurityContext` solo con 5 raíces fijadas | Sí: 10 pruebas; `pinning.yml` semanal | Sí | `docs/evidencias/pinning-2026-10-21/`; `PINNING_ROTACION.md` | Rotar según el plan |
| 6.5 | Almacenamiento local cifrado Android | GH#40 | **Cumple** | Sí: `flutter_secure_storage` con `encryptedSharedPreferences` y `allowBackup=false` | Sí: en emulador, ninguna entrada legible (20-oct) | Sí | `docs/evidencias/seguridad/almacenamiento-cifrado-2026-10-20.md` | Repetir en un Android físico |
| 6.6 | Aviso de privacidad | GH#41, GH#59 | **Cumple** | Sí: pantalla con el texto de `GET /public/legal/?tipo=privacidad`, la misma política de `tonystylo.vercel.app/nosotros?tipo=privacidad` | Sí: `test/privacidad_views_test.dart`; en producción (solo lectura, 2026-11-11) el texto ya no tiene marcadores sin llenar | Sí | PR #90; `docs/play/SEGURIDAD_DE_LOS_DATOS.md` | — |
| 6.7 | Consentimiento Opt-In explícito (inicialmente desactivado) | GH#41 | **Cumple** | Sí: finalidades opcionales apagadas; se guardan en la cuenta con fecha y versión (`/privacidad/preferencias/`, backend PR #3) | Sí: en emulador y `test/unit/privacidad_test.dart`; Django `test_privacidad_preferencias` (5) | Sí | `docs/evidencias/sprint-2026-10-20/` | — |
| 6.8a | ARCO Acceso (consultar perfil) | GH#42 | **Cumple** | Sí: "Mis datos" con perfil e historial (`GET /perfil/`, `GET /mis-citas/`) | Sí: en emulador y con `MockClient`. Aislamiento entre cuentas comprobado (PM02 del 11-nov) | Sí | PR #90; `logs/api_pm02_pm04_pm08.log` | — |
| 6.8b | ARCO Rectificación (editar perfil) | GH#43 | **Parcial** | Sí: "Corregir mis datos" con `PUT /perfil/` y reenvío de avatar y dirección (ERR-07) | Parcial: con `MockClient`; en emulador solo se abrió el formulario | Parcial: `09_arco_corregir_datos.png` (20-oct) | PR #90 | Guardar un cambio real en emulador contra Django local y capturar el antes y el después |
| 6.8c | ARCO Cancelación (eliminar cuenta) | GH#44 | **Cumple (falta el Cron en Render)** | Sí: app (PR #101), `POST /api/privacidad/cancelacion/` (backend PR #5) y página web `/eliminar-cuenta` (front PR #3). Bloqueo inmediato y supresión a los 30 días. El backend corre la supresión en cada arranque (`start.sh`, backend PR #8) | Sí: 10 pruebas Django, 12 de Flutter, E2E en emulador | Sí | `docs/evidencias/arco/2026-10-21-cancelacion/` | No hay evidencia de un Cron Job diario en Render con `suprimir_cuentas_vencidas`. Con el ping cada 5 minutos el servicio casi no reinicia |
| 6.8d | ARCO Oposición (Opt-Out) | GH#45 | **Cumple** | Sí: el titular apaga `acepta_analitica_perfilado`; el backend (PR #7) deja fuera de predicción y segmentación a quien se opuso | Sí: en emulador (`11b_…`); Django `test_oposicion_perfilado` (4), en verde el 2026-11-06 | Sí | `CATALOGO_PRUEBAS.md` §4; backend PR #7 | — |
| 6.9 | R8/ProGuard (`minifyEnabled`, `shrinkResources`, reglas) | GH#46 | **Cumple** | Sí: `isMinifyEnabled`, `isShrinkResources`, `proguard-rules.pro` | Sí: en el release 0.8.1+5, 796 clases renombradas por R8 (JADX, 11-nov) | Sí | `JADX_RESULTADOS.md`; `docs/evidencias/estatico-2026-10-21/` | `mapping.txt` nunca se versiona |
| 6.10 | Ofuscación release | GH#47 | **Cumple** | Sí: `--obfuscate --split-debug-info` en `release.yml` | Sí: 0 nombres de clases Dart en `libapp.so` del release 0.8.1+5 | Sí | `JADX_RESULTADOS.md` | Las cadenas (URL, rutas) siguen legibles; no son secretos |
| 6.11 | Evaluación JADX/MobSF | GH#48, GH#49 | **Parcial** | JADX 1.5.6 sobre debug y release 0.8.1+5 | JADX sí (2026-11-11). MobSF no | JADX sí | `JADX_RESULTADOS.md` | Correr MobSF o mobsfscan (GH#49) |
| 6.12 | Pruebas caja negra E2E | GH#17, GH#74 | **Parcial** | `integration_test` (PI-01) y batería manual PM01–PM10 | Sí: PI-01 1/1 (oct); batería PM01–PM10 en emulador API 37 y API 24 el 2026-11-11 | Sí: 53 capturas y logs | `BATERIA_FINAL_PM.md`; `MATRIZ_DISPOSITIVOS.md` | Patrol no está en el proyecto: la aceptación PA-01 a PA-07 no está automatizada. PM07-c (reintento sin duplicar) depende de la idempotencia del backend |
| 6.13 | Matriz Debug/Release | GH#52 | **Cumple** | Sí | Sí: con `aapt2` (19-oct) y con JADX sobre debug y release 0.8.1+5 (11-nov) | Sí | `docs/evidencias/seguridad/2026-10-19/README.md`; `JADX_RESULTADOS.md` | — |
| 6.14 | Registro de errores encontrados/corregidos | GH#28 | **Cumple** | Sí: ERR-01 a ERR-19 con severidad, versión, entorno, esperado/observado, responsable y regresión | Sí: cada "Corregido" tiene su prueba | Sí | `REGISTRO_ERRORES.md` | Siguen abiertos ERR-05 y ERR-17 (los dos de severidad baja) |

**Resumen Actividad 6:** API, JWT con refresh, pinning, almacenamiento cifrado, R8 y ofuscación (verificados con JADX sobre el release publicado), aviso con opt-in y ARCO de Acceso, Cancelación y Oposición están comprobados.

Faltan:
- Guardar una rectificación en emulador (6.8b).
- MobSF (6.11).
- Patrol (6.12).
- El Cron de supresión en Render (6.8c).

---

## ACTIVIDAD 7: Publicación Google Play

**Puntuación:** 2 puntos · **Entrega:** 26 de noviembre de 2026

| # | Criterio oficial | Issue | Estado | Implementado | Probado | Evidenciado | Evidencia (ruta o PR) | Pendiente |
|---|---|---|---|---|---|---|---|---|
| 7.1 | App en revisión o publicada | GH#60, GH#62 | **Parcial** | Sí: según `ACTA_ACEPTACION.md`, 0.8.1+5 está en la prueba cerrada (Alpha) de Play | No hay smoke test desde la versión distribuida (GH#61) | No: no hay captura de Play Console en el repo | Release [v0.8.1](https://github.com/Gilberto625/MovilStyloBarberConect/releases/tag/v0.8.1) | Capturas de la consola (7.6). Para producción, Play pide 12 testers durante 14 días seguidos |
| 7.2 | APK/AAB firmado correctamente | GH#55, GH#56 | **Cumple** | Sí: `release.yml` compila AAB y APK ofuscados, los firma con el keystore de los secretos y falla si quedan firmados con la clave debug | Sí: run 41021801630 en verde, incluido el paso "Verify signature is not debug". El SHA-256 del APK coincide con `SHA256SUMS.txt` (JADX) | Sí: assets del release v0.8.1 | `.github/workflows/release.yml`; `JADX_RESULTADOS.md` | — |
| 7.3 | Firma de publicación (no debug) | GH#53, GH#54 | **Cumple** | Sí: `signingConfig` de release lee `android/key.properties`; en CI, los 5 secretos (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `SYMBOLS_PASSPHRASE`) están cargados (`gh secret list`, 11-nov) | Sí: el run de v0.8.1 pasó la verificación de firma no debug | Sí | `docs/play/FIRMA_Y_PUBLICACION.md` | La clave y sus contraseñas no salen del equipo |
| 7.4 | Permisos Android justificados | GH#57 | **Cumple** | Sí: solo `INTERNET` | Sí: manifiesto del APK release con `aapt2`; en Android, "No permissions allowed / denied" | Sí | `PERMISOS_Y_DATOS.md`; `ANALISIS_ESTATICO.md` | Explicar "Nearby devices" en la pantalla de permisos (SEG-09) |
| 7.5 | Diálogos runtime de permisos | GH#57 | **No aplica** | No hay permisos peligrosos | Sí: manifiesto del APK release | Sí | `PERMISOS_Y_DATOS.md` | Si se agregan cámara o ubicación, pedirlos en tiempo de ejecución con explicación previa |
| 7.6 | Evidencias Google Play Console | GH#58, GH#62 | **Pendiente** | Kit de la ficha listo (`FICHA.md`, ícono, gráfico destacado y 5 capturas) | No | No: no hay capturas de la consola en el repo | `docs/play/` | Capturar la versión en prueba cerrada, la ficha y los formularios de contenido |

**Resumen Actividad 7:** el AAB firmado existe y se publicó en la prueba cerrada según el acta. Falta evidenciar Play Console y cumplir los 14 días con 12 testers para pedir producción.

---

## Matriz SAST vs DAST (GH#36)

Para no llamar DAST a un análisis estático.

| Herramienta | Tipo | Qué analiza | ¿Necesita la app en ejecución? | Ambiente | Estado | Evidencia |
|---|---|---|---|---|---|---|
| Semgrep | SAST | Código fuente del repo | No | GitHub Actions, en cada PR y push | Ejecutado, bloqueante con severidad ERROR | `POLITICA_CI_SAST.md`; artefacto `semgrep-sast-evidence` |
| `flutter analyze` | Análisis estático de código | Código Dart | No | GitHub Actions | Ejecutado, bloqueante | Artefacto `flutter-quality-evidence` |
| `aapt2`, `apksigner`, `tool/analisis_apk.py` | Análisis estático del binario | APK release (manifiesto, firma, R8, secretos) | No | Laptop del equipo | Ejecutado el 2026-10-21 | `docs/evidencias/estatico-2026-10-21/` |
| JADX | Análisis estático del binario (descompilación) | APK debug y release 0.8.1+5 | No | Laptop del equipo | Ejecutado el 2026-11-11 | `JADX_RESULTADOS.md` |
| MobSF / mobsfscan | Análisis estático del binario | APK release | No | — | **No ejecutado** | — |
| OWASP ZAP | **DAST** | API en ejecución (Django local), con y sin sesión de cliente | **Sí** | Backend local con PostgreSQL local; nunca producción | Ejecutado el 2026-11-11 | `DAST_RESULTADOS.md`; `docs/evidencias/dast-zap-2026-11-11/` |
| Frida, Ghidra | Instrumentación y desensamblado | APK release | Frida sí; Ghidra no | — | **Fuera de alcance** (decisión del equipo, 2026-11-11) | `ACTA_ACEPTACION.md` §4 |

---

## Puntuación potencial (autodiagnóstico)

Cálculo: cada criterio vale 1 si Cumple, 0.5 si es Parcial y 0 si está Pendiente o Bloqueado; "No aplica" no cuenta. El resultado se prorratea con los puntos de cada actividad.

| Actividad | Puntos | Criterios (Cumple / Parcial / Pendiente o Bloqueado) | Estimación al 11-nov | Qué falta |
|---|---|---|---|---|
| 5 | 3 | 7 / 0 / 0 | ≈ 3.0 (100 %) | Detalles: proteger `release` y capturar un PR bloqueado |
| 4 | 7 | 10 / 1 / 0 | ≈ 6.7 (95 %) | ERR-17 y TalkBack con gestos |
| 6 | 8 | 14 / 3 / 0 | ≈ 7.3 (91 %) | Rectificación en emulador, MobSF y Patrol |
| 7 | 2 | 3 / 1 / 1 (más 1 que no aplica) | ≈ 1.4 (70 %) | Capturas de Play Console y producción |
| **Total** | **20** | **34 / 5 / 1** | **≈ 18.4 (92 %)** | |

**Nota:** la estimación no es la calificación del profesor. Ninguna fila se marca como aceptada: la aceptación ocurre al firmar `ACTA_ACEPTACION.md`.
