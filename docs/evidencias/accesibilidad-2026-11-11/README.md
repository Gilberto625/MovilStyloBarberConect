# Accesibilidad verificable: evidencia (2026-11-11)

Tarjetas: GH#19 (QA-006), PM10, S8-03. Rama `feature/accesibilidad-ambientes`.

| Archivo | Qué es |
|---|---|
| `flutter_test_accesibilidad.txt` | Salida de `flutter test --reporter expanded test/accesibilidad` con la corrección aplicada: **176 pruebas, todas en verde** |
| `antes_correccion_texto_x2.txt` | Salida de `flutter test --reporter expanded test/accesibilidad/texto_ampliado_test.dart --plain-name "×2.0"` con `client_agendar_view.dart` de `develop` (sin la corrección): 3 pruebas fallan por `A RenderFlex overflowed by 20 pixels on the bottom` |

Las rutas absolutas de la máquina local se recortaron a rutas relativas al repo. No se cambió nada más de la salida.

## Cómo se prueba

Pruebas de widget en `test/accesibilidad/`, sin red: repositorios falsos (`support/fakes_accesibilidad.dart`) con el patrón de `client_secretary_premium_test.dart`, y el tema, idioma y rutas de la app real (`support/arnes_accesibilidad.dart`). Cada escenario llega a su pantalla tocando como lo haría el usuario y declara sus controles clave (por `Key`).

Pantallas (17 escenarios): inicio de sesión, registro, inicio de invitado, inicio de cliente, Agendar pasos 1 a 4, Mis citas, detalle de cita, diálogo de cancelar cita, Perfil, Hoy de secretaría, detalle de cita de secretaría, hoja de cobro, confirmación de "no asistió" y agenda del barbero.

| Archivo | Pruebas | Qué revisa |
|---|---|---|
| `guias_android_test.dart` | 85 | `labeledTapTargetGuideline`, `androidTapTargetGuideline` y `textContrastGuideline` en 5 superficies: vista inicial en 412×915, 360×640 y 412×915 con texto ×2.0; y "completa" (pantalla entera sin scroll, comprobado con `maxScrollExtent == 0`) a 360 de ancho y a 412 de ancho con texto ×2.0 |
| `texto_ampliado_test.dart` | 37 | `TextScaler.linear(1.3)` y `TextScaler.linear(2.0)`: reserva completa de punta a punta, cada pantalla sin excepción de layout y cada control clave alcanzable; además, que la escala llega a la pantalla |
| `pantalla_pequena_test.dart` | 54 | 360×640 dp con texto ×1.0, ×1.3 y ×2.0: reserva completa, sin overflow y cada control clave alcanzable y tocable (con scroll si hace falta) |

"Sin overflow" significa `tester.takeException()` nulo después de montar y después de cada scroll; un `RenderFlex overflowed` se reporta como excepción y hace fallar la prueba. "Alcanzable" significa que, después de `scrollUntilVisible`/`ensureVisible`, el control pasa `hitTestable()` (no queda tapado ni fuera de la pantalla).

## Incidencias

| # | Pantalla | Problema | Cambio | Prueba que lo cubre | Estado |
|---|---|---|---|---|---|
| 1 | Agendar, paso 3 (día y hora) | La fila de días tenía alto fijo de 76 dp y chips de 60 dp de ancho. Con texto ×2.0 el contenido de cada día se desbordaba 20 px (`client_agendar_view.dart:683`) y la reserva no se podía revisar ni confirmar sin el error de layout | La fila pasa a `SingleChildScrollView` horizontal con `IntrinsicHeight` + `Row`. El chip usa `minWidth: 60, minHeight: 76` y padding, así que crece con el texto y a tamaño normal se ve igual. Son 15 chips: ya no hace falta construirlos de forma perezosa, y "Otra fecha" se puede alcanzar con scroll | `PM10 reserva completa con texto ×2.0`, `QA-006 agendar_3 con texto ×2.0 sin overflow`, `QA-006 agendar_4 con texto ×2.0 sin overflow`, `S8-03 … en 360x640 texto ×2.0`, `QA-006 guías Android · agendar_3 · completa 412 de ancho, texto ×2.0` | Corregida |

Encontradas: 1. Corregidas: 1. Abiertas: 0.

Nota de método (no es un defecto de la app): al pasar las guías después de hacer scroll, `androidTapTargetGuideline` marcó en registro (360×640) un campo que quedaba recortado a 4 dp en el borde inferior de la lista. El campo real mide más de 48 dp; la guía mide lo que queda visible. No se relajó la guía: las pantallas largas se revisan con una superficie lo bastante alta para que todo quepa sin scroll, y la prueba comprueba que no quedó contenido fuera.

## Checklist de accesibilidad

| Criterio | Prueba | Resultado |
|---|---|---|
| Controles clave con etiqueta para TalkBack | `labeledTapTargetGuideline` en los 17 escenarios × 5 superficies (`guias_android_test.dart`) | Cumple (85/85) |
| Objetivos táctiles de al menos 48×48 dp | `androidTapTargetGuideline`, mismas 85 pruebas | Cumple (85/85) |
| Contraste de texto adecuado | `textContrastGuideline`, mismas 85 pruebas; incluye la etiqueta de ambiente (`DEV`) en inicio de sesión y Perfil | Cumple (85/85) |
| Texto ×1.3: la reserva se completa | `PM10 reserva completa con texto ×1.3` | Cumple |
| Texto ×2.0: la reserva se completa | `PM10 reserva completa con texto ×2.0` | Cumple tras la incidencia 1 |
| Texto ×1.3 y ×2.0 sin overflow, controles alcanzables | `QA-006 <escenario> con texto ×1.3/×2.0 sin overflow` (34) | Cumple tras la incidencia 1 |
| 360×640 sin overflow y controles alcanzables | `S8-03 <escenario> en 360x640…` con texto ×1.0, ×1.3 y ×2.0 (51) | Cumple |
| 360×640: la reserva se completa | `S8-03 reserva completa en 360x640` (×1.0, ×1.3, ×2.0) | Cumple |

## Qué no cubre

- No se probó en un dispositivo con TalkBack ni con Accessibility Scanner: esta tarea no usó el emulador. Las guías de `flutter_test` son las mismas reglas que aplica el informe previo al lanzamiento de Play, pero no sustituyen escuchar el orden de lectura real.
- `TextScaler.linear` escala todo por igual. Android 14+ escala los textos grandes de forma no lineal (menos que lineal), así que ×2.0 lineal es un caso igual o más exigente.
- Las guías solo ven lo que se dibuja: los estados de carga y error de cada pantalla no forman parte de estos escenarios.
