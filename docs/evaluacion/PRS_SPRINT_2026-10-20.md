# Descripciones de PR — sprint 2026-10-19/20

Texto listo para pegar en cada PR. Ninguna rama se ha subido todavía.

Orden de merge sugerido (Movil → `develop`, squash; backend → `main` con revisión porque despliega):
1. Backend `feature/movil-arco-preferencias` (antes que el PR 4 de Movil, que usa el endpoint).
2. Movil `feature/security-r8-obfuscation`
3. Movil `feature/test-unit-mockito`
4. Movil `feature/arco-acceso-rectificacion` (apilado sobre el 3: retarget a `develop` cuando el 3 entre)
5. Movil `feature/test-integration-http`
6. Movil `feature/ci-quality-gates`
7. Movil `feature/test-integration-device`
8. Movil `fix/secretaria-cobro-dialogo`
9. Movil `docs/avance-sprint-2026-10-20`
10. Backend `feature/movil-seed-pruebas` (solo herramienta de pruebas; no cambia la API)

Cerrar sin merge: Movil #82 y #83 (ver el resumen del Prompt 0).

---

## Movil · `feature/security-r8-obfuscation` → `develop`
**Título:** feat(security): R8 explícito, firma por key.properties y allowBackup=false

Closes #46 · Refs GH#46, GH#47, GH#52, GH#53/54

**Qué cambia**
- `android/app/build.gradle.kts` (release): `isMinifyEnabled`, `isShrinkResources` y `proguard-rules.pro` mínimo (sin `-keep` global). La firma usa `android/key.properties` si existe; si no, la clave debug (desarrollo local).
- `AndroidManifest.xml` (main): `android:allowBackup="false"`.
- README: sección "Release ofuscado" (comandos y dónde guardar símbolos y `mapping.txt`, fuera del repo).

