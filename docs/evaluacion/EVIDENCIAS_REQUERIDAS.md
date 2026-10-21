# EVIDENCIAS REQUERIDAS — Instrumento Integral de Evaluación Móvil

Lista de artefactos que el equipo debe **poseer y poder mostrar** en cada entrega.  
Estado al **2026-10-06** según inspección de `/Movil` (sin afirmar aceptación del profesor).

Leyenda: ✅ disponible · ⚠️ parcial · ❌ ausente · 🔒 bloqueado externo · ❓ no comprobado

---

## Actividad 5 — 22 octubre (3 pts)

| Evidencia | Estado | Ubicación / nota |
|-----------|--------|------------------|
| Captura `git branch -a` con `main`, `develop`, `feature/*` | ⚠️ | Existen ramas; falta demostrar flujo PR merge |
| Historial `git shortlog -sn --all` con **2 autores** | ❌ | Solo Gilberto / `20201171@uthh.edu.mx` |
| Enlaces o capturas de PRs colaborativos | ❌ | — |
| Convención de commits (documento o ejemplos ≥5 commits claros) | ⚠️ | 2 commits semánticos + 1 genérico |
| Archivo `.github/workflows/*.yml` | ✅ | `.github/workflows/ci.yml` creado; pendiente ejecutar en GitHub |
| Run de GitHub Actions en verde (URL o captura) | ❌ | Pendiente hasta push/PR |
| Informe SAST (Semgrep/Sonar/Snyk) | ⚠️ | Semgrep configurado en CI; falta run y artefacto real |
| Informe DAST o análisis APK (MobSF) | ❌ | Procedimiento documentado; SAST ≠ DAST |
| Log `flutter analyze` / `flutter test` en CI | ⚠️ | Solo corridas locales previas |

**Criterio de “listo para entregar Act. 5”:** ramas usadas en PRs + 2 autores + CI con analyze/test + al menos un informe SAST + evidencia DAST o pendiente justificado, etiquetado correctamente.

---

## Actividad 4 — 29 octubre (7 pts)

| Evidencia | Estado | Ubicación / nota |
|-----------|--------|------------------|
| Capturas/video pantallas Invitado | ❌ / ❓ | Código sí; UI Android no acreditada |
| Capturas Cliente / Secretaría | ❌ / ❓ | Idem |
| Diagrama MVVM + capas | ⚠️ | Descrito en README; falta diagrama formal |
| Documento de patrones (Singleton, Factory, Repository, Observer) con paths | ❌ | Crear a partir de matriz |
| `flutter test` ≥ unit VM/Repo/Models | ⚠️ | 19 tests locales; falta CI |
| Pruebas de integración (mock HTTP o `integration_test`) | ❌ | — |
| Evidencia navegación por roles | ⚠️ | Código `app_routes.dart`; sin demo device |
| Checklist UX (SafeArea, overflow, 360×800) firmado | ❌ | — |
| APK debug instalable | ✅ | `build/app/outputs/flutter-apk/app-debug.apk` (~153 MB) |

---

## Actividad 6 — 26 noviembre (8 pts)

| Evidencia | Estado | Ubicación / nota |
|-----------|--------|------------------|
| Smoke API REST (health/públicos) | ⚠️ | Ejecutado en fase 3; guardar log fechado |
| Captura JWT Bearer / login staging | ❌ | No usar prod para demos sensibles |
| Prueba 401 → refresh → retry | ⚠️ | Código en `api_client.dart`; falta test/evidencia |
| Config Certificate Pinning + doc rotación pines | ❌ | — |
| Prueba pin inválido rechaza conexión | ❌ | — |
| Evidencia `flutter_secure_storage` / Keystore | ⚠️ | Código; falta captura dispositivo/MobSF |
| Pantalla aviso de privacidad | ❌ | — |
| Opt-In desactivado por defecto (captura) | ❌ | — |
| ARCO Acceso (perfil) | ⚠️ | UI lectura parcial |
| ARCO Rectificación (editar + PUT) | ❌ | Backend PUT existe; UI no |
| ARCO Cancelación (eliminar cuenta) | 🔒 | **Sin endpoint** Django — evidencia = documento de bloqueo |
| ARCO Oposición / Opt-Out | ❌ | Definir alcance |
| `minifyEnabled` + `shrinkResources` + `proguard-rules.pro` | ✅ | R8 activo: 95 % de clases renombradas. `docs/evidencias/estatico-2026-10-21/` |
| Comando y log `--obfuscate --split-debug-info` | ✅ | Antes y después de `libapp.so` (7.41 → 6.16 MB; identificadores a 0) en `docs/evidencias/estatico-2026-10-21/` |
| Informe JADX (antes/después ofuscación) | ⚠️ | Mismo antes/después con herramientas del SDK; faltan capturas de JADX-GUI |
| Informe MobSF release | ❌ | — |
| Suite E2E caja negra + resultados | ❌ | — |
| Matriz Debug vs Release | ❌ | — |
| Bitácora errores encontrados/corregidos | ⚠️ | Informal; formalizar `REGISTRO_ERRORES.md` |

**Importante:** conservar `build/symbols` **fuera del repo público** (ya en `.gitignore`).

---

## Actividad 7 — 26 noviembre (2 pts)

| Evidencia | Estado | Ubicación / nota |
|-----------|--------|------------------|
| Keystore de publicación (privado) | ❌ | No crear sin autorización |
| `key.properties` gitignored | ❌ | — |
| AAB/APK firmado release (no debug) | ❌ | Hoy `signingConfig debug` |
| Captura Play Console (borrador/revisión/publicado) | ❌ | — |
| Justificación permiso INTERNET / Data safety | ❌ | — |
| Política de privacidad URL en ficha | ❌ | — |
| Diálogos runtime (si aplica) | ❓ | Solo INTERNET hoy |

---

## Artefactos técnicos ya generados (útiles como base)

| Artefacto | Ruta aproximada | Uso académico |
|-----------|-----------------|---------------|
| APK debug | `build/app/outputs/flutter-apk/app-debug.apk` | Act. 4 / MobSF preliminar |
| APK release ofuscado Dart | `build/app/outputs/flutter-apk/app-release.apk` | Act. 6 (insuficiente solo) |
| Symbols ofuscación | `build/symbols/*.symbols` | Privado; Act. 6 |
| README técnico | `README.MD` | Soporte |
| Matriz / plan | `docs/evaluacion/*` | Esta carpeta |

---

## Cómo archivar evidencias (recomendación)

```text
docs/evaluacion/evidencias/
  act5_cicd/
  act4_ui_arquitectura/
  act6_seguridad/
  act7_play/
```

Reglas:

1. No subir keystores, tokens, OTP ni PII de clientes reales.
2. Preferir ambiente de **prueba**.
3. Nombrar archivos con fecha: `2026-10-22_actions_ci_green.png`.
4. Cada evidencia debe enlazarse en la matriz (columna Evidencia).

---

## PDF del instrumento

| Ítem | Estado |
|------|--------|
| PDF “Instrumento Integral de Evaluación Móvil” en el workspace | ❓ **No localizado** |
| Acción | Adjuntar PDF a `docs/evaluacion/instrumento/` cuando esté disponible y **revalidar** ponderaciones literales |

Si el PDF difiere de esta consigna, actualizar la matriz antes de la entrega del 22 de octubre.
