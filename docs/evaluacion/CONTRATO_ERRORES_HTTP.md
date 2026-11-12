# Contrato de errores HTTP (GH#69, CORE-002)

Cómo convierte la app cada respuesta de la API en una excepción de dominio y qué mensaje ve la persona. Revisión: **2026-11-11**, versión 0.8.1+5 más `develop`.

Fuentes:
- `lib/core/errors/app_exception.dart`: `AppException`, `ApiException` y `NetworkException`.
- `lib/core/network/api_client.dart`: envío, refresh del token y decodificación.
- `lib/services/*_api_service.dart`: respuestas `ok: false` y cuerpos con forma inesperada.
- Pruebas en `test/`. La columna "Prueba" da el archivo y el nombre del caso.

## Excepciones de dominio

| Clase | Cuándo | Campos |
|---|---|---|
| `NetworkException` (extiende `AppException`) | No hubo respuesta del servidor: sin internet, DNS, socket, TLS o pinning rechazado, tiempo agotado, cliente cerrado. `ApiClient._enviar` convierte cualquier `Exception` del transporte | `message` = `NetworkException.sinConexion`; sin `statusCode` |
| `ApiException` (extiende `AppException`) | El servidor respondió con un código fuera de 2xx, o un service recibió `ok: false` o un cuerpo inválido | `message`, `statusCode` (cuando viene del código HTTP) y `body` (el cuerpo decodificado) |

`AppException` expone `isUnauthorized` (401) e `isForbidden` (403). `toString()` devuelve solo `message`, y los ViewModels muestran `e.toString()` en su estado de error. Por eso el mensaje de la excepción es el que ve la persona.

### Cómo se elige el mensaje de un `ApiException` (`ApiException.fromBody`)

1. Si el cuerpo es JSON con `error`, `detail`, `mensaje` o `message` (en ese orden) y no está vacío: ese texto.
2. Si no, y el código es menor a 500 y el cuerpo es texto plano de hasta 200 caracteres que no empieza con `<`: ese texto.
3. Si no:
   - 4xx: "Error del servidor (NNN)."
   - 5xx: "El servidor no está disponible en este momento (NNN). Intenta de nuevo en unos minutos."

Una página HTML de error (proxy, Render o Django con `DEBUG`) y el texto de un 5xx nunca llegan a la pantalla.

## Matriz código HTTP → excepción → mensaje → prueba

