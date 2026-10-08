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
