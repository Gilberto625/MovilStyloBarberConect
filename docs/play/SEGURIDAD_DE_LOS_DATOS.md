# Seguridad de los datos, eliminación de cuenta y privacidad

Play Console › Supervisar y mejorar › Política y programas › **Contenido de la app**. Fuente de verdad del inventario: `docs/evaluacion/PERMISOS_Y_DATOS.md`. Si la app cambia, se actualizan los dos.

## Política de privacidad
- URL: `https://tonystylo.vercel.app/nosotros?tipo=privacidad`.
- Es pública, no pide sesión y es la misma que muestra la app en "Aviso de privacidad".
- **Antes de enviar a revisión (lo hace el equipo):** el texto publicado todavía tiene dos marcadores sin llenar (revisado en producción el 2026-10-29): `[NOMBRE O RAZÓN SOCIAL DE LA PERSONA RESPONSABLE]` y `[CORREO PARA PRIVACIDAD Y DERECHOS ARCO]`.
  - Play pide que la política identifique al responsable y dé un contacto. Con marcadores, la revisión la puede rechazar.
  - Se llenan desde el contenido legal del backend (panel de administración de la web), no en la app.
  - El correo debe ser el mismo de la ficha.

## Eliminación de la cuenta
Play pide las dos vías porque la app permite crear cuenta:

| Vía | Cómo | Estado |
|---|---|---|
| **Desde la app** | Perfil › Privacidad y mis datos › **Eliminar mi cuenta**. Se reautentica con la contraseña y la palabra ELIMINAR. | ✅ en producción (app PR #101, backend PR #5) |
| **Desde la web**, sin instalar la app | `https://tonystylo.vercel.app/eliminar-cuenta`: correo o usuario más contraseña, y responde con un folio | ✅ publicada (front PR #3); usa el mismo `POST /api/privacidad/cancelacion/` sin sesión |

Respuestas del formulario "Eliminación de datos":
- **¿La app permite crear cuentas?** Sí.
- **Vínculo para borrar la cuenta:** `https://tonystylo.vercel.app/eliminar-cuenta`.
- **¿Se puede pedir borrar algunos datos sin borrar la cuenta?** Sí. En "Corregir mis datos" el teléfono, la fecha de nacimiento y la dirección son opcionales y se pueden dejar vacíos (`PUT /perfil/`), y los usos opcionales se apagan en "Aviso de privacidad y preferencias".
- **Qué se borra y cuándo** (texto para la página web y para la revisión):
  > Al pedirlo, la cuenta se bloquea de inmediato. En 30 días se eliminan el nombre, el correo, el teléfono, la fecha de nacimiento, el usuario, la contraseña y las direcciones. Las citas, cobros y ventas se conservan sin datos que te identifiquen, porque la barbería debe guardar sus registros contables.

**Requisito del backend:** programar en Render un **Cron Job diario** con `python manage.py suprimir_cuentas_vencidas` (se puede probar antes con `--dry-run`). Como respaldo, el backend PR #8 lo corre en cada arranque del servicio; pero con el ping cada 10 minutos el servicio casi no reinicia, así que el Cron diario sigue siendo necesario.

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
| Información personal › **Dirección de correo electrónico** | Obligatorio | Funcionalidad de la app; Administración de la cuenta; Prevención de fraudes, seguridad y cumplimiento (códigos 2FA) |
| Información personal › **ID de usuario** (nombre de usuario) | Obligatorio | Administración de la cuenta |
| Información personal › **Número de teléfono** | Obligatorio (registro) | Funcionalidad de la app (contacto por la cita) |
| Información personal › **Dirección** | Opcional ("Corregir mis datos") | Funcionalidad de la app |
| Información personal › **Otra información** (fecha de nacimiento, pregunta y respuesta secretas) | Fecha: opcional; pregunta secreta: obligatoria | Administración de la cuenta (recuperación) |
| Información financiera › **Historial de compras** (citas cobradas y pedidos de la tienda) | Obligatorio para usar citas y tienda | Funcionalidad de la app; Análisis |
| Actividad en la app › **Otras acciones** (reservas, asistencia) | Obligatorio | Funcionalidad de la app; Análisis |

**No se recopilan:** ubicación, contactos, fotos o videos, archivos, calendario, mensajes, salud, datos de pago (tarjetas: la app no cobra), identificadores del dispositivo, historial web, diagnósticos ni analítica. La app no tiene SDK de analítica, anuncios ni Firebase.

**Análisis:** la política publicada declara en su sección 9, "Analítica, segmentación y predicción", indicadores de recurrencia, gasto, recencia e historial de inasistencia. Para que Play y la política digan lo mismo, en **Historial de compras** y en **Otras acciones** se marca también la finalidad **Análisis**. La persona puede oponerse con las finalidades opcionales de la app.

**Seguridad que se puede mencionar:** sesión en `flutter_secure_storage` (Keystore de Android), contraseña que no se guarda en el teléfono, `allowBackup=false`, sin tráfico HTTP en release, y certificate pinning.
