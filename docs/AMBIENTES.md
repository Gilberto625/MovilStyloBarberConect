# Ambientes: dev, staging y prod

Tarjeta GH#68 (CORE-001). La app elige su ambiente al compilar con dos `--dart-define`:

| Variable | Valores | Por defecto |
|---|---|---|
| `APP_ENV` | `dev`, `staging`, `prod` (sin distinguir mayúsculas) | `dev` |
| `API_BASE_URL` | URL base de Django con `/api` | Depende del ambiente (tabla de abajo) |

El código está en `lib/core/config/app_config.dart` (`AppConfig.ambiente` y `AmbienteConfig.resolver`). La etiqueta visible es `lib/widgets/etiqueta_ambiente.dart`.

## Tabla de ambientes

| Ambiente | URL base por defecto | Backend | Para qué | Comando | Datos |
|---|---|---|---|---|---|
| `dev` | `http://10.0.2.2:8000/api` (el `localhost` de la PC visto desde el emulador Android) | Django local (`backend/`, `python manage.py runserver 0.0.0.0:8000`) con base de datos local | Desarrollo diario, pruebas de integración (`integration_test/`) y evidencias que escriben datos | `flutter run` (o `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000/api` en un teléfono de la LAN) | Datos de prueba sembrados en la base local. Nunca la base en la nube de `backend/.env` |
| `staging` | **Ninguna: `API_BASE_URL` es obligatoria** | No hay servidor de staging propio. Se usa el backend local o un despliegue de la rama de pruebas del backend, el que se indique en `API_BASE_URL` | Probar un build "casi release" (DAST, revisión del equipo) contra un backend que no es producción | `flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=http://10.0.2.2:8000/api` | Los del backend que se indique. Nunca producción |
| `prod` | `https://backendstylobarberconect-lo71.onrender.com/api` | Django en Render (`stylo-barber-api`) por HTTPS, con certificate pinning | Builds firmados de `release.yml` (AAB/APK para Play Store) | `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/<versión> --dart-define=APP_ENV=prod` | Datos reales. Para pruebas, solo lectura de endpoints públicos (`/public/...`). Nada de reservas, cobros, asistencias ni carga |

## Reglas

1. **Sin `APP_ENV` es `dev`.** Un build sin configurar nunca apunta a producción por accidente. `release.yml` pasa `--dart-define=APP_ENV=prod` explícitamente.
2. **`API_BASE_URL` manda sobre la URL por defecto** del ambiente. Se le quitan las barras finales.
3. **`staging` exige `API_BASE_URL`**, porque no hay un servidor de staging que poner por defecto.
4. **`prod` exige HTTPS.** `APP_ENV=prod` con una URL `http://` no arranca.
5. **Valor desconocido = error claro.** `APP_ENV=qa` o una URL sin `http(s)://` y sin host no arrancan contra ningún backend: la app muestra "Configuración de ambiente no válida" con el motivo (`AmbienteInvalidoApp` en `lib/main.dart`).
6. **HTTP solo en debug.** El manifest de debug permite tráfico sin cifrar hacia `10.0.2.2`, `localhost` y `127.0.0.1`. Un build release de `dev` o `staging` con URL `http://` no podrá conectarse: para probar contra el backend local usa un build debug, o un `staging` con HTTPS.

## Cómo se identifica el ambiente

- Fuera de producción aparece una etiqueta discreta con el ambiente y el host de la API: `DEV · 10.0.2.2:8000` o `STAGING · <host>`. Está al pie del **inicio de sesión** y de **Perfil** del cliente. TalkBack la lee como "Ambiente DEV, API 10.0.2.2:8000".
- En `prod` no se muestra nada.

## Pruebas de arranque por ambiente

| Prueba | Qué cubre |
|---|---|
| `test/ambientes/app_config_ambiente_test.dart` | Resolución de dev, staging y prod con sus URL; `prod` exige HTTPS; `APP_ENV` desconocido y URL inválida dan error; la etiqueta se ve en dev y staging y no en prod; pantalla de configuración inválida |
| `test/ambientes/arranque_ambiente_test.dart` | Usa los `--dart-define` reales del build: el ambiente resuelto, la URL que usa `ApiClient` y la etiqueta en el inicio de sesión |

En CI de PR corre sin defines (dev). Para los otros ambientes:

```bash
flutter test test/ambientes/arranque_ambiente_test.dart \
  --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
flutter test test/ambientes/arranque_ambiente_test.dart --dart-define=APP_ENV=prod
```

Estas pruebas no hacen peticiones de red.
