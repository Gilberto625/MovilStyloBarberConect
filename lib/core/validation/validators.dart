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
