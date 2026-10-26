---
name: Stylo Barber Connect
description: La app de Tony Stylo Barbería, de noche, con latón y cuero verde.
colors:
  laton: "#D4AF37"
  laton-hondo: "#B8941F"
  laton-claro: "#E2C76B"
  tinta-sobre-laton: "#0A120E"
  verde-noche: "#0A100E"
  negro-sillon: "#0D0D0D"
  cuero-verde-hondo: "#0E1612"
  cuero-verde: "#14211B"
  cuero-verde-claro: "#1B2A23"
  carbon: "#141414"
  marfil: "#F4F0E8"
  texto-claro: "#EBF0E7"
  salvia: "#718F83"
  niebla: "#A6BAB0"
  filo: "#3D4F49"
  estado-ok: "#34D66B"
  estado-aviso: "#E2B35A"
  estado-critico: "#F45B5B"
typography:
  display:
    fontFamily: "Fraunces, serif"
    fontSize: "36sp"
    fontWeight: 600
    lineHeight: 1.1
    letterSpacing: "-0.5px"
  headline:
    fontFamily: "Fraunces, serif"
    fontSize: "26sp"
    fontWeight: 500
    lineHeight: 1.2
  title:
    fontFamily: "Fraunces, serif"
    fontSize: "20sp"
    fontWeight: 500
    lineHeight: 1.25
  item:
    fontFamily: "Manrope, sans-serif"
    fontSize: "16sp"
    fontWeight: 700
    lineHeight: 1.3
  body:
    fontFamily: "Manrope, sans-serif"
    fontSize: "15sp"
    fontWeight: 500
    lineHeight: 1.45
  label:
    fontFamily: "Manrope, sans-serif"
    fontSize: "13sp"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0.2px"
  cifra:
    fontFamily: "Manrope, sans-serif"
    fontSize: "16sp"
    fontWeight: 700
    fontFeature: "tnum"
rounded:
  chip: "10dp"
  control: "14dp"
  card: "18dp"
  hoja: "24dp"
  pildora: "999dp"
spacing:
  xs: "4dp"
  sm: "8dp"
  md: "12dp"
  lg: "16dp"
  xl: "20dp"
  2xl: "24dp"
  3xl: "32dp"
  4xl: "40dp"
components:
  boton-principal:
    backgroundColor: "{colors.laton}"
    textColor: "{colors.tinta-sobre-laton}"
    typography: "{typography.item}"
    rounded: "{rounded.control}"
    height: "52dp"
    padding: "0 20dp"
  boton-principal-presionado:
    backgroundColor: "{colors.laton-hondo}"
    textColor: "{colors.tinta-sobre-laton}"
  boton-tonal:
    backgroundColor: "{colors.cuero-verde-claro}"
    textColor: "{colors.marfil}"
    rounded: "{rounded.control}"
    height: "52dp"
  boton-contorno:
    backgroundColor: "transparent"
    textColor: "{colors.laton}"
    rounded: "{rounded.control}"
    height: "52dp"
  campo:
    backgroundColor: "{colors.cuero-verde}"
    textColor: "{colors.texto-claro}"
    rounded: "{rounded.control}"
    padding: "16dp"
  tarjeta:
    backgroundColor: "{colors.cuero-verde}"
    rounded: "{rounded.card}"
    padding: "16dp"
  chip-estado:
    backgroundColor: "{colors.cuero-verde-claro}"
    textColor: "{colors.texto-claro}"
    typography: "{typography.label}"
    rounded: "{rounded.pildora}"
    padding: "4dp 10dp"
  barra-navegacion:
    backgroundColor: "{colors.cuero-verde-hondo}"
    textColor: "{colors.niebla}"
    height: "72dp"
---

# Design System: Stylo Barber Connect

## Overview

**Creative North Star: "Barbería de noche"**

La app se siente como Tony Stylo al final del día. Cuero verde profundo, herrajes de latón y toallas marfil, con la luz baja de un local donde el trabajo está bien hecho. No hay neón ni brillo de vitrina. El lujo está en el acabado: una cifra bien alineada, un botón que responde al dedo, un horario que no miente.

Es oscuro porque así se usa. El cliente reserva de noche desde su cama o en el camino, y la secretaría trabaja bajo la luz cálida del mostrador. El latón es escaso a propósito: marca la acción principal y el dinero (precios, anticipos, cobros) y nada más. Los componentes son **táctiles y seguros**: botones grandes y firmes que bajan un poco al tocarse, superficies que se distinguen por tono, no por sombra.

Cada rol tiene su densidad. El invitado ve fotos reales y aire. El cliente avanza paso a paso sin perderse. La secretaría lee su día de un vistazo, con filas altas y estados de color que se entienden sin leer.

