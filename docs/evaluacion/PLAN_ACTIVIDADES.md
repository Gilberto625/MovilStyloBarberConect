# PLAN DE ACTIVIDADES — Octubre y Noviembre 2026

Basado en el Instrumento Integral de Evaluación Móvil y en el estado comprobado de `/Movil` (ver `MATRIZ_CUMPLIMIENTO.md`).

**Reglas del plan**

- Solo cambios en `/Movil` salvo autorización explícita de backend.
- No commits/push automáticos.
- No fabricar historial Git ni contribuciones.
- No operaciones destructivas ni escrituras en producción.
- Distinguir Flutter `--obfuscate` de R8/ProGuard.

---

## Prioridad 1 — Actividad 5 (entrega 22 oct · 3 pts)

### Objetivo
Dejar el repositorio evaluable: GitFlow usable, CI real, SAST en pipeline, evidencia de colaboración, y un camino claro a DAST (MobSF) **sin fingir** que SAST = DAST.

### Orden de trabajo

| Semana | Fecha meta | Tareas | Resultado esperable | Evidencia |
|--------|------------|--------|---------------------|-----------|
| W1 | 08–12 oct | 1) Inventario ramas vs `main`/`develop`. 2) Documentar convención GitFlow en `docs/evaluacion/`. 3) Segundo integrante: primer PR real a `develop` desde `feature/*` | Historial de **2 autores** verificable | `git shortlog`, captura PR |
| W1 | 10–14 oct | Subir `.github/workflows/ci.yml` por PR y ejecutar `flutter pub get`, `analyze`, `test` en Ubuntu | Pipeline verde en PR | Actions run URL / capturas |
| W2 | 14–18 oct | Añadir job **SAST** (recomendado: **Semgrep** OSS en CI; alternativa SonarCloud si hay cuenta) | Fallos critical bloquean merge | Log Semgrep/Sonar |
| W2 | 18–20 oct | Generar APK debug en CI o local; subir a **MobSF** (DAST/estático móvil) | Informe MobSF (esto **no** se vende como “solo SAST”) | PDF/HTML MobSF |
| W2 | 20–22 oct | Cerrar PRs feature→develop→main según GitFlow; checklist de entrega Act. 5 | Repo listo para revisión | Capturas branches + CI |

### Primera tarea concreta (empezar ya)
**Publicar por PR el workflow `.github/workflows/ci.yml`** que ejecuta formato, `flutter analyze`, `flutter test --coverage` y Semgrep en `pull_request`/`push` a `develop`/`main`.  
En paralelo: el segundo integrante debe abrir un PR real con su identidad Git.

### No hacer en Act. 5
- No inventar commits del compañero.
- No marcar DAST cumplido solo con Semgrep.
- No subir secretos (keystore, tokens) al workflow.

---

## Prioridad 2 — Actividad 4 (entrega 29 oct · 7 pts)

### Objetivo
Acreditar pantallas, MVVM, patrones justificados y pruebas de caja blanca + navegación evidenciada.

### Orden de trabajo

| Semana | Fecha meta | Tareas | Resultado | Evidencia |
|--------|------------|--------|-----------|-----------|
| W3 | 22–24 oct | Documento `PATRONES.md`: Singleton app-scoped, Factory, Repository, Observer con rutas de archivo | Patrones explícitos y honestos | Markdown + capturas código |
| W3 | 23–26 oct | Ampliar tests unitarios Models/VM/Repo; añadir **integración** con `MockClient` (401 refresh, catálogo) | Suite >19 tests, con integración HTTP mock | `flutter test` log |
| W3 | 25–28 oct | QA visual en emulador `Pixel_3a_API_36...` o dispositivo: invitado, login UI, cliente, secretaría | Navegación sin crashes visibles | Video/capturas 360×800 |
| W4 | 28–29 oct | Empaquetar evidencia Act. 4 (diagramas MVVM, tests, UI) | Entregable académico | Carpeta evidencias |

### Patrones — reglas
- **Repository / Factory / Observer:** ya existen; documentar y probar.
- **Singleton:** documentar `AppScope` como instancia única de aplicación; no crear un `Singleton` vacío solo para la rúbrica.

