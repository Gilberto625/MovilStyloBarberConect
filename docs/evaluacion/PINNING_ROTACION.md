# Certificate pinning y rotación de pines (GH#38, GH#39)

## Qué se fija y por qué
- **Solo se confía en raíces fijadas.** El cliente HTTP de la API (`lib/core/network/cliente_http.dart`) usa `SecurityContext(withTrustedRoots: false)` con cinco raíces públicas (`lib/core/network/certificados_raiz.dart`). Una conexión HTTPS cuya cadena no termine en una de ellas se corta en el handshake, **antes** de mandar el token. La verificación del nombre del host sigue activa.
- **Por qué la raíz y no el certificado del servidor.** Render renueva el certificado de `*.onrender.com` cada ~90 días; el actual vence el 2026-12-20. Si se fijara ese certificado o su intermedia, cada renovación dejaría a la app sin conexión hasta publicar otra versión. Fijar la raíz aguanta las renovaciones y aun así bloquea cualquier otra autoridad, incluidas las que un proxy de interceptación instala en el teléfono.
- **Por qué en Dart y no en `network_security_config.xml`.** Flutter hace sus conexiones con `dart:io` y BoringSSL, no con la pila de red de Android, así que la configuración XML no le aplica.
- **Alcance:** solo la API (`ApiClient`), que es la que lleva el JWT. Las imágenes y los enlaces externos usan la validación normal del sistema.

## Pines

| Rol | Raíz | Clave | SHA-256 del certificado (DER) | Pin SPKI SHA-256 (base64) | Vence |
|---|---|---|---|---|---|
| **Primario** (cadena actual: hoja → WE1 → GTS Root R4) | GTS Root R4 | ECDSA P-384 | `349dfa4058c5e263123b398ae795573c4e1313c83fe68f93556cd5e8031b3c7d` | `mEflZT5enoR1FuXLgYYGqnVEoZvmf9c2bVBpiOjYQ0c=` | 2036-06-22 |
| Respaldo, misma autoridad | GTS Root R1 | RSA 4096 | `d947432abde7b7fa90fc2e6b59101b1280e0e1c7e4e40fa3c6887fff57a7f4cf` | `hxqRlPTu1bMS/0DITB1SSu0vd4u/8l8TjPgfaAp63Gc=` | 2036-06-22 |
| Respaldo, misma autoridad | GTS Root R3 | ECDSA P-384 | `34d8a73ee208d9bcdb0d956520934b4e40e69482596e8b6f73c8426b010a6f48` | `QXnt2YHvdHR3tJYmQIr0Paosp6t/nggsEGD4QJZ3Q0g=` | 2036-06-22 |
| Respaldo, otra autoridad | ISRG Root X1 (Let's Encrypt) | RSA 4096 | `96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6` | `C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M=` | 2035-06-04 |
| Respaldo, otra autoridad | ISRG Root X2 (Let's Encrypt) | ECDSA P-384 | `69729b8e15a86efc177a57afb7171dfc64add28c2fca8cf1507e34453ccb1470` | `diGVwiVYbubAI3RW4hB9xU8e/CH2GnkuvVFZE8zmgzI=` | 2040-09-17 |

- **Respaldo de otra autoridad:** si Render pasa de Google Trust Services a Let's Encrypt, la app sigue funcionando sin una versión nueva.
- **Origen:** cada certificado se comparó por SHA-256 entre dos fuentes: el bundle de Mozilla (`certifi` 2026.06.17) y el sitio oficial de la autoridad (`pki.goog/repo/certs`, `letsencrypt.org/certs`). `test/pinning_test.dart` vuelve a comprobar la huella de cada PEM en cada corrida.
- **Se dejaron fuera** GTS Root R2 y GlobalSign Root CA: las dos fuentes no coincidieron. La cadena actual valida sin ellas; lo comprueba `tool/verificar_pines.dart` contra el backend real.
- **No hay claves privadas en el repo:** son certificados públicos de autoridades. La prueba con servidor TLS genera una autoridad y una clave efímeras con openssl al correr y las borra al terminar.

## Debug y release

| Build | API por HTTPS | API por HTTP (backend local, `10.0.2.2`) |
|---|---|---|
| Release | Pinning **siempre**; `DESACTIVAR_PINNING` no tiene efecto | No aplica (sin TLS) |
| Debug / profile | Pinning activo; se puede apagar con `--dart-define=DESACTIVAR_PINNING=true` para un staging con otra autoridad | No aplica |

Nunca hay `badCertificateCallback` ni "confiar en todo". Un certificado no permitido siempre se rechaza.

## Cómo se comprueba
- `test/pinning_test.dart` (10 pruebas):
  - Huellas de las raíces y que ninguna venza antes de 2030.
  - Reglas de debug y release.
  - Servidor TLS local con un certificado de otra autoridad. Control: confiando en esa autoridad responde 200. Con pinning se rechaza con `CERTIFICATE_VERIFY_FAILED`.
- `dart run tool/verificar_pines.dart`: el backend de producción responde con las raíces fijadas (un GET de lectura a `/api/public/servicios/`) y `www.digicert.com` (raíz DigiCert, no fijada) se rechaza.
- `.github/workflows/pinning.yml` corre esa verificación **cada lunes** y a mano. Si falla, GitHub avisa por correo.
- Evidencia en el emulador: `docs/evidencias/pinning-2026-10-21/`.

## Rotación

**Cuándo revisar**
- Falla el workflow semanal, o avisa que el certificado del backend vence en menos de 21 días.
- Render anuncia un cambio de autoridad.
- Una raíz fijada se acerca a su vencimiento. La primera es ISRG Root X1, en 2035.

**Procedimiento**
1. Ver la cadena nueva: `openssl s_client -connect backendstylobarberconect-lo71.onrender.com:443 -servername backendstylobarberconect-lo71.onrender.com -showcerts`.
2. Si la raíz ya está en la tabla, no hay que hacer nada; la renovación es transparente.
3. Si no está:
   - Bajar el PEM de la raíz de **dos fuentes** (sitio oficial de la autoridad y bundle de Mozilla) y comparar su SHA-256.
   - Agregarlo a `certificados_raiz.dart` con su huella, su pin SPKI y su vencimiento.
   - Actualizar esta tabla.
   - Correr `flutter test test/pinning_test.dart` y `dart run tool/verificar_pines.dart`.
4. Publicar esa versión **antes** de que el backend cambie. Las raíces viejas se quedan mientras alguna versión soportada las necesite.
5. Quitar una raíz solo cuando ninguna versión en uso dependa de ella.

**Si el backend ya cambió y la app publicada no conecta:** la app muestra "No hay conexión con el servidor" y no expone ningún dato. Se publica una versión urgente con la raíz nueva. Con dos autoridades fijadas (GTS y Let's Encrypt), el riesgo queda acotado a un cambio a una tercera autoridad. Es un riesgo aceptado y documentado.

## Lo que no cubre
En un teléfono con root y Frida (GH#50), el pinning se puede desactivar en memoria. Protege contra la interceptación en teléfonos normales, incluso con una autoridad instalada por el usuario. No sustituye la seguridad del servidor.
