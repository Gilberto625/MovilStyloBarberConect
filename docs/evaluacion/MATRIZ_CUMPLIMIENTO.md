# MATRIZ DE CUMPLIMIENTO — Instrumento Integral de Evaluación Móvil

**Proyecto:** Stylo Barber Connect Mobile (`/Movil`)  
**Versión app:** `0.1.0+1`  
**Fecha de elaboración:** 2026-10-06  
**Fuente de criterios:** Instrumento Integral de Evaluación Móvil (octubre–noviembre 2026), según requisitos oficiales comunicados.  
**PDF adjunto en workspace:** **No encontrado** al momento de esta matriz (`[No comprobado]` búsqueda de `*Instrumento*` / PDF en `/Movil` y raíz). Los criterios se toman **literalmente** del enunciado oficial proporcionado por el profesor vía la consigna de esta fase.

**Leyenda de estado**

| Estado | Significado |
|--------|-------------|
| Cumple | Implementado **y** comprobado (código + prueba/evidencia) |
| Parcial | Hay avance real, pero falta prueba, evidencia o un subcriterio |
| Pendiente | No implementado o no ejecutado |
| Bloqueado | Depende de backend/proceso externo no autorizado aún |
| No comprobado | No se pudo verificar (falta PDF, dispositivo, cuenta Play, etc.) |

**Capas de madurez (no confundir)**

| Capa | Definición |
|------|------------|
| Implementado | Existe código/configuración |
| Probado | Hay ejecución de prueba con resultado |
| Documentado | Descrito en README/docs |
| Evidenciado | Capturas/logs/artefactos guardados para entrega |
| Aceptado | Revisado/aprobado por el profesor (fuera de alcance del agente) |

---

## ACTIVIDAD 5 — Repositorio, versionamiento y CI/CD  
**Puntuación:** 3 puntos · **Entrega:** 22 de octubre de 2026

| # | Criterio oficial | Estado | Implementado | Probado | Documentado | Evidenciado | Archivos / evidencias | Prueba necesaria | Acción pendiente | Responsable |
|---|------------------|--------|--------------|---------|--------------------------|------------------------|------------------|------------------|-------------|
| 5.1 | GitFlow activo (`main`, `develop`, `feature/*`) | **Parcial** | Sí (ramas existen) | No (flujo no demostrado en PRs) | Parcial | No | Ramas locales/remotas: `main`, `develop`, `feature/flutter-login`, `feature/flutter-citas`, `feature/flutter-usuarios` (`git branch -a`) | Demostrar merge feature→develop→main con PR | Usar GitFlow real en siguientes features; no dejar features apuntando al mismo commit base | Equipo |
| 5.2 | Historial colaborativo de **ambos** integrantes | **Pendiente** | No | No | No | No | `git shortlog -sn --all`: solo **Gilberto Hernandez** / `20201171@uthh.edu.mx` (3 commits) | Commits/PRs del segundo integrante con identidad Git real | Segundo integrante debe clonar, configurar `user.name`/`user.email` propios y contribuir; **no fabricar** historial | Ambos |
| 5.3 | Commits claros y estructurados | **Parcial** | Sí | N/A | Parcial | Parcial | `feat: implement initial Flutter...`, `chore: configuración inicial...`, `first commit` | Convención Conventional Commits en todo el historial futuro | Estandarizar mensajes; evitar “first commit” genéricos | Equipo |
| 5.4 | Pipeline en `.github/workflows` | **Parcial** | Sí | No en GitHub | Sí | No | `.github/workflows/ci.yml` | Run en PR/push con resultado verde | Subir por PR y guardar URL/captura del run | Dev móvil |
| 5.5 | Análisis de seguridad SAST/DAST | **Parcial** | SAST sí; DAST documentado | No en GitHub / no dinámico | Sí | No | `.semgrep.yml`, `.github/workflows/ci.yml`, `docs/evaluacion/DAST_PROCEDIMIENTO.md` | Artefacto Semgrep + DAST autorizado | Ejecutar CI y preparar MobSF dinámico o justificar bloqueo | Dev móvil + seguridad |
| 5.6 | Herramientas admitidas (SonarQube, MobSF, Semgrep, Snyk) | **Parcial** | Semgrep configurado | No ejecutado en Actions | Sí | No | Semgrep local + registry `p/secrets`, `p/security-audit`, `p/owasp-top-ten` | Run Semgrep sin `ERROR` | Revisar hallazgos cuando corra CI | Equipo |
| 5.7 | Ausencia de fallos críticos en análisis previo a compilación | **No comprobado** | Gate configurado | No hay run remoto | Sí | No | `semgrep scan ... --severity ERROR --error` | Ejecutar pipeline | Depende de push/PR y Actions verde | Equipo |

