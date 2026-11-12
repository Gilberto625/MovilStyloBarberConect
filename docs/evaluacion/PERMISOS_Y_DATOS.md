# Permisos y datos: Stylo Barber Connect Móvil (GH#57, GH#59)

Criterios 7.4 (permisos justificados) y 7.5 (diálogos de permisos) de `MATRIZ_CUMPLIMIENTO.md`. Es la fuente del formulario **Seguridad de los datos** de Play Console (`docs/play/SEGURIDAD_DE_LOS_DATOS.md`). Fuentes: `android/app/src/main/AndroidManifest.xml`, `android/app/src/debug/AndroidManifest.xml`, `pubspec.yaml` y `lib/services/`. Revisión: **2026-11-11**, versión 0.8.1+5.

## Permisos

| Permiso | Tipo | Para qué | Diálogo en tiempo de ejecución |
|---|---|---|---|
| `android.permission.INTERNET` | Normal (se concede al instalar) | Hablar con la API de la barbería (Django) y cargar las fotos del catálogo | No aplica |

No hay permisos peligrosos: ni ubicación, cámara, contactos, almacenamiento ni teléfono. Por eso **no hay diálogos de permisos** (7.5 no aplica). Si una función futura los necesita, se pedirán en el momento de usarla y con una explicación previa.

Comprobado:
- Manifiesto del APK release con `aapt2` (`docs/evidencias/estatico-2026-10-21/ANALISIS_ESTATICO.md`).
- En Android, la pantalla de la app 0.8.1 dice "No permissions allowed / No permissions denied" (`docs/manual/img/perm_01_info_app.jpg`, SEG-08 en `CATALOGO_PRUEBAS.md`).

Notas:
- **`<queries>` no es un permiso.** Es la visibilidad de paquetes de Android 11+. El manifiesto declara `PROCESS_TEXT` (lo usa el motor de Flutter), `VIEW https` y `DIAL tel`, para que Contacto abra el mapa, WhatsApp o el marcador.
- **Llamar no usa `CALL_PHONE`.** La app abre el marcador con el número escrito y la persona decide si llama.
- **Componentes exportados:** solo `MainActivity`, con el `intent-filter` `MAIN`/`LAUNCHER` que Android exige. La app no declara deep links.
- **HTTP sin cifrar solo en debug.** `android/app/src/debug/AndroidManifest.xml` agrega `usesCleartextTraffic="true"` y `network_security_config` para el backend local (`10.0.2.2`). El manifiesto principal, que es el del release, no lo permite, y la regla de Semgrep `android-cleartext-release-config` bloquea la CI si alguien lo agrega. En producción todo va por HTTPS.
- **Sin respaldo automático.** `android:allowBackup="false"`, para que los datos de sesión no salgan en copias de seguridad.
- **Pendiente: "Nearby devices".** En el emulador con Android 17, la pantalla de permisos de la app 0.8.1 debug lista "Nearby devices — Accessed in past 24 hours", aunque el manifiesto solo declara `INTERNET` (SEG-09, `docs/manual/img/perm_02_permisos.jpg`). Falta confirmar el origen (posiblemente el acceso a la red local `10.0.2.2` del build debug) y revisarlo con la versión instalada desde Play.

## Datos que maneja la app

| Dato | Se recopila | Para qué | Dónde se guarda |
|---|---|---|---|
| Nombre, apellidos, usuario, correo y teléfono | Sí, al registrarse o al corregir el perfil | Cuenta del cliente y contacto por sus citas | Backend de la barbería |
| Pregunta y respuesta secretas | Sí, al registrarse (`preguntasecreta` en `POST /register/`) | Recuperación de la cuenta | Backend |
| Fecha de nacimiento y dirección | Opcionales, en "Corregir mis datos" | Perfil del cliente | Backend |
| Citas (servicio, barbero, fecha, hora, pagos) | Sí | Reservar y atender | Backend |
| Pedidos de la tienda | Sí | Apartar y entregar productos en la barbería | Backend |
| Tokens de sesión (JWT) | Sí, en el dispositivo | Mantener la sesión | `flutter_secure_storage` cifrado (`docs/evidencias/seguridad/almacenamiento-cifrado-2026-10-20.md`) |
| Preferencias de privacidad (opt-in) | Sí | Finalidades secundarias, apagadas por defecto | Backend (`/api/privacidad/preferencias/`), con fecha y versión del aviso |
| Ubicación, contactos, fotos, archivos | **No** | — | — |

- **Contraseña:** viaja solo al iniciar sesión, registrarse o confirmar la eliminación de la cuenta, siempre por HTTPS en release. **No se guarda en el teléfono.**
- **Código por correo (2FA):** opcional y apagado por defecto desde la 0.8.1 (app PR #120, backend PR #10). Si la persona lo enciende, Django manda el código a su correo.
- **Terceros:** la app no tiene analítica ni publicidad. Las fotos del catálogo vienen de Cloudinary (URLs que publica el backend) y las peticiones no llevan datos personales. Las tipografías (Fraunces y Manrope, licencia OFL) van empaquetadas en la app: no se descargan. WhatsApp, Maps y el marcador solo se abren cuando la persona lo pide.
- **Cifrado en tránsito:** sí. HTTPS en release, con certificate pinning (`PINNING_ROTACION.md`).

## Eliminación de datos (ARCO cancelación, GH#44)

**Ya existe y está en producción.** Lo que decía la versión anterior de este documento ("aún no tiene endpoint") quedó viejo.

| Vía | Cómo | Endpoint | Fuente |
|---|---|---|---|
| Desde la app | Perfil › Privacidad y mis datos › **Eliminar mi cuenta**. Pide la contraseña y escribir ELIMINAR | `POST /api/privacidad/cancelacion/` con sesión y `{contrasena, motivo?}`. Responde con folio, estado y fecha de supresión | `lib/services/privacidad_api_service.dart` (`cancelarCuenta`); `lib/views/privacy/eliminar_cuenta_view.dart`; app PR #101; backend PR #5 |
| Desde la web, sin instalar la app | `https://tonystylo.vercel.app/eliminar-cuenta`: correo o usuario más contraseña | El mismo endpoint, sin sesión, con `{cuenta, contrasena}` | Front PR #3 |

Qué pasa:
1. La cuenta se **bloquea de inmediato**: ya no se puede iniciar sesión ni renovar tokens.
2. A los **30 días** el comando `python manage.py suprimir_cuentas_vencidas` suprime los datos personales. Las citas, cobros y ventas se conservan sin datos que identifiquen a la persona.

Evidencia: 10 pruebas Django, 12 de Flutter y el E2E en emulador (`docs/evidencias/arco/2026-10-21-cancelacion/`).

**Pendiente: la supresión automática a los 30 días no está garantizada.**
- El backend corre `suprimir_cuentas_vencidas` al arrancar (`start.sh`, backend PR #8).
- Pero el workflow `mantener-activo.yml` del backend hace ping cada 5 minutos, así que el servicio casi no reinicia.
- Hace falta un **Cron Job diario en Render** con ese comando. No hay evidencia en el repo de que exista: el backend no versiona la configuración de Render y no hay captura del panel.
- Hasta que se configure y se evidencie, no se debe afirmar en Play que la supresión ocurre exactamente a los 30 días.

## Oposición y perfilado (GH#45)

La persona puede apagar `acepta_analitica_perfilado` en "Aviso de privacidad y preferencias". Desde el backend PR #7, la predicción de inasistencia y la segmentación dejan fuera a quien se opuso (prueba Django `test_oposicion_perfilado`, 4 casos, en verde el 2026-11-06).
