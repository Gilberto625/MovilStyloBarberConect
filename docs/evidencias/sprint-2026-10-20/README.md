# Recorrido de evidencia del sprint — 2026-10-20

## Cómo se obtuvo
- **Dispositivo:** emulador `Medium_Phone_API_37.0`, Android 17, x86_64, 1080×2400. El reloj del emulador está en GMT; el backend usa la hora de México. Por eso secretaría ve "Hoy" = 2026-10-20 y la app reserva para el 22.
- **Backend:** Django local en `127.0.0.1:8000` (el emulador lo ve como `10.0.2.2`) con PostgreSQL local. Datos de `manage.py sembrar_datos_prueba` (backend `feature/movil-seed-pruebas`) y el endpoint de preferencias (backend `feature/movil-arco-preferencias`).
  - Los datos marcados "(pruebas)" y el aviso "BORRADOR DE PRUEBA" vienen de esa base local. **No son datos simulados en la app:** la app los recibe del backend como recibiría los reales.
  - Nada se escribió en producción ni en Neon.
- **App:** build debug con `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api`, sobre una rama local que une `feature/arco-acceso-rectificacion`, `feature/test-integration-device` y `fix/secretaria-cobro-dialogo`. Esa rama no se sube; las piezas van en sus PRs.
- **Automatización:** `integration_test`.
  - `pi01_reserva_test.dart` crea la cita.
  - `recorrido_evidencia_test.dart` (copia exacta en `recorrido_evidencia_test.dart.txt`) recorre las pantallas e imprime `EVIDENCIA:<nombre>` en cada paso. Un script en la PC toma la captura con `adb exec-out screencap` al ver la marca.
  - Credenciales de prueba por `--dart-define`; no se versionan.
- **Resultado:**
  - `pi01_2026-10-20.log`: 1/1 en verde, 25 s.
  - `recorrido_2026-10-20.log`: 1/1 en verde, 3 min, sin excepciones de Flutter.
  - Cada captura se revisó a mano antes de incluirla.

## Casos

| Caso | Esperado | Observado | Captura | Tarjeta |
|---|---|---|---|---|
| Catálogo de invitado | Servicios y datos del negocio desde el backend | Muestra el negocio y los 3 servicios de la base local | `01_invitado_inicio.png` | GH#09, 4.1 |
| PM01 login inválido | Se queda en login con mensaje | "Credenciales incorrectas." (401 del backend) | `02_pm01_login_invalido.png` | PM01, GH#16 |
| PM01 login válido | Entra al panel del rol cliente | "Hola, cliente.prueba" y próxima cita | `03_pm01_cliente_inicio.png` | PM01, GH#16 |
| PM01 sesión vencida | 401 → refresh → reintento; refresh fallido → cierra sesión | Probado con MockClient (sin captura: no se puede forzar la expiración en el emulador sin esperar el JWT) | `test/integration/api_client_refresh_test.dart` (rama `feature/test-integration-http`) | PM01, GH#69 |
| PM03 reserva (PI-01) | La cita creada aparece en Mis citas con los mismos datos | Corte clásico, 2026-10-22 10:00, confirmada; la del 20 queda en historial | `04_pm03_mis_citas.png`, `pi01_2026-10-20.log` | PM03, GH#17 |
| PM03 horarios reales | La disponibilidad sale de Django | Horarios del barbero elegido para la fecha | `05_pm03_agendar_horarios.png` | PM04, S5-02 |
| ARCO: entrada | Perfil → Privacidad y mis datos | Botón en Perfil y centro de privacidad | `06_perfil.png`, `07_arco_privacidad.png` | S3-04 |
| ARCO Acceso | Perfil e historial del titular | Datos de la cuenta, "Sin registrar" en lo vacío, 2 citas | `08_arco_mis_datos.png` | GH#42, 6.8a |
| ARCO Rectificación | Formulario con los campos que acepta `PUT /perfil/` | Correo no editable, validaciones y ayuda | `09_arco_corregir_datos.png` | GH#43, 6.8b |
| Aviso de privacidad | Texto desde `/public/legal/?tipo=privacidad` | Muestra el borrador de la base local | `10_aviso_optin_apagado.png` | GH#41, 6.6 |
| Opt-in (usuario nuevo) | Todo apagado; activar uno se guarda en la cuenta | Corrida del 2026-10-19: WhatsApp activado y "Preferencias guardadas en tu cuenta." | `11a_aviso_optin_activado_usuario_nuevo.png` | GH#41, GH#45, 6.7 |
| Opt-in (cambio) | Desactivar también se guarda en el servidor, con su fecha | Esta corrida: el mismo usuario lo desactiva; en la base queda todo en `false` con fecha 2026-10-21 02:01 UTC y versión del aviso | `11b_aviso_optin_desactivado_en_backend.png` | GH#45, 6.8d |
| PM09 logout | Vuelve a invitado | Inicio de invitado | `12_pm09_logout.png` | PM09, GH#26 |
| PM09 cambio de usuario | La secretaria no ve datos del cliente anterior | Panel "Operación" de secretaría | `13_pm09_secretaria_hoy.png` | PM09 |
| Secretaría: día | La cita del día elegido, con acciones según el servidor | 2026-10-22, 1 cita confirmada, restante $150 | `14_secretaria_dia_con_cita.png`, `15_secretaria_detalle.png` | GH#12 |
| No asistió | Confirmación fuerte (penaliza) | Diálogo que explica la penalización; se canceló, no se marcó | `16_no_asistio_confirmacion_fuerte.png` | PM06 |
| Llegó | Pasa a en curso solo si el servidor acepta | "Cliente marcado en sala", estado `en_curso` | `17_secretaria_llego.png` | GH#12 |
| Cobrar | Registra el cobro en el servidor | Diálogo en efectivo; "Cobro de $150.00 MXN registrado (efectivo). Cita completada." y restante $0.00. Sin el error ERR-01 | `18_secretaria_cobrar_dialogo.png`, `19_secretaria_cobrado.png` | GH#12, ERR-01 |
| PM07 doble toque | No duplica | Probado en prueba unitaria (secretaría) y en la UI (botón deshabilitado) | `test/unit/viewmodels_mockito_test.dart` | PM07, GH#25 |
| PM10 texto 1.3 y 360×800 | Sin overflow | Probado en pruebas de widget de las pantallas nuevas (sin captura en dispositivo) | `test/privacidad_views_test.dart` | PM10, GH#18, GH#19 |

## Observaciones para el rediseño (no bloquean)
- "No asistió" usa el mismo botón dorado que una acción normal. Por la penalización, debería verse como acción peligrosa (rojo, o escribir para confirmar).
- El estado se muestra crudo (`en_curso`) y el contador dice "1 citas".
- Al marcar Llegó o cobrar, el mismo mensaje sale en el banner y en el snackbar.
