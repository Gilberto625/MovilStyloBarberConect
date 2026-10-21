# Permisos y datos — Stylo Barber Connect Móvil

Criterios 7.4 (permisos justificados) y 7.5 (diálogos de permisos) de `MATRIZ_CUMPLIMIENTO.md`. Sirve también de borrador para la sección **Seguridad de los datos** de Play Console. Fuente: `android/app/src/main/AndroidManifest.xml` y `pubspec.yaml`.

## Permisos

| Permiso | Tipo | Para qué | Diálogo en tiempo de ejecución |
|---|---|---|---|
| `android.permission.INTERNET` | Normal (se concede al instalar) | Hablar con la API de la barbería (Django) y cargar las fotos del catálogo. | No aplica |

No hay permisos peligrosos: ni ubicación, cámara, contactos, almacenamiento ni teléfono. Por eso **no hay diálogos de permisos** (7.5 no aplica hoy). Si una función futura los necesita, se pedirán en el momento de usarla y con una explicación previa.

Notas:
- **`<queries>` no es un permiso.** Es la visibilidad de paquetes de Android 11+. El manifiesto declara `PROCESS_TEXT` (lo usa el motor de Flutter). Con el rediseño se agregan `VIEW https` y `DIAL tel` para que Contacto abra el mapa, WhatsApp o el marcador.
- **Llamar no usa `CALL_PHONE`.** La app abre el marcador con el número escrito y la persona decide si llama.
- **HTTP sin cifrar solo en debug.** `android/app/src/debug/AndroidManifest.xml` permite cleartext para el backend local (`10.0.2.2`). El manifiesto principal, el de release, no lo permite: en producción todo va por HTTPS.
- **Sin respaldo automático.** `android:allowBackup="false"` (rama de seguridad R8), para que los datos de sesión no salgan en copias de seguridad.

## Datos que maneja la app (borrador de "Seguridad de los datos")

| Dato | Se recopila | Para qué | Dónde se guarda |
|---|---|---|---|
| Nombre, apellidos, usuario, correo, teléfono | Sí, al registrarse o corregir el perfil | Cuenta del cliente y contacto por sus citas | Backend de la barbería |
| Citas (servicio, barbero, fecha, hora, pagos) | Sí | Reservar y atender | Backend |
| Pedidos de la tienda | Sí | Apartar y entregar productos en la barbería | Backend |
| Tokens de sesión (JWT) | Sí, en el dispositivo | Mantener la sesión | `flutter_secure_storage` cifrado (ver `docs/evidencias/seguridad/almacenamiento-cifrado-2026-10-20.md`) |
| Preferencias de privacidad (opt-in) | Sí | Finalidades secundarias, apagadas por defecto | Backend (`/api/privacidad/preferencias/`) |
| Ubicación, contactos, fotos, archivos | **No** | — | — |

- **Contraseña:** viaja una sola vez al iniciar sesión o registrarse, por HTTPS. **No se guarda en el teléfono.**
- **Terceros:** la app no tiene analítica ni publicidad. Las fotos del catálogo vienen de Cloudinary (URLs que publica el backend) y las tipografías de Google Fonts; ninguna de las dos peticiones lleva datos personales. WhatsApp, Maps y el marcador solo se abren cuando la persona lo pide.
- **Cifrado en tránsito:** sí, HTTPS en release.
- **Eliminación de datos:** la cancelación ARCO (borrar la cuenta) **aún no tiene endpoint** en el backend (GH#44). Hasta que exista, se solicita a la barbería con los datos de contacto del aviso de privacidad. No se debe declarar "eliminación desde la app" en Play hasta tenerla.
