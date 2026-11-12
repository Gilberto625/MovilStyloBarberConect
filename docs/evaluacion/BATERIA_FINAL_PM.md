# Batería final PM01–PM10 (SF-01, SF-04, GH#66)

- **Fecha:** 2026-11-11, de 21:15 a 21:57 (hora de Ciudad de México).
- **Versión:** `develop` en el commit `e208588`: 0.8.1+5 con los PR #125, #126, #127 y #128 y la corrección de BUG-02. Build debug, `APP_ENV=dev`.
- **Backend:** Django local (`10.0.2.2:8000` desde el emulador) con PostgreSQL 17 local y datos de prueba sembrados. No se usaron producción ni la base en la nube.
- **Dispositivos:** ver [MATRIZ_DISPOSITIVOS.md](MATRIZ_DISPOSITIVOS.md). Principal: emulador Medium Phone, Android 17 (API 37), 1080×2400 a 420 dpi.
- **Cuentas:** cliente A, cliente B, secretaría y barbero 1, todas de prueba. Las credenciales salen de un archivo local y no se versionan.
- **Evidencia:**
  - Capturas en `docs/evidencias/bateria-final-2026-11-11/img/`.
  - Logs en `docs/evidencias/bateria-final-2026-11-11/logs/`.
  - El script de API está en el mismo directorio.

| Caso | Prioridad | Qué se hizo | Esperado | Observado | Resultado | Evidencia |
|---|---|---|---|---|---|---|
| PM01 | Crítica | Login con contraseña incorrecta y después con la correcta | Rechaza la incorrecta y entra con la correcta | "Credenciales incorrectas." y luego el panel del cliente | Aprobado | `pm01_login_invalido`, `pm01_login_valido_panel_cliente`. Sesión vencida: prueba `ApiClient` de refresh/401 en la suite |
| PM02 | Crítica | Cliente B abre Mis citas. Por API, B intenta cancelar y reprogramar la cita #1580 de A | B no ve ni modifica citas de A | "Aún no tienes citas."; la API responde 404 "Cita no encontrada." y la cita sigue confirmada para A | Aprobado | `pm02_cliente_b_no_ve_cita_de_a`, `logs/api_pm02_pm04_pm08.log` |
| PM03 | Crítica | Reserva Barba, Barbero Uno, lunes 16 a las 11:00 | Cita persistida con sus datos | "Barba, Lunes 16 de noviembre a las 11:00, Confirmada"; `POST /api/citas/` 201 | Aprobado | `pm03_paso1…4`, `pm03_pm07_confirmada_doble_toque` |
| PM04 | Crítica | 5 rondas de 4 reservas simultáneas (A, B, A, B) al mismo horario | Solo una aceptada por horario | Rondas 1 a 4: 1 aceptada y 3 rechazadas (400). Ronda 5: 0 aceptadas, porque ese horario ya lo ocupaba la cita de PM08-3. "Con más de una aceptada: 0" | Aprobado | `logs/api_pm02_pm04_pm08.log` |
| PM05 | Alta | Reprogramar la cita propia al martes 17 a las 12:00 y después cancelarla | Se aplica la regla de 2 días y se libera el horario | Detalle "hasta el domingo 15 a las 11:00"; reprogramar 200; cancelar 200; "Próximas (0)" | Aprobado | `pm05_*`, `logs/pm05_reprogramar_cancelar_backend.log` |
| PM06 | Alta | Barbero 1 consulta su agenda de hoy y la del jueves 12 | Solo ve citas asignadas; solo se marcan las de hoy | Hoy: "Sin citas asignadas". Jueves 12: solo su cita de las 10:00 (las 2 de Barbero Dos no aparecen), con el aviso "la atención solo se marca en las citas de hoy" | Aprobado | `pm06_*` |
| PM07 | Alta | Doble toque en "Confirmar reserva" y modo avión al actualizar la agenda | Sin duplicados; mensaje claro y recuperación | Un solo `POST /api/citas/` (201) y "Próximas (1)". Sin red: "No hay conexión con el servidor…", sin perder lo cargado; con red se actualiza | Aprobado | `pm03_pm07_confirmada_doble_toque`, `logs/pm07_doble_toque_backend.log`, `pm07_*` |
| PM08 | Media | Por API: precio mayor al vigente, duración de 5 min enviada por la app y servicio desactivado en la base local | El servidor valida lo vigente | 400 "precio_total no puede exceder…"; la cita se guarda con 30 min y $100 (los vigentes); 400 "Servicio principal no encontrado o inactivo."; el servicio se reactiva al final | Aprobado | `logs/api_pm02_pm04_pm08.log` |
| PM09 | Alta | Cerrar sesión del cliente A, entrar como B y luego como secretaría | No quedan datos de la cuenta anterior | Al cerrar sesión vuelve al inicio de invitado; B ve sus propias citas; la secretaría ve su agenda | Aprobado | `pm09_*` |
| PM10 | Media | Texto al 200 %, pantalla de 360×640 dp y TalkBack activo | Sin recortes; controles identificables | Reserva completa hasta el resumen con texto al 200 % y en 360 dp. TalkBack activo; el árbol de accesibilidad expone etiquetas en todos los controles | Aprobado, con una limitación | `pm10_*`, `logs/pm10_arbol_accesibilidad_paso3.txt`, `docs/evidencias/accesibilidad-2026-11-11/` |

