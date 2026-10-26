# Certificate pinning: evidencia (2026-10-21)

Diseño, pines y rotación: `docs/evaluacion/PINNING_ROTACION.md`.

| Caso (GH#38 / GH#39) | Esperado | Observado | Evidencia |
|---|---|---|---|
| Pin válido | La app conecta con el backend real usando solo las raíces fijadas | Emulador, build debug contra producción (solo lectura del catálogo público): carga logo, promociones y servicios | `01_produccion_con_pinning.png` |
| Pin válido (fuera de la app) | GET de lectura al backend con el contexto fijado | HTTP 200; certificado `onrender.com` emitido por GTS WE1, que encadena a GTS Root R4 | `verificar_pines.log` |
| Certificado no permitido | Un servidor con otra autoridad se rechaza en el handshake | `www.digicert.com` (raíz DigiCert): `CERTIFICATE_VERIFY_FAILED`, tanto en la app como en la herramienta | `02_otra_autoridad_rechazada.png`, `verificar_pines.log` |
| Certificado no permitido (prueba automática) | Servidor TLS local con autoridad efímera: con su autoridad responde; con pinning se rechaza | Control 200; con pinning `CERTIFICATE_VERIFY_FAILED` | `pinning_flutter-test.log` |
| Sin "confiar en todo" | No hay `badCertificateCallback` | Ninguno en `lib/`; si lo hubiera, la prueba anterior aceptaría el certificado | `lib/core/network/cliente_http.dart` |
| Debug y release separados | Release siempre fija; debug se puede apagar a propósito | Probado en `pinning_test.dart` (grupo "cuándo aplica") | `pinning_flutter-test.log` |
| Rotación | Primario y respaldos de dos autoridades, vencimientos y procedimiento | Tabla y procedimiento; workflow semanal `pinning.yml` | `docs/evaluacion/PINNING_ROTACION.md` |

En `02_otra_autoridad_rechazada.png` el error sale en texto técnico porque esta rama sale de `develop`. Con el PR #103 esa pantalla dice "No hay conexión con el servidor. Revisa tu internet e intenta de nuevo."
