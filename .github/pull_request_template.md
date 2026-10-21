<!--
Título: Conventional Commit, por ejemplo "feat(citas): …", "fix(red): …" o "docs: …".
Rama destino: feature/* y fix/* → develop (squash) · develop → release · release → main.
Nada entra directo a main, release ni develop.
-->

**Qué hace**
<!-- Qué cambia y por qué, en pocas líneas. Si toca el backend o la web, enlaza su PR. -->
-

**Issue y tarjeta**
Closes #
Tarjeta de Trello: GH#

**Pruebas**
<!-- Pruebas nuevas o actualizadas, con su ID (PM-U01, PI-01, PA-01…). Una prueba que se rompe se arregla, no se borra. -->
- [ ] `dart format --output=none --set-exit-if-changed .` sin cambios
- [ ] `flutter analyze` sin hallazgos
- [ ] `flutter test --coverage`: ___/___ en verde, cobertura ___ % (no baja)
- [ ] En emulador o dispositivo, si cambia algo que se ve o algo de red. Indica el ambiente: backend local o producción solo en lectura.

**Evidencia**
<!-- Capturas de antes y después, logs o carpeta en docs/evidencias/. Escribe "No aplica" si es solo código o documentación. -->
-

**Seguridad y privacidad**
- [ ] Sin secretos en el código, logs ni commits (`.env`, `key.properties`, `*.jks`, tokens, símbolos o `mapping.txt`)
- [ ] Sin `print`/`debugPrint` de tokens, OTP, contraseñas ni headers
- [ ] Nada que escriba datos se probó contra producción ni contra Neon
- [ ] Si cambia el contrato con Django, la tabla de endpoints de `README.MD` está al día

**Antes de fusionar**
- [ ] CI en verde: "Flutter quality gate" y "SAST Semgrep gate"
- [ ] Aprobado por el compañero
