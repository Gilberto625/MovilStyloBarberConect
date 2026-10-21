# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users
Dos públicos con el mismo peso, cada uno en su propio modo:

- **Cliente e invitado** (celular personal, en cualquier momento del día). El invitado explora servicios, productos y contacto, y decide reservar. El cliente con cuenta agenda (servicio → barbero → fecha y hora → confirmar), consulta sus citas, compra productos y administra su perfil y su privacidad.
- **Secretaría** (mostrador de la barbería, con prisa y a veces mala señal). Opera el día: ve la agenda de hoy, marca quién llegó y quién no asistió, cobra y crea citas para clientes que llegan sin reserva.

Barberos y administración usan la web Angular; esta app no los atiende.

## Product Purpose
Stylo Barber Connect es la app Android de **Tony Stylo Barbería** (Huejutla, Hidalgo). Permite reservar con horarios reales, comprar productos y ejercer derechos sobre los datos personales. A la secretaría le da una herramienta rápida para el día a día. Hay éxito cuando el cliente reserva sin llamar ni esperar, llega a su cita y vuelve, y la secretaría cierra el día sin dobles citas ni cobros perdidos.

## Positioning
Una barbería premium y cercana a la vez:
- **Experiencia premium:** rituales de barba, cortes cuidados, trato personal.
- **Horarios reales:** la disponibilidad sale del sistema de la barbería, no de un chat; no hay dobles citas.
- **Cercanía y confianza:** WhatsApp, recordatorios, el barbero conoce a su cliente.
- **Tienda:** ceras, pomadas y aceites para mantener el estilo en casa.

## Operating Context
- **Backend:** Django REST (`/api/`) es la fuente de verdad, compartido con la web Angular (`tonystylo.vercel.app`). La app nunca simula datos ni decisiones del servidor: horarios, permisos, penalizaciones y pagos los decide Django.
- **Pagos:** el anticipo y las compras van por checkout externo (Clip). El teléfono nunca confirma un pago.
- **Secretaría:** trabaja en el mostrador con conectividad irregular. El diseño de referencia contempla un modo sin señal y una cola de sincronización. Esa cola necesita idempotencia en el backend (`client_event_id`), que aún no existe.
- **Referencia de diseño:** Actividad 3, interfaces en Figma (26 pantallas por rol), `C:\Users\yager\Documents\Gadiel\Actividad_3_Interfaces_Stylo_Barber_Móvil.pdf`. También `../FrontStyloBarberConect/docs/referencia-inicio-figma-flutter.md` y `referencia-movil-secretaria-cliente-figma.md`.
- **Proceso:** materia de Desarrollo Móvil Integral (UTHH, 10.º B). GitFlow con PRs a `develop` y aprobación obligatoria; cada cambio lleva pruebas y evidencia.

## Capabilities and Constraints
- **Invitado:** inicio, servicios, productos, contacto y login (con 2FA si el backend lo pide).
- **Cliente:**
  - inicio con próxima cita;
  - agendar con política de anticipo;
  - mis citas (próximas e historial);
  - perfil;
  - privacidad: mis datos, corregir datos, aviso y preferencias de uso opcional guardadas en el servidor.
- **Secretaría:** agenda del día con filtros, detalle de cita (llegó, no asistió, cobrar, reprogramar), nueva cita y citas de un cliente.
- **Pendientes del backend** (no simularlos):
  - que el cliente cancele su propia cita;
  - eliminar la cuenta (cancelación ARCO);
  - cola offline con idempotencia;
  - que WhatsApp, promociones y ML respeten las preferencias.
- **"No asistió" penaliza al cliente** (anticipo del 50 % en sus siguientes citas): exige una confirmación fuerte.
- **Técnicas:**
  - Flutter con MVVM + Repository y Provider + ChangeNotifier, sin cambiar de gestor de estado;
  - release ofuscado con R8 y `--obfuscate`: nada de lógica basada en nombres de clase;
  - sin secretos en el cliente.
- **Terminología:**
  - cita, anticipo, restante, cobro, "llegó", "no asistió", "en curso";
  - servicio, barbero, producto, pedido;
  - aviso de privacidad, derechos ARCO.

## Brand Commitments
- **Nombre:** Tony Stylo Barbería. La app se llama "Stylo Barber Connect".
- **Lema en uso:** "Tu Estilo, Nuestra Pasión".
- **Identidad vinculante** (decidida por el equipo):
  - **Dark-first**, con dos temas: invitado (fondo `#0A100E`) y paneles con sesión (`#0D0D0D`).
  - **Dorado `#D4AF37`** para la acción principal y los precios. El texto sobre dorado es `#0A120E`, nunca blanco.
  - **Estados:** ok `#34D66B`, aviso `#E2B35A`, crítico `#F45B5B`.
  - **Tipografía:** Fraunces para títulos y Manrope para la interfaz.
- **Voz:** español de México, directo y cálido. Tutea al cliente y dice qué pasa en cada momento sin tecnicismos.

## Evidence on Hand
- En el backend de producción, servidos por la API desde Cloudinary:
  - el logo de Tony Stylo;
  - fotos reales de 16 servicios (cortes, barba, etc.);
  - fotos de 19 de los 20 productos.
- Datos reales del negocio en `/public/contacto/`: dirección, horarios por día, redes, Google Maps y WhatsApp.
- No hay fotos del local ni del equipo aparte, ni testimonios, reseñas, cifras de clientes o premios. **No se inventan.** Donde falte una imagen se usa un placeholder honesto.

## Product Principles
1. **El servidor manda.** Lo que se ve viene de Django; si falta un dato o un endpoint, se dice y se pide al backend, no se simula.
2. **Cada rol, su modo.** El invitado se convence, el cliente resuelve rápido y la secretaría opera sin fricción. No se mezclan.
3. **Premium es precisión.** Cuidado en detalles, tiempos y estados, no adorno: la experiencia de la barbería se nota en lo que funciona sin pensar.
4. **Confianza visible.** Precios, horarios, anticipos y consecuencias (como la penalización) se dicen claro y antes de actuar.
5. **Aguantar la realidad.** Mala señal, textos largos, listas vacías y errores del servidor tienen un estado digno.

## Accessibility & Inclusion
- Objetivos táctiles de 48 dp o más; filas de cita de 72 dp o más.
- Texto escalado a 1.3 sin desbordes; 360×800 como pantalla mínima.
- TalkBack: etiquetas en controles e iconos.
- Respetar "reducir movimiento" (`MediaQuery.disableAnimationsOf`).
- Contraste suficiente sobre fondos oscuros.
