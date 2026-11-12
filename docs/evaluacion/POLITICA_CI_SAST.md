# Política de CI/CD y SAST (GH#32, GH#03)

Proyecto: Stylo Barber Connect Mobile. Revisión: **2026-11-11**, leída de `.github/workflows/ci.yml`, `tool/coverage_gate.sh`, `.semgrep.yml`, la protección de ramas en GitHub y los runs citados.

## Objetivo

Bloquear integraciones inseguras o rotas antes de que lleguen a `develop` o `main`, sin exponer secretos ni ejecutar pruebas contra producción.

## Cuándo corre `ci.yml`

- `pull_request` hacia `develop`, `release` y `main`.
- `push` a `develop`, `release` y `main`.
- `workflow_dispatch` (manual). Con la casilla `build_release` también compila el APK release ofuscado.
- `concurrency` con `cancel-in-progress`: un push nuevo a la misma rama cancela el run anterior.

## Toolchain fijo

Los tres workflows (`ci.yml`, `release.yml` y `pinning.yml`) instalan **Flutter 3.47.9** del canal `stable` (`flutter-version: 3.47.9`).

Antes solo decían `channel: stable`. El 2026-11-12 (UTC; noche del 11-nov en México) el push del merge del PR #125 tomó Flutter 3.50.0 y `flutter analyze` falló con 58 avisos de deprecación de `package:flutter/material.dart`. El código era el mismo que había pasado en el PR con 3.47.9 (ERR-18 en `REGISTRO_ERRORES.md`). El PR #127 fijó la versión.

