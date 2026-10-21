# Permisos, aislamiento entre clientes y reservas simultáneas (2026-10-21)

Pruebas de API para S3-05, GH#70, PM02 (GH#23), PM04 (GH#24, S5-05) y PC-03.

## Cómo se obtuvo
- **Backend:** Django local en `127.0.0.1:8000` (`runserver` con hilos), con PostgreSQL local (`stylo_barber_local`) y el código de `main` del backend (`e0c0f93`). Nada se ejecutó contra producción ni contra Neon.
- **Producción:** corre con `gunicorn --workers 2` (`start.sh`), así que también atiende dos peticiones a la vez.
- **Cuentas:** las de la semilla local.
  - Cliente A: id 1.
  - Cliente B: id 2.
  - Secretaría: id 3.

  Las credenciales se leen de un archivo local que no se versiona. Los resultados omiten tokens, correos, teléfonos y datos bancarios.
- **Scripts:** `pruebas_permisos_aislamiento.py.txt` y `pruebas_concurrencia.py.txt`. Son Python estándar y se corren con `python -I`; llevan la extensión `.txt` para que el SAST no los trate como código de la app.
- **Restauración:** al terminar se borraron las 36 citas de prueba (ids 2 a 37) y su historial. La base quedó con su única cita previa (id 1, confirmada), y B quedó sin penalización (se comprobó con `politica-pago`).

## 1. Cliente contra endpoints de secretaría (S3-05, GH#70): **pasa**

| Petición con el token del cliente A | Esperado | Observado |
|---|---|---|
| `GET /secretaria/citas/dia/` | 403 | 403 "No autorizado." |
| `GET /secretaria/clientes/?q=prueba` | 403 | 403 |
| `GET /secretaria/citas/buscar/?cliente_id=2` | 403 | 403 |
| `POST /secretaria/citas/1/asistencia/` (`llego`) | 403 | 403. La cita 1 siguió confirmada |
| `POST /secretaria/citas/crear/` | 403 | 403 |
| Control: `GET /secretaria/citas/dia/` con el token de secretaría | 200 | 200 |

El permiso lo da `SecretariaPermisoMixin._ensure_permiso`. Solo acepta `secretaria`, `administrador` o `admin`, y se revisa antes de leer la cita.

## 2. Aislamiento entre clientes (PM02, GH#23): **falla en `politica-pago`** (ERR-02 confirmado)

**Preparación:** secretaría creó una cita de prueba para B, con fecha de hoy, y la marcó "No asistió". Con eso B queda penalizado: 1 inasistencia, anticipo del 50 % y 10 citas por cumplir.

| Petición | Observado | Lectura |
|---|---|---|
| B pide su política (`cliente_id=2`) | 200, `penalizado: true`, 1 inasistencia | Correcto |
| A pide su política (`cliente_id=1`) | 200, `penalizado: false`, 0 inasistencias | Correcto |
| **A pide la política de B (`cliente_id=2`)** | **200, `penalizado: true`, 1 inasistencia, anticipo del 50 %** | **Falla: A ve el historial de inasistencias de B** |
| A pide `/mis-citas/` | Solo la cita 1, que es suya | Correcto |
| B pide `/mis-citas/` | Solo la cita 2, que es suya | Correcto |
| A hace `POST /citas/` con `cliente_id=2` | 201. La cita quedó a nombre de A (`cliente_usuario_id=1`) | Correcto: el servidor ignora el id ajeno |

**Causa:** `CitaPoliticaPagoView` (`core/views.py`) calcula la penalización del `cliente_id` recibido y no lo compara con el usuario autenticado.

**Límite:** en esta base el id de Django y el de `negocio.usuario` coinciden (1, 2 y 3). Por eso aquí no se puede reproducir la otra mitad de ERR-02 y ERR-03, que ocurre cuando esos ids no coinciden.

## 3. Reservas simultáneas (PM04, GH#24, S5-05): **falla** (ERR-14)

**Primera corrida** (`corrida_permisos_aislamiento.log`, rondas 1 a 4):
- Las rondas 1 a 3 no sirven como prueba, porque B estaba penalizado y lo rechazó la regla del anticipo.
- La ronda 4 (A, A, B y B a las 13:00) aceptó solo una.

**Segunda corrida, sin penalizaciones** (`corrida_concurrencia.log` y `concurrencia_resultados.json`):
- Condiciones: barbero con `empleado_id` 3, servicio 1 (45 min) y días 28 y 29 de octubre.
- En cada ronda, las peticiones salen juntas, detrás de una barrera de hilos.

| Rondas | Peticiones por ronda | Resultado |
|---|---|---|
| 1 a 10 | A y B | En 8 rondas se aceptaron **las dos**; en 2 rondas, solo una |
| 11 a 13 | A, A, B y B | Se aceptaron **las cuatro** en cada ronda, incluidas dos del mismo cliente |

**En la base** (`duplicados_en_base.txt`): 11 horarios del mismo barbero quedaron con 2 a 4 citas activas.

**Causa:** `CitasView.post` (`core/views.py`) hace dos pasos dentro de `transaction.atomic()` y sin ningún bloqueo:
1. Consulta los horarios ocupados (`sql_citas_ocupadas_dia`).
2. Hace el `INSERT INTO negocio.cita`.

Con el aislamiento READ COMMITTED de PostgreSQL, dos transacciones simultáneas ven el horario libre y las dos insertan. El aviso "Ese horario ya está ocupado." solo aparece si la otra cita ya se había confirmado.

**Propuesta** (toca el backend, requiere aprobación y debe ser compatible con la web):
1. Serializar las reservas por barbero y día con `SELECT pg_advisory_xact_lock(empleado_id, día)` antes de consultar los ocupados, en la creación del cliente y en la de secretaría.
2. Como respaldo en la base, una restricción de exclusión con `btree_gist` sobre (`empleado_id`, rango de la cita) para las citas activas.
3. Una prueba de Django con hilos que haga dos reservas simultáneas y espere exactamente una aceptada.

## Qué cambia en el tablero
- **S3-05:** puede pasar a TERMINADO. El backend rechaza al cliente en los cinco endpoints, y la app ya tenía su prueba.
- **GH#70:** el lado del servidor está probado; falta la guarda central de rutas en la app.
- **PM02 y GH#23:** ejecutado. `mis-citas` está aislado, pero `politica-pago` filtra datos (ERR-02). Sigue bloqueado hasta el arreglo del backend.
- **PM04, GH#24 y S5-05:** ejecutado y falla (ERR-14). Sigue bloqueado hasta el arreglo del backend.
- **PC-03:** permisos y concurrencia ya probados contra la API, con dos defectos registrados.
