# Catálogo final de pruebas (DOC-002, GH#64)

Reúne todas las pruebas de la app móvil y de la API que usa, con su versión, entorno, resultado esperado y observado, estado y evidencia. Corte: **2026-11-11**.

**Regla:** solo es "Aprobado" lo que se ejecutó y cuyo resultado se vio. Lo demás es "Pendiente" (con su motivo) o "Fuera de alcance" (decisión del equipo).

## Cómo leer este catálogo

### Estados

| Estado | Significado |
|---|---|
| **Aprobado** | Se ejecutó, el resultado observado coincide con el esperado y la evidencia está enlazada |
| **Pendiente** | No se ha ejecutado, está en ejecución, o se ejecutó y encontró un defecto abierto. Se dice el motivo |
| **Fuera de alcance** | El equipo decidió no hacerlo en esta entrega |

### Versiones y entornos

| Clave | Qué es |
|---|---|
| **V-F** | App: `main` 0.8.1+5 (`f16e65f`) más el PR #125 (`ad9afd6`). Es el contenido de `develop` en `b04e63c` |
| **V-B** | Backend: `main` en `970e9ad` (incluye los PR #7 y #11) |
| **E-T** | `flutter test` (VM de Dart, sin dispositivo). Corrida del 2026-11-06: **349 de 349 aprobadas** (`docs/evidencias/pruebas/2026-11-06/catalogo_flutter.txt`). La misma suite en CI del PR #125, run [42258784727](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/42258784727) (Flutter 3.47.9): 349/349, **cobertura de líneas 79.51 %** (5537/6964), mínimo 55 % |
| **E-D** | `python manage.py test core.tests` sobre V-B con PostgreSQL local, 2026-11-06: **401 pruebas**, 5 fallos previos ajenos a la app (`docs/evidencias/pruebas/2026-11-06/catalogo_backend.txt`; PR #11 del backend) |
| **E-E** | Emulador Android `Medium_Phone_API_37.0` (Android 17, 1080 × 2400) contra Django local con PostgreSQL local. Nunca contra producción ni Neon |
| **E-CI** | GitHub Actions (`ci.yml`, `release.yml`, `pinning.yml`) |

## Resumen por tipo

| Tipo | Casos / grupos | Aprobado | Pendiente | Fuera de alcance |
|---|---|---|---|---|
| Unitarias (Dart) | 11 archivos, 113 pruebas | 113 | 0 | 0 |
| Widget | 21 archivos, 207 pruebas | 207 | 0 | 0 |
| Integración HTTP con `MockClient` | 4 archivos, 29 pruebas | 29 | 0 | 0 |
| Integración en emulador (`integration_test`) | 2 | 2 | 0 | 0 |
| API / backend (Django) | 26 archivos, 404 métodos | 396 | 5 fallos previos ajenos (8 métodos) | 0 |
| Recorridos de API contra Django local | 3 | 3 | 0 | 0 |
| Seguridad | 15 | 9 | 5 | 1 (Frida/Ghidra) |
| No funcionales | 9 | 3 | 6 | 0 |
| Aceptación PM01–PM10 | 10 casos (12 filas) | 9 | 3 | 0 |
| Recorrido manual de la versión 0.8.1 en emulador | 9 | 8 | 1 | 0 |

Las 349 pruebas Flutter se reparten en 113 + 207 + 29. La división unitaria/widget es por archivo según lo que predomina: varios archivos mezclan pruebas de ViewModel con pruebas de pantalla.

---

## 1. Unitarias

Versión **V-F**, entorno **E-T**, 2026-11-06. Esperado: cada prueba en verde. Observado: todas en verde.

| Archivo | Pruebas | Qué cubre | Estado | Evidencia |
|---|---|---|---|---|
| `test/unit/models_json_test.dart` | 8 | U-JSON: `fromJson` con fixtures del JSON real de Django (usuario, barbero, cita, perfil, política de pago, cita de secretaría) | Aprobado | E-T; `test/fixtures/*.json` |
| `test/unit/validators_test.dart` | 4 | PM-U01: validador de correo o usuario | Aprobado | E-T |
| `test/unit/viewmodels_mockito_test.dart` | 12 | U-MOCK: ViewModels con repositorios de Mockito (login, 2FA, logout, mis citas, secretaría y doble envío) | Aprobado | E-T; `docs/evidencias/pruebas/2026-10-19/test-unit-mockito_flutter-test.log` (primera corrida) |
| `test/unit/privacidad_test.dart` | 24 | ARCO-M01/M02: Mis datos, Corregir mis datos (un solo PUT, conserva avatar y dirección, ERR-07), preferencias y contrato con `MockClient` | Aprobado | E-T; `docs/evidencias/arco/2026-10-19/` |
| `test/auth_and_flows_test.dart` | 16 | `ApiException` (sobres `detail` y `ok/error`), `AuthViewModel` (login, 2FA, logout), `ClientCitasViewModel` (fallo al crear no se da por hecho, política de anticipo) | Aprobado | E-T |
| `test/viewmodel_repository_test.dart` | 4 | ViewModels con repositorios falsos, sin red; roles | Aprobado | E-T |
| `test/contacto_horarios_test.dart` | 7 | `ContactoDto`: horarios reales, filas malformadas, contrato anterior | Aprobado | E-T |
| `test/variante_imagen_test.dart` | 7 | ERR-13: variante de Cloudinary recortada por contenido y del tamaño mostrado | Aprobado | E-T; `docs/evidencias/encuadre-fotos-2026-10-21/` |
| `test/app_locale_test.dart` | 1 | Componentes de Material en español de México | Aprobado | E-T |
| `test/app_fonts_test.dart` | 1 | Fuentes empaquetadas con su licencia (sin descarga en tiempo de ejecución) | Aprobado | E-T |
| `test/design_system_test.dart` | 14 | Estados de cita en palabras y color, estados vacío/error/carga, "reducir movimiento" | Aprobado | E-T |
| `test/splash_routes_test.dart` | 4 | Splash restaura la sesión y lleva a cada rol a su panel | Aprobado | E-T |
| `test/splash_view_test.dart` | 1 | Splash | Aprobado | E-T |

(113 = 8 + 4 + 12 + 24 + 16 + 4 + 7 + 7 + 1 + 1 + 14 + 4 + 1 + 10 de `pinning_test.dart`, que se detalla en Seguridad.)

## 2. Widget

Versión **V-F**, entorno **E-T**, 2026-11-06. Esperado: la pantalla muestra lo correcto, responde a toques y teclado y no desborda. Observado: todas en verde.

| Archivo | Pruebas | Qué cubre | Estado | Evidencia |
|---|---|---|---|---|
| `test/guest_home_premium_test.dart` | 39 | Invitado: navegación, Atrás, teclado (Tab/Enter), catálogo, contacto, estados de error | Aprobado | E-T |
| `test/guest_premium_widgets_test.dart` | 13 | Tarjetas del catálogo: nombres largos con texto grande, acciones accesibles | Aprobado | E-T |
| `test/login_premium_test.dart` | 9 | Login y pantalla de código 2FA: validación, error anunciado, carga, tamaños teléfono/tablet/horizontal | Aprobado | E-T |
| `test/registro_test.dart` | 23 | Registro: contrato `POST /register/`, reglas de contraseña, aceptación de términos | Aprobado | E-T; PR #120 |
| `test/seguridad_terminos_test.dart` | 15 | 2FA opcional (`/perfil/2fa/`) y términos de uso | Aprobado | E-T; PR #120 |
| `test/cliente_test.dart` | 17 | Panel del cliente: agendar por pasos, anticipo obligatorio, tienda y contrato de pedidos | Aprobado | E-T |
| `test/cliente_cambios_cita_test.dart` | 16 | PA-06: reprogramar y cancelar la cita propia, fuera de plazo, 409, ERR-06 (doble toque) | Aprobado | E-T; PR #110 |
| `test/client_secretary_premium_test.dart` | 9 | Conflicto de horario, reserva sin horario falso, rol cliente no abre secretaría, búsqueda en vivo | Aprobado | E-T |
| `test/secretaria_rediseno_test.dart` | 8 | Hoy y detalle a 360 × 800 con texto 1.0 y 1.3, cobro con cambio y comprobante | Aprobado | E-T; PR #100 |
| `test/secretaria_gestion_test.dart` | 8 | Nueva cita y edición: sin cliente no crea, bloquea el segundo envío, horario rechazado | Aprobado | E-T |
| `test/secretaria_cobro_dialogo_test.dart` | 3 | ERR-01: diálogo de cobro sin controladores liberados antes de tiempo | Aprobado | E-T; `docs/evidencias/pruebas/2026-10-19/fix-secretaria-cobro-dialogo.md` |
| `test/barbero_agenda_test.dart` | 14 | PM06: Mi agenda, iniciar/terminar sin repetir, 403 de otro rol | Aprobado | E-T; PR #110 |
| `test/privacidad_views_test.dart` | 16 | ARCO: Mis datos, Corregir (360 × 800, texto 1.3), aviso y opt-in | Aprobado | E-T; PR #90 |
| `test/arco_cancelacion_test.dart` | 12 | ARCO-M03: Eliminar mi cuenta, folio, cierre de sesión, ERR-09 y ERR-10 | Aprobado | E-T; `docs/evidencias/arco/2026-10-21-cancelacion/` |
| `test/accesibilidad_guias_test.dart` | 4 | GH#19: guías de accesibilidad en acceso, agenda del barbero, detalle y reprogramar | Aprobado | E-T |
| `test/widget_test.dart` | 1 | Inicio de invitado con catálogo vacío | Aprobado | E-T |

(207 = 39 + 13 + 9 + 23 + 15 + 17 + 16 + 9 + 8 + 8 + 3 + 14 + 16 + 12 + 4 + 1.)

## 3. Integración

### 3.1 HTTP con `MockClient` (sin red, en CI)

Repository → Service → `ApiClient` real con un servidor simulado. Versión **V-F**, entorno **E-T**.

| Archivo | Pruebas | Esperado | Observado | Estado | Evidencia |
|---|---|---|---|---|---|
| `test/integration/api_client_refresh_test.dart` | 7 | I-401: 401 → refresh → reintento; refresh rechazado cierra la sesión | Así ocurre | Aprobado | E-T; PR #91 |
| `test/integration/api_client_errores_red_test.dart` | 6 | Sin red: mensaje claro, sin IP ni URL; un corte al renovar no cierra la sesión (ERR-11, ERR-12) | Así ocurre | Aprobado | E-T; `docs/evidencias/red-2026-10-21/` |
| `test/integration/repositories_http_test.dart` | 11 | I-REPO: catálogo, citas, auth y secretaría; 400/409/500 no se toman como éxito | Así ocurre | Aprobado | E-T; `docs/evidencias/pruebas/2026-10-19/test-integration-http_flutter-test.log` |
| `test/integration/secretaria_api_service_http_test.dart` | 5 | BUG-01 (ERR-15): buscar clientes, cliente de paso, citas de un cliente y cita editable devuelven datos; `ok=false` llega como error | Así ocurre; con el código anterior fallan con el error de tipo | Aprobado | E-T; PR #125 |

### 3.2 `integration_test` en emulador contra Django local

| ID | Versión | Entorno | Esperado | Observado | Estado | Evidencia |
|---|---|---|---|---|---|---|
| PI-01 reserva | `develop` del 19 y 20-oct (0.1.0+1) | E-E | La cita creada aparece en Mis citas con los mismos datos; un error del backend no la muestra como creada | 1/1 en verde (19 y 20-oct); Corte clásico, 22-oct 10:00, confirmada | Aprobado | `integration_test/pi01_reserva_test.dart`; `docs/evidencias/pruebas/2026-10-19/pi01_*.log`; `docs/evidencias/sprint-2026-10-20/pi01_2026-10-20.log` |
| Recorrido de tres roles | Rama local de evidencia del 20-oct | E-E | Invitado → cliente → logout → secretaría sin excepciones | 1/1 en verde, 3 min, 20 capturas | Aprobado | `docs/evidencias/sprint-2026-10-20/recorrido_2026-10-20.log` y `recorrido_evidencia_test.dart.txt` |

PI-01 no se volvió a correr sobre V-F. El recorrido de la versión 0.8.1 del 6-nov fue manual (sección 8).

## 4. API / backend (Django)

Versión **V-B**, entorno **E-D**, 2026-11-06. Esperado: todas en verde. Observado: 401 ejecutadas, 5 fallos que ya existían y no tocan la app.

| Archivo (`backend/core/tests/`) | Métodos | Qué cubre | Estado | Evidencia |
|---|---|---|---|---|
| `test_cliente_cita_modificar.py` | 17 | PM05: cancelar y reprogramar la cita propia, anticipación 1 o 2 días, 404 ajena, 409; ERR-03 | Aprobado | E-D; backend PR #7 |
| `test_barbero_agenda.py` | 8 | PM06: solo sus citas, solo hoy, transiciones, 403/404 | Aprobado | E-D; backend PR #7 |
| `test_politica_pago_propia.py` | 7 | PM02 / ERR-02: el cliente recibe su propia política aunque pida otro id | Aprobado | E-D; backend PR #6 (en `main` con #7) |
| `test_agenda_bloqueo.py` | 6 | PM04 / ERR-14: candado por barbero y día con conexiones reales | Aprobado | E-D |
| `test_secretaria_cliente_paso.py` | 4 | ERR-16: alta de cliente de paso 201, teléfono inválido 400 | Aprobado | E-D; backend PR #11 |
| `test_2fa_opcional.py` | 8 | 2FA opcional apagado por defecto; registro sin código | Aprobado | E-D |
| `test_privacidad_preferencias.py` | 5 | Opt-in con fecha y versión; cada usuario solo lo suyo; 401 | Aprobado | E-D; backend PR #3 |
| `test_privacidad_cancelacion.py` | 10 | ARCO cancelación: bloqueo, folio, sin login ni tokens después, supresión `--dry-run` | Aprobado | E-D; backend PR #5 |
| `test_oposicion_perfilado.py` | 4 | ARCO oposición: quien se opuso queda fuera de predicción y segmentación | Aprobado | E-D; backend PR #7 |
| `test_ping.py` | 2 | `/ping/` sin consultas | Aprobado | E-D |
| `test_clip_checkout.py` | 14 | Cliente de Clip (pagos solo en el servidor) | Aprobado | E-D |
| ML: `test_ml_citas_etl`, `test_ml_inasistencia_*` (5), `test_ml_segmentacion_etl`, `_features`, `_prediccion`, `_endpoint`, `_productos_synth`, `test_generar_datos_ml_citas` | 279 | Modelos de inasistencia y segmentación (no los usa la app) | Aprobado | E-D |
| `test_ml_segmentacion_lote.py` | 19 | Segmentación por lote | Pendiente: `test_varios_clientes_resumen_orden` falla (mock con 0 llamadas, fallo previo, ERR-05). Las otras 18 pasan | E-D |
| `test_ml_segmentacion_clustering.py` | 4 | Pipeline de clustering | Pendiente: el módulo no carga porque falta `matplotlib` en `requirements.txt` (ERR-05); Django lo cuenta como 1 error | E-D |
| `test_webauthn.py` | 17 | Passkeys (web) | Pendiente: 3 fallan con `InFailedSqlTransaction`, fallo previo de la web; el log no dice cuáles. Las otras 14 pasan | E-D; descripción del backend PR #11 |

404 métodos listados; Django cuenta 401 porque el módulo de clustering que no carga cuenta como un solo error.

### 4.1 Recorridos de API contra Django local

| Caso | Versión | Esperado | Observado | Estado | Evidencia |
|---|---|---|---|---|---|
| Permisos y aislamiento (PM02) | Backend antes y después del arreglo, 2026-10-21 | A no ve ni recibe datos de B | Antes: `politica-pago` filtraba datos de B (ERR-02). Después: aislado | Aprobado (después del arreglo) | `docs/evidencias/permisos-concurrencia-2026-10-21/` (`despues-del-arreglo/`) |
| Reservas simultáneas (PM04) | Ídem | Una sola reserva aceptada por horario | Antes: 11 de 13 rondas con 2–4 aceptadas. Después: 13 de 13 con una sola y 0 duplicados | Aprobado (después del arreglo) | `docs/evidencias/permisos-concurrencia-2026-10-21/despues-del-arreglo/corrida_concurrencia.log`; app PR #109 |
| Cambiar la cita propia y agenda del barbero (PM05, PM06) | Backend `feature/movil-citas-cliente-barbero` (luego PR #7), 2026-10-23 | 27 casos de la tabla del README | 27 de 27 | Aprobado | `docs/evidencias/cierre-funcional-2026-10-23/corrida_api.log`, `e2e_api_resultados.json` |

## 5. Seguridad

| ID | Prueba | Versión / entorno | Esperado | Observado | Estado | Evidencia |
|---|---|---|---|---|---|---|
| SEG-01 | SAST con Semgrep (`p/secrets`, `p/security-audit`, `p/owasp-top-ten` y reglas propias) | V-F, E-CI, 2026-11-06 | 0 hallazgos de severidad ERROR | Job "SAST Semgrep gate" en verde (también en el push del 12-nov) | Aprobado | Run [42258784727](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/42258784727); `.semgrep.yml`; `docs/evaluacion/POLITICA_CI_SAST.md` |
| SEG-02 | Análisis estático (`flutter analyze`) | V-F, E-CI | 0 incidencias | Con Flutter 3.47.9 (6-nov): limpio. Con Flutter 3.50.0 (12-nov): 58 avisos de deprecación y el job falla | Aprobado tras PR #127 (ERR-18 corregido: Flutter fijo en 3.47.9): fijar la versión de Flutter en CI) | Runs [42258784727](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/42258784727) y [43135262264](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/43135262264) |
| SEG-03 | R8 / ProGuard | `develop` `67e04ab` (0.1.0+1), 2026-10-21 | Clases Java/Kotlin renombradas | 981 de 1 038 (95 %) | Aprobado | `docs/evidencias/estatico-2026-10-21/ANALISIS_ESTATICO.md` |
| SEG-04 | Ofuscación Dart (`--obfuscate --split-debug-info`) | Ídem | Identificadores de la app ausentes en `libapp.so` | 14 identificadores pasan de 1–2 apariciones a 0; el APK ofuscado funciona en emulador | Aprobado | Ídem; el AAB de 0.8.1 lo generó `release.yml`, run [41021801630](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/41021801630) (no se volvió a analizar) |
| SEG-05 | Secretos en el APK | Ídem | Ninguna clave privada, API key ni token | Ninguno | Aprobado | Ídem |
| SEG-06 | Certificate pinning SHA-256 | V-F, E-T (10 pruebas) y emulador del 21-oct | Raíces fijadas; un certificado de otra autoridad se rechaza en el handshake | Así ocurre (también con un servidor TLS local) | Aprobado | `test/pinning_test.dart`; `docs/evidencias/pinning-2026-10-21/`; workflow semanal `pinning.yml` (último run en verde 2026-11-09) |
| SEG-07 | Almacenamiento seguro (`flutter_secure_storage`) | Emulador, 2026-10-20 | Tokens cifrados; `allowBackup=false` | 6 entradas, ninguna legible | Aprobado | `docs/evidencias/seguridad/almacenamiento-cifrado-2026-10-20.md` |
| SEG-08 | Permisos y manifiesto | APK release 0.1.0+1 (21-oct) y app 0.8.1 en emulador (6-nov) | Solo `INTERNET`; sin diálogos de permisos peligrosos | `aapt2`: solo `INTERNET`. En Android: "No permissions allowed / No permissions denied" | Aprobado | `ANALISIS_ESTATICO.md`; `docs/evaluacion/PERMISOS_Y_DATOS.md`; `docs/manual/img/perm_01_info_app.jpg` |
| SEG-09 | Observación: "Nearby devices" en la pantalla de permisos | App 0.8.1 debug en emulador, 2026-11-06 | — | Android 17 lista "Nearby devices — Accessed in past 24 hours" bajo "Allowed to keep app working", aunque el manifiesto solo declara `INTERNET` | Pendiente: confirmar el origen (posiblemente el acceso a la red local `10.0.2.2` del build debug) y revisarlo en el AAB de Play | `docs/manual/img/perm_02_permisos.jpg` |
| SEG-10 | Matriz Debug / Release | 3 APK del 19-oct | Controles distintos por build | Comprobado con `aapt2` y lectura de binarios | Aprobado | `docs/evidencias/seguridad/2026-10-19/README.md` |
| SEG-11 | Aislamiento por rol en el servidor | V-B, E-D y recorridos | 403/404 para otros roles y citas ajenas | Así ocurre | Aprobado | Sección 4; `docs/evidencias/cierre-funcional-2026-10-23/` |
| SEG-12 | JADX-GUI (antes y después de ofuscar) | — | Capturas de JADX | No se instaló; lo mismo se midió con `aapt2`, `apksigner` y `tool/analisis_apk.py` (SEG-03 a SEG-05) | Pendiente: decisión del equipo de bajar JADX | `ANALISIS_ESTATICO.md`, sección "Pendiente" |
| SEG-13 | MobSF / mobsfscan | — | Reporte del APK release | No ejecutado | Pendiente | — |
| SEG-14 | DAST | — | Escaneo autorizado contra un ambiente de pruebas | No ejecutado: no hay staging; nunca contra producción | Pendiente | `docs/evaluacion/DAST_PROCEDIMIENTO.md` |
| SEG-15 | Frida y Ghidra (instrumentación y desensamblado) | — | — | — | **Fuera de alcance** (decisión del equipo, 2026-11-11) | — |

## 6. No funcionales

| ID | Prueba | Versión / entorno | Esperado | Observado | Estado | Evidencia |
|---|---|---|---|---|---|---|
| NF-01 | Rendimiento (30 mediciones por consulta) | Laptop Windows 11, Wi‑Fi, 2026-11-11; backend local y producción (solo lectura pública) | ≥ 95 % de consultas en 3 s o menos | Local: p95 81–209 ms. Producción: p95 1096–1117 ms, máx. 1324 ms. 100 % en 3 s o menos | Aprobado | `RENDIMIENTO.md`, `docs/evidencias/rendimiento-2026-11-11/` |
| NF-02 | Carga y estrés de la API (k6) | — | Latencias p95 y degradación medidas | No ejecutado. Solo contra backend local o staging, nunca producción | Pendiente | — |
| NF-03 | Accesibilidad automatizada | V-F, E-T | Sin desbordes a 360 × 800 con texto 1.3; acciones con nombre accesible; teclado | Pruebas de widget en verde (`accesibilidad_guias_test`, `secretaria_rediseno_test`, `privacidad_views_test`, `arco_cancelacion_test`, `guest_premium_widgets_test`) | Aprobado | E-T |
| NF-04 | Texto del sistema al 130 % en emulador | App 0.8.1, E-E, 2026-11-06 | Ningún texto recortado | Inicio y login se leen completos; la etiqueta "Productos" de la barra inferior se parte en dos líneas (ERR-17, cosmético) | Pendiente (ERR-17 abierto) | `docs/manual/img/acc_01_texto_130.jpg`, `acc_02_login_texto_130.jpg` |
| NF-05 | Accesibilidad con TalkBack | Emulador API 37 con TalkBack activo, 2026-11-11 | Cada control con etiqueta identificable | El árbol de accesibilidad expone la etiqueta de cada control del flujo de reserva. La navegación con gestos reales no se puede simular con adb | Aprobado con limitación (falta recorrido por gestos hecho por una persona) | `BATERIA_FINAL_PM.md`, `docs/evidencias/bateria-final-2026-11-11/` |
| NF-06 | Pantalla pequeña 720 × 1280 | App 0.8.1, emulador, 2026-11-06 | Inicio completo, sin desbordes | Inicio, CTA y barra inferior visibles y completos | Aprobado (una pantalla) | `docs/manual/img/resp_01_pantalla_pequena_720x1280.jpg` |
| NF-07 | Matriz de dispositivos | API 37 (411×914 y 360×640 dp, texto 200 %) y API 24 (versión mínima), 2026-11-11 | La reserva se completa en todos | Completa en los 4 casos, sin cierres | Aprobado (sin equipo físico) | `MATRIZ_DISPOSITIVOS.md` |
| NF-08 | Red: sin conexión y regreso de la red | App 0.8.1, E-E, 2026-11-06 (y 21-oct) | Mensaje claro, sin datos técnicos; al volver la red se entra normal | "No hay conexión con el servidor. Revisa tu internet e intenta de nuevo."; con red, entra con su próxima cita | Aprobado | `docs/manual/img/red_01_sin_conexion.jpg` a `red_03_con_red_entra.jpg`; `docs/evidencias/red-2026-10-21/` |
| NF-09 | Teléfono físico | — | Repetir capturas y almacenamiento cifrado en un Android real | No hubo teléfono físico: todo se probó en emuladores | Pendiente | — |

## 7. Aceptación: PM01–PM10

Casos críticos de la Actividad 1. Prioridad según la tarjeta de cada caso.

| Caso | Prioridad | Versión / entorno | Esperado | Observado | Estado | Evidencia |
|---|---|---|---|---|---|---|
| PM01 Acceso válido, inválido y sesión vencida | Alta | Emulador 20-oct; V-F, E-T | Solo entra con credenciales válidas; 401 → refresh; si falla, cierra sesión | Login inválido se queda con "Credenciales incorrectas."; válido entra; refresh y cierre probados con `MockClient` | Aprobado | `docs/evidencias/sprint-2026-10-20/capturas/02_*`, `03_*`; `test/integration/api_client_refresh_test.dart`; `docs/manual/img/cli_00_login_lleno.jpg`, `cli_01_inicio.jpg` |
| PM02 Cliente A no accede a citas de B | Crítica | V-B, E-D; API 21-oct; app 0.8.1 6-nov | Acceso denegado, sin datos ajenos | Mis citas aislado; política de pago propia; cita ajena 404; otra cuenta en el mismo emulador no ve la cita del primero | Aprobado | Sección 4; `docs/manual/img/cli2_01_mis_citas_aislado.jpg` |
| PM03 Reserva en horario disponible | Alta | PI-01 20-oct; app 0.8.1, E-E, 6-nov | Cita con usuario, barbero, servicio y horario correctos; el horario tomado ya no se ofrece | PI-01 1/1; 6-nov: reserva en 4 pasos confirmada y 11:00 ya no aparece | Aprobado | Sección 3.2; `docs/manual/img/cli_02_*` a `cli_09_*` |
| PM04 Reservas simultáneas | Crítica | V-B, E-D; API 21-oct después del arreglo | Una sola aceptada; la otra informa conflicto | 13 de 13 rondas con una sola; `test_agenda_bloqueo` en verde | Aprobado | Sección 4.1 |
| PM05 Reprogramar y cancelar la cita propia | Alta | API 23-oct (27/27); emulador 26-oct; V-F, E-T | Reglas aplicadas y disponibilidad actualizada | 200/200, horario liberado, 404 ajena, 409 fuera de plazo | Aprobado | `docs/evidencias/cierre-funcional-2026-10-23/`; `docs/manual/img/cli_08_detalle_cita.jpg` (fuera de plazo) |
| PM06 Agenda y estado del barbero | Alta | Ídem | Solo sus citas; transiciones indebidas rechazadas | Iniciar y terminar 200; 409/400 indebidas; 403 otros roles | Aprobado | Ídem; `docs/manual/img/bar_01_agenda.jpg`, `bar_02_agenda_sabado.jpg` |
| PM07-a Doble pulsación | Alta | V-F, E-T | Una sola petición de reserva | `crearCita` se llama 1 vez (ERR-06); secretaría bloquea el segundo envío | Aprobado | `test/cliente_cambios_cita_test.dart`; `test/unit/viewmodels_mockito_test.dart` |
| PM07-b Pérdida de red al reservar | Alta | V-F, E-T | Sin éxito local ni cierre de sesión | Así ocurre (ERR-11, ERR-12) | Aprobado | `test/integration/api_client_errores_red_test.dart` |
| PM07-c Reintento tras un corte, sin duplicar | Alta | — | Antes de reintentar, la app comprueba si la cita ya quedó | No implementado: depende de la idempotencia (`client_event_id`) que no existe en el backend | Pendiente | Criterio sin marcar en la tarjeta PM07 |
| PM08 Servicio inactivo o cambio de precio | Media | API local, 2026-11-11 | El servidor rechaza servicio inactivo o precio desactualizado y usa la duración vigente | 400 por servicio inactivo; 400 por precio mayor; duración 5 → 30 min del servidor | Aprobado | `BATERIA_FINAL_PM.md`, `docs/evidencias/bateria-final-2026-11-11/logs/api_pm02_pm04_pm08.log` |
| PM09 Cierre y cambio de sesión | Alta | Emulador 20-oct; app 0.8.1 6-nov | No quedan datos de la cuenta anterior | Logout vuelve a invitado; secretaría y otro cliente no ven datos del anterior | Aprobado | `docs/evidencias/sprint-2026-10-20/capturas/12_*`, `13_*`; `docs/manual/img/cli_21_cerrar_sesion.jpg`, `cli2_01_mis_citas_aislado.jpg` |
| PM10 Texto ampliado, TalkBack y pantalla pequeña | Media | V-F, E-T; emulador 6-nov | Controles identificables y operables, sin recortes que impidan reservar | Widget: en verde. Emulador: texto 130 % con ERR-17 cosmético; 720 × 1280 bien. TalkBack sin ejecutar | **Pendiente – en ejecución** (TalkBack y matriz de dispositivos) | NF-03 a NF-07 |

## 8. Recorrido manual de la versión 0.8.1 en emulador (2026-11-06)

App 0.8.1 en E-E. Las capturas `fix_*` son con V-F (PR #125). Todas las capturas están en `docs/manual/img/` y se explican en los manuales.

| Recorrido | Esperado | Observado | Estado | Capturas |
|---|---|---|---|---|
| Invitado | Catálogo, productos y contacto desde el backend | Así | Aprobado | `inv_01` a `inv_06` |
| Registro | Formulario con reglas de contraseña y aceptación de aviso y términos | Así (no se capturó el resultado de crear la cuenta) | Aprobado | `reg_01` a `reg_03` |
| Cliente: reservar y ver la cita | Reserva en 4 pasos, confirmada, en Mis citas | Así | Aprobado | `cli_00` a `cli_09` |
| Cliente: tienda y pedidos | Carrito, pedido recibido y Mis pedidos | Pedido #2 por $330.00, pendiente | Aprobado | `cli_10` a `cli_14` |
| Cliente: perfil, privacidad y 2FA | Opciones ARCO; 2FA se activa y desactiva con mensaje | Así | Aprobado | `cli_15` a `cli_20` |
| Cerrar sesión | Vuelve al inicio de invitado | Así | Aprobado | `cli_21` |
| Secretaría con 0.8.1 (antes del PR #125) | Clientes, Nueva cita y Reprogramar funcionan | Error de tipo `_Map … is not a subtype of … Future<dynamic>` (ERR-15). Hoy, Otro día, detalle y Más sí funcionan | Pendiente en 0.8.1; corregido en `develop` (fila siguiente) | `sec_01` a `sec_09` |
| Secretaría con V-F | Buscar cliente, sus citas, reprogramar 11:00 → 12:00, formulario de cliente de paso | Así. El alta del cliente de paso respondió 500 del backend local (ERR-16, corregido después en el backend PR #11; no se recapturó) | Aprobado | `fix_01` a `fix_12` |
| Barbero | Mi agenda de hoy y de otro día | Así; sin cita de hoy, no se vieron los botones "Pasó a la silla" / "Terminé el servicio" | Aprobado | `bar_01`, `bar_02` |

---

## Índice de evidencias

### En este repositorio

| Ruta | Qué contiene | Fecha |
|---|---|---|
| `docs/evidencias/pruebas/2026-11-06/catalogo_flutter.txt` | Lista de las 349 pruebas Flutter con resultado OK (V-F) | 2026-11-06 |
| `docs/evidencias/pruebas/2026-11-06/catalogo_backend.txt` | Lista de las pruebas Django de V-B y los fallos previos | 2026-11-06 |
| `docs/manual/img/` | 63 capturas del emulador de la app 0.8.1 y de V-F (JPG 720 px) | 2026-11-06 |
| `docs/evidencias/pruebas/2026-10-19/` | Primeras corridas: Mockito, integración HTTP, cobertura, PI-01 (2 corridas), ERR-01 | 2026-10-19 |
| `docs/evidencias/arco/2026-10-19/` | ARCO M01, M02 y M05, `flutter analyze` y cobertura | 2026-10-19 |
| `docs/evidencias/seguridad/2026-10-19/` | Matriz Debug/Release, `strings` de `libapp.so`, banderas del manifiesto, SHA-256 de los APK | 2026-10-19 |
| `docs/evidencias/seguridad/almacenamiento-cifrado-2026-10-20.md` | Almacenamiento cifrado en emulador | 2026-10-20 |
| `docs/evidencias/sprint-2026-10-20/` | PI-01, recorrido de tres roles y 20 capturas (PM01, PM03, PM09, ARCO, secretaría) | 2026-10-20 |
| `docs/evidencias/rediseno-2026-10-20/` | Capturas del rediseño | 2026-10-20 |
| `docs/evidencias/arco/2026-10-21-cancelacion/` | ARCO cancelación de punta a punta, log del servidor, ERR-09 y ERR-10 | 2026-10-21 |
| `docs/evidencias/permisos-concurrencia-2026-10-21/` | PM02 y PM04 antes y después del arreglo del backend | 2026-10-21 |
| `docs/evidencias/red-2026-10-21/` | ERR-11 y ERR-12, sin conexión | 2026-10-21 |
| `docs/evidencias/pinning-2026-10-21/` | Certificate pinning en emulador y herramienta | 2026-10-21 |
| `docs/evidencias/estatico-2026-10-21/` | Análisis estático del APK release: R8, ofuscación, permisos, firma, 16 KB, secretos | 2026-10-21 |
| `docs/evidencias/encuadre-fotos-2026-10-21/` | ERR-13, fotos del catálogo | 2026-10-21 |
| `docs/evidencias/marca-2026-10-21/` | Ícono y tipografías | 2026-10-21 |
| `docs/evidencias/cierre-funcional-2026-10-23/` | PM05 y PM06: 27/27 casos de API y 11 capturas | 2026-10-23 |
| `docs/evaluacion/REGISTRO_ERRORES.md` | ERR-01 a ERR-18 | Actualizado 2026-11-11 |
| `docs/evaluacion/AUDITORIA_DEPENDENCIAS.md` | `pub outdated`, `pub deps` y decisión por dependencia | 2026-11-11 |
| `docs/evaluacion/MATRIZ_CUMPLIMIENTO.md` | Criterios de las Actividades 4 a 7 | Revisión 2026-10-21 |

### En GitHub

| Enlace | Qué es |
|---|---|
| [Run 42258784727](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/42258784727) | CI del PR #125: Semgrep, analyze, 349/349, cobertura 79.51 % |
| [Run 43135262264](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/43135262264) | CI de `develop` tras el PR #125: falla `analyze` con Flutter 3.50.0 (ERR-18) |
| [Run 41021801630](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/41021801630) | `release.yml` de `main` para v0.8.1 |
| [Release v0.8.1](https://github.com/Gilberto625/MovilStyloBarberConect/releases/tag/v0.8.1) | Versión publicada en la prueba cerrada de Play |
| PRs de la app [#91](https://github.com/Gilberto625/MovilStyloBarberConect/pull/91), [#101](https://github.com/Gilberto625/MovilStyloBarberConect/pull/101), [#103](https://github.com/Gilberto625/MovilStyloBarberConect/pull/103), [#104](https://github.com/Gilberto625/MovilStyloBarberConect/pull/104), [#109](https://github.com/Gilberto625/MovilStyloBarberConect/pull/109), [#110](https://github.com/Gilberto625/MovilStyloBarberConect/pull/110), [#120](https://github.com/Gilberto625/MovilStyloBarberConect/pull/120), [#125](https://github.com/Gilberto625/MovilStyloBarberConect/pull/125) | Cambios con sus pruebas |
| PRs del backend [#7](https://github.com/Gilberto625/BackendStyloBarberConect/pull/7) y [#11](https://github.com/Gilberto625/BackendStyloBarberConect/pull/11) | Cambiar la cita propia, agenda del barbero, oposición, ERR-02/03/14; cliente de paso (ERR-16) |

### Pendientes de otras tareas

- `RENDIMIENTO.md` y `MATRIZ_DISPOSITIVOS.md`: se están ejecutando en paralelo. Cuando existan, actualizar NF-01, NF-05, NF-07 y PM10.