| Run | Evento | Flutter | Resultado |
|---|---|---|---|
| [43135262264](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/43135262264) | `push` a `develop` (merge del PR #125, `b04e63c`) | 3.50.0 | **Falló** "Flutter quality gate" en `Analyze Flutter code`: "58 issues found". Las pruebas y la cobertura no llegaron a correr. "SAST Semgrep gate" pasó |
| [43146040237](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/43146040237) | `pull_request` del PR #128 (`feature/accesibilidad-ambientes`), después del PR #127 | 3.47.9 | **Verde.** `flutter analyze`: "No issues found!". 538 pruebas aprobadas. Cobertura 80.80 % (5703/7058). Semgrep: 0 hallazgos |

Actualizar Flutter es una decisión del equipo. Se hace en un PR propio que cambie la versión en los tres workflows y deje `flutter analyze` limpio con la versión nueva.

## Gates: qué hace fallar el pipeline

Hay dos jobs obligatorios en cada PR y en cada push. Un tercero es manual.

### Job "Flutter quality gate" (`flutter-quality`)

Cada paso corre con `set -o pipefail`. Si un comando falla, el paso falla y el job queda en rojo.

| # | Paso | Comando | Falla si… |
|---|---|---|---|
| 1 | Dependencias | `flutter pub get` | No se resuelven las dependencias de `pubspec.yaml` / `pubspec.lock` |
| 2 | Formato | `dart format --output=none --set-exit-if-changed .` | Algún archivo `.dart` no tiene el formato de `dart format` |
| 3 | Análisis estático | `flutter analyze` | Hay **cualquier** incidencia, incluidos los avisos `info`. Así falló el run 43135262264 |
| 4 | Pruebas | `flutter test --coverage --reporter expanded` | Falla una prueba |
| 5 | Cobertura mínima | `bash tool/coverage_gate.sh 55` | La cobertura de líneas de `coverage/lcov.info` es **menor a 55 %**, o el archivo no existe o no tiene líneas medidas |
| 6 | Evidencia | `actions/upload-artifact` (siempre, aunque falle) | No hace fallar el job. Sube `flutter-quality-evidence` (logs, `lcov.info`) por 30 días |

El mínimo de cobertura está en el propio `ci.yml` (`coverage_gate.sh 55`). El script dice que sube por hito (55 → 60 → 70). Hoy sigue en 55 % y la cobertura real es mayor: 81.15 % en el run [43154349514](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/43154349514) del PR #129 (539 pruebas aprobadas).

### Job "SAST Semgrep gate" (`sast-semgrep`)

| # | Paso | Qué hace | Falla si… |
|---|---|---|---|
| 1 | Escaneo de reporte | `semgrep scan --strict` con `.semgrep.yml`, `p/secrets`, `p/security-audit` y `p/owasp-top-ten`. Guarda JSON | Hay un error de configuración o de escaneo (`--strict`). Los hallazgos **no** lo hacen fallar |
| 2 | Política bloqueante | El mismo escaneo con `--severity ERROR --error`. Guarda SARIF | Hay **al menos un hallazgo de severidad ERROR** |
| 3 | SARIF a Code Scanning | `upload-sarif` con `continue-on-error: true` | No hace fallar el job. Si Code Scanning no está disponible, deja un aviso en el resumen |
| 4 | Evidencia | Sube `semgrep-sast-evidence` (JSON y SARIF) por 30 días | No hace fallar el job |

Reglas propias de `.semgrep.yml`, las tres de severidad ERROR:
- `flutter-dangerous-bad-certificate-callback`: prohíbe `badCertificateCallback`.
- `flutter-token-print`: prohíbe `print`/`debugPrint` de tokens, `Authorization`, `Bearer`, JWT o refresh.
- `android-cleartext-release-config`: prohíbe `usesCleartextTraffic="true"` en el manifiesto principal y en el de release.

### Job "Release build check (R8 + obfuscate)" (`build-release`)

Solo corre con `workflow_dispatch` y `build_release` marcado. Falla si no se genera `mapping.txt` de R8 o si `libapp.so` conserva nombres de clases Dart (`AuthViewModel`, `SecretariaGestionViewModel`, `_tryRefresh`). No sube el APK, los símbolos ni `mapping.txt`, porque el repo es público.

## Protección de ramas (verificada el 2026-11-11)

Consultada con `gh api repos/Gilberto625/MovilStyloBarberConect/branches/<rama>/protection`.

| Rama | Checks obligatorios | Rama al día con la base | Aprobaciones | Aplica a administradores |
|---|---|---|---|---|
| `develop` | "Flutter quality gate" y "SAST Semgrep gate" | Sí | 1 | Sí |
| `main` | "Flutter quality gate" y "SAST Semgrep gate" | Sí | 1 | Sí |
| `release` | Sin protección (la API responde "Branch not protected") | — | — | — |

Con esto, un PR con un gate en rojo no se puede fusionar en `develop` ni en `main`. El push posterior al merge vuelve a correr la CI. Así se detectó ERR-18: el gate no lo frenó en el PR, porque en el PR la versión de Flutter era otra.

## Política Semgrep

| Severidad del hallazgo | Acción |
|---|---|
| `ERROR` | Bloquea el pipeline. Se corrige, o se justifica con un cambio revisado en un PR |
| `WARNING` | No bloquea. Se revisa antes del merge y puede convertirse en tarea |
| `INFO` | Informativo, no bloquea |

- La severidad `ERROR` de Semgrep es la política del proyecto. No equivale por sí sola a una clasificación universal de vulnerabilidad crítica.
- **Falsos positivos y excepciones:** hoy no hay ninguna. No hay comentarios `nosemgrep` ni archivo `.semgrepignore` en el repo. Si hace falta una, se agrega con un comentario que explique por qué y se anota en esta sección.
- **Hallazgos no bloqueantes sin clasificar:** en el run 43154349514 del PR #129, el escaneo de reporte encontró **27 hallazgos** de severidad menor a ERROR. El paso bloqueante encontró 0. En el run 43146040237 el escaneo de reporte tenía 0, así que los 27 vienen de lo que agrega o cambia el PR #129 (los archivos escaneados pasaron de 216 a 246). El detalle está en el JSON del artefacto `semgrep-sast-evidence` de ese run. **Falta revisarlos y clasificarlos** aquí.
- El log de Semgrep avisa que los `include` de `android-cleartext-release-config` cambiarán de interpretación (anclados a la raíz). Hoy la regla funciona; conviene escribir las rutas como `/android/app/src/...` para fijar el comportamiento.

## Secretos y credenciales

Prohibido:
- subir keystores;
- subir `key.properties`;
- escribir tokens en logs;
- imprimir JWT, refresh tokens o cabeceras `Authorization`;
- guardar credenciales en archivos versionados.

Permitido:
- usar los secretos de GitHub Actions para los valores necesarios (`release.yml` usa los 5 de firma y símbolos);
- usar entornos de pruebas;
- guardar reportes sin datos personales ni secretos.

## DAST

DAST no corre en este workflow: necesita la aplicación en ejecución y un entorno autorizado. Se ejecutó a mano el 2026-11-11 con OWASP ZAP contra el backend local: `DAST_PROCEDIMIENTO.md` y `DAST_RESULTADOS.md`. Nunca contra producción.

## Evidencia para el profesor

| Evidencia | Dónde |
|---|---|
| Run en verde | [43146040237](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/43146040237) (PR #128) y [43154349514](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/43154349514) (PR #129) |
| Run en rojo y su causa | [43135262264](https://github.com/Gilberto625/MovilStyloBarberConect/actions/runs/43135262264): `flutter analyze` con Flutter 3.50.0 (ERR-18) |
| Logs de formato, analyze, pruebas y cobertura | Artefacto `flutter-quality-evidence` de cada run (se conserva 30 días) |
| Reporte Semgrep | Artefacto `semgrep-sast-evidence` (JSON y SARIF, 30 días) |
| Protección de ramas | Tabla de arriba |
| PR feature → develop y develop → main | Pestaña Pull requests de GitHub |

## Pendiente

- **Fallo controlado en un PR:** abrir un PR de prueba con una prueba rota o un `print(token)` y capturar que queda bloqueado. El run 43135262264 sí es un fallo real, pero fue en un push después del merge, no en un PR bloqueado.
- **Clasificar los 27 hallazgos no bloqueantes** de Semgrep del PR #129.
- **Proteger `release`** con los mismos checks, o documentar por qué no.
- **Descargar los artefactos** de los runs citados antes de que venzan (30 días) si se quieren conservar para la entrega.