## Secretaría (regresión de BUG-01 y del alta de cliente de paso)

| Flujo | Observado | Evidencia |
|---|---|---|
| Buscar "Cliente" en Clientes | Lista "Cliente Prueba Local" y "Cliente Dos Prueba Local". BUG-01 ya no ocurre | `sec_bug01_buscar_cliente_corregido` |
| Citas del cliente A | Muestra la cancelada del martes 17 y la confirmada del jueves 12 | `sec_citas_del_cliente_a` |
| Registrar cliente de paso "Paso Final" | `POST /api/secretaria/clientes/` 201 y el cliente queda seleccionado | `sec_cliente_paso_*` |
| Crear cita para el cliente de paso | `POST /api/secretaria/citas/crear/` 201 | `sec_nueva_cita_paso_horario` |

## Defecto encontrado en esta batería

**BUG-02 (Alta):** al crear una cita desde la pestaña "Nueva" del panel de secretaría, la pantalla quedaba en negro (`sec_cita_paso_creada`). La vista hacía `Navigator.pop(context)`, pero ahí es una pestaña y no una ruta, así que el pop sacaba el panel completo.
- **Corrección:** commit `e208588`. Ahora vuelve a la pestaña Hoy y muestra la agenda del día de la cita (`sec_bug02_tras_crear_cita_vuelve_a_hoy`, "Jueves 12 de noviembre, 3 citas").
- **Prueba:** `BUG-02 …` en `test/secretaria_gestion_test.dart`. Falla sin el cambio y pasa con él (`docs/evidencias/bug02-2026-11-11/`).
- **Suite completa:** 539 pruebas aprobadas.

## Limitaciones

- No hubo teléfono físico; los dispositivos son emuladores (ver la matriz).
- La sesión vencida de PM01 está cubierta por pruebas automatizadas de `ApiClient`, no por una espera real de expiración del token.
- **TalkBack:** se activó en el emulador y el árbol de accesibilidad muestra la etiqueta de cada control. Los gestos inyectados por `adb` no reproducen la navegación real de TalkBack (el toque activa en lugar de enfocar, y Alt+flecha solo recorre la barra inferior). Una persona debe confirmar el recorrido con gestos en un dispositivo. Las guías de etiquetas, tamaño táctil y contraste están cubiertas por 85 pruebas automáticas.
- No se marcó "Cliente llegó", "Cobrar" ni "No asistió", porque eran citas de días futuros y la app solo lo permite el mismo día. Esos flujos tienen pruebas de widget y evidencia de octubre.
