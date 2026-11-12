# Seguridad de los datos, eliminación de cuenta y privacidad

Play Console › Supervisar y mejorar › Política y programas › **Contenido de la app**. Fuente de verdad del inventario: `docs/evaluacion/PERMISOS_Y_DATOS.md`. Si la app cambia, se actualizan los dos.

## Política de privacidad
- URL: `https://tonystylo.vercel.app/nosotros?tipo=privacidad`.
- Es pública, no pide sesión y es la misma que muestra la app en "Aviso de privacidad".
- **Marcadores llenos.** El 2026-10-29 el texto publicado tenía dos marcadores sin llenar (responsable y correo ARCO). Al 2026-11-11 ya no los tiene: identifica al responsable con su domicilio y da un correo de contacto para privacidad y derechos ARCO. Se comprobó en producción, solo lectura, con `GET /api/public/legal/?tipo=privacidad`.
  - El correo que publica la política es una cuenta personal. Conviene que el de la ficha de Play (`FICHA.md`) sea el mismo, o cambiar los dos a un correo del negocio.
  - Se editan desde el contenido legal del backend (panel de administración de la web), no en la app.

## Eliminación de la cuenta
Play pide las dos vías porque la app permite crear cuenta:

| Vía | Cómo | Estado |
|---|---|---|
| **Desde la app** | Perfil › Privacidad y mis datos › **Eliminar mi cuenta**. Se reautentica con la contraseña y la palabra ELIMINAR. | ✅ en producción (app PR #101, backend PR #5); `POST /api/privacidad/cancelacion/` con sesión |
| **Desde la web**, sin instalar la app | `https://tonystylo.vercel.app/eliminar-cuenta`: correo o usuario más contraseña, y responde con un folio | ✅ publicada (front PR #3); usa el mismo `POST /api/privacidad/cancelacion/` sin sesión |

Respuestas del formulario "Eliminación de datos":
- **¿La app permite crear cuentas?** Sí.
- **Vínculo para borrar la cuenta:** `https://tonystylo.vercel.app/eliminar-cuenta`.
- **¿Se puede pedir borrar algunos datos sin borrar la cuenta?** Sí. En "Corregir mis datos" el teléfono, la fecha de nacimiento y la dirección son opcionales y se pueden dejar vacíos (`PUT /perfil/`), y los usos opcionales se apagan en "Aviso de privacidad y preferencias".
- **Qué se borra y cuándo** (texto para la página web y para la revisión):
  > Al pedirlo, la cuenta se bloquea de inmediato. En 30 días se eliminan el nombre, el correo, el teléfono, la fecha de nacimiento, el usuario, la contraseña y las direcciones. Las citas, cobros y ventas se conservan sin datos que te identifiquen, porque la barbería debe guardar sus registros contables.

**Pendiente del backend: Cron Job diario en Render** con `python manage.py suprimir_cuentas_vencidas` (se puede probar antes con `--dry-run`).
- Como respaldo, el backend la corre en cada arranque (`start.sh`, backend PR #8).
- Pero `mantener-activo.yml` del backend hace ping cada 5 minutos, así que el servicio casi no reinicia.
- Al 2026-11-11 no hay evidencia de que el Cron exista: la configuración de Render no está versionada y no hay captura del panel. Hasta tenerla, la supresión a los 30 días no está garantizada.

## Formulario "Seguridad de los datos"

**Recopilación y uso compartido**
- ¿Recopila o comparte alguno de los tipos de datos requeridos? **Sí.**
- ¿Todos los datos se cifran en tránsito? **Sí.** HTTPS con certificate pinning en release (`docs/evaluacion/PINNING_ROTACION.md`).
- ¿Ofreces una forma de solicitar que se borren los datos? **Sí** (ver arriba).
- **Compartir con terceros: No.** Los datos van solo al backend de la propia barbería. Cloudinary sirve las fotos del catálogo y las peticiones no llevan datos personales. WhatsApp, Maps y el marcador los abre la persona.

**Tipos de datos** (todos se **recopilan**, ninguno se **comparte**, ninguno se procesa solo de forma efímera):

| Categoría › tipo | Obligatorio u opcional | Finalidades que se marcan |
|---|---|---|
| Información personal › **Nombre** | Obligatorio (registro) | Funcionalidad de la app; Administración de la cuenta |
| Información personal › **Dirección de correo electrónico** | Obligatorio | Funcionalidad de la app; Administración de la cuenta; Prevención de fraudes, seguridad y cumplimiento (código por correo opcional, apagado por defecto desde la 0.8.1) |
| Información personal › **ID de usuario** (nombre de usuario) | Obligatorio | Administración de la cuenta |
| Información personal › **Número de teléfono** | Obligatorio (registro) | Funcionalidad de la app (contacto por la cita) |
| Información personal › **Dirección** | Opcional ("Corregir mis datos") | Funcionalidad de la app |
| Información personal › **Otra información** (fecha de nacimiento, pregunta y respuesta secretas) | Fecha: opcional; pregunta secreta: obligatoria | Administración de la cuenta (recuperación) |
| Información financiera › **Historial de compras** (citas cobradas y pedidos de la tienda) | Obligatorio para usar citas y tienda | Funcionalidad de la app; Análisis |
| Actividad en la app › **Otras acciones** (reservas, asistencia) | Obligatorio | Funcionalidad de la app; Análisis |

**No se recopilan:** ubicación, contactos, fotos o videos, archivos, calendario, mensajes, salud, datos de pago (tarjetas: la app no cobra), identificadores del dispositivo, historial web, diagnósticos ni analítica. La app no tiene SDK de analítica, anuncios ni Firebase.

**Análisis:** la política publicada declara en su sección 9, "Analítica, segmentación y predicción", indicadores de recurrencia, gasto, recencia e historial de inasistencia. Para que Play y la política digan lo mismo, en **Historial de compras** y en **Otras acciones** se marca también la finalidad **Análisis**. La persona puede oponerse con las finalidades opcionales de la app.

**Seguridad que se puede mencionar:** sesión en `flutter_secure_storage` (Keystore de Android), contraseña que no se guarda en el teléfono, `allowBackup=false`, sin tráfico HTTP en release, y certificate pinning.
