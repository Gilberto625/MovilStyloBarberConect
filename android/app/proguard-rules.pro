# Reglas de R8 para el release (GH#46).
#
# Se mantienen mínimas a propósito: el plugin de Flutter y cada plugin (flutter_secure_storage,
# etc.) ya aportan sus propias reglas de consumidor. La lógica de la app vive en libapp.so y se
# ofusca con --obfuscate, no con R8.
#
# - Si R8 falla con "Missing classes", copia aquí solo las líneas -dontwarn de
#   build/app/outputs/mapping/release/missing_rules.txt.
# - Si un plugin falla en tiempo de ejecución por reflexión, agrega -keep solo para esa clase
#   y documenta por qué.
# - Prohibido -keep class ** { *; }: anula la ofuscación.