**Key Characteristics:**
- Fondo verde noche (invitado) y negro sillón (paneles con sesión), capas de cuero verde encima.
- Latón solo para la acción principal y el dinero; el texto sobre latón siempre es tinta oscura.
- Fraunces para títulos con carácter; Manrope para todo lo que se opera.
- Fotos reales del backend (servicios, productos, logo). Sin imagen, un placeholder honesto, nunca una ilustración inventada.
- Motion corto, con ease-out, que responde al usuario. Una sola entrada orquestada por pantalla.

## Colors

Una paleta restringida: neutros teñidos de verde y un solo acento metálico que trabaja.

### Primary
- **Latón** (`laton`): acción principal (Reservar, Confirmar, Cobrar), precios, la pestaña activa y el foco de los campos.
- **Latón hondo** (`laton-hondo`): estado presionado del botón principal y bordes sobre latón.
- **Latón claro** (`laton-claro`): reflejos puntuales, como la selección de un horario o un realce de foco. Nunca un fondo grande.
- **Tinta sobre latón** (`tinta-sobre-laton`): todo texto o icono sobre latón.

### Secondary
- **Salvia** (`salvia`): acento frío y secundario para iconos de apoyo, el estado "en sala" y datos de contexto.

### Neutral
- **Verde noche** (`verde-noche`): suelo de las pantallas de invitado.
- **Negro sillón** (`negro-sillon`): suelo de los paneles con sesión (cliente y secretaría).
- **Cuero verde hondo** (`cuero-verde-hondo`): primera capa sobre el suelo, la barra de navegación.
- **Cuero verde** (`cuero-verde`): tarjetas, campos y filas.
- **Cuero verde claro** (`cuero-verde-claro`): capa elevada, como lo seleccionado, el botón tonal, las hojas y los chips.
- **Carbón** (`carbon`): superficie heredada de los paneles; se sustituye por cuero verde al rediseñar cada panel.
- **Marfil** (`marfil`): títulos y cifras importantes.
- **Texto claro** (`texto-claro`): cuerpo de texto.
- **Niebla** (`niebla`): texto secundario y etiquetas.
- **Filo** (`filo`): borde fino de tarjetas, campos y divisores.

### Estados
- **Ok** (`estado-ok`): confirmada, completada, hecho.
- **Aviso** (`estado-aviso`): pendiente, por subir, requiere anticipo.
- **Crítico** (`estado-critico`): no asistió, error, acción que penaliza.

### Named Rules
**The Latón Escaso Rule.** El latón ocupa menos del 10 % de cualquier pantalla. Si dos cosas compiten por latón, solo una es la acción principal.

**The Tinta Oscura Rule.** Sobre latón el texto es `tinta-sobre-laton`. Nunca blanco.

**The Estado Con Palabra Rule.** El color de estado siempre va con su palabra ("Confirmada", "No asistió"). El color solo no comunica.

## Typography

**Display Font:** Fraunces (serif)
**Body Font:** Manrope (sans-serif)

**Character:** Fraunces pone la voz de la barbería, cálida y con oficio, en títulos y nombres de pantalla. Manrope es la herramienta: clara a 13 sp, con números tabulares para horas y precios.

### Hierarchy
- **Display** (Fraunces 600, 36 sp, 1.1): solo el titular del inicio de invitado.
- **Headline** (Fraunces 500, 26 sp, 1.2): el título de cada pantalla.
- **Title** (Fraunces 500, 20 sp, 1.25): títulos de sección dentro de una pantalla.
- **Item** (Manrope 700, 16 sp, 1.3): nombres de servicio, cliente o producto en filas y tarjetas.
- **Body** (Manrope 500, 15 sp, 1.45): descripciones y mensajes, a menos de 70 caracteres por línea.
- **Label** (Manrope 600, 13 sp, 0.2 px): etiquetas de campo, chips y datos secundarios, en mayúscula inicial.
- **Cifra** (Manrope 700, 16 sp, tabular): horas, precios y montos, alineados en columna.

### Named Rules
**The Sin Versalitas Rule.** No hay etiquetas en mayúsculas espaciadas ni cejas sobre los títulos. El título se sostiene solo.

**The Dato Estructurado Rule.** Los metadatos (hora, duración, barbero) van en filas o pares etiqueta–valor, no en una cadena unida con puntos medios.

## Layout

