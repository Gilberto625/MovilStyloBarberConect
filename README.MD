# Stylo Barber Connect Mobile

Aplicación Android Flutter/Dart para Tony Stylo Barbería.

**Versión:** `0.1.0+1`  
**Arquitectura:** Cliente-servidor · MVVM + Repository  
**API:** Django REST existente bajo `/api/` (no `/api/v1/`)

## Requisitos

- Flutter 3.47+ / Dart 3.13+
- **Android SDK** (hoy no está instalado en esta máquina; ver abajo)
- Java 17+ (detectado: 17.0.12)
- Backend Stylo Barber Connect accesible por HTTPS/HTTP

## Android SDK (bloqueante para APK)

Guía paso a paso: [docs/ANDROID_SDK_SETUP.md](docs/ANDROID_SDK_SETUP.md)

Sin `ANDROID_HOME` / SDK, `flutter build apk` y `flutter run` en Android **no pueden ejecutarse**.

## Estructura

```text
lib/
  core/           config, network, errors, storage, theme, di
  models/         DTO según JSON real del backend
  services/       API HTTP (Catalog, Auth, Citas, Secretaría)
  repositories/   orquestación de datos
  viewmodels/     ChangeNotifier
  views/          guest, auth, client, secretary
  widgets/
  routes/
  main.dart
```

Flujo: **View → ViewModel → Repository → API Service → Django REST**

## Configuración de API

```bash
# Emulador Android → backend local
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Producción (default embebido)
flutter run --dart-define=API_BASE_URL=https://backendstylobarberconect-lo71.onrender.com/api
```

## Instalación y ejecución

```bash
cd Movil
flutter pub get
flutter analyze
flutter test
flutter run   # requiere Android SDK + dispositivo/emulador
```

Release:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

Los símbolos de ofuscación (`debug-info/`, `*.symbols`) están en `.gitignore`.

## Endpoints conectados

| Área | Endpoints |
|------|-----------|
| Público | `GET /public/servicios/`, `/public/productos/`, `/public/contacto/` |
| Auth | `POST /login/`, `/login/2fa/verificar/`, `/login/2fa/solicitar-codigo/`, `POST /auth/token/refresh/`, `GET /auth/me/`, `GET /perfil/` |
| Cliente | `GET /barberos/`, `/disponibilidad/`, `/citas/politica-pago/`, `/mis-citas/`, `POST /citas/` |
| Secretaría | `GET /secretaria/citas/dia/`, `POST .../asistencia/`, `POST .../cobrar/` |

## Seguridad

- Tokens en `flutter_secure_storage` (no contraseñas).
- Sin logs de `Authorization`, tokens u OTP.
- Logout solo local (el backend no expone logout).
- 401 → intento de refresh; si falla, limpia sesión.
- Roles: secretaría solo si el backend reporta `secretaria` o `admin`.

## Pruebas

```bash
dart format .
flutter analyze
flutter test
```

## Notas

- No es monorepo: este directorio tiene su propio `.git`.
- No modifica `/backend` ni `/FrontStyloBarberConect`.
- No hay pagos simulados ni sync offline de asistencia/cobro.
