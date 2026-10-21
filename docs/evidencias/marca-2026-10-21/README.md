# Ícono y tipografías en el dispositivo (2026-10-21)

Emulador `Medium_Phone_API_37.0` (Android 17, 1080×2400), build debug de `feature/marca-icono-fuentes`.

| Caso | Esperado | Observado | Captura |
|---|---|---|---|
| Arranque (Android 12+) | El sistema usa el ícono adaptativo en la pantalla de arranque | Monograma TS sobre verde noche; ya no sale el logo de Flutter | `01_arranque_android.png` |
| Launcher | Ícono adaptativo recortado por la máscara del sistema | Monograma TS sobre círculo oscuro. El aro dorado lo dibuja el launcher porque el ícono ocupaba el lugar de "app sugerida" | `02_icono_launcher_x2.png` (recorte ampliado de `04_pantalla_inicio_android.png`) |
| Tipografía sin internet | Con modo avión y datos de la app borrados, el texto sale en Manrope/Fraunces y no en Roboto | Manrope en el estado de error; logcat sin errores de `google_fonts` | `03_tipografia_sin_red.png` |

En `03_tipografia_sin_red.png`, el texto del error muestra la excepción técnica (IP y URL del backend). Es otro defecto, que se corrige en su propio PR.