**Evidencia** (`docs/evidencias/seguridad/2026-10-19/`)
- `AuthViewModel`, `SecretariaGestionViewModel` y `_tryRefresh` aparecen en `libapp.so` sin `--obfuscate` (2/2/1) y **0** con `--obfuscate`.
- R8 renombró 951 de 1007 clases (`mapping.txt`). Release sin `debuggable`, sin cleartext y sin `ALLOW_BACKUP` en el paquete instalado.
- Tamaños y SHA-256 de debug, release y release ofuscado. Matriz Debug vs Release (GH#52). Pasos para JADX (GH#48) y MobSF (GH#49).
- APK ofuscado instalado en emulador: arranca, carga el catálogo y abre el login.

**Pruebas:** `dart format` sin cambios, `flutter analyze` sin issues, `flutter test` 96/96.

**Pendiente:** login/logout en el APK ofuscado contra producción (lo hace el equipo con una cuenta real); JADX y MobSF.

---

## Movil · `feature/test-unit-mockito` → `develop`
**Título:** test(unit): agrega Mockito, PM-U01 y fixtures de fromJson

Refs GH#14, GH#15, GH#20

- Extrae el validador de "Correo o usuario" a `lib/core/validation/validators.dart` sin cambiar comportamiento (PM-U01).
- `mockito` + `build_runner`. Los mocks generados se versionan (CI no necesita `build_runner`).
- Fixtures con la forma real de Django (datos ficticios) y pruebas de `fromJson`.
- ViewModels con `verify`, 401/403/409/500, timeout y doble toque en secretaría (PM07).

**Pruebas:** 120/120, cobertura 55.39 % → 57.53 %. Evidencia en `docs/evidencias/pruebas/2026-10-19/`.

**Hallazgo (no corregido):** `ClientCitasViewModel.reservar` no tiene guarda propia contra doble envío; hoy la protege el botón deshabilitado mientras `bookingBusy`.

---

## Movil · `feature/arco-acceso-rectificacion` → `develop` (apilado sobre `feature/test-unit-mockito`)
**Título:** feat(privacidad): Mis datos, corregir perfil y aviso con opt-in (ARCO)

Refs GH#41, GH#42, GH#43, GH#45, S3-04 · Depende de backend `feature/movil-arco-preferencias` (PR enlazado)

- Perfil → **Privacidad y mis datos**:
  - **Mis datos** (GET `/perfil/` + `/mis-citas/`, GH#42).
  - **Corregir mis datos** (PUT `/perfil/`, GH#43). Reenvía `avatar_url` y `direccion` porque Django reemplaza el perfil completo.
- **Aviso de privacidad** desde `/public/legal/?tipo=privacidad`, accesible desde el login y el perfil.
- **Opt-in** de tres finalidades secundarias apagadas por defecto, guardado en la cuenta con `GET/PUT /privacidad/preferencias/`. Nada se guarda solo en el teléfono. Sin sesión el aviso se lee, pero no se puede elegir.
- MVVM: service → `PrivacidadRepository` → ViewModels creados por ruta (sin estado entre usuarios, PM09).

**Pruebas:** ARCO-M01, ARCO-M02 (Mockito `verify` + MockClient del PUT), ARCO-M05 (con/sin sesión, 400/500, versión del aviso), 360×800 y texto 1.3 sin overflow. 160/160, cobertura 61.86 %. Evidencia en `docs/evidencias/arco/2026-10-19/`.

**Merge:** después del PR de backend y su despliegue; antes, la sección de permisos muestra el error del servidor (404) y no deja guardar.

---

## Movil · `feature/test-integration-http` → `develop`
**Título:** test(integration): ApiClient y repositorios contra MockClient

Refs GH#69, S4-03, PM09

- I-401: 401 → refresh → reintento (con y sin rotación); refresh rechazado o ausente → borra tokens y `onSessionExpired`; 401 en login no intenta refresh.
- I-REPO: catálogo, citas, secretaría y auth con 200, `ok:false`, 400, 403, 409, 500 y 503; rutas, query y cuerpo enviados.

**Pruebas:** 114/114, cobertura 55.39 % → 62.29 % (`api_client.dart` 0 % → 84 %).

---

## Movil · `feature/ci-quality-gates` → `develop`
**Título:** ci: gate de cobertura, rama release y release.yml firmado

Refs GH#02, GH#32, GH#47

- `ci.yml`: también en `release`; **gate de cobertura** (mínimo 55 %, `tool/coverage_gate.sh`, PR-01); job manual `build-release` que compila con R8 + `--obfuscate` y falla si `libapp.so` conserva nombres de clase. No sube símbolos, mapping ni APK.
- `release.yml`: en `release`/`main` compila AAB y APK **firmados** y ofuscados; en `main` crea el tag `vX.Y.Z` y la Release. Falla a propósito sin los secretos de firma.
- `.gitattributes`: scripts `.sh` con LF.

**Validado en local:** el gate pasa con 55.39 % y falla con 99 % o sin `lcov.info`; los dos YAML cargan. **Falta:** el run en GitHub; los secretos y el keystore los crea el equipo.

---

## Movil · `feature/test-integration-device` → `develop`
**Título:** test(e2e): PI-01 reserva en emulador contra backend local

Refs GH#17, PM03

- `integration_test` + `integration_test/pi01_reserva_test.dart`: login → Agendar (servicio, barbero, primer horario libre) → confirmar → la cita aparece en "Mis citas" con el mismo servicio, fecha y hora → ese horario ya no se ofrece.
- Aborta si `API_BASE_URL` apunta a `onrender.com`. Credenciales por `--dart-define`, nunca versionadas.

**Resultado:**
- 2026-10-19: corrida 1 falló en la prueba misma (el resumen estaba fuera de pantalla; no creó cita). La corrida 2 pasó: 1/1 en 19 s.
- 2026-10-20: pasó de nuevo, 1/1 en 25 s.
- Logs en `docs/evidencias/pruebas/2026-10-19/` y `docs/evidencias/sprint-2026-10-20/`.

---

## Movil · `fix/secretaria-cobro-dialogo` → `develop`
**Título:** fix(secretaria): el diálogo de cobro ya no usa controladores liberados

Refs GH#12 · `docs/evaluacion/REGISTRO_ERRORES.md` ERR-01

- **Problema** (hallado en el recorrido E2E en emulador): al tocar Cobrar o Cancelar, `_cobrar` liberaba los `TextEditingController` apenas regresaba `showDialog`, mientras el diálogo seguía animando su salida. Salían "used after being disposed", un overflow de ~99 000 px y GlobalKeys duplicadas. El cobro sí llegaba al servidor.
- **Arreglo:** el diálogo pasa a `_CobroDialog` (StatefulWidget), dueño de sus controladores, que los libera en su `dispose`. Sin cambios de contrato.

**Pruebas:** `test/secretaria_cobro_dialogo_test.dart`, 3 casos (cobrar, cancelar, efectivo insuficiente): fallan sin el arreglo y pasan con él. Suite 99/99, cobertura 57.87 %. En emulador, el recorrido completo pasa sin excepciones (capturas `18` y `19` en `docs/evidencias/sprint-2026-10-20/`).

---

## Movil · `docs/avance-sprint-2026-10-20` → `develop`
**Título:** docs: avance al 2026-10-20, registro de errores y evidencia del recorrido

- `docs/evaluacion/AVANCE_2026-10-20.md`: estado por criterio (actividades 4 a 7) en `develop` y con las ramas del sprint, y porcentaje ponderado con la fórmula (34.4 % → 68.6 %).
- `docs/evaluacion/REGISTRO_ERRORES.md`: bitácora de errores encontrados y corregidos (criterio 6.14).
- `docs/evidencias/sprint-2026-10-20/`: 20 capturas del recorrido en Android contra el backend local, logs de PI-01 y del recorrido, y la tabla caso → esperado → observado → captura → tarjeta.
- `docs/evaluacion/PRS_SPRINT_2026-10-20.md`: estas descripciones y el orden de merge.

Solo documentación: no cambia código.

---

## Backend · `feature/movil-arco-preferencias` → `main`
**Título:** feat(privacidad): GET/PUT /api/privacidad/preferencias/ (opt-in ARCO)

Refs GH#41, GH#45 · PR enlazado: Movil `feature/arco-acceso-rectificacion`

- Modelo `bootstrap.PreferenciaPrivacidad` + migración `0002`. `build.sh` ya corre `migrate`: la tabla se crea al desplegar, sin SQL manual en Neon.
- Solo opera sobre el usuario autenticado: no recibe ids. Exige booleanos reales y `version_aviso` ≤ 64.
- No cambia endpoints existentes: la web Angular no se afecta.
- **Contrato:** `GET` → `{"ok":true,"preferencias":{"acepta_promociones":false,"acepta_recordatorios_whatsapp":false,"acepta_analitica_perfilado":false,"version_aviso":"","fecha_respuesta":null,"respondido":false}}`. `PUT` con los tres booleanos y `version_aviso` → la misma forma, con `fecha_respuesta`.

**Pruebas:** `core.tests.test_privacidad_preferencias` 5/5 (401, opt-in por defecto, guardado, aislamiento entre usuarios, datos inválidos). Suite: 335, con los 2 fallos previos de ML (falta `matplotlib`; un mock de segmentación). Probado con curl contra PostgreSQL local.

**Pendiente (ARCO-B06):** que WhatsApp, promociones y el lote de ML respeten estas preferencias.

---

## Backend · `feature/movil-seed-pruebas` → `main`

> **Antes de abrir este PR:** la rama ya no termina en `e5723b9`. Tiene además `694106e` (2026-10-20 20:00): productos, cliente B, credenciales para Flutter, `--limpiar`, `scripts/manage_local.py` y `test_sembrar_datos_prueba_pg.py`. Ese commit no se revisó en este sprint: completa esta descripción con sus pruebas reales.
**Título:** feat(seed): comando sembrar_datos_prueba para pruebas locales de la app móvil

- `manage.py sembrar_datos_prueba`: empresa, horario, política de anticipo, 3 servicios, 2 barberos con horario, cliente y secretaria de prueba, y un aviso de privacidad marcado como **borrador de prueba**. Idempotente.
- Se niega a correr si la base no es PostgreSQL local, si se llama `neondb` o si la primera empresa no es la de pruebas. La contraseña nunca se imprime: va a un archivo fuera del repo.

**Pruebas:** 13 nuevas (guardas, que la contraseña no salga por stdout, archivo de credenciales). Dos corridas contra PostgreSQL local con los mismos conteos de filas.
