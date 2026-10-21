final _correoValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Valida el campo "Correo o usuario" del login (PM-U01).
///
/// Acepta un nombre de usuario sin `@`. Si el texto trae `@`, debe ser un correo
/// con usuario, dominio y extensión.
String? validarCuenta(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Obligatorio';
  if (text.contains('@') && !_correoValido.hasMatch(text)) {
    return 'Correo no válido';
  }
  return null;
}
