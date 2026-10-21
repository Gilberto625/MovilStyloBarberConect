# Almacenamiento cifrado en el dispositivo (6.5)

Fecha: 2026-10-20. Emulador Android, build debug (`run-as` solo funciona en debug), sesión iniciada con la cuenta de prueba de secretaría del backend local.

Configuración: `SecureTokenStorage` usa `flutter_secure_storage` con `AndroidOptions(encryptedSharedPreferences: true)`: Jetpack Security cifra nombres (AES-256-SIV) y valores (AES-256-GCM) con una llave guardada en el Android Keystore.

## `FlutterSecureStorage.xml`: 6 entradas

Las entradas 1 y 2 son los *keysets* de Jetpack Security (nombres `__androidx_security_crypto_encrypted_prefs_*`), cifrados a su vez con la llave maestra del Android Keystore. Las entradas 3 a 6 son los datos de sesión: nombre y valor cifrados.

| # | Largo del nombre | Largo del valor | Nombre legible | Valor legible |
|---|---|---|---|---|
| 1 | 55 | 484 | no | no |
| 2 | 57 | 418 | no | no |
| 3 | 124 | 364 | no | no |
| 4 | 120 | 68 | no | no |
| 5 | 120 | 188 | no | no |
| 6 | 124 | 364 | no | no |

- Prefijos de JWT (`eyJ`) en texto plano: **0**.
- Nombres de clave legibles (`access_token`, `refresh_token`): **0**.

## `FlutterSecureKeyStorage.xml`: 1 entradas

| # | Largo del nombre | Largo del valor | Nombre legible | Valor legible |
|---|---|---|---|---|
| 1 | 60 | 353 | no | no |

- Prefijos de JWT (`eyJ`) en texto plano: **0**.
- Nombres de clave legibles (`access_token`, `refresh_token`): **0**.

Cómo se generó: `adb shell run-as <paquete> cat shared_prefs/…` y un script que solo cuenta longitudes y busca texto legible; no guarda valores.

Conclusión: la sesión existe en el dispositivo, pero ni los nombres de las claves ni los tokens aparecen en claro. Ningún valor se copió a este reporte.
