# Primera subida a Google Play, paso a paso

Para la versión **0.8.0-beta.1+4** (HITO 03 – Versión beta integrada). Se hace desde la cuenta de desarrollador ya pagada, después de **verificar la identidad** con el teléfono Android.

## 0. Antes de empezar (una sola vez)
| Qué | Quién | Para qué |
|---|---|---|
| Verificar identidad y domicilio en Play Console | El dueño de la cuenta, con su teléfono Android | Sin esto Play no deja crear versiones |
| Llenar los 2 marcadores de la política de privacidad (responsable y correo ARCO) desde el panel admin de la web | Equipo | Play revisa que la política diga quién es el responsable |
| Cuenta de revisor de **cliente** en producción, con el 2FA apagado desde el perfil web | Equipo | Los revisores no reciben códigos por correo |
| Fusionar el backend PR #8 | Equipo | Mantiene despierto el backend durante la revisión |

## 1. Bajar el AAB firmado
1. GitHub › **Actions** › workflow **Release build** › la ejecución de la rama `release` con versión `0.8.0-beta.1+4`.
2. Abajo, en **Artifacts**, descarga `android-release-0.8.0-beta.1+4` (un `.zip`). Contiene:

   | Archivo | Para qué |
   |---|---|
   | `stylo-barber-connect-0.8.0-beta.1+4.aab` | **El que se sube a Play** |
   | `stylo-barber-connect-0.8.0-beta.1+4.apk` | Para instalar a mano en un teléfono |
   | `symbols-0.8.0-beta.1+4.tgz.gpg` | Símbolos y `mapping.txt`, cifrados |
   | `SHA256SUMS.txt` | Huellas de los archivos |

3. Guarda el `.zip` fuera del repo. GitHub lo borra a los 30 días.

## 2. Crear la app en Play Console
1. **Crear app:**
   - Nombre `Stylo Barber Connect`.
   - Idioma predeterminado **Español (Latinoamérica)**.
   - **App**, **Gratis**. Acepta las declaraciones.
2. **Panel** › "Configura tu app". Llena cada tarea con las respuestas de este kit:

   | Tarea | Respuestas en |
   |---|---|
   | Política de privacidad | `SEGURIDAD_DE_LOS_DATOS.md` |
   | Acceso a la app (usuario y contraseña del revisor e instrucciones) | `CLASIFICACION_Y_ACCESO.md` |
   | Anuncios | `CLASIFICACION_Y_ACCESO.md` (No) |
   | Clasificación de contenido | `CLASIFICACION_Y_ACCESO.md` |
   | Público objetivo | `CLASIFICACION_Y_ACCESO.md` (18+) |
   | Seguridad de los datos y eliminación de datos | `SEGURIDAD_DE_LOS_DATOS.md` |
   | Apps del gobierno, funciones financieras, apps de salud, ID de publicidad | `CLASIFICACION_Y_ACCESO.md` (todas No) |
   | Categoría y contacto | `FICHA.md` (Belleza; correo de la barbería) |
   | Ficha de Play Store | `FICHA.md`, `graficos/` y `capturas/` |

## 3. Prueba interna (sale en minutos)
1. **Prueba › Prueba interna › Crear versión.**
2. La primera vez pide **Firma de apps de Google Play**: acepta la opción recomendada. Google guarda la clave de firma; tú conservas la de subida (`upload-keystore.jks`).
3. Sube el `.aab`. Play lee solo el nombre (`0.8.0-beta.1`) y el código (`4`).
4. **Notas de la versión** (es-419):
   ```
   Primera versión beta: reserva de citas, reprogramar y cancelar, tienda, privacidad y agenda del barbero.
   ```
5. **Guardar › Revisar versión › Lanzar en prueba interna.**
6. Pestaña **Testers**:
   - Crea una lista con los correos de Gmail del equipo.
   - Copia el **vínculo de participación** y ábrelo en el teléfono Android. Así se instala la app desde Play.
7. A los minutos aparece el **Informe previo al lanzamiento** (Calidad › Informe previo al lanzamiento): Google prueba la app en teléfonos reales con la cuenta del revisor. Revisa que no haya fallos ni advertencias de accesibilidad.

## 4. Archivo de desofuscación (quita una advertencia)
Como el AAB está ofuscado, Play avisa *"No hay ningún archivo de desofuscación asociado"*. No impide publicar. Para quitarlo:
1. En Git Bash, en la carpeta del `.zip` descomprimido:
   ```bash
   gpg --decrypt symbols-0.8.0-beta.1+4.tgz.gpg > symbols.tgz
   ```
   ```bash
   tar xzf symbols.tgz
   ```
   La frase que pide es la de `SYMBOLS_PASSPHRASE`.
2. Play Console › **Explorador de apps** › versión `4` › **Subir archivo de desofuscación de ReTrace** › `build/app/outputs/mapping/release/mapping.txt`.
3. Los símbolos de Dart (`build/symbols/...`) **no** se suben a Play. Se guardan para leer errores con `flutter symbolize`.

## 5. Prueba cerrada: el reloj de 14 días
Obligatoria para cuentas personales antes de pedir producción.
1. **Prueba › Prueba cerrada › Crear canal**, o usa **Alpha**.
2. **Países:** México.
3. **Testers:**
   - Una lista de correos o un Grupo de Google con **15 a 20 personas** con teléfono Android.
   - Mínimo 12. Si bajan de 12, el conteo de 14 días vuelve a empezar.
4. **Crear versión:** usa **"Agregar desde la biblioteca"** para tomar el mismo AAB (versión 4) que ya está en prueba interna.
5. **Enviar a revisión.**
   - La primera versión cerrada la revisa Google: de horas a pocos días.
   - Al aprobarla, comparte el vínculo con los testers.
   - Cada tester debe: aceptar desde su cuenta de Google › instalar › **dejarla instalada** y abrirla de vez en cuando durante los 14 días.
6. **Panel** muestra el avance: "X testers inscritos, Y de 14 días".

## 6. Producción
Al cumplir 14 días seguidos con 12 o más testers:
1. **Panel › Solicitar acceso a producción.** Es un cuestionario sobre cómo fue la prueba. Google responde en unos 7 días.
2. Con el acceso aprobado:
   - Crear la versión de **Producción** con un AAB nuevo (`1.0.0-rc.1` o `1.0.0`, `+N` mayor).
   - Elegir México.
   - Enviar a revisión.

## Si algo falla
| Mensaje de Play | Qué significa |
|---|---|
| "El código de versión 4 ya se usó" | Hay que subir la versión en `release` por PR (`+5`) |
| "Firmaste con una clave distinta" | Se subió un AAB firmado con debug o con otra llave. Usa solo el del artefacto de GitHub |
| "Tu app requiere acceso / no pudimos iniciar sesión" | La cuenta del revisor tiene 2FA o la contraseña cambió |
| "Política de privacidad incompleta" | Faltan los marcadores del responsable o del correo ARCO |
