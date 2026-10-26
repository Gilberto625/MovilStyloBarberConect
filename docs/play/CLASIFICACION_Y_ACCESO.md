# Clasificación, público objetivo, anuncios y acceso para revisores

Play Console › Política y programas › **Contenido de la app**.

## Acceso a la app (cuenta para revisores)
Casi toda la app exige sesión, así que se marca **"Todas o algunas funciones están restringidas"** y se dan instrucciones.

1. El equipo crea en **producción**, desde la propia app o la web, una cuenta de **cliente** solo para la revisión (por ejemplo `revisor.play`). **Sin 2FA:** los revisores no reciben los códigos por correo.
   - La crea una persona del equipo; nadie más maneja su contraseña.
   - Las credenciales se escriben **solo** en Play Console, nunca en el repo ni en issues.
2. Instrucciones para Play (copiar):
   > Abre la app, toca "Entrar" en la barra inferior e inicia sesión con el usuario y la contraseña de abajo. Como cliente puedes ver servicios, agendar una cita (elige servicio, barbero y horario), ver "Mis citas", apartar productos en "Tienda" y revisar "Perfil › Privacidad y mis datos". Si agendas una cita de prueba, cancélala desde la barbería o déjala; no se cobra nada en la app. El panel de recepción es solo para empleados de la barbería y no forma parte del uso público.
3. No se da una cuenta de recepción. Ese panel muestra datos reales de los clientes. Si Play la pidiera, se graba un video del panel con datos de prueba del backend local.

## Anuncios
**No**, la app no contiene anuncios.

## Clasificación de contenido (cuestionario IARC)
- Correo de contacto: el de la ficha.
- Categoría: **"Todas las demás tipos de apps"** (no es juego, ni red social, ni de noticias).

| Pregunta | Respuesta |
|---|---|
| Violencia, sangre, miedo | No |
| Contenido sexual o desnudos | No |
| Lenguaje soez u ofensivo | No |
| Drogas, alcohol o tabaco (referencias o uso) | No |
| Apuestas o simulación de apuestas | No |
| ¿Los usuarios pueden interactuar o comunicarse entre sí dentro de la app? | No. El botón de WhatsApp solo abre el chat con la barbería, fuera de la app |
| ¿Comparte la ubicación del usuario con otros usuarios? | No |
| ¿Permite comprar bienes digitales? | No. Los productos son físicos y se pagan en la barbería |
| ¿Es un navegador web o motor de búsqueda? | No |
| ¿Contenido generado por usuarios visible para otros? | No |

Resultado esperado: **Para todos** / PEGI 3 / clasificación A.

## Público objetivo y contenido
- **Edad del público objetivo:** **18 años o más.**
  - Si se marca menor de 13, la app entra al programa de Familias, con requisitos extra.
  - La LFPDPPP pide el consentimiento de los padres para datos de menores.
  - Los cortes infantiles los agenda un adulto con su propia cuenta (recomendación; lo confirma la barbería).
- **¿Atrae a niños sin querer?** No.
- **Otras declaraciones:** no es app de noticias, ni de salud, ni financiera, ni del gobierno. No usa permisos sensibles (solo `INTERNET`) ni ID de publicidad. No tiene Firebase ni SDK de anuncios. En "ID de publicidad" se responde **No**.
