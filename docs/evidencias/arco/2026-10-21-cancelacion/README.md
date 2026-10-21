# ARCO Cancelación: "Eliminar mi cuenta" de punta a punta (2026-10-21)

## Cómo se obtuvo
- **Dispositivo:** emulador `Medium_Phone_API_37.0`, Android 17, 1080×2400, arrancado en frío. El reloj del emulador está en GMT; Django usa la hora de México.
- **Backend:** Django local en `127.0.0.1:8000` (en el emulador, `10.0.2.2`) con PostgreSQL local, rama `feature/movil-arco-cancelacion` (PR #5 del backend) con su migración aplicada. Nada se escribió en producción ni en Neon.
- **App:** build debug con `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api` de la rama `feature/arco-cancelacion`.
- **Cuenta:** cliente de prueba de la base local. Las credenciales se escribieron desde un archivo local que no se versiona, y ninguna captura las muestra (la contraseña sale oculta y el usuario se borró antes de la última captura).
- **Restauración:** al terminar, la cuenta se reactivó en la base local (`is_active`, `negocio.usuario.activo`) y se borró la solicitud de prueba. El login volvió a dar 200.

## Casos

| Caso | Esperado | Observado | Evidencia |
|---|---|---|---|
| Entrada | Perfil → Privacidad y mis datos → Eliminar mi cuenta | Opción en rojo con "Se bloquea al momento y tus datos se borran en 30 días" | `capturas/01_perfil.png`, `capturas/02_privacidad.png` |
| Explicación previa | Qué se bloquea, qué se borra y qué se conserva, antes de pedir nada | Tres pasos y el aviso "No se puede deshacer desde la app" | `capturas/03_eliminar_formulario.png` |
| Reautenticación | El botón solo se activa con contraseña y la palabra ELIMINAR | Botón apagado con el formulario vacío; rojo al llenarlo | `capturas/03_…`, `capturas/04_eliminar_lleno.png` |
| Bloqueo en el servidor | `POST /api/privacidad/cancelacion/` → 201 con folio | 201; folio `ARCO-C-20261021-…` y fecha de supresión 2026-11-20 (30 días) | `capturas/05_cuenta_bloqueada_folio.png`, `servidor_2026-10-21.log` |
| Base local | Cuenta inactiva en Django y en `negocio.usuario`; solicitud con canal y motivo | `is_active=False`, `activo=False`, solicitud `bloqueada`, canal `app`, motivo "Prueba E2E en emulador" | Consulta con `manage_local.py shell` (salida en este README) |
| Sesión local | Al cancelar se borran los tokens del teléfono | Cierra sesión; Atrás del sistema lleva al inicio de invitado | `capturas/06_atras_va_a_inicio_invitado.png` |
| Login después | La cuenta ya no entra, sin revelar que existe | 401 "Credenciales incorrectas." | `capturas/08_login_rechazado.png`, `servidor_2026-10-21.log` |
| Pruebas automáticas | Contrato HTTP, ViewModel, pantalla, 360×800 con texto 1.3 | 12/12 en verde | `arco_cancelacion_flutter-test.log` |

Salida de la consulta a la base local, tras la primera corrida:

```
django is_active False
negocio [(1, False)]
solicitud ARCO-C-20261021-1B1F25 bloqueada app 'Prueba E2E en emulador' 2026-11-20
```

## Errores que encontró esta prueba (corregidos en la misma rama)

1. **Error viejo en la pantalla de acceso.** Al cancelar, la app cierra todas las rutas. La pestaña Perfil esperaba el regreso de "Privacidad" para recargar el perfil y lo pidió sin token: `GET /api/perfil/ 401` (corrida 1 del log). Ese 401 quedó guardado en el `AuthViewModel` y la pantalla de acceso mostró "Las credenciales de autenticación no se proveyeron." antes de que el usuario escribiera nada.
   - **Arreglo:** `AuthViewModel.loadPerfil()` no pide nada sin sesión y descarta una respuesta que llegue después de cerrarla. La pestaña Perfil solo recarga si sigue habiendo sesión.
   - **Verificación:** en la corrida 2 ya no hay `GET /api/perfil/` después de cancelar, y el acceso sale limpio (`capturas/07_login_sin_error_viejo.png`). Dos pruebas nuevas fallan sin el arreglo y pasan con él.
2. **Flecha de regreso que no hacía nada.** Con la cuenta ya cancelada, la pantalla bloquea el regreso para no volver a pantallas con sesión, pero seguía mostrando la flecha (`capturas/antes_flecha_sin_accion.png`).
   - **Arreglo:** la flecha se oculta, y Atrás del sistema lleva al inicio de invitado, igual que "Entendido".
   - **Verificación:** `capturas/05_…` sin flecha y `capturas/06_…`, más una prueba de widget nueva.

## Gate de la rama
- `dart format --set-exit-if-changed .`: 0 cambios.
- `flutter analyze`: sin hallazgos.
- `flutter test --coverage`: 262/262 en verde, cobertura de líneas 76.95 % (4800/6238).