**Resumen Actividad 5:** avance de ramas GitFlow **estructural** y CI/SAST ya configurado en archivos, pero **sin ejecución remota, sin DAST real y sin segundo autor evidenciado**. Riesgo alto de no acreditar los 3 puntos el 22-oct si no se generan PRs, runs y colaboración verificable.

---

## ACTIVIDAD 4 — Interfaces, arquitectura, patrones y pruebas  
**Puntuación:** 7 puntos · **Entrega:** 29 de octubre de 2026

| # | Criterio oficial | Estado | Implementado | Probado | Documentado | Evidenciado | Archivos / evidencias | Prueba necesaria | Acción pendiente | Responsable |
|---|------------------|--------|--------------|---------|--------------------------|------------------------|------------------|------------------|-------------|
| 4.1 | Pantallas Flutter funcionales | **Parcial** | Sí | Parcial (widget/unit) | Sí (README) | Parcial (APK existe; **sin** evidencia visual Android acreditada) | `lib/views/guest/*`, `auth/*`, `client/*`, `secretary/*` | Ejecución en emulador/dispositivo + capturas | `flutter run` / instalar APK y grabar evidencias | Dev móvil |
| 4.2 | Arquitectura MVVM/Clean desacoplada | **Parcial** | Sí (MVVM + Repository) | Parcial | Sí | Parcial | `viewmodels/`, `repositories/`, `services/`, `views/`, `core/di/app_scope.dart` | Diagrama + tests que fallen si se acopla View→API | Mantener capas; documentar diagrama Clean/MVVM | Arquitecto |
| 4.3a | Patrón **Singleton** | **Parcial** | Parcial (instancia única de `AppScope` en `main`) | No como patrón documentado | No | No | `lib/main.dart` (`AppScope.create()` una vez); `Provider` | Justificar en doc + evitar múltiples scopes | Documentar “composition root / app singleton”; no añadir Singleton falso | Arquitecto |
| 4.3b | Patrón **Factory** | **Parcial** | Sí | Parcial (tests DTO) | No explícito | No | `*.fromJson` en `models/*`; `AppScope.create`; `ApiException.fromBody` | Test de factory JSON | Nombrar/documentar factories en `docs/` | Dev móvil |
| 4.3c | Patrón **Repository** | **Cumple** (código+tests) / **Parcial** evidencia académica | Sí | Sí (fakes + VM) | Sí | Parcial | `lib/repositories/*`; `test/viewmodel_repository_test.dart`; `test/auth_and_flows_test.dart` | Captura de cobertura/reporte CI | Incluir en evidencia Entrega 4 | Dev móvil |
| 4.3d | Patrón **Observer** | **Parcial** | Sí | Parcial | Parcial | No | `ChangeNotifier` + `Provider`/`Consumer` en views | Test de notifyListeners / widget rebuild | Documentar Observer = ChangeNotifier | Dev móvil |
| 4.4 | Pruebas caja blanca: unitarias | **Parcial** | Sí | Sí (19 tests) | Parcial | Parcial | `test/*.dart` | Mantener/ampliar en CI | Ampliar models assertions | QA |
| 4.5 | Pruebas de integración | **Pendiente** | No (no hay `integration_test/` real contra API/mock HTTP) | No | No | No | Solo fakes in-memory | `integration_test` o test HTTP mock (`http` MockClient) | Crear suite integración Repository↔ApiClient | QA |
| 4.6 | Assertions sobre lógica interna (VM/Repo/Models) | **Parcial** | Sí | Sí | Parcial | Parcial | `auth_and_flows_test.dart`, `viewmodel_repository_test.dart` | Aumentar edge cases 401/anticipo/roles | Ampliar | QA |
| 4.7 | Navegación funcional | **Parcial** | Sí | No en dispositivo | Parcial | No | `lib/routes/app_routes.dart`; guards por rol en views | E2E navegación invitado→login→cliente/secretaría | Evidencias de pantallas | Dev móvil |
| 4.8 | UX/UI responsiva sin errores visuales | **No comprobado** | Implementado (SafeArea, listas) | No en Android UI | Parcial | No | Themes `lib/core/theme/app_theme.dart` | Revisión visual 360×800 / 390×844 | Sesión de QA visual en emulador | UX/Dev |

