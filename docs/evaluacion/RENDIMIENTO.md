# Rendimiento de catálogo y disponibilidad (GH#27 · QA-014)

Objetivo de la historia: el catálogo y los horarios disponibles cargan en **3 s o menos en al menos el 95 %** de las consultas.

## Cómo se midió

- Script repetible: [`tool/rendimiento/medir_rendimiento.py`](../../tool/rendimiento/medir_rendimiento.py).
- 30 consultas controladas y secuenciales por endpoint. Cada una abre una conexión nueva y manda `Cache-Control: no-cache`. Antes de cada serie hay una consulta de calentamiento que no se cuenta.
- Catálogo (`GET /public/servicios/` y `GET /public/productos/`) y disponibilidad (`GET /disponibilidad/?barbero_id=3&fecha=2026-11-12&duracion=45`, con la sesión de un cliente de prueba) se miden por separado.
- Equipo: laptop con Windows 11, Python 3.13.0, red Wi‑Fi. Fecha: 2026-11-11.
- Ambientes:
  - **Local:** Django + PostgreSQL 17 locales (`http://127.0.0.1:8000/api`), con datos de prueba sembrados. Aquí se mide también la disponibilidad, porque necesita iniciar sesión.
  - **Producción (Render):** solo los endpoints públicos de lectura. No hay login, escrituras ni pruebas de carga. La disponibilidad no se mide en producción, porque requeriría la sesión de una cuenta real.

Para repetirlo:
```bash
python tool/rendimiento/medir_rendimiento.py --base http://127.0.0.1:8000/api --credenciales ~/.stylo-local/dart_defines.local.json --salida docs/evidencias/rendimiento-2026-11-11/local
python tool/rendimiento/medir_rendimiento.py --base https://backendstylobarberconect-lo71.onrender.com/api --solo-publico --salida docs/evidencias/rendimiento-2026-11-11/produccion
```
El script no imprime credenciales. Si recibe una URL de `onrender.com` sin `--solo-publico`, se niega a correr.

## Resultados (30 mediciones por consulta)

| Ambiente | Consulta | HTTP 200 | p50 | p95 | Máx. | % ≤ 3 s | Cumple |
|---|---|---|---|---|---|---|---|
| Local | Catálogo de servicios | 30/30 | 69 ms | 209 ms | 255 ms | 100 % | Sí |
| Local | Catálogo de productos | 30/30 | 67 ms | 173 ms | 180 ms | 100 % | Sí |
| Local | Disponibilidad | 30/30 | 63 ms | 81 ms | 159 ms | 100 % | Sí |
| Producción | Catálogo de servicios | 30/30 | 879 ms | 1096 ms | 1216 ms | 100 % | Sí |
| Producción | Catálogo de productos | 30/30 | 568 ms | 1117 ms | 1324 ms | 100 % | Sí |

La tabla completa de cada serie, con hora, código HTTP y bytes de cada consulta, está en `docs/evidencias/rendimiento-2026-11-11/{local,produccion}/mediciones.csv`. El resumen estadístico (mínimo, promedio, p50, p95 y máximo) está en `resumen.json`.

## Lectura y límites

- Todas las series cumplen el objetivo: el 100 % de las consultas tarda 3 s o menos.
- El primer intento contra producción (19:38) terminó con error antes de escribir resultados. Render tiene arranque en frío cuando el servicio está inactivo. La serie válida es la de las 19:39 y se documenta tal cual. Ese primer arranque en frío puede superar los 3 s y no forma parte de la muestra.
- Se mide el tiempo de red y servidor desde una laptop. El tiempo que la app tarda en dibujar las pantallas se revisa aparte, con el modo profile de Flutter (SF-03).
- Son consultas secuenciales: esto no es una prueba de carga ni de estrés.