Margen lateral de 20 dp en teléfono y columna de máximo 640 dp centrada en tablet. El ritmo usa la escala de 4 dp: grupos internos a 8–12 dp, separación entre bloques a 24–32 dp y más aire arriba de un título que abajo. Los objetivos táctiles miden 48 dp o más; las filas de cita, 72 dp o más. Cada rol tiene una sola barra superior y una sola navegación: la barra inferior en teléfono y el riel lateral desde 720 dp de ancho. Las pantallas respetan los insets del sistema y del teclado, y el gesto Atrás siempre funciona.

## Elevation & Depth

Capas tonales, sin sombras. La profundidad sale de subir un tono: suelo, cuero verde hondo, cuero verde, cuero verde claro. Cada capa lleva un borde filo de 1 dp. Las hojas inferiores y los diálogos usan cuero verde claro con esquina de hoja; el fondo detrás se oscurece con un velo, no con sombra.

### Named Rules
**The Sin Sombra Rule.** Ninguna superficie lleva sombra ni brillo de color. Si algo necesita destacar, sube de tono o usa latón.

## Shapes

Esquinas suaves y consistentes por jerarquía: chips de 10 dp, controles de 14 dp, tarjetas de 18 dp, hojas de 24 dp y píldora para chips de estado y la selección de la barra. Las fotos de servicio van en proporción 4:3 y las de producto en 3:4 con `contain`, sobre cuero verde, para no recortar el envase.

## Components

### Buttons
- **Shape:** control de 14 dp, alto de 52 dp.
- **Principal:** latón con tinta oscura, Manrope 700. Una sola por pantalla.
- **Presión:** baja a escala 0.97 en 120 ms con ease-out `Cubic(0.23, 1, 0.32, 1)` y pasa a latón hondo. Al soltar regresa igual de rápido.
- **Tonal:** cuero verde claro con texto marfil, para acciones secundarias como "Ver citas" o "Reprogramar".
- **Contorno:** borde de latón de 1.2 dp, para la alternativa directa ("Cerrar sesión", "No asistió").
- **Ocupado:** el botón conserva su tamaño y muestra un indicador circular en tinta; no se puede volver a tocar.

### Chips
- **Estado:** píldora de cuero verde claro con punto y palabra en el color del estado.
- **Selección (horarios, filtros):** cuero verde con borde filo; seleccionado, fondo latón claro al 18 % y borde latón.

### Cards / Containers
- **Corner Style:** tarjeta de 18 dp.
- **Background:** cuero verde (invitado y paneles).
- **Border:** filo de 1 dp.
- **Internal Padding:** 16 dp.
- No se anidan tarjetas. Las listas largas son filas separadas por filo, no una tarjeta por elemento.

### Inputs / Fields
- **Style:** relleno de cuero verde, borde filo y control de 14 dp; la etiqueta flota en niebla.
- **Focus:** el borde pasa a latón de 1.4 dp.
- **Error:** borde y mensaje en crítico; el mensaje dice el problema y cómo arreglarlo.

### Navigation
- **Barra inferior:** cuero verde hondo con 72 dp de alto. Indicador en píldora de latón al 16 % detrás del icono activo; etiqueta activa en marfil y las demás en niebla.
- **Riel:** el mismo lenguaje en tablet.

### Próxima cita (Signature Component)
- Tarjeta-boleto en cuero verde claro. Arriba, la hora en cifra marfil grande y el estado; abajo, servicio y barbero como pares etiqueta–valor, con la acción "Ver cita" a la derecha.
- Es lo primero que ve el cliente con sesión. La única entrada orquestada de su inicio es esta tarjeta: sube 8 dp y aparece en 220 ms.

## Do's and Don'ts

### Do:
- **Do** usar latón solo para la acción principal, precios y cobros (The Latón Escaso Rule).
- **Do** mostrar las fotos reales del backend. Si falta una, poner un placeholder honesto con el icono del rubro.
- **Do** dar a cada estado su palabra y su color (The Estado Con Palabra Rule).
- **Do** usar ease-out `Cubic(0.23, 1, 0.32, 1)` por debajo de 300 ms y respetar "reducir movimiento" con un corte inmediato.
- **Do** escribir errores que digan qué pasó y qué hacer ("No se pudo cargar la agenda. Revisa tu conexión y reintenta").

### Don't:
- **Don't** poner etiquetas en mayúsculas espaciadas ni cejas sobre los títulos (The Sin Versalitas Rule).
- **Don't** unir metadatos con puntos medios (The Dato Estructurado Rule).
- **Don't** usar sombras, brillos ni degradados como decoración (The Sin Sombra Rule).
- **Don't** usar texto blanco sobre latón (The Tinta Oscura Rule).
- **Don't** animar desde `scale(0)` ni repetir la misma entrada en cada sección.
- **Don't** animar lo que la secretaría hace decenas de veces al día (marcar llegada, filtrar). Ahí solo hay respuesta táctil.
