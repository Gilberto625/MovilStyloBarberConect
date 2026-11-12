# Acta de aceptación: Stylo Barber Connect, app móvil (DOC-003 / DE-03, GH#65)

| Dato | Valor |
|---|---|
| Proyecto | Stylo Barber Connect, app Android para Tony Stylo Barbería |
| Repositorio | `Gilberto625/MovilStyloBarberConect` |
| Versión evaluada | **0.8.1+5**, publicada en Google Play en **prueba cerrada (Alpha)**. Tag `v0.8.1`, generado por `release.yml` (run 41021801630, 2026-10-30) |
| Cambios posteriores incluidos en la evaluación | PR #125 (BUG-01), fusionado en `develop` el 2026-11-12. Todavía no está en una versión publicada |
| Versión candidata | **1.0.0-rc.1**, por preparar en la rama `release` (hito del 30-nov-2026) |
| Backend evaluado | `BackendStyloBarberConect` `main` en `970e9ad` (incluye los PR #7 y #11) |
| Documento preparado | 2026-11-11 |
| Documentos de soporte | `docs/evaluacion/CATALOGO_PRUEBAS.md`, `REGISTRO_ERRORES.md`, `AUDITORIA_DEPENDENCIAS.md`, `docs/manual/MANUAL_CLIENTE.md`, `docs/manual/MANUAL_SECRETARIA_BARBERO.md` |

Esta acta resume lo que se probó y lo que falta. **No da nada por aceptado:** la aceptación ocurre cuando los participantes la firman.

## 1. Alcance entregado

Roles de la app según `docs/evaluacion/DECISION_ALCANCE_ROLES.md` (decidido por el equipo; **falta el visto bueno del docente**):

| Rol | Qué hace en la app |
|---|---|
| Invitado | Catálogo de servicios y productos, contacto, aviso de privacidad y registro |
| Cliente | Reservar en 4 pasos, Mis citas, reprogramar y cancelar su cita (con plazo), tienda y pedidos, perfil, privacidad y derechos ARCO, código por correo opcional |
| Secretaría | Agenda de hoy y de otro día, detalle, Cliente llegó, No asistió, cobro, clientes y búsqueda, nueva cita, cliente de paso y reprogramar |
| Barbero | Su agenda; "Pasó a la silla" y "Terminé el servicio" en las citas de hoy |

Fuera de la app (siguen en la web): administración, reportes, inventario, ventas, pagos con Clip y corte de caja.

## 2. Resumen de pruebas

Detalle y evidencia de cada fila en `CATALOGO_PRUEBAS.md`.

| Tipo | Resultado |
|---|---|
| Flutter (unitarias, widget e integración HTTP) | **349 de 349** aprobadas el 2026-11-06; cobertura de líneas **79.51 %** en CI (run 42258784727) |
| Integración en emulador | PI-01 (reserva) y recorrido de tres roles, 1/1 cada uno (19 y 20-oct) |
| Backend (Django) | 401 pruebas; los 5 fallos son previos y de módulos que la app no usa (ML y passkeys web) |
| Seguridad | SAST, R8, ofuscación, secretos, pinning, almacenamiento cifrado, permisos y matriz Debug/Release aprobados. JADX, MobSF y DAST pendientes. Frida y Ghidra fuera de alcance |
| No funcionales | Accesibilidad automatizada, pantalla pequeña y red aprobadas. Rendimiento (100 % ≤ 3 s), matriz de dispositivos (API 24 y 37, 360 dp, texto 200 %) y TalkBack aprobados el 2026-11-11; el recorrido de TalkBack con gestos lo debe confirmar una persona |

### Casos críticos y altos

| Caso | Prioridad | Estado | Evidencia principal |
|---|---|---|---|
| PM02 Cliente A no accede a citas de B | Crítica | Aprobado | Pruebas Django `test_politica_pago_propia` y `test_cliente_cita_modificar`; `docs/evidencias/permisos-concurrencia-2026-10-21/` |
| PM04 Reservas simultáneas | Crítica | Aprobado | 13 de 13 rondas con una sola reserva; `test_agenda_bloqueo` |
| PM01 Acceso válido, inválido y sesión vencida | Alta | Aprobado | Capturas del 20-oct; `api_client_refresh_test.dart` |
| PM03 Reserva en horario disponible | Alta | Aprobado | PI-01; recorrido 0.8.1 del 6-nov |
| PM05 Reprogramar y cancelar la cita propia | Alta | Aprobado | `docs/evidencias/cierre-funcional-2026-10-23/` (27/27) |
| PM06 Agenda y estado del barbero | Alta | Aprobado | Ídem |
| PM07 Doble pulsación y pérdida de red | Alta | **Parcial**: doble pulsación y pérdida de red aprobadas; **pendiente** el reintento que verifica si la cita ya quedó (falta idempotencia en el backend) | `cliente_cambios_cita_test.dart`, `api_client_errores_red_test.dart` |
| PM09 Cierre y cambio de sesión | Alta | Aprobado | Capturas del 20-oct y del 6-nov |

Prioridad media: **PM08** aprobado el 2026-11-11 por API y **PM10** aprobado con la limitación de TalkBack por gestos (ERR-17 cosmético). Ver `BATERIA_FINAL_PM.md`.

## 3. Defectos

Fuente: `docs/evaluacion/REGISTRO_ERRORES.md`.

### Cerrados

| ID | Defecto | Cómo se cerró |
|---|---|---|
| ERR-01 | Diálogo de cobro: controladores liberados antes de tiempo | `fix/secretaria-cobro-dialogo`, con prueba |
| ERR-02 | Backend: `politica-pago` mostraba datos de otro cliente | Backend PR #6, en `main` con el #7 |
| ERR-03 | Backend: podía resolver a otra persona | Backend PR #7 |
| ERR-04 | Backend local con SQLite respondía 503 | Entorno con PostgreSQL local y semilla |
| ERR-06 | Reserva sin guarda propia contra doble envío | App PR #110 |
| ERR-07 | `PUT /perfil/` borraba campos no reenviados | Mitigado en la app: siempre los reenvía |
| ERR-09, ERR-10 | Error viejo y flecha sin acción tras cancelar la cuenta | App PR #101 |
| ERR-11, ERR-12 | Excepción cruda sin red; un corte al renovar cerraba la sesión | App PR #103 |
| ERR-13 | Fotos del catálogo mal encuadradas y pesadas | App PR #106 |
| ERR-14 | Backend: reservas simultáneas duplicadas | Backend PR #6, en `main` con el #7 |
| **ERR-15 (BUG-01)** | Secretaría: buscar clientes, cliente de paso y reprogramar fallaban con un error de tipo `Future` | **App PR #125**, fusionado en `develop` el 2026-11-12. Falta publicarlo en una versión |
| **ERR-16** | Backend: el alta de cliente de paso respondía 500 | **Backend PR #11**, fusionado en `main` el 2026-11-06 |

ERR-08 (el release no permite HTTP sin cifrar) es un control esperado, no un defecto.

### Abiertos

| ID | Defecto | Impacto | Qué falta |
|---|---|---|---|
| ERR-05 | Backend: pruebas de ML que fallan desde antes (falta `matplotlib`; un mock de segmentación). En la corrida del 6-nov también fallan 3 de passkeys (web) | No afecta a la app | Corregir en el backend |
| ERR-17 | "Productos" se parte en dos líneas en la barra del invitado con texto al 130 % | Cosmético | Ajuste de la etiqueta y prueba de widget |
| ERR-18 | La CI de `develop` falla en `flutter analyze` con Flutter 3.50.0 (versión sin fijar) | Bloquea los checks de los PR hasta corregirlo | Fijar la versión de Flutter en los workflows y luego migrar a `material_ui` |

## 4. Limitaciones y bloqueos

1. **Producción en Google Play.** La app está en prueba cerrada. Para pedir producción, Play exige **12 testers aceptados durante 14 días seguidos**. Hasta cumplirlo, no hay versión en producción.
2. **Sin teléfono físico.** Todas las pruebas en dispositivo se hicieron en **emuladores** (Android 17, API 37). Falta repetir capturas y almacenamiento cifrado en un Android real.
3. **Frida y Ghidra**, fuera de alcance por decisión del equipo (2026-11-11). Tampoco se hicieron JADX-GUI, MobSF ni DAST; lo equivalente se midió con las herramientas del SDK (`ANALISIS_ESTATICO.md`).
4. **Historias del backlog no implementadas:**
   - Recuperar y cambiar la contraseña desde la app.
   - Recordatorios de citas por WhatsApp.
   - Cola sin conexión de la secretaría (necesita `client_event_id` e idempotencia en el backend; también resolvería PM07-c).
   - Cron de supresión ARCO: el comando `suprimir_cuentas_vencidas` existe y tiene pruebas, pero según la matriz de cumplimiento (revisión del 21-oct) no está programado como Cron Job en Render. Sin él, las cuentas canceladas quedan bloqueadas y no se suprimen solas a los 30 días.
5. **Mediciones en curso:** rendimiento (30 mediciones), TalkBack y matriz de dispositivos se están ejecutando; sus resultados irán en `RENDIMIENTO.md` y `MATRIZ_DISPOSITIVOS.md`.
6. **El PR #125 no está publicado.** La versión de Play (0.8.1+5) todavía tiene ERR-15 en la secretaría. Se corrige con la siguiente versión (1.0.0-rc.1).
7. **Alcance de roles:** falta el visto bueno del docente a `DECISION_ALCANCE_ROLES.md`.
8. **Dependencias:** hay tres majors pendientes (`flutter_secure_storage`, `google_fonts`, `cupertino_icons`) que requieren pruebas antes de actualizar (`AUDITORIA_DEPENDENCIAS.md`).

## 5. Participantes

| Rol | Nombre | Firma | Fecha |
|---|---|---|---|
| Equipo de desarrollo | Gilberto Hernández Hernández | ______________________________ | ____________ |
| Equipo de desarrollo | Jorge Miguel Cayetano García | ______________________________ | ____________ |
| Cliente (Tony Stylo Barbería) | ______________________________ | ______________________________ | ____________ |
| Docente | ______________________________ | ______________________________ | ____________ |

## 6. Dictamen

Marcar una opción al firmar:

- [ ] Aceptada sin observaciones.
- [ ] Aceptada con las observaciones y limitaciones de las secciones 3 y 4.
- [ ] No aceptada. Motivo: ______________________________________________

Observaciones de los participantes:

______________________________________________________________________

______________________________________________________________________
