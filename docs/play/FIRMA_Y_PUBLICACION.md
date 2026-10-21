# Firma, AAB y publicación

## 1. Clave de subida (lo hace el equipo, una sola vez)
La clave y sus contraseñas son del equipo: no se versionan ni se pegan en chats, issues ni PRs.

1. Crear el keystore **fuera del repo**. En PowerShell:
   ```powershell
   New-Item -ItemType Directory -Force "$env:USERPROFILE\.stylo-keys"
   & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v `
     -keystore "$env:USERPROFILE\.stylo-keys\upload-keystore.jks" `
     -keyalg RSA -keysize 4096 -validity 10000 -alias upload
   ```
   - `keytool` pide la contraseña del almacén, la de la clave y los datos del certificado (nombre, organización "Tony Stylo Barbería", ciudad, país `MX`). Las contraseñas se escriben en la terminal y no quedan en el historial.
2. **Respaldo** del `.jks` y las contraseñas en dos lugares del equipo, por ejemplo el gestor de contraseñas de cada integrante. Si se pierde, Play permite reiniciar la clave de subida, pero tarda días.
3. Cargar los secretos en GitHub con `gh`. Cada comando pide el valor en la terminal, sin que se vea:
   ```bash
   base64 -w0 ~/.stylo-keys/upload-keystore.jks | gh secret set ANDROID_KEYSTORE_BASE64 --repo Gilberto625/MovilStyloBarberConect
   gh secret set ANDROID_KEYSTORE_PASSWORD --repo Gilberto625/MovilStyloBarberConect
   gh secret set ANDROID_KEY_ALIAS --repo Gilberto625/MovilStyloBarberConect --body upload
   gh secret set ANDROID_KEY_PASSWORD --repo Gilberto625/MovilStyloBarberConect
   gh secret set SYMBOLS_PASSPHRASE --repo Gilberto625/MovilStyloBarberConect
   ```
   - `SYMBOLS_PASSPHRASE` cifra los símbolos de `--split-debug-info` y `mapping.txt` que salen como artefacto. El repo es público.
4. Comprobar: `gh secret list --repo Gilberto625/MovilStyloBarberConect` debe mostrar los cinco nombres; los valores nunca se muestran.

Para compilar firmado en una PC, `android/key.properties` (ignorado por git) apunta al `.jks`. Ver `android/app/build.gradle.kts`.

## 2. AAB firmado (GitFlow)
1. PR de versión hacia `release`: `version: 0.4.0+2` en `pubspec.yaml`. El `+N` es el `versionCode` de Play y **siempre crece**.
2. Al fusionarlo, `release.yml`:
   - corre las pruebas;
   - compila AAB y APK **ofuscados**;
   - **falla si quedaran firmados con la clave debug**;
   - publica el artefacto `android-release-0.4.0+2` con el `.aab`, el `.apk`, los símbolos cifrados y `SHA256SUMS.txt`.
3. PR de `release` hacia `main`: el mismo workflow crea el tag `v0.4.0` y la GitHub Release. Después, el back-merge de `main` hacia `develop`.

## 3. Play Console
1. **Crear la app:** nombre "Stylo Barber Connect", idioma es-419, tipo **App**, **Gratis**. Aceptar las declaraciones.
2. **Firma de apps de Play:** se deja activada (opción por defecto). Google guarda la clave de firma de la app y el equipo solo conserva la de subida.
3. **Contenido de la app:** llenar las secciones con `SEGURIDAD_DE_LOS_DATOS.md` y `CLASIFICACION_Y_ACCESO.md`.
4. **Ficha:** `FICHA.md`, `graficos/` y `capturas/`.
5. **Prueba interna** (Pruebas › Prueba interna):
   - Crear una versión y subir el `.aab` del artefacto.
   - Agregar hasta 100 correos de testers y compartir el vínculo de aceptación.
   - Sale en minutos, sin la revisión completa.
   - Revisar el **informe previo al lanzamiento**: Google la prueba en dispositivos reales y usa la cuenta de revisores si se dio en "Acceso a la app".
6. **Prueba cerrada** (Pruebas › Prueba cerrada › Alpha):
   - **Obligatoria para cuentas personales** creadas después del 13-nov-2023.
   - Al menos **12 testers aceptados durante 14 días seguidos**. Conviene invitar a 15 o 20: si bajan de 12, el conteo se reinicia.
   - Luego, en el Panel, **"Solicitar acceso a producción"**: un cuestionario sobre la prueba y la app. Google responde en unos 7 días.
   - Las cuentas de **organización** (con D-U-N-S) no tienen este requisito.
7. **Producción:** crear la versión con el mismo AAB (o uno nuevo con `+N` mayor), elegir países (México) y enviar a revisión.

## 4. Requisitos técnicos ya verificados
Los da el análisis estático de `docs/evidencias/estatico-2026-10-21/`:
- `targetSdk=36` (obligatorio para apps nuevas desde el 31-ago-2026) y `minSdk=24`.
- Bibliotecas nativas alineadas a **16 KB**.
- Solo el permiso `INTERNET`.
- `allowBackup=false` y sin tráfico HTTP en release.
- Código Dart ofuscado y R8 activo. Los símbolos no se publican.
