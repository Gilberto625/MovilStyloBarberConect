# Resultados del DAST con OWASP ZAP (GH#04 · DEVOPS-004, SF-03)

Fecha: 2026-11-11. Herramienta: **OWASP ZAP 2.17.0** en modo comando (`-cmd`), con el JDK de Android Studio. El procedimiento está en [`DAST_PROCEDIMIENTO.md`](DAST_PROCEDIMIENTO.md).

## Entorno autorizado

- Solo se escaneó el **backend local**: Django en `http://127.0.0.1:8000/api`, con PostgreSQL 17 local y datos de prueba sembrados. Es el mismo backend que usa la app 0.8.1+5 en el emulador (`10.0.2.2:8000`).
- **No se atacó producción** (Render) ni la base en la nube.
- Sesión: token JWT del cliente de prueba, pasado por la variable `ZAP_AUTH_HEADER_VALUE`. El token no se guarda en el plan ni en los reportes.

## Ejecuciones

| # | Tipo | Alcance | Archivo |
|---|---|---|---|
| 1 | `-quickurl` (spider + escaneo activo), sin sesión | `/api/public/servicios/` y lo que encontró el spider | `docs/evidencias/dast-zap-2026-11-11/zap_reporte_local.html` |
| 2 | Plan de automatización con sesión de cliente: requestor + spider + pasivo + activo | 12 endpoints públicos, de cliente y de secretaría | `zap_plan_autenticado.yaml`, `zap_reporte_autenticado.html` y `.json` |

## Hallazgos y clasificación

| Riesgo ZAP | Alerta | Dónde | Verificación | Clasificación |
|---|---|---|---|---|
| Alto (confianza baja) | SQL Injection | `GET /api/barberos/?servicio_id='` devolvió 500 | Se reprodujo a mano: `'`, `1'`, `1 OR 1=1` y `1;SELECT pg_sleep(5)` responden **400 "servicio_id inválido."** en ~50 ms; `1` responde 200. La vista convierte el valor a `int` antes del SQL, y la consulta usa parámetros `%s`. El 500 coincidió con `FATAL: ya tenemos demasiados clientes` del PostgreSQL local durante el escaneo (`verificacion_sqli_barberos.txt`) | **Falso positivo** |
| Medio | Content Security Policy (CSP) Header Not Set | Respuestas de `/api/`, `/api/auth`, `/api/public`, `/api/secretaria` | Son respuestas JSON de una API que no se renderizan en un navegador. La app móvil no usa CSP | Bajo impacto en la API. Se recomienda agregar CSP en el backend para las páginas HTML |
| Bajo | Server Leaks Version Information ("Server" header) | Todas | La cabecera `WSGIServer/x CPython/x` es del servidor de desarrollo `runserver`. En Render responde gunicorn detrás del proxy | Solo en local |
| Informativo | User Agent Fuzzer | `/api/auth/me`, `/api/barberos` | Respuestas iguales con distintos User-Agent | Sin riesgo |

### Otras observaciones del escaneo

- **Autorización por rol:** con el token del cliente, `/api/secretaria/citas/dia/` respondió **403** en las 29 peticiones. `/api/mis-citas/`, `/api/perfil/` y `/api/auth/me/` respondieron 200 con los datos del propio cliente.
- **500 por `APPEND_SLASH`:** al hacer `POST` sin la `/` final, Django lanza `RuntimeError`. Eso solo ocurre con `DEBUG=True` (servidor local). Con `DEBUG=False` redirige sin error. No aplica a producción.
- **Conexiones agotadas en PostgreSQL local** (`ya tenemos demasiados clientes`): pasó 8 veces durante el escaneo activo, porque `runserver` abre una conexión por hilo. Es una limitación del entorno local, no de la API. Se registra como observación para una prueba de carga en staging.

## Resultado

**Sin hallazgos críticos ni altos confirmados.** El único "alto" fue un falso positivo verificado a mano. Queda una recomendación media (CSP en el backend) que no bloquea el release móvil.

## Límites

- No se probaron los flujos que escriben datos (reserva, cobro, asistencia). El escaneo activo solo varió parámetros de peticiones `GET`.
- El escaneo duró pocos minutos; no es una auditoría completa.
- Staging no existe como servidor propio; el backend local hace sus veces (ver `docs/AMBIENTES.md`).
