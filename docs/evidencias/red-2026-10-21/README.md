# Errores de red con mensaje para la persona (2026-10-21)

Emulador `Medium_Phone_API_37.0` (Android 17), build debug de `fix/mensajes-error-red` contra Django local (`10.0.2.2:8000`).

| Caso | Antes | Después | Captura |
|---|---|---|---|
| Sin internet (modo avión, datos de la app borrados) | La pantalla mostraba la excepción cruda: `ClientException with SocketException … address = 10.0.2.2, port = 8000, uri=…` | "No hay conexión con el servidor. Revisa tu internet e intenta de nuevo." | `antes_excepcion_cruda.png`, `01_sin_red_mensaje_claro.png` |
| Vuelve la red y se toca Reintentar | — | Carga el catálogo (log de Django: `GET /api/public/servicios/ 200`) | `02_reintentar_con_red.png` |

En estas dos capturas los títulos salen en Roboto porque esta rama sale de `develop`, que aún no empaqueta las fuentes. Eso lo corrige el PR #102. `antes_excepcion_cruda.png` se tomó con el build de ese PR y por eso ya sale en Manrope.

Pruebas automáticas (`api_client_errores_red_flutter-test.log`), con `MockClient` y sin red real:
- `ClientException`, `SocketException`, `HandshakeException` y `TimeoutException` → `NetworkException`, sin IP, puerto, URL ni nombre de excepción en el texto.
- Una página HTML de error (502) o el texto de un 5xx no llegan a la pantalla. El mensaje JSON de Django y un texto corto de un 4xx sí.
- Si la red falla al renovar el token, la sesión **no** se cierra y el refresh token se conserva. Antes, un corte de red en ese momento sacaba a la persona de su cuenta.
