# Actividad 5 - GitFlow y CI/CD

Proyecto: Stylo Barber Connect Mobile (`/Movil`)
Repositorio oficial: `https://github.com/Gilberto625/MovilStyloBarberConect`
Fecha de entrega: 2026-10-22

Este documento registra evidencia y pendientes de la Actividad 5. No sustituye las capturas o enlaces reales de GitHub Actions y Pull Requests.

## Estado verificado localmente

Comandos ejecutados el 2026-10-06:

```powershell
git status --short --branch
git remote -v
git branch -a -vv
git log --all --decorate --graph --oneline --max-count=30
git shortlog -sne --all
```

Resultado observado:

| Elemento | Evidencia |
|----------|-----------|
| Remoto oficial | `origin` apunta a `https://github.com/Gilberto625/MovilStyloBarberConect.git` |
| Rama principal | `main` rastrea `origin/main` |
| Rama de integracion | `develop` existe local/remota, pero apunta al commit inicial `3e34e17` |
| Ramas feature | `feature/flutter-login`, `feature/flutter-citas`, `feature/flutter-usuarios` existen local/remotas, pero apuntan al commit inicial `3e34e17` |
| Historial visible | `main` contiene `102974a`, `ea42568`, `3e34e17` |
| Autores visibles | Solo aparecen variantes de Gilberto Hernandez con `20201171@uthh.edu.mx` |
| GitHub CLI | `gh` no esta instalado en este equipo, por lo que no se verifico historial de PRs desde CLI |

## Evaluacion GitFlow

Estrategia requerida:

```text
feature/* -> develop -> main
```

Estado actualizado tras verificar la sincronizacion del 2026-10-08:

| Requisito | Estado | Motivo |
|-----------|--------|--------|
| Ramas `main`, `develop`, `feature/*` | Parcial | Existen las ramas requeridas |
| Desarrollo real en `feature/*` | Pendiente | Las ramas feature no tienen commits distintos al primer commit |
| Integracion hacia `develop` | Base sincronizada | `origin/develop` en `e709d60` contiene `102974a`; falta integrar el PR CI |
| PR feature -> develop | No comprobado | Falta enlace/captura de PR |
| PR develop -> main | No comprobado | Falta enlace/captura de PR |
| Revision de cambios | No comprobado | Requiere evidencia de GitHub |
| Participacion de ambos integrantes | Pendiente | `git shortlog` solo muestra un autor |

No se debe declarar GitFlow como cumplido hasta que existan PRs reales y commits autenticos de ambos integrantes.

## Workflow implementado

Archivo:

```text
.github/workflows/ci.yml
```

Disparadores:

| Evento | Ramas |
|--------|-------|
| `pull_request` | `develop`, `main` |
| `push` | `develop`, `main` |
| `workflow_dispatch` | ejecucion manual |

Jobs:

| Job | Proposito | Politica de fallo |
|-----|-----------|-------------------|
| `flutter-quality` | `flutter pub get`, formato Dart, `flutter analyze`, `flutter test --coverage` | Falla si formato, analisis o pruebas fallan |
| `sast-semgrep` | Semgrep con reglas locales y reglas de registro | Falla si Semgrep encuentra hallazgos `ERROR` |

Artefactos:

| Artefacto | Contenido |
|-----------|-----------|
| `flutter-quality-evidence` | Version Flutter, log analyze, log tests, cobertura |
| `semgrep-sast-evidence` | Reporte JSON y SARIF de Semgrep |

Permisos del workflow:

```yaml
permissions:
  contents: read
  security-events: write
```

`security-events: write` se usa solo para subir SARIF a Code Scanning.

## SAST configurado

Herramienta: Semgrep.

Configuraciones:

| Fuente | Uso |
|--------|-----|
| `.semgrep.yml` | Reglas locales para Flutter/Android |
| `p/secrets` | Deteccion de secretos |
| `p/security-audit` | Reglas generales de seguridad |
| `p/owasp-top-ten` | Cobertura OWASP |

Politica:

| Severidad | Resultado |
|-----------|-----------|
| `ERROR` | Bloquea el pipeline |
| `WARNING` / `INFO` | Se reporta como evidencia para revision |

No se deben subir secretos ni credenciales al repositorio ni al workflow.

## DAST

DAST no queda completado por este workflow, porque requiere una aplicacion ejecutandose en un entorno controlado.

Procedimiento reproducible documentado en:

```text
docs/evaluacion/DAST_PROCEDIMIENTO.md
```

Estado actual: pendiente hasta contar con emulador/dispositivo, APK autorizado y backend de pruebas.

## Colaboracion requerida

Integrantes:

| Integrante | Evidencia requerida |
|------------|---------------------|
| Jorge Miguel Cayetano Garcia | Commits reales, rama feature propia, PR a `develop`, revision o aprobacion |
| Gilberto Hernandez Hernandez | Commits reales, rama feature propia, PR a `develop`, revision o aprobacion |

No se deben fabricar autorias ni reescribir historial para aparentar colaboracion.

## Tareas recomendadas para cerrar Actividad 5

1. Crear una rama `feature/devsecops-ci` desde `develop` o actualizar `develop` mediante PR controlado segun el flujo del equipo.
2. Subir estos cambios mediante PR a `develop`.
3. Esperar ejecucion verde de GitHub Actions.
4. Corregir cualquier fallo real de formato, analisis, pruebas o Semgrep.
5. Abrir PR `develop -> main` solo cuando el equipo lo autorice.
6. Guardar evidencias:
   - captura de ramas;
   - enlace de PR feature -> develop;
   - enlace de PR develop -> main;
   - captura del run verde de GitHub Actions;
   - artefactos `flutter-quality-evidence` y `semgrep-sast-evidence`;
   - salida `git shortlog -sne --all` con ambos autores cuando exista.

## Comandos sugeridos para publicar cambios

Preparacion verificada el 2026-10-08: `feature/devsecops-ci` fue creada desde
`102974a` (main), conservando los cambios locales. Tras la sincronizacion del
usuario, `origin/develop` apunta a `e709d60` y contiene `102974a`.
El historial propio y diff heredado de la feature estan vacios antes del commit CI.
Se conserva esta rama sin reescribir historial ni incluir cambios locales ajenos.

Registro y conjunto exacto propuesto: `VALIDACION_LOCAL_ACT5_2026-10-08.md`.
Estos comandos son para despues de resolver la base y revisar los cambios ajenos.

```powershell
git status --short --branch
git add -- .github/workflows/ci.yml .semgrep.yml docs/evaluacion/ACTIVIDAD_5_GITFLOW_CICD.md docs/evaluacion/DAST_PROCEDIMIENTO.md docs/evaluacion/POLITICA_CI_SAST.md docs/evaluacion/VALIDACION_LOCAL_ACT5_2026-10-08.md
git diff --cached --check
git diff --cached --stat
git diff --cached
git commit -m "ci: add mobile quality and sast workflow"
git push -u origin feature/devsecops-ci
```

Despues, abrir Pull Request en GitHub:

```text
feature/devsecops-ci -> develop
```

Cuando el PR este aprobado y con CI en verde, integrar a `develop`. Para `main`, abrir PR separado:

```text
develop -> main
```
