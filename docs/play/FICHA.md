# Ficha de Play Store (es-419 / México)

Play Console › Crecimiento › Presencia en Play Store › **Ficha de Play Store principal**. Idioma predeterminado: **Español (Latinoamérica) – es-419**.

## Detalles de la app

**Nombre de la app** (máx. 30) — 20 caracteres:
```
Stylo Barber Connect
```
Coincide con el nombre que muestra el launcher (`android:label`).

**Descripción breve** (máx. 80) — 77 caracteres:
```
Reserva tu corte en Tony Stylo Barbería, revisa tus citas y aparta productos.
```

**Descripción completa** (máx. 4000) — 1 240 caracteres:
```
Stylo Barber Connect es la app oficial de Tony Stylo Barbería. Reserva tu lugar en la silla sin llamar ni esperar respuesta.

RESERVA EN POCOS PASOS
• Elige el servicio, el barbero y un horario que de verdad está libre: la disponibilidad sale directo de la agenda de la barbería.
• Revisa el resumen antes de confirmar: servicio, barbero, fecha, hora y precio.
• Consulta tus próximas citas y tu historial cuando quieras.

TIENDA DE LA BARBERÍA
• Mira los productos con su precio y disponibilidad.
• Apártalos desde la app y recógelos en la barbería.
• Sigue el estado de tus pedidos.

CONOCE LA BARBERÍA
• Servicios, precios y duración de cada uno.
• Horario del día: si está abierta y a qué hora cierra.
• Llama, escribe por WhatsApp o abre la ubicación en el mapa con un toque.

TUS DATOS, BAJO TU CONTROL
• Consulta y corrige tus datos personales desde la app.
• Decide si aceptas usos opcionales de tus datos; vienen apagados.
• Elimina tu cuenta cuando quieras desde Perfil › Privacidad.
• Tu sesión se guarda cifrada en el teléfono y tu contraseña nunca se guarda en él.

PARA EL EQUIPO DE LA BARBERÍA
El personal de recepción tiene su propio panel para la operación del día: citas de hoy, llegada del cliente y cobro.

Sin anuncios.
```

**Categoría:** Aplicación › **Belleza**. Etiquetas sugeridas: barbería, citas, peluquería.

## Datos de contacto
- **Correo** (obligatorio, público): uno de atención de la barbería. Lo captura el equipo. Conviene que sea un correo del negocio y no uno personal, porque Play lo muestra a todos.
- **Teléfono** (opcional): el de la barbería.
- **Sitio web:** `https://tonystylo.vercel.app`

## Política de privacidad
```
https://tonystylo.vercel.app/nosotros?tipo=privacidad
```
Es pública: se abre sin iniciar sesión.

## Gráficos
| Recurso | Requisito | Archivo |
|---|---|---|
| Ícono | PNG 512×512, 32 bits, ≤ 1 MB | `graficos/icono-512.png` (PR #102) |
| Gráfico destacado | PNG/JPG 1024×500 | `graficos/grafico-destacado-1024x500.png` (PR #102) |
| Capturas de teléfono | 2 a 8; PNG/JPG; 320–3840 px; **el lado mayor no puede pasar del doble del menor** | `capturas/` (1080×2160) |

Las capturas del emulador miden 1080×2400 (2.22:1), así que Play las rechaza. Las de `capturas/` se ajustaron a 1080×2160 (2:1) sobre el fondo de la marca, sin recortar contenido.

| Orden | Archivo | Qué muestra |
|---|---|---|
| 1 | `capturas/01_inicio.png` | Inicio con estado de hoy, promoción y servicios |
| 2 | `capturas/02_servicios.png` | Servicios con foto, precio y duración |
| 3 | `capturas/03_detalle_servicio.png` | Detalle de un servicio y "Reservar este servicio" |
| 4 | `capturas/04_productos.png` | Tienda |
| 5 | `capturas/05_acceso.png` | Inicio de sesión y registro |

**Contacto no se incluyó a propósito:** muestra el correo que publica el backend de producción, que parece una cuenta personal. Si se usa un correo de la barbería, se puede capturar y agregar como sexta imagen.

Son pantallas públicas del **APK release ofuscado** contra el backend de producción: datos reales del catálogo y solo lectura. Las pantallas con sesión (agendar, mis citas) se pueden agregar desde la cuenta de revisores cuando exista, para no mostrar datos de prueba con la etiqueta "(prueba)".
