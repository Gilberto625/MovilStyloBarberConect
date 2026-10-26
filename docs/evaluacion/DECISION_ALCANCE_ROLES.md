# Decisión de alcance: roles de la app móvil (GH#08, S1-01)

Fecha: 2026-10-23. Estado: **decidida por el equipo; falta el visto bueno del docente.**

## Contexto

- La Actividad 1 plantea tres roles móviles: Visitante, Cliente y Barbero.
- La app se construyó con Invitado, Cliente y Secretaría, porque la operación diaria (llegada, inasistencia y cobro) la hace recepción.
- Django no tenía endpoints para el barbero, y el panel del barbero en la web Angular está vacío.

## Decisión

La versión 1 de la app móvil cubre cuatro roles. El rol lo da Django y la app lleva a cada quien a su panel.

| Rol | Qué hace en la app | Endpoints |
|---|---|---|
| Invitado | Catálogo de servicios y productos, contacto, aviso de privacidad, registro | `GET /public/*` |
| Cliente | Agendar; ver, **reprogramar y cancelar** sus citas; tienda; perfil y privacidad (ARCO) | `/citas/`, `/mis-citas/`, `/mis-citas/{id}/cancelar/`, `/mis-citas/{id}/reprogramar/`, `/perfil/`, `/privacidad/*` |
| Secretaría | Agenda del día, llegó, no asistió, cobro, crear, buscar y editar citas | `/secretaria/*` |
| Barbero | **Mi agenda**: solo sus citas, y marcar "pasó a la silla" y "terminé el servicio" en las de hoy | `/barbero/agenda/`, `/barbero/citas/{id}/atencion/` |

Quedan fuera de la app y siguen en Angular: administración, reportes, inventario, configuración de pagos y corte de caja.

## Reglas que cuida el servidor

- **Barbero:**
  - Solo ve y cambia sus citas; una ajena responde 404.
  - Solo opera las de hoy.
  - No marca "no asistió": penaliza al cliente y sigue siendo de secretaría.
  - "Terminé el servicio" deja la cita en curso para que secretaría cobre.
- **Cliente:**
  - Solo cambia sus citas, en estado pendiente o confirmada.
  - Necesita 1 día de anticipación, o 2 si la cita cae de viernes a domingo, como dice la Ayuda de la web.
  - El anticipo no se reembolsa desde la app: la barbería lo resuelve.
- **Otros roles:** Django responde 403 en los endpoints de cada rol. La guarda de rutas de la app (GH#70) es una capa extra, no la seguridad.

## Evidencia

- **Backend:**
  - `core/barbero_views.py` y `core/cliente_cita_views.py`.
  - Pruebas `test_barbero_agenda` y `test_cliente_cita_modificar`, que corren el SQL real en PostgreSQL.
- **App:**
  - `lib/views/barber/`, `lib/views/client/client_reprogramar_view.dart` y `lib/routes/route_guard.dart`.
  - Pruebas `test/barbero_agenda_test.dart` y `test/cliente_cambios_cita_test.dart`.
- **Recorrido de API y en emulador contra Django local:** `docs/evidencias/cierre-funcional-2026-10-23/`.

## Pendiente

- El visto bueno del docente sobre este alcance.
- Que Figma y el manual (GH#63) incluyan las pantallas del barbero y las de cambiar una cita.
