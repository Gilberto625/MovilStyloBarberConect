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

// Reglas de `PUT /perfil/` (backend/core/views.py, PerfilView.put). Validar aquí
// solo ahorra una ida al servidor: Django vuelve a validar y manda.

/// Nombre obligatorio, de al menos 2 caracteres.
String? validarNombre(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Obligatorio';
  if (text.length < 2) return 'Escribe al menos 2 caracteres';
  return null;
}

/// Teléfono opcional. Si se escribe, debe tener de 10 a 15 dígitos.
String? validarTelefono(String? value) {
  final digitos = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digitos.isEmpty) return null;
  if (digitos.length < 10 || digitos.length > 15) {
    return 'Debe tener de 10 a 15 dígitos';
  }
  return null;
}

/// Fecha de nacimiento opcional en formato AAAA-MM-DD y no futura.
String? validarFechaNacimiento(String? value, {DateTime? hoy}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
  final fecha = match == null ? null : DateTime.tryParse(text);
  // DateTime.tryParse acepta 2026-02-31 y lo mueve a marzo: se rechaza.
  if (fecha == null ||
      fecha.month != int.parse(match!.group(2)!) ||
      fecha.day != int.parse(match.group(3)!)) {
    return 'Usa el formato AAAA-MM-DD';
  }
  final ref = hoy ?? DateTime.now();
  if (fecha.isAfter(DateTime(ref.year, ref.month, ref.day))) {
    return 'No puede ser una fecha futura';
  }
  return null;
}

// Reglas de `POST /register/` (backend/core/views.py, RegisterView). La app
// avisa antes de enviar; Django vuelve a validar y su mensaje manda.

final _usuarioValido = RegExp(r'^[A-Za-z0-9_.+\-]{4,150}$');
final _correoRegistro = RegExp(
  r'^[a-zA-Z0-9._%+\-]{1,64}@[a-zA-Z0-9.\-]{1,253}\.[a-zA-Z]{2,}$',
);
final _especial = RegExp(r'''[!@#$%^&*(),.?":{}|<>\[\]\/_+\-=~`]''');

/// Usuario de 4 a 150 caracteres: letras, números y `. _ + -`.
String? validarUsuario(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Obligatorio';
  if (!_usuarioValido.hasMatch(text)) {
    return 'Usa 4 o más letras o números, sin espacios';
  }
  return null;
}

/// Correo obligatorio con usuario, dominio y extensión.
String? validarCorreo(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Obligatorio';
  if (!_correoRegistro.hasMatch(text)) return 'Correo no válido';
  return null;
}

/// Teléfono obligatorio de 10 a 15 dígitos.
String? validarTelefonoObligatorio(String? value) {
  final digitos = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digitos.isEmpty) return 'Obligatorio';
  return validarTelefono(value);
}

/// Cada requisito de la contraseña y si ya se cumple, para mostrarlos
/// mientras se escribe.
List<({String regla, bool cumple})> requisitosContrasena(String value) => [
  (regla: '8 caracteres o más', cumple: value.length >= 8),
  (regla: 'Una mayúscula', cumple: RegExp(r'[A-Z]').hasMatch(value)),
  (regla: 'Una minúscula', cumple: RegExp(r'[a-z]').hasMatch(value)),
  (regla: 'Un número', cumple: RegExp(r'\d').hasMatch(value)),
  (regla: 'Un carácter especial', cumple: _especial.hasMatch(value)),
];

String? validarContrasenaNueva(String? value) {
  final text = value ?? '';
  if (text.isEmpty) return 'Obligatorio';
  if (requisitosContrasena(text).any((r) => !r.cumple)) {
    return 'Aún no cumple todos los requisitos';
  }
  return null;
}

String? validarConfirmacion(String? value, String original) {
  if ((value ?? '').isEmpty) return 'Obligatorio';
  if (value != original) return 'Las contraseñas no coinciden';
  return null;
}
