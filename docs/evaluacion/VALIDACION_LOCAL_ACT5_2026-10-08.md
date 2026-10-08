# Actividad 5: preparacion local del 2026-10-08

## Git comprobado

- Remoto: https://github.com/Gilberto625/MovilStyloBarberConect.git
- HEAD inicial: main, 102974ade4aa7d5059fdf9c87b39f3a0b02d38ec.
- Rama creada: feature/devsecops-ci, desde ese HEAD; no existia local/remota.
- Tras la sincronizacion del usuario, origin/develop apunta a
  e709d60c9efac596128f691ac9f8311bacbcee94 y contiene 102974a (merge-base exit 0).
- Las tres ramas feature/flutter-* siguen en 3e34e17.
- Historial: 102974a, ea42568, 3e34e17; solo variantes del autor Gilberto.
- Antes del commit CI: origin/develop..HEAD y origin/develop...HEAD vacios.
- Preparacion inicial sin staging/publicacion; continuacion autorizada para
  commit y push de los seis archivos tras validar. Sin cambios de autoria.

## Resultados ejecutados

| Comando | Resultado | Exit code |
|---|---|---|
| dart format --output=none --set-exit-if-changed . | 33 archivos, 0 cambios | 0 |
| flutter analyze | No issues found! | 0 |
| flutter test | 19 pruebas aprobadas | 0 |
| flutter test --coverage | 19 pruebas aprobadas; coverage/lcov.info generado | 0 |
| Parser PyYAML sobre workflow y reglas | YAML valido; 2 jobs y 3 reglas locales | 0 |

LCOV: 317 de 1685 registros de linea cubiertos, 18.81%. El denominador solo
representa los archivos incluidos en el reporte, no acredita toda la aplicacion.
SHA256 de coverage/lcov.info:
7B8BD0F64BB1E28907346CF68C3F63E1D2664B2B57CDE8188588F2CA0D5ED3D4

Este registro resume salidas observadas localmente sobre un arbol con cambios;
no es un run GitHub Actions ni una validacion de un commit nuevo publicado.

## Conjunto exacto propuesto para commit

1. .github/workflows/ci.yml
2. .semgrep.yml
3. docs/evaluacion/ACTIVIDAD_5_GITFLOW_CICD.md
4. docs/evaluacion/DAST_PROCEDIMIENTO.md
5. docs/evaluacion/POLITICA_CI_SAST.md
6. docs/evaluacion/VALIDACION_LOCAL_ACT5_2026-10-08.md

Excluidos: .gitignore (log debug), README.MD (setup/build), android/.gitignore
(crash logs), android/app/build.gradle.kts (NDK local), android/gradle.properties
(memoria JVM). Tambien se excluyen los documentos generales no versionados
EVIDENCIAS_REQUERIDAS.md, MATRIZ_CUMPLIMIENTO.md y PLAN_ACTIVIDADES.md, cuyo
alcance incluye otras actividades. No se eliminan ni revierten.

## Workflow y limitaciones

Incluye pub get, formato, analyze, tests con coverage, Semgrep y artefactos
flutter-quality-evidence / semgrep-sast-evidence, retencion 30 dias.
Se agrego log de formato con pipefail, se retiro cache pip sin manifiesto de
dependencias y se agrego --strict a ambos escaneos Semgrep.

Semgrep no esta instalado localmente: reglas parseadas como YAML, pero su
validez semantica y sus hallazgos NO estan comprobados. No se declara SAST limpio.
DAST no se ejecuta en este workflow y sigue pendiente de entorno autorizado.
No se ha comprobado proteccion de ramas ni disponibilidad de carga SARIF en GitHub.
Flutter stable, Semgrep y reglas remotas no estan fijados a versiones inmutables.
Registrar versiones y revisar reportes antes de compartirlos para evitar secretos.
No hay umbral minimo de cobertura ni job de despliegue: este flujo acredita CI,
no un despliegue CD. Un fallo detiene pasos posteriores del mismo job.

## Bloqueo resuelto antes de publicar

Anteriormente develop estaba dos commits por detras, con 63 archivos heredados.
El usuario sincronizo main -> develop. Se verifico el remoto y se actualizo
explicitamente origin/develop: e709d60c9efac596128f691ac9f8311bacbcee94.
git merge-base --is-ancestor 102974a origin/develop devuelve 0.
La feature se conserva; el diff de tres puntos previo al commit esta vacio.

## Publicacion posterior

Tras resolver la base y revisar el staging, commit propuesto:
ci: add mobile quality and sast workflow

Push: git push -u origin feature/devsecops-ci

GitHub CLI no esta instalado. Alternativa PowerShell:

```powershell
Start-Process 'https://github.com/Gilberto625/MovilStyloBarberConect/compare/develop...feature/devsecops-ci?expand=1'
```

Si se instala y autentica gh con la identidad real del autor:

```powershell
gh pr create --repo Gilberto625/MovilStyloBarberConect --base develop --head feature/devsecops-ci --title "ci: add mobile quality and sast workflow" --body "Agrega quality gate Flutter, SAST Semgrep y evidencia de Actividad 5. Validacion local: formato limpio, analyze limpio y 19 pruebas aprobadas con cobertura. Pendiente validar GitHub Actions, reportes SAST y revision del equipo."
```

El push feature no dispara este workflow; el PR abierto hacia develop si.
Conservar URL del PR, URL del run, SHA probado, logs de cada gate, versiones,
LCOV, JSON/SARIF y ambos artefactos. Descargar antes de vencer la retencion.
URL PR: pendiente. URL run: pendiente. Resultado CI/SAST remoto: pendiente.

## Propuestas Trello condicionadas

- GH#02, GH#03, GH#06, GH#32, GH#33, GH#36: EN REVISION cuando exista
  PR con implementacion/documentacion completa para el alcance de cada tarjeta.
- GH#29: revisar al existir PR real feature -> develop y su diff correcto.
- GH#31, GH#34: EN PRUEBAS al ejecutar CI/Semgrep y revisar salidas reales;
  no mover a TERMINADO por configuracion solamente.
- GH#02, GH#03, GH#32, GH#33: de revision a pruebas con revision aceptada y
  ejecuciones; TERMINADO solo con criterios de tarjeta satisfechos y evidencias.
- GH#35: mantener EN PRUEBAS hasta revisar secretos y logging con evidencia.
- GH#01/GH#37: requieren flujo e historial comprobables; crear rama no basta.
- GH#05: sigue pendiente de contribucion autentica de Jorge y Gilberto.
- GH#36: distinguir SAST/DAST no acredita haber ejecutado DAST.

No se actualizaron tarjetas ni se cerraron Issues.
