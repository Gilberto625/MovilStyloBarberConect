# Ambientes dev/staging/prod: evidencia (2026-11-11)

Tarjeta GH#68 (CORE-001). Diseño y comandos: `docs/AMBIENTES.md`.

`flutter_test_ambientes.txt` tiene tres corridas reales, una por ambiente:

| Corrida | `--dart-define` | Resultado |
|---|---|---|
| `test/ambientes` completo | ninguno (dev, como el CI de PR) | 13 pruebas en verde: resolución de los tres ambientes, HTTPS en prod, errores claros, etiqueta visible en dev/staging y oculta en prod, y arranque en dev con `DEV · 10.0.2.2:8000` en el inicio de sesión |
| `arranque_ambiente_test.dart` | `APP_ENV=staging`, `API_BASE_URL=http://10.0.2.2:8000/api` | 2 en verde: el build resuelve `staging` y el inicio de sesión muestra `STAGING` |
| `arranque_ambiente_test.dart` | `APP_ENV=prod` | 2 en verde: el build resuelve `prod` con la URL HTTPS de Render y el inicio de sesión no muestra etiqueta |

Ninguna de estas pruebas hace peticiones de red. Las rutas absolutas de la máquina local se recortaron a rutas relativas al repo.

No verificado aquí: un build release con `--dart-define=APP_ENV=prod` corriendo en un teléfono. Ese build lo hace `release.yml` al llegar a `release`/`main`.
