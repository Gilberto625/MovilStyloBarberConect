# Encuadre de las fotos del catálogo (2026-10-21)

**Problema:** en la tarjeta de Servicios del inicio, la foto salía recortada: se veía la pared o la tele y la cabeza cortada (por ejemplo, Corte Fade cortado a la altura de la boca).

**Causa:**
- El backend publica la foto original: 16 servicios en Cloudinary, varias de 3024×4032 (12 MP) y verticales.
- La tarjeta es 16:10 y recortaba en el teléfono con una alineación fija hacia arriba (`Alignment(0, -0.2)`). `analisis_banda_anterior.png` marca en rojo la franja que se mostraba: en la mitad de las fotos dejaba fuera la cara.
- Además, la app bajaba y decodificaba la foto de 12 MP completa para una tarjeta de ~280 px.

**Cambio:**
- La app pide a Cloudinary una variante ya recortada y del tamaño en que se muestra (`lib/core/media/variante_imagen.dart`):
  - `c_fill,g_auto`: recorte centrado en el contenido (persona, corte, producto).
  - Variantes fijas: tarjeta 16:10 de 720 px, miniatura 1:1 de 240 px, detalle 5:4 y portada 4:3 de 1080 px.
  - Banners de promoción y productos: solo se reducen (`c_limit`), sin recorte.
- `analisis_recorte_g_auto.png` muestra los recortes 16:10 de las 15 fotos: la cabeza queda dentro en todas. Cada imagen pesa 23–36 KB, contra varios MB del original.
- Al tocar un servicio, la foto del detalle se empieza a bajar durante la transición.
- URLs fuera de Cloudinary no cambian, pero se decodifican al ancho de la variante.

**Verificación (emulador, Android 17, contra producción y solo lectura del catálogo público):**

| Pantalla | Captura |
|---|---|
| Antes: inicio con el carrusel recortado (APK release del 21-oct) | `antes_inicio_carrusel.png` |
| Después: carrusel | `despues_carrusel.png`, `despues_carrusel_corte_fade.png` |
| Después: lista de servicios | `despues_lista.png` |
| Después: detalle | `despues_detalle.png` |

- Las 122 variantes del catálogo actual se pidieron una vez al CDN y todas respondieron 200. Así ya están generadas: la primera generación de una foto de 12 MP puede tardar decenas de segundos.
- Una foto nueva que suba la barbería se genera la primera vez que alguien la ve.
- **Límite:** si el sujeto ocupa poco del encuadre original, el recorte no puede acercarse sin perder el corte de cabello. `c_thumb` se acercaba tanto que solo quedaba la cara, así que se descartó.
