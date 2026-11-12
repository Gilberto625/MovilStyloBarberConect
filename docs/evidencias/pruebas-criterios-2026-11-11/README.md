# Pruebas de criterios pendientes (2026-11-11)

Pruebas automáticas que cierran criterios de tarjetas del tablero. Cada prueba lleva el ID de su tarjeta en el nombre. Están en `test/criterios/`.

## Cómo se ejecutaron

```bash
dart format --output=none --set-exit-if-changed .   # 0 cambios
flutter analyze                                     # No issues found!
flutter test --coverage                             # 553 pruebas, todas en verde
flutter test --concurrency=1 --reporter expanded test/criterios/   # salida_pruebas_nuevas.txt
```

- Flutter 3.47.7 en Windows, sin emulador ni backend: las pruebas usan `MockClient` y mocks de Mockito.
- Cobertura de líneas de `lib/` después del cambio: 84.28 % (5956 de 7067, `coverage/lcov.info`).
- En las salidas guardadas, las rutas son relativas al repo.

## Tarjeta → criterio → prueba → resultado

| Tarjeta | Criterio | Prueba (archivo › nombre) | Resultado |
|---|---|---|---|
| GH#11 | Un doble toque en "Entrar" no envía dos veces: el repositorio de auth se llama una vez | `test/criterios/login_2fa_test.dart` › `GH#11 doble toque en "Entrar" llama una sola vez al repositorio de auth` | Pasa |
| GH#20 | La verificación 2FA se abre solo cuando el ViewModel la pide | `test/criterios/login_2fa_test.dart` › `GH#20 si el servidor pide 2FA, el login abre la verificación y no guarda tokens` | Pasa |
| GH#20 | Un login normal no abre la verificación 2FA | `test/criterios/login_2fa_test.dart` › `GH#20 un login normal va al panel y nunca abre la verificación 2FA` | Pasa |
| GH#20 | Un OTP inválido muestra el mensaje del servidor y no pinta el código ni los tokens | `test/criterios/login_2fa_test.dart` › `GH#20 OTP inválido muestra el mensaje del servidor sin exponer el código ni los tokens` | Pasa |
| GH#17 | Un error de red al reservar deja un mensaje claro, no marca la cita como creada y permite reintentar (pila real hasta `ApiClient`) | `test/criterios/reserva_cliente_test.dart` › `GH#17 sin conexión: mensaje claro, cita no creada y el reintento sí la crea` | Pasa |
| GH#17 | Lo mismo con `NetworkException` lanzada por el repositorio (Mockito) | `test/criterios/reserva_cliente_test.dart` › `GH#17 NetworkException desde el repositorio no marca la cita como creada` | Pasa |
| GH#25 / PM07-a | Mientras la reserva se envía, "Confirmar reserva" queda deshabilitado y se crea una sola cita | `test/criterios/reserva_cliente_test.dart` › `GH#25 PM07-a mientras se envía, "Confirmar reserva" queda deshabilitado y se crea una sola cita` | Pasa |
| GH#25 / PM07-a | Un segundo toque mientras se revisa la política de anticipo no envía otra reserva | `test/criterios/reserva_cliente_test.dart` › `GH#25 un segundo toque mientras se revisa la política no envía otra reserva` | **Fallaba; pasa tras el fix 1** |
| GH#23 / PM02 | Cancelar una cita ajena: 404 "Cita no encontrada." llega como `ApiException` con ese mensaje | `test/criterios/cita_ajena_test.dart` › `GH#23 PM02 cancelar una cita ajena: 404 como ApiException con el mensaje del servidor` | Pasa |
| GH#23 / PM02 | Reprogramar una cita ajena: lo mismo | `test/criterios/cita_ajena_test.dart` › `GH#23 PM02 reprogramar una cita ajena: 404 como ApiException con el mensaje del servidor` | Pasa |
| GH#23 / PM02 | El ViewModel no da la cita ajena por cambiada ni recarga la lista | `test/criterios/cita_ajena_test.dart` › `GH#23 el ViewModel no da la cita ajena por cancelada ni reprogramada` | Pasa |
| S7-01 | La agenda del barbero muestra la carga al abrir y al reintentar, el error de red con "Reintentar" y el vacío | `test/criterios/barbero_agenda_estados_test.dart` › `S7-01 muestra la carga al abrir y al reintentar, luego error y vacío` | Pasa |
| US-SEC-EDITAR | Si Django rechaza el horario (400 "Ese horario ya está ocupado."), se ve el mensaje y la cita no queda reprogramada | `test/criterios/secretaria_criterios_test.dart` › `US-SEC-EDITAR si el servidor rechaza el horario, se ve su mensaje y la cita no queda reprogramada` | **Fallaba al abrir la pantalla; pasa tras el fix 2** |
| US-SEC-EDITAR | Abrir Reprogramar muestra primero la carga, sin datos de otra cita y sin error de construcción | `test/criterios/secretaria_criterios_test.dart` › `US-SEC-EDITAR abrir Reprogramar muestra la carga primero y no avisa a los oyentes durante la construcción` | **Fallaba; pasa tras el fix 2** |
| US-SEC-ALTA | El cliente de paso queda seleccionado con su nombre, Nueva cita solo ofrece horarios `disponible: true` y la cita sale a su nombre | `test/criterios/secretaria_criterios_test.dart` › `US-SEC-ALTA el cliente de paso queda seleccionado y Nueva cita solo ofrece horarios libres` | Pasa |

