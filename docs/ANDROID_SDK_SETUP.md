# Configurar Android SDK (Windows) — Stylo Barber Connect Mobile

Entorno detectado: **Windows local** (`YAGER`, Windows 11 25H2).  
Estado actual: **Android SDK no instalado**, `ANDROID_HOME` / `ANDROID_SDK_ROOT` vacíos, Android Studio no encontrado.

Flutter y Java 17 sí están disponibles. No se instaló nada de forma global (requiere tu autorización).

## Opción recomendada — Android Studio

1. Descarga e instala: https://developer.android.com/studio  
2. En el asistente inicial marca:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (opcional)
3. Abre **SDK Manager** y confirma al menos:
   - Android SDK Platform 35 (o la que pida Flutter)
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android SDK Platform-Tools
4. Ruta típica del SDK:
   `C:\Users\yager\AppData\Local\Android\Sdk`
5. Configura variables de usuario (PowerShell como usuario, no admin obligatorio):

```powershell
[System.Environment]::SetEnvironmentVariable(
  'ANDROID_HOME',
  "$env:LOCALAPPDATA\Android\Sdk",
  'User'
)
[System.Environment]::SetEnvironmentVariable(
  'ANDROID_SDK_ROOT',
  "$env:LOCALAPPDATA\Android\Sdk",
  'User'
)
$path = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$add = @(
  "$env:LOCALAPPDATA\Android\Sdk\platform-tools",
  "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin"
)
foreach ($p in $add) {
  if ($path -notlike "*$p*") { $path = "$path;$p" }
}
[System.Environment]::SetEnvironmentVariable('Path', $path, 'User')
```

6. Cierra y abre la terminal, luego:

```powershell
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
flutter doctor --android-licenses
cd "C:\Users\yager\Documents\INGENIERIA\proyevto v2\Movil"
flutter doctor -v
flutter devices
flutter build apk --debug
flutter run
```

## Opción cmdline-tools (sin IDE completo)

Solo si prefieres no instalar Android Studio. Requiere aceptar licencias y descargar paquetes SDK manualmente. Guía oficial: https://flutter.dev/to/windows-android-setup

## Teléfono físico

1. Activa **Opciones de desarrollador** → **Depuración USB**.
2. Conecta por USB y acepta la huella.
3. `flutter devices` debe listar el teléfono.
4. `flutter run --dart-define=API_BASE_URL=https://backendstylobarberconect-lo71.onrender.com/api`

## Nota sobre Java

Ya tienes **Java 17.0.12** (adecuado para Gradle/Android actuales). Opcional: definir `JAVA_HOME` al JDK completo si Flutter/Android Studio lo piden.