| Código o situación | Excepción | Efecto en la sesión | Mensaje para la persona | Prueba que lo cubre |
|---|---|---|---|---|
| **Sin red**: `ClientException`/`SocketException` (sin internet, DNS) | `NetworkException` | Se conserva | "No hay conexión con el servidor. Revisa tu internet e intenta de nuevo." Sin IP, puerto, URL ni nombre de excepción | `test/integration/api_client_errores_red_test.dart`: "sin internet: mensaje para la persona, sin IP ni excepción" |
| **TLS o pinning rechazado** (`HandshakeException`) | `NetworkException` | Se conserva | Igual que sin red | Mismo archivo: "socket, TLS y tiempo agotado también son NetworkException"; el rechazo del certificado en `test/pinning_test.dart` |
| **Tiempo agotado** (`TimeoutException` del cliente HTTP) | `NetworkException` | Se conserva | Igual que sin red | Mismo caso. En el ViewModel: `test/unit/viewmodels_mockito_test.dart` "mis citas: un timeout queda en error, no en carga infinita" |
| **2xx** con JSON | Ninguna: `ApiClient` devuelve el JSON | — | — | `test/integration/repositories_http_test.dart` (casos 200) |
| **2xx con `ok: false`** | `ApiException` lanzada por el service, sin `statusCode` | Se conserva | El `error` del servidor, o un texto por defecto del service (por ejemplo "No se pudieron cargar citas.") | `repositories_http_test.dart`: "un 200 con ok:false también es error"; `test/integration/secretaria_api_service_http_test.dart`: "un ok=false del servidor llega como ApiException" |
| **2xx con un cuerpo de otra forma** | `ApiException` del service, sin `statusCode` | Se conserva | "Respuesta de … inválida." (por ejemplo "Respuesta de citas inválida.") | Sin prueba propia |
| **400** validación | `ApiException(400)` | Se conserva | Mensaje de Django, por ejemplo "Horario no disponible." | `test/integration/api_client_refresh_test.dart`: "errores HTTP traen el mensaje de Django (error, detail o texto)"; `repositories_http_test.dart`: "400 y 409 al crear cita no se toman como creadas" |
| **401 con sesión**, refresh correcto | Ninguna si el reintento responde 2xx | Se renuevan los tokens (y el refresh, si el servidor lo rota) | — | `api_client_refresh_test.dart`: "401 → refresh → reintento con el token nuevo" y "refresh sin rotación guarda solo el access nuevo" |
| **401 con sesión**, refresh rechazado, sin refresh guardado o sin `access` en la respuesta | `ApiException(401)` | **Se cierra**: borra los tokens y llama `onSessionExpired` (`AuthRepository.logoutLocal` y `AuthViewModel.logout`, en `lib/core/di/app_scope.dart`) | Mensaje de Django del 401 original | `api_client_refresh_test.dart`: "refresh rechazado → borra tokens, avisa sesión vencida y lanza 401" y "sin refresh guardado no llama al endpoint de refresh" |
| **401 con sesión** y la red falla durante el refresh | `NetworkException` | **Se conserva**, incluido el refresh token (ERR-12) | Igual que sin red | `api_client_errores_red_test.dart`: "si la red falla al renovar el token, la sesión no se cierra" |
| **401 con sesión**, refresh correcto pero el reintento vuelve a dar 401 | `ApiException(401)` | Se conserva: no hay segundo refresh ni cierre | Mensaje de Django | Sin prueba propia |
| **401 sin sesión** (login, `auth: false`) | `ApiException(401)` | No intenta refresh ni cierra sesión | Mensaje de Django, por ejemplo "Credenciales incorrectas." | `api_client_refresh_test.dart`: "un 401 en login (sin auth) no intenta refresh ni cierra sesión" |
| **403** rol sin permiso | `ApiException(403)`, `isForbidden` | Se conserva: **no** se trata como 401 | Mensaje de Django, por ejemplo "No tienes permiso para realizar esta acción." | `repositories_http_test.dart`: "403 de citas del día (rol sin permiso) llega como prohibido"; `api_client_refresh_test.dart` (e403); en ViewModels, `test/barbero_agenda_test.dart` y `test/unit/viewmodels_mockito_test.dart` "no asistió rechazado por el servidor (403) no recarga ni penaliza" |
| **404** recurso ajeno o inexistente | `ApiException(404)` | Se conserva | Mensaje de Django, por ejemplo "Cita no encontrada." | En ViewModel: `test/unit/privacidad_test.dart` "si falla el perfil, queda en error y no pide el historial". Sin prueba en `ApiClient` |
| **409** conflicto de negocio (horario ocupado, fuera de plazo) | `ApiException(409)` | Se conserva | Mensaje de Django, por ejemplo "Ese horario ya está ocupado." | `test/cliente_cambios_cita_test.dart`: "un 409 llega con el mensaje del servidor"; `repositories_http_test.dart`: "400 y 409 al crear cita no se toman como creadas"; `test/unit/viewmodels_mockito_test.dart`: "reservar con 409 (horario ocupado) no da la cita por creada" |
| **429** u otro 4xx con texto plano corto | `ApiException(429)` | Se conserva | El texto tal cual, por ejemplo "Demasiadas solicitudes." | `api_client_errores_red_test.dart`: "un texto plano corto sí se muestra" |
| **4xx sin cuerpo útil** | `ApiException(NNN)` | Se conserva | "Error del servidor (NNN)." | Sin prueba en `ApiClient` |
| **5xx** con JSON de Django | `ApiException(5xx)` | Se conserva | El mensaje del JSON. La prueba usa un 503 con `detail` "La estructura de base de datos requerida no esta disponible", y ese texto llega a la pantalla | `repositories_http_test.dart`: "500 del catálogo llega como error, no como lista vacía" |
| **5xx** con HTML, texto o vacío | `ApiException(5xx)` | Se conserva | "El servidor no está disponible en este momento (NNN). Intenta de nuevo en unos minutos." | `api_client_errores_red_test.dart`: "una página HTML de error no llega a la pantalla" (502); `api_client_refresh_test.dart` (500 con "Internal Server Error" y 502 vacío); `repositories_http_test.dart`: "500 al cobrar no se toma como cobrado" |

Evidencia de ejecución: las 539 pruebas pasan en el run [43154349514](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/43154349514) del PR #129. Comprobación en emulador sin red: PM07 de `BATERIA_FINAL_PM.md` y `docs/evidencias/red-2026-10-21/`.

## Criterios de GH#69

| Criterio | Estado | Detalle |
|---|---|---|
| 401 dispara el flujo de sesión definido | Cumple | Un refresh; si falla, cierre de sesión. Un corte de red no la cierra |
| 403 se diferencia de 401 | Cumple | 403 no intenta refresh ni cierra sesión; `isForbidden` lo identifica. Ninguna pantalla usa hoy `isForbidden` para un mensaje propio: se muestra el texto de Django |
| 409 representa conflicto de negocio | Parcial | Llega como `ApiException` con `statusCode` 409 y el mensaje del servidor. No hay una clase de dominio propia para el conflicto |
| Timeout y red con mensaje controlado | Parcial | El mensaje está controlado. Falta un **tiempo límite propio**: `ApiClient` no aplica `.timeout()`, así que una petición que el servidor acepta y no contesta espera lo que tarde el sistema en cortar |
| 5xx no exponen detalles internos | Parcial | HTML y texto de un 5xx no se muestran. Pero si Django manda un mensaje en el JSON del 5xx, se muestra tal cual. La prueba del catálogo lo documenta con un 503 que dice "La estructura de base de datos requerida no esta disponible": es un detalle interno. Hay que decidir si la app ignora el mensaje de los 5xx o si el backend cambia esos textos |

## Observaciones pendientes (sin prueba)

- **Dos 401 al mismo tiempo.** Por lectura del código, si dos peticiones reciben 401 a la vez, la segunda encuentra `_refreshing` en `true`, recibe `false` de `_tryRefresh` y llama `onSessionExpired`, aunque el refresh de la primera esté por salir bien. La persona podría salir de su cuenta. No se ha reproducido ni tiene prueba, así que no se registra como defecto en `REGISTRO_ERRORES.md` hasta comprobarlo. La prueba sería: dos `api.get` en paralelo con un `MockClient` que responde 401 y un refresh lento.
- **Casos sin prueba propia:** 404 y "4xx sin cuerpo" a nivel de `ApiClient`, 2xx con un cuerpo de otra forma y el 401 repetido después de un refresh correcto.