## Defectos encontrados y corregidos

### Fix 1: GH#25, doble reserva si se toca dos veces mientras se revisa la política

- **Qué pasaba:** al tocar "Confirmar reserva", la vista primero vuelve a pedir la política de anticipo (`loadPolitica`) y después reserva. Durante esa consulta `bookingBusy` todavía es `false`. El botón seguía activo y sin spinner. Un segundo toque iniciaba otro `_confirmar()`. Si la primera reserva terminaba antes de que respondiera la segunda consulta de política, se creaba **una segunda cita**.
- **Prueba que lo muestra:** `GH#25 un segundo toque mientras se revisa la política no envía otra reserva`. Antes del fix: `Expected: <1> Actual: <2>` llamadas a `crearCita` (`gh25_antes_del_fix.txt`). Después: pasa (`gh25_despues_del_fix.txt`).
- **Cambio (`lib/views/client/client_agendar_view.dart`):** bandera `_confirmando` en el estado de la vista. Se activa al primer toque y se apaga en un `finally`. Mientras está activa, `_confirmar` no hace nada y el botón y "Paso anterior" quedan deshabilitados, con spinner.

### Fix 2: US-SEC-EDITAR, error de construcción al abrir "Reprogramar" desde secretaría

- **Qué pasaba:** `SecretaryReprogramarView` llamaba a `cargarEditable()` dentro de `didChangeDependencies`. Ese método avisa a los oyentes en el acto, durante la construcción de la ruta, y Flutter reporta `setState() or markNeedsBuild() called during build.` cada vez que se abre la pantalla (es una aserción: se ve en debug y en las pruebas). Ninguna prueba abría esta pantalla, así que no se había detectado.
- **Pruebas que lo muestran:** las dos `US-SEC-EDITAR`. Antes del fix las dos fallan con esa aserción (`us_sec_editar_antes_del_fix.txt`). Después pasan (`us_sec_editar_despues_del_fix.txt`).
- **Cambio (`lib/views/secretary/secretary_gestion_views.dart`):** la cita se pide en un `addPostFrameCallback`. Hasta entonces la vista muestra "Cargando cita…" con la bandera `_pedida`. Así no aparecen, ni por un cuadro, los datos de una cita abierta antes, porque el ViewModel es compartido por toda la app.

## Criterios que ya estaban cubiertos (no se duplicaron)

| Tarjeta | Criterio | Prueba existente |
|---|---|---|
| S7-01 | Vacío y error con reintento en la pantalla | `test/barbero_agenda_test.dart` › `vacía y error con reintento`. Se agregó solo el estado de carga. |
| S7-01 | Estados del ViewModel: lista, vacía y error | `test/barbero_agenda_test.dart` › `estados de carga: lista, vacía y error` |
| GH#25 / PM07-a | Doble envío a nivel ViewModel (`reservar` dos veces seguidas) | `test/cliente_cambios_cita_test.dart` › `ERR-06: reservar dos veces seguidas crea una sola cita`. Se agregó el nivel de widget. |
| GH#20 | Fase `needs2fa` del ViewModel sin inventar tokens | `test/auth_and_flows_test.dart` › `login requires 2FA without inventing tokens`. Se agregó la navegación en la vista. |
| GH#17 | Rechazo 409 al reservar no da la cita por creada | `test/unit/viewmodels_mockito_test.dart` › `reservar con 409 (horario ocupado) no da la cita por creada`. El caso de red no estaba. |
| US-SEC-ALTA | Clientes de paso por HTTP (`crearClientePaso`) | `test/integration/secretaria_api_service_http_test.dart` › `crearClientePaso devuelve el cliente creado`. Faltaba la pantalla. |

## Archivos

- `salida_pruebas_nuevas.txt`: salida `--reporter expanded` de `test/criterios/`, todas en verde.
- `gh25_antes_del_fix.txt` / `gh25_despues_del_fix.txt`: `test/criterios/reserva_cliente_test.dart` sin y con el fix 1.
- `us_sec_editar_antes_del_fix.txt` / `us_sec_editar_despues_del_fix.txt`: las pruebas `US-SEC-EDITAR` sin y con el fix 2.