---

## Prioridad 3 — Actividad 6 (entrega 26 nov · 8 pts)

### Objetivo
Seguridad integral alineada a Django: pinning, R8, ARCO factible, E2E en staging, matriz Debug/Release.

### Orden (noviembre)

| Fase | Fecha meta | Tareas | Notas |
|------|------------|--------|-------|
| N1 | 01–07 nov | Opt-In privacidad (checkbox off) + pantalla aviso (legal público) | Usar endpoints públicos legales existentes |
| N1 | 01–07 nov | ARCO Acceso/Rectificación: UI editar perfil → `PUT /api/perfil/` | Contrato ya existe en backend |
| N1 | 05–10 nov | Documentar **bloqueo ARCO Cancelación**: no hay DELETE cuenta en Django | Solicitud formal al backend; sin inventar API |
| N2 | 08–15 nov | Certificate Pinning SHA-256 + pin de respaldo + procedimiento rotación | Staging primero; riesgo de outage si el cert rota |
| N2 | 10–18 nov | Activar R8: `minifyEnabled`, `shrinkResources`, `proguard-rules.pro` | Independiente de `--obfuscate` |
| N2 | 15–20 nov | Release: `--obfuscate --split-debug-info` **y** R8; guardar symbols privados | Comparar con JADX/MobSF |
| N3 | 18–24 nov | E2E caja negra (staging); matriz Debug/Release; bitácora errores | Sin writes a producción |
| N3 | 24–26 nov | Empaquetar evidencias Act. 6 | Informes MobSF/JADX |

### Certificate Pinning — checklist obligatorio
1. Extraer SHA-256 del certificado/public key del host real.
2. Incluir **pin primario + backup**.
3. Documentar renovación (90 días antes de expiración).
4. Probar fallo controlado (pin incorrecto → error, no bypass).
5. **Nunca** `badCertificateCallback: (_) => true`.

### Bloqueos backend conocidos
| Necesidad | Estado Django | Acción |
|-----------|---------------|--------|
| Eliminar cuenta (ARCO Cancelación) | **No existe** endpoint en `urls.py` | Pedir endpoint (p. ej. soft-delete) sin implementarlo aquí |
| Opt-Out amplio | Parcial (2FA preferencia) | Definir alcance con negocio |
| Ambiente staging | Depende del equipo | Obligatorio para E2E writes |

---

## Prioridad 4 — Actividad 7 (entrega 26 nov · 2 pts)

### Objetivo
Publicación o envío a revisión con firma de **release**, no debug.

### Orden
1. Autorización escrita para crear keystore de publicación.
2. `key.properties` local (gitignored) + `signingConfigs.release`.
3. `flutter build appbundle --release --obfuscate --split-debug-info=... --strip` (recomendado).
4. Justificar permiso `INTERNET` en Play Console / Data safety.
5. Subir AAB, completar ficha, capturas, política de privacidad URL.
6. Guardar evidencias de consola (sin compartir secretos).

**No hacer sin autorización:** generar clave definitiva, publicar, ni cambiar cuenta Play.

---

## Calendario resumido

```text
OCT 2026
|08----12| CI + Semgrep start          [Act 5]
|14----18| MobSF + GitFlow PRs         [Act 5]
|20----22| Entrega Actividad 5
|22----29| Patrones, tests, UI device  [Act 4]
|29------| Entrega Actividad 4

NOV 2026
|01----10| Privacidad Opt-In + ARCO A/R [Act 6]
|08----18| Pinning + R8                 [Act 6]
|15----24| E2E staging + MobSF/JADX     [Act 6]
|18----26| Firma release + Play prep    [Act 7]
|26------| Entrega Actividades 6 y 7
```

---

## Primera tarea concreta (siguiente acción de implementación)

Cuando se autorice publicar cambios:

1. Crear rama `feature/devsecops-ci`.
2. Subir `.github/workflows/ci.yml`, `.semgrep.yml` y documentos de Actividad 5.
3. Abrir PR a `develop` y guardar evidencia del run.
4. **No** tocar backend ni publicar en Play.
