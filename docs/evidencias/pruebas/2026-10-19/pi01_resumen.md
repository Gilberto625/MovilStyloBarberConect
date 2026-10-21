# PI-01 en emulador contra backend local
- Emulador: Medium_Phone_API_37.0 (Android 17, x86_64)
- Backend: Django local en 127.0.0.1:8000 (el emulador lo ve como 10.0.2.2) con PostgreSQL local y datos de manage.py sembrar_datos_prueba (backend feature/movil-seed-pruebas)
- Corrida 1: falló en la prueba misma (el resumen estaba fuera de pantalla); no llegó a confirmar, no creó cita.
- Corrida 2: pasó (1/1, 19 s).

Cita en la base local después de la corrida 2 (psql):
cita_id|fecha_hora (convención del backend: hora local guardada como UTC)|servicio|estado
1|2026-10-20 10:00|Corte clásico|confirmada
