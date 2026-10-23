# Cierre funcional: cambiar la cita propia y agenda del barbero (2026-10-23)

Tarjetas:
- **Cliente:** S6-02, S6-03, PM05.
- **Barbero:** GH#08, S7-01, S7-02, S7-03, PM06.
- **Rutas y errores:** GH#70, ERR-03, ERR-06.

## Cómo se obtuvo

- **Backend:**
  - Django local en `127.0.0.1:8000` con PostgreSQL local (`stylo_barber_local`).
  - Código de la rama `feature/movil-citas-cliente-barbero` (incluye el arreglo de concurrencia de Gilberto625/BackendStyloBarberConect#6).
  - Nada se ejecutó contra producción ni contra Neon.
- **App:**
  - APK debug de `feature/cierre-funcional` con `API_BASE_URL=http://10.0.2.2:8000/api`.
  - Emulador Android `Medium_Phone_API_37.0`, en zona UTC.
- **Cuentas:**
  - `cliente.prueba` (A), `cliente2.prueba` (B), `secretaria.prueba` y `barbero1.prueba`, de la semilla local.
  - Las claves se leen de un archivo local sin versionar y no aparecen aquí.
- **Recorrido de API:**
  - Script `e2e_cierre.py.txt` (Python estándar, se corre con `python -I`).
  - Salida en `corrida_api.log` y `e2e_api_resultados.json`, sin tokens, correos ni teléfonos.
- **Hoy en la prueba:** viernes 23 de octubre de 2026, ~13:00 (México).

## 1. Recorrido de API: 27 de 27 casos pasan

| Caso | Quién | Esperado | Observado |
|---|---|---|---|
| PM05-01 `mis-citas` marca la cita del martes como modificable | A | `puede_modificar: true`, límite lunes 10:00 | Igual |
| PM05-02/03 B cancela o reprograma la cita de A | B | 404 | 404 "Cita no encontrada." |
| PM05-04 Sin sesión | — | 401 | 401 |
| PM05-05/06 A reprograma a un horario libre | A | 200 y `mis-citas` con la nueva fecha | 200, miércoles 10:00 |
| PM05-07 Mover encima de la cita de B | A | 409 | 409 "Ese horario ya está ocupado." |
| PM05-08 Domingo | A | 409 | 409 "El negocio no abre ese día." |
| PM05-09 Hora fuera de bloque (12:10) | A | 400 | 400 |
| PM05-10/11 Cita del sábado (faltan menos de 2 días) | A | No modificable y 409 al cancelar | 409 "…al menos 2 días de anticipación…" |
| PM05-12/13 A cancela | A | 200 y estado `cancelada` | Igual |
| PM05-14 El horario se libera | A | Disponible otra vez | Disponible |
| PM05-15 Cancelar dos veces | A | 409 | 409 |
| PM06-01 Agenda del barbero | barbero1 | Solo sus citas de hoy | Solo la suya; la del barbero 2 no aparece |
| PM06-02/03 Cliente y secretaría en la agenda del barbero | A, secretaría | 403 | 403 |
| PM06-04 Cita de otro barbero | barbero1 | 404 | 404 |
| PM06-05 Terminar sin iniciar | barbero1 | 409 | 409 |
| PM06-06 Cita de otro día | barbero1 | 409 | 409 "Solo puedes cambiar la atención de las citas de hoy." |
| PM06-07 "no_asistio" | barbero1 | 400 | 400: no es acción del barbero |
| PM06-08/09 Iniciar y terminar | barbero1 | `en_silla` y luego `terminada`, en curso | Igual |
| PM06-10 Terminar dos veces | barbero1 | 409 | 409 (el mensaje se aclaró después: "Ya marcaste esta cita como terminada.") |
| PM06-11 Secretaría la ve lista para cobrar | secretaría | `en_curso`, `puede_cobrar: true` | Igual |
| PM06-12 El cliente cancela una cita en curso | A | 409 | 409 |

## 2. Recorrido en el emulador

| Captura | Qué muestra |
|---|---|
| `01_mis_citas.png` | Mis citas del cliente A |
| `02_fuera_de_plazo.png` | Cita del sábado: explica la anticipación de 2 días y solo ofrece llamar |
| `03_con_plazo.png` | Cita del martes: "Reprogramar" y "Cancelar cita", hasta el lunes a la misma hora |
| `04_reprogramar.png`, `05_reprogramar_elegido.png` | Mismo barbero y servicio, horarios libres y botón "Mover al martes 27 de octubre, 16:00" |
| `06_reprogramada.png` | La lista, recargada del servidor, con la nueva hora |
| `07_confirmar_cancelacion.png` | Confirmación con motivo opcional |
| `08_cancelada.png` | Mensaje del servidor; la cita pasa al historial |
| `09_barbero_agenda.png` | Al entrar, el barbero va a "Mi agenda de hoy" |
| `10_barbero_en_silla.png`, `11_barbero_terminado.png` | "Pasó a la silla" → "En la silla" → "Terminé el servicio" → "Lista para cobrar" |

El log del servidor de esa corrida registra:
- `POST /api/mis-citas/62/reprogramar/ 200`
- `POST /api/mis-citas/62/cancelar/ 200`
- `POST /api/barbero/citas/63/atencion/ 200`, dos veces

Cada acción va seguida de la recarga de la lista.

### Defectos que encontró el recorrido y ya están corregidos

1. **El límite salía en la zona del teléfono.** En el emulador (UTC), "hasta el lunes a las 12:00" de México se mostraba como 18:00. Ahora la app usa la hora de pared que manda Django. Commit `03bbd3f`; `03_con_plazo.png` ya es del APK corregido.
2. **La fecha a media frase iba en mayúscula** ("Mover al Martes…"). Corregido en el mismo commit. `07_confirmar_cancelacion.png` es de antes del arreglo.
3. **Una cita confirmada de un día anterior aparecía en "Próximas" y como "Próxima cita".** Ahora va al historial. Commit `d00e660`; `01_mis_citas.png` es de antes del arreglo.
4. **"Terminar" dos veces respondía "Primero inicia la atención".** Ahora dice "Ya marcaste esta cita como terminada." Backend `0d40726`.

## 3. Pruebas automatizadas

- **Django:**
  - `test_cliente_cita_modificar` (17), `test_barbero_agenda` (8) y `test_oposicion_perfilado` (4).
  - Corren el SQL real sobre un esquema `negocio` mínimo copiado de `sql/stylo_barber_connect.sql`.
  - Suite completa: 387 pruebas, con los mismos 5 problemas previos de ML y WebAuthn (ERR-05).
- **Flutter:**
  - `test/cliente_cambios_cita_test.dart` (16) y `test/barbero_agenda_test.dart` (14).
  - Suite completa: 316 pruebas en verde, cobertura de 77.94 %.

## Limpieza

Las citas de prueba de esta corrida se borraron de la base local al terminar.