**Patrones ya implementados (ubicación exacta, sin inventar)**

| Patrón | Justificación real | Ubicación |
|--------|--------------------|-----------|
| Repository | Aísla fuentes de datos de ViewModels | `lib/repositories/catalog_repository.dart`, `auth_repository.dart`, `citas_repository.dart`, `secretaria_repository.dart` |
| Factory | Construcción tipada desde JSON/contratos Django | `lib/models/*.dart` (`fromJson`); `ApiException.fromBody`; `AppScope.create` |
| Observer | UI reacciona a cambios de estado | `ChangeNotifier` en `lib/viewmodels/*`; consumo en Views vía `Provider`/`Consumer` |
| Singleton (débil / app-scoped) | Un grafo DI por proceso | `AppScope` creado una vez en `main.dart` — **no** hay `getInstance()` clásico; documentar honestamente |

---

## ACTIVIDAD 6 — Cloud y seguridad integral  
**Puntuación:** 8 puntos · **Entrega:** 26 de noviembre de 2026

| # | Criterio oficial | Estado | Implementado | Probado | Documentado | Evidenciado | Archivos / evidencias | Prueba necesaria | Acción pendiente | Responsable |
|---|------------------|--------|--------------|---------|--------------------------|------------------------|------------------|------------------|-------------|
| 6.1 | API REST operativa | **Parcial** | Sí (cliente HTTP) | Smoke público 200; auth mutaciones **no** en prod | Sí | Parcial | `ApiClient`, services; smoke `/public/*`, `/health/` | Ambiente de prueba autorizado | Usar staging/local, no prod para writes | Equipo |
| 6.2 | JWT Bearer | **Parcial** | Sí | Parcial (código + 401 sin token) | Sí | Parcial | `api_client.dart` header `Authorization: Bearer` | Login real en staging | Cuentas de prueba | Dev |
| 6.3 | Interceptor 401 + refresh | **Parcial** | Sí | Unit no cubre refresh HTTP real | Parcial | No | `ApiClient._tryRefresh` → `POST /auth/token/refresh/` | Test MockClient 401→refresh→retry | Añadir test integración | Dev |
| 6.4 | Certificate Pinning SHA-256 | **Pendiente** | No | No | No | No | — | Pin leaf/backup; plan rotación | Implementar con `http` custom / IOClient; **nunca** desactivar TLS | Seguridad |
| 6.5 | Almacenamiento local cifrado Android | **Parcial** | Sí | No en dispositivo | Parcial | No | `flutter_secure_storage` + `AndroidOptions(encryptedSharedPreferences: true)` | Verificar Keystore en dispositivo | Evidencia MobSF/dispositivo | Dev |
| 6.6 | Aviso de privacidad | **Pendiente** | No en app | No | No | No | Backend tiene contenido legal público; mobile no lo muestra como flujo Opt-In | Pantalla/webview política | Consumir `/api/public/legal/` o `/contenido-legal/` | Dev |
| 6.7 | Consentimiento Opt-In explícito (inicialmente desactivado) | **Pendiente** | No | No | No | No | Backend exige `acepto_privacidad` en **registro** web; mobile no tiene UI Opt-In | Checkbox off por defecto | Implementar en registro/login gate | Dev |
| 6.8a | ARCO Acceso (consultar perfil) | **Parcial** | Sí (lectura) | Parcial | Parcial | No | `GET /api/perfil/` vía `AuthApiService.perfil()`; UI perfil cliente | Captura perfil | Completar | Dev |
| 6.8b | ARCO Rectificación (editar perfil) | **Pendiente** | API `PUT` existe en `ApiClient`; **UI no edita** | No | No | No | Backend `PerfilView` PUT; mobile solo GET | Formulario edición → PUT `/perfil/` | Implementar UI | Dev |
| 6.8c | ARCO Cancelación (eliminar cuenta) | **Cumple (falta fusionar backend)** | Sí: app (Perfil › Privacidad › Eliminar mi cuenta) y `POST /api/privacidad/cancelacion/` (backend PR #5): bloqueo inmediato y supresión a los 30 días | Sí: 10 pruebas Django, 12 de Flutter, E2E en emulador | Sí | Sí | `docs/evidencias/arco/2026-10-21-cancelacion/` | — | Fusionar backend PR #5 y programar `suprimir_cuentas_vencidas` (Cron de Render) | Dev |
| 6.8d | ARCO Oposición (Opt-Out) | **Pendiente** / parcial backend | No en mobile | No | No | No | Preferencia 2FA perfil existe; no Opt-Out marketing/datos genérico | Definir alcance Opt-Out con negocio | Coordinar contrato | Equipo |
| 6.9 | R8/ProGuard (`minifyEnabled`, `shrinkResources`, reglas) | **Pendiente** | No | No | No | No | `android/app/build.gradle.kts` release **sin** minify; firma debug | Activar minify + `proguard-rules.pro` | Distinto de `--obfuscate` Dart | Android |
| 6.10 | Ofuscación release | **Parcial** | Sí (`flutter build apk --release --obfuscate`) | Build OK | Sí | Parcial (APK+symbols) | `app-release.apk`; `build/symbols/*.symbols` | JADX/MobSF comparación | Guardar evidencias privadas | Dev |
| 6.11 | Evaluación JADX/MobSF | **Pendiente** | N/A | No | No | No | — | Informe MobSF/JADX | Ejecutar post-R8+obfuscate | Seguridad |
| 6.12 | Pruebas caja negra E2E | **Pendiente** | No | No | No | No | Sin `integration_test` E2E / Patrol | Flujos login/catálogo/secretaría en staging | Implementar | QA |
| 6.13 | Matriz Debug/Release | **Pendiente** | No formal | No | No | No | — | Tabla casos Debug vs Release | Crear en docs | QA |
| 6.14 | Registro de errores encontrados/corregidos | **Parcial** | Informal (auditoría/fase 3) | N/A | Parcial | No | Historial chat + EOCD path spaces, NDK | Bitácora formal `REGISTRO_ERRORES.md` | Crear registro | QA |

---

## ACTIVIDAD 7 — Publicación Google Play  
**Puntuación:** 2 puntos · **Entrega:** 26 de noviembre de 2026

| # | Criterio oficial | Estado | Implementado | Probado | Documentado | Evidenciado | Archivos / evidencias | Prueba necesaria | Acción pendiente | Responsable |
|---|------------------|--------|--------------|---------|--------------------------|------------------------|------------------|------------------|-------------|
| 7.1 | App en revisión o publicada | **Pendiente** | No | No | No | No | — | Consola Play | Solo con autorización | Product Owner |
| 7.2 | APK/AAB firmado correctamente | **Parcial** | APK release existe | Firmado **debug** | Sí (README advierte) | Parcial | `signingConfig = debug` en release | Keystore upload + AAB | Crear keystore; **no** sin autorización | Android |
| 7.3 | Firma de publicación (no debug) | **Pendiente** | No | No | Parcial | No | `build.gradle.kts` L35–38 | `flutter build appbundle` con key.properties | Autorización de clave | Android |
| 7.4 | Permisos Android justificados | **Parcial** | `INTERNET` | No justificación Play | Parcial | No | `AndroidManifest.xml` | Texto Play Data safety | Documentar por qué INTERNET | Dev |
| 7.5 | Diálogos runtime de permisos | **Pendiente** / N/A parcial | No hay permisos peligrosos hoy | N/A | No | No | Solo INTERNET (normal) | Si se agregan cámara/ubicación, diálogos | Evaluar al añadir features | Dev |
| 7.6 | Evidencias Google Play Console | **Pendiente** | No | No | No | No | — | Screenshots consola | Tras envío autorizado | Product Owner |

---

## Puntuación potencial (autodiagnóstico honesto)

| Actividad | Puntos | Estimación actual de acreditación | Comentario |
|-----------|--------|-----------------------------------|------------|
| 5 | 3 | Baja–media | Ramas sí; CI/SAST/DAST/colaboración no |
| 4 | 7 | Media | Código y tests unitarios sí; evidencia visual/integración/E2E no |
| 6 | 8 | Baja–media | JWT/secure storage/obfuscate parcial; pinning/R8/ARCO/E2E faltan |
| 7 | 2 | Baja | Sin Play ni firma release |

**Nota:** Estimación ≠ calificación del profesor. Nada se marca “Aceptado”.
