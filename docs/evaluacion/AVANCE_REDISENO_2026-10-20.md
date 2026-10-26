# Avance con el rediseño — 2026-10-20 (noche)

Continúa `AVANCE_2026-10-20.md` (PR #95). Mismo método: `puntaje = puntos × (C + 0.5 × P) / criterios`; un criterio es **C** solo con implementación, prueba ejecutada y evidencia guardada.

## Qué cambió desde el corte anterior

| Criterio | Antes | Ahora | Evidencia |
|---|---|---|---|
| 4.2 MVVM desacoplado | P | **C** | Diagrama y reglas verificadas en `ARQUITECTURA_Y_PATRONES.md` |
| 4.3a Singleton | P | **C** | Composition root `AppScope.create()`, misma sección |
| 4.3b Factory | P | **C** | `fromJson`, `ApiException.fromBody`, `AuthApiService.login` con sus pruebas |
| 4.3d Observer | P | **C** | `ChangeNotifier` + `Provider`, flujo de cobro de punta a punta |
| 4.8 UX responsiva | P | **C** | Rediseño "Barbería de noche" (invitado, auth, cliente, secretaría): todas las pestañas probadas a 360×800 con texto 1.0 y 1.3, revisión en emulador contra el backend local y la app en español de México. Capturas en `docs/evidencias/rediseno-2026-10-20/` (rama del rediseño) |
| 6.5 Almacenamiento cifrado | P | **C** | `docs/evidencias/seguridad/almacenamiento-cifrado-2026-10-20.md`: 0 JWT y 0 nombres de clave en claro en el dispositivo |
| 7.4 Permisos justificados | P | **C** | `PERMISOS_Y_DATOS.md` (solo `INTERNET`; borrador de "Seguridad de los datos") |

## Porcentaje

| Actividad | Puntos | Criterios | C / P | Puntaje |
|---|---|---|---|---|
| 4 | 7 | 11 | 11 / 0 | 7 × 11 / 11 = **7.00** |
| 5 | 3 | 7 | 2 / 5 | 3 × (2 + 2.5) / 7 = **1.93** |
| 6 | 8 | 17 | 12 / 2 | 8 × (12 + 1) / 17 = **6.12** |
| 7 | 2 | 6 | 1 / 2 | 2 × (1 + 1) / 6 = **0.67** |
| **Total** | **20** | | | **15.72 / 20 = 78.6 %** |

Esto cuenta todo lo que está en PR o en rama, **fusionado**. Hoy en `develop` ya están #91, #93 y #94; faltan las aprobaciones de #88, #89, #90, #92 y #95 y los PRs del rediseño y de este documento.

## Qué falta para acercarse a 90 %

| Paso | Criterio | Suma | Quién |
|---|---|---|---|
| Aprobar y fusionar los PRs con la cuenta del compañero | 5.2 → C | +0.21 | Equipo |
| Crear la rama `release` y el tag `v0.1.0` | 5.1 → C | +0.21 | Dueño del repo |
| Correr JADX y MobSF sobre el APK ofuscado (pasos ya escritos) | 6.11 → C, 5.6 → C | +0.68 | Equipo |
| Keystore de subida y secretos en GitHub | 7.2 → C, 7.3 → C | +0.33 | Equipo |
| Certificate pinning | 6.4 → C | +0.47 | Desarrollo (requiere decidir qué llave fijar sin romper producción) |
| Patrol para PA-01…PA-07 | 6.12 → C | +0.24 | Desarrollo |

Con todo eso: **17.86 / 20 = 89.3 %**. Publicar en Play (7.1, 7.6) y ARCO cancelación (6.8c, necesita endpoint) quedan fuera de este cierre.

## Rediseño entregado (ramas locales, se abren como PR al fusionar lo anterior)

| Rama | Qué trae | Pruebas |
|---|---|---|
| `feature/ui-invitado` | Tokens y `DESIGN.md`; barra de invitado, detalle de servicio y producto, Contacto con llamar, WhatsApp y mapa, estado "Abierto ahora" | 124 → 209 con la integración |
| `feature/ui-auth-registro` | Login rediseñado y **registro con código por correo** (`/register/`, `/register/2fa/verificar/`) | +15 |
| `feature/ui-cliente` | Agendar en 4 pasos, Mis citas con detalle, **tienda con carrito y pedido real** (`/pedidos/crear/`), perfil | +17 |
| `feature/ui-secretaria` | Hoy legible, "No asistió" con confirmación fuerte, cobro con cambio, español de México | 250 en total |

Verificado en emulador contra el backend local: reserva creada desde el cliente que aparece en la agenda de secretaría, pedido #1 con total calculado por Django, confirmación de inasistencia y hoja de cobro (canceladas, sin escribir).

## Tarjetas de Trello a mover

| Tarjeta | A | Evidencia |
|---|---|---|
| Rediseño de UI (Prompt 1) | EN REVISIÓN al abrir los PRs | Capturas del rediseño, 250 pruebas |
| GH#12 secretaría Hoy/Llegó/Cobrar | EN REVISIÓN | `secretaria_rediseno_test.dart`, capturas |
| Patrones (4.2, 4.3) | EN REVISIÓN | `ARQUITECTURA_Y_PATRONES.md` |
| 6.5 almacenamiento cifrado | EN REVISIÓN | Reporte del dispositivo |
| 7.4 permisos | EN REVISIÓN | `PERMISOS_Y_DATOS.md` |
