import 'dart:convert';

enum UserRole { cliente, secretaria, barbero, admin, unknown }

UserRole parseUserRole(String? raw) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'administrador':
    case 'admin':
      return UserRole.admin;
    case 'secretaria':
      return UserRole.secretaria;
    case 'barbero':
      return UserRole.barbero;
    case 'cliente':
      return UserRole.cliente;
    default:
      return UserRole.unknown;
  }
}

extension UserRoleX on UserRole {
  String get apiValue {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.secretaria:
        return 'secretaria';
      case UserRole.barbero:
        return 'barbero';
      case UserRole.cliente:
        return 'cliente';
      case UserRole.unknown:
        return 'cliente';
    }
  }

  bool get isStaffPanel =>
      this == UserRole.secretaria || this == UserRole.admin;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.rol,
  });

  final int id;
  final String username;
  final String email;
  final UserRole rol;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      rol: parseUserRole(json['rol']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'rol': rol.apiValue,
  };

  String encode() => jsonEncode(toJson());

  static AuthUser? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthUser.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }
}

sealed class LoginResult {
  const LoginResult();
}

class LoginSuccess extends LoginResult {
  const LoginSuccess({
    required this.access,
    required this.refresh,
    required this.user,
  });

  final String access;
  final String refresh;
  final AuthUser user;
}

class LoginRequires2FA extends LoginResult {
  const LoginRequires2FA({
    required this.tempToken,
    required this.destino,
    required this.mensaje,
  });

  final String tempToken;
  final String destino;
  final String mensaje;
}

class PerfilDto {
  const PerfilDto({
    required this.email,
    required this.username,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.fechaNacimiento,
    required this.avatarUrl,
    required this.direccion,
  });

  final String email;
  final String username;
  final String nombre;
  final String apellido;
  final String telefono;
  final String fechaNacimiento;
  final String avatarUrl;
  final String direccion;

  String get displayName {
    final n = '$nombre $apellido'.trim();
    if (n.isNotEmpty) return n;
    if (username.isNotEmpty) return username;
    return email;
  }

  factory PerfilDto.fromJson(Map<String, dynamic> json) {
    return PerfilDto(
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      apellido: (json['apellido'] ?? '').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      fechaNacimiento: (json['fecha_nacimiento'] ?? '').toString(),
      avatarUrl: (json['avatar_url'] ?? '').toString(),
      direccion: (json['direccion'] ?? '').toString(),
    );
  }
}

/// Alta de cliente (`POST /register/`). Los nombres de campo son los de
/// Django (`RegisterView`), igual que en la web.
class RegistroRequest {
  const RegistroRequest({
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.username,
    required this.correo,
    required this.telefono,
    required this.contrasena,
    required this.preguntaSecreta,
    required this.respuestaSecreta,
    required this.aceptaTerminos,
    this.sinVerificacion = true,
  });

  /// Las mismas opciones que ofrece la web (register.component.html).
  static const preguntas = [
    '¿Cuál es el nombre de tu primera mascota?',
    '¿Cuál es el nombre de tu madre?',
    '¿En qué ciudad naciste?',
    '¿Cuál es el nombre de tu mejor amigo de la infancia?',
    '¿Cuál es el modelo de tu primer automóvil?',
    '¿Cuál es el nombre de tu escuela primaria?',
  ];

  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String username;
  final String correo;
  final String telefono;
  final String contrasena;
  final String preguntaSecreta;
  final String respuestaSecreta;
  final bool aceptaTerminos;

  /// Pide a Django crear la cuenta ya verificada y devolver la sesión, sin
  /// mandar código al correo. Un servidor que no lo conoce lo ignora y
  /// responde con el flujo de código de siempre.
  final bool sinVerificacion;

  Map<String, dynamic> toJson() => {
    'nombre': nombre.trim(),
    'apellidopaterno': apellidoPaterno.trim(),
    'apellidomaterno': apellidoMaterno.trim(),
    'username': username.trim(),
    'correo': correo.trim().toLowerCase(),
    'telefono': telefono.replaceAll(RegExp(r'\D'), ''),
    'contrasena': contrasena,
    'preguntasecreta': preguntaSecreta,
    'respuestasecreta': respuestaSecreta.trim(),
    'aceptaTerminos': aceptaTerminos,
    if (sinVerificacion) 'sinVerificacion': true,
  };
}

/// Respuesta de `POST /register/`: la cuenta queda lista con su sesión
/// ([RegistroCompletado]) o pendiente del código del correo
/// ([RegistroPendiente], servidores sin `sinVerificacion`).
sealed class RegistroResultado {
  const RegistroResultado();
}

/// Cuenta creada y verificada: Django devolvió los tokens del cliente.
class RegistroCompletado extends RegistroResultado {
  const RegistroCompletado({required this.sesion, required this.mensaje});

  final LoginSuccess sesion;
  final String mensaje;
}

/// Registro creado, pendiente de confirmar con el código del correo.
class RegistroPendiente extends RegistroResultado {
  const RegistroPendiente({
    required this.tempToken,
    required this.destino,
    required this.mensaje,
    this.emailEnviado = true,
  });

  final String tempToken;

  /// Correo enmascarado por el servidor (`j***e@correo.com`).
  final String destino;
  final String mensaje;

  /// `email_enviado` de Django. Si es falso, el código no salió y no hay que
  /// decir "Enviado a …". Servidores que no lo mandan cuentan como enviado.
  final bool emailEnviado;
}

/// `GET/PUT /perfil/2fa/`: pedir código por correo al iniciar sesión.
class Preferencia2fa {
  const Preferencia2fa({
    required this.email2fa,
    this.puedeGestionar = true,
    this.motivoBloqueo = '',
    this.proveedorAuth = '',
  });

  final bool email2fa;
  final bool puedeGestionar;
  final String motivoBloqueo;
  final String proveedorAuth;

  factory Preferencia2fa.fromJson(Map<String, dynamic> json) {
    return Preferencia2fa(
      email2fa: json['email_2fa'] == true,
      // El PUT no lo devuelve: si falta, se puede gestionar.
      puedeGestionar: json['puede_gestionar'] != false,
      motivoBloqueo: (json['motivo_bloqueo'] ?? '').toString(),
      proveedorAuth: (json['proveedor_auth'] ?? '').toString(),
    );
  }
}
