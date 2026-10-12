# Politica CI/CD y SAST

Proyecto: Stylo Barber Connect Mobile.

## Objetivo

Bloquear integraciones inseguras o rotas antes de que lleguen a `develop` o `main`, sin exponer secretos ni ejecutar pruebas contra produccion.

## Ramas protegidas esperadas

| Rama | Politica recomendada |
|------|----------------------|
| `develop` | Requiere PR desde `feature/*` y CI en verde |
| `main` | Requiere PR desde `develop`, revision del equipo y CI en verde |

## Gates obligatorios

Los comandos hacen fallar el job. Bloquear el merge requiere ademas rulesets o
proteccion de rama con ambos checks obligatorios; esa configuracion remota no se
ha verificado. Generar cobertura no impone un porcentaje minimo de cobertura.

| Gate | Comando | Bloquea merge si falla |
|------|---------|------------------------|
| Dependencias Flutter | `flutter pub get` | Si |
| Formato Dart | `dart format --output=none --set-exit-if-changed .` | Si |
| Analisis estatico Flutter | `flutter analyze` | Si |
| Pruebas | `flutter test --coverage` | Si |
| SAST | `semgrep scan ... --severity ERROR --error` | Si |

## Politica Semgrep

| Hallazgo | Accion |
|----------|--------|
| `ERROR` | Bloquea pipeline. Corregir o justificar con cambio revisado |
| `WARNING` | Revisar antes del merge. Puede convertirse en tarea |
| `INFO` | Informativo, no bloqueante |

Los escaneos usan `--strict` para fallar ante errores de escaneo/configuracion.
La severidad `ERROR` de Semgrep es la politica del proyecto; no equivale por si
sola a una clasificacion universal de vulnerabilidad critica.

Los reportes Semgrep deben conservarse como artefacto de GitHub Actions y, si GitHub Code Scanning esta habilitado, subirse como SARIF.

## Secretos y credenciales

Prohibido:

- subir keystores;
- subir `key.properties`;
- escribir tokens en logs;
- imprimir JWT, refresh tokens o cabeceras `Authorization`;
- guardar credenciales en archivos versionados.

Permitido:

- usar `GitHub Actions secrets` para valores necesarios;
- usar entornos de pruebas;
- guardar reportes sin PII ni secretos.

## DAST

DAST no se ejecuta en este workflow porque requiere aplicacion corriendo y entorno autorizado.

La evidencia DAST se debe generar siguiendo:

```text
docs/evaluacion/DAST_PROCEDIMIENTO.md
```

No se debe atacar el backend productivo.

## Evidencia minima para el profesor

| Evidencia | Fuente |
|-----------|--------|
| Run verde de GitHub Actions | Pestaña Actions del repositorio |
| Logs de formato/analyze/test | Artefacto `flutter-quality-evidence` |
| Reporte Semgrep | Artefacto `semgrep-sast-evidence` |
| Pull Request feature -> develop | GitHub Pull Requests |
| Pull Request develop -> main | GitHub Pull Requests |
| Colaboracion de ambos integrantes | Commits y revisiones reales |
| Estado DAST | Reporte dinamico o documento de pendiente/bloqueo |
