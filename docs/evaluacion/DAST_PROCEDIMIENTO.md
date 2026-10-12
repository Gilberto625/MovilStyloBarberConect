# Procedimiento DAST - Actividad 5

Objetivo: documentar una evaluacion dinamica reproducible y autorizada para la aplicacion movil Stylo Barber Connect Mobile.

DAST significa probar la aplicacion ejecutandose. Semgrep, JADX y analisis estatico de APK no son DAST por si solos.

## Estado actual

| Elemento | Estado |
|----------|--------|
| Entorno Android conectado | Pendiente |
| Backend de pruebas/staging | Pendiente |
| APK debug autorizado | Disponible localmente en builds previos, pero debe regenerarse para la evidencia |
| APK release autorizado | Disponible localmente, pero firmado con debug key; no usar como evidencia final de publicacion |
| MobSF dinamico | Pendiente |
| Evidencia DAST final | Pendiente |

No ejecutar pruebas destructivas ni ataques contra produccion.

## Entorno requerido

| Recurso | Requisito |
|---------|-----------|
| Dispositivo/emulador | Android con red controlada y datos de prueba |
| Backend | Staging/local autorizado, no produccion |
| Cuentas | Usuario cliente y usuario secretaria de prueba |
| APK | Build debug o release de prueba generado desde el commit auditado |
| Herramienta | MobSF Dynamic Analyzer, proxy autorizado o herramienta equivalente |

## Preparacion recomendada

1. Crear o seleccionar backend de pruebas.
2. Confirmar que `API_BASE_URL` apunta al entorno de pruebas con `--dart-define`.
3. Crear datos ficticios: cliente, secretaria, citas, servicios.
4. Generar APK desde el commit que se va a evaluar.
5. Registrar version de herramientas:
   - Flutter;
   - Android SDK;
   - MobSF;
   - emulador/dispositivo;
   - backend usado.

## Comandos base

Generar APK debug para pruebas dinamicas:

```powershell
flutter pub get
flutter build apk --debug --dart-define=API_BASE_URL=https://staging.example.com/api
```

Generar APK release de prueba, si ya existe firma de release autorizada:

```powershell
flutter build apk --release --obfuscate --split-debug-info=build/symbols --dart-define=API_BASE_URL=https://staging.example.com/api
```

No usar `https://staging.example.com/api` literalmente. Reemplazar por el backend de pruebas autorizado.

## Casos minimos DAST

| Caso | Esperado |
|------|----------|
| Abrir app sin sesion | No crash; muestra estado invitado/login |
| Login con credenciales invalidas | Error controlado, sin exposicion de token |
| Login con usuario cliente | JWT almacenado; navegacion a cliente |
| Login con usuario secretaria | JWT almacenado; navegacion a secretaria |
| Peticion autenticada | Header `Authorization: Bearer` enviado solo por HTTPS |
| Token expirado | 401 controlado y refresh/retry si aplica |
| Logout | Tokens eliminados de almacenamiento seguro |
| Trafico HTTP claro | No permitido en release |
| TLS/pinning cuando exista | Pin incorrecto debe bloquear conexion |
| Datos sensibles en logs | No deben aparecer tokens, contrasenas ni PII |

## Evidencia a guardar

Guardar en:

```text
docs/evaluacion/evidencias/act5_dast/
```

Archivos recomendados:

| Archivo | Contenido |
|---------|-----------|
| `YYYY-MM-DD_mobsf_dynamic_report.pdf` | Reporte MobSF dinamico |
| `YYYY-MM-DD_test_environment.md` | Versiones, commit, APK, backend, dispositivo |
| `YYYY-MM-DD_screenshots/` | Capturas sin PII real |
| `YYYY-MM-DD_findings.md` | Hallazgos, severidad, correccion o justificacion |

## Limitaciones que deben declararse

Si no hay backend de pruebas, no declarar DAST cumplido. Registrar:

```text
DAST pendiente por falta de entorno staging autorizado. No se ejecutaron pruebas dinamicas sobre produccion.
```

Si solo se ejecuta MobSF estatico sobre APK, registrar:

```text
MobSF estatico ejecutado. No equivale a DAST porque la aplicacion no se probo en ejecucion.
```
