import 'auth_models.dart';

/// Un bloque de `/public/legal/` (`{tipo, tipo_display, titulo, contenido}`).
class ContenidoLegalDto {
  const ContenidoLegalDto({
    required this.tipo,
    required this.tipoDisplay,
    required this.titulo,
    required this.contenido,
  });

  final String tipo;
  final String tipoDisplay;
  final String titulo;
  final String contenido;

  factory ContenidoLegalDto.fromJson(Map<String, dynamic> json) {
    final tipo = (json['tipo'] ?? '').toString();
    return ContenidoLegalDto(
      tipo: tipo,
      tipoDisplay: (json['tipo_display'] ?? tipo).toString(),
      titulo: (json['titulo'] ?? '').toString(),
      contenido: (json['contenido'] ?? '').toString(),
    );
  }

  /// Huella estable del texto (FNV-1a de 32 bits). Sirve como versión del aviso
  /// aceptado, porque `/public/legal/` no devuelve id ni fecha de publicación.
  String get version {
    var hash = 0x811c9dc5;
    for (final unit in '$titulo\n$contenido'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 'fnv1a-${hash.toRadixString(16).padLeft(8, '0')}';
  }
}

/// Cuerpo de `PUT /perfil/` (rectificación, ARCO GH#43).
///
/// Django reemplaza el perfil completo: un `avatar_url` vacío lo borra y una
/// `direccion` vacía desmarca la dirección principal. Por eso se parte siempre
/// del perfil actual con [PerfilUpdate.desde] y se reenvían esos campos.
class PerfilUpdate {
  const PerfilUpdate({
    required this.nombre,
    required this.apellido,
    required this.telefono,
    required this.fechaNacimiento,
    required this.direccion,
    required this.avatarUrl,
  });

  factory PerfilUpdate.desde(PerfilDto perfil) => PerfilUpdate(
    nombre: perfil.nombre,
    apellido: perfil.apellido,
    telefono: perfil.telefono,
    fechaNacimiento: perfil.fechaNacimiento,
    direccion: perfil.direccion,
    avatarUrl: perfil.avatarUrl,
  );

  final String nombre;
  final String apellido;
  final String telefono;
  final String fechaNacimiento;
  final String direccion;
  final String avatarUrl;

  PerfilUpdate copyWith({
    String? nombre,
    String? apellido,
    String? telefono,
    String? fechaNacimiento,
    String? direccion,
  }) => PerfilUpdate(
    nombre: nombre ?? this.nombre,
    apellido: apellido ?? this.apellido,
    telefono: telefono ?? this.telefono,
    fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
    direccion: direccion ?? this.direccion,
    avatarUrl: avatarUrl,
  );

  Map<String, dynamic> toJson() => {
    'nombre': nombre.trim(),
    'apellido': apellido.trim(),
    'telefono': telefono.trim(),
    'fecha_nacimiento': fechaNacimiento.trim(),
    'direccion': direccion.trim(),
    'avatar_url': avatarUrl,
  };
}

/// Finalidades secundarias del aviso (opt-in, GH#41). Todas empiezan apagadas.
/// Se guardan en Django (`/api/privacidad/preferencias/`), no en el teléfono.
class ConsentimientoPrivacidad {
  const ConsentimientoPrivacidad({
    this.promociones = false,
    this.recordatoriosWhatsapp = false,
    this.analiticaPerfilado = false,
    this.fecha,
    this.versionAviso = '',
  });

  static const sinRespuesta = ConsentimientoPrivacidad();

  final bool promociones;
  final bool recordatoriosWhatsapp;
  final bool analiticaPerfilado;

  /// Cuándo guardó su elección, según el servidor. `null` si nunca respondió.
  final DateTime? fecha;
  final String versionAviso;

  bool get respondido => fecha != null;

  ConsentimientoPrivacidad copyWith({
    bool? promociones,
    bool? recordatoriosWhatsapp,
    bool? analiticaPerfilado,
    DateTime? fecha,
    String? versionAviso,
  }) => ConsentimientoPrivacidad(
    promociones: promociones ?? this.promociones,
    recordatoriosWhatsapp: recordatoriosWhatsapp ?? this.recordatoriosWhatsapp,
    analiticaPerfilado: analiticaPerfilado ?? this.analiticaPerfilado,
    fecha: fecha ?? this.fecha,
    versionAviso: versionAviso ?? this.versionAviso,
  );

  /// Cuerpo de `PUT /privacidad/preferencias/`. La fecha la pone el servidor.
  Map<String, dynamic> toJson() => {
    'acepta_promociones': promociones,
    'acepta_recordatorios_whatsapp': recordatoriosWhatsapp,
    'acepta_analitica_perfilado': analiticaPerfilado,
    'version_aviso': versionAviso,
  };

  factory ConsentimientoPrivacidad.fromJson(Map<String, dynamic> json) {
    return ConsentimientoPrivacidad(
      promociones: json['acepta_promociones'] == true,
      recordatoriosWhatsapp: json['acepta_recordatorios_whatsapp'] == true,
      analiticaPerfilado: json['acepta_analitica_perfilado'] == true,
      fecha: DateTime.tryParse('${json['fecha_respuesta'] ?? ''}'),
      versionAviso: (json['version_aviso'] ?? '').toString(),
    );
  }
}
