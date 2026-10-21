class ServicioDto {
  const ServicioDto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.duracionMinutos,
    required this.categoria,
    required this.popular,
    required this.activo,
    required this.imagenUrl,
    required this.bannerUrl,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int duracionMinutos;
  final String categoria;
  final bool popular;
  final bool activo;
  final String imagenUrl;
  final String bannerUrl;

  bool get isPromocion => categoria.toLowerCase() == 'promocion';

  factory ServicioDto.fromJson(Map<String, dynamic> json) {
    return ServicioDto(
      id: _asInt(json['id']),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      precio: _asDouble(json['precio']),
      duracionMinutos: _asInt(json['duracion_minutos']),
      categoria: (json['categoria'] ?? '').toString(),
      popular: json['popular'] == true,
      activo: json['activo'] != false,
      imagenUrl: (json['imagen_url'] ?? '').toString(),
      bannerUrl: (json['banner_url'] ?? '').toString(),
    );
  }

  static int _asInt(Object? v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _asDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class ProductoDto {
  const ProductoDto({
    required this.id,
    required this.nombre,
    required this.marca,
    required this.descripcion,
    required this.precio,
    required this.categoria,
    required this.stock,
    required this.imagenUrl,
    required this.destacado,
  });

  final int id;
  final String nombre;
  final String marca;
  final String descripcion;
  final double precio;
  final String categoria;
  final int stock;
  final String imagenUrl;
  final bool destacado;

  factory ProductoDto.fromJson(Map<String, dynamic> json) {
    return ProductoDto(
      id: ServicioDto._asInt(json['id']),
      nombre: (json['nombre'] ?? '').toString(),
      marca: (json['marca'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      precio: ServicioDto._asDouble(json['precio']),
      categoria: (json['categoria'] ?? '').toString(),
      stock: ServicioDto._asInt(json['stock']),
      imagenUrl: (json['imagen_url'] ?? '').toString(),
      destacado: json['destacado'] == true,
    );
  }
}

class HorarioDiaDto {
  const HorarioDiaDto({
    required this.diaSemana,
    this.abierto,
    this.apertura,
    this.cierre,
  }) : assert(diaSemana >= 0 && diaSemana <= 6);

  final int diaSemana;
  final bool? abierto;
  final String? apertura;
  final String? cierre;

  bool get cerrado => abierto == false;

  static HorarioDiaDto? tryFromJson(Map<dynamic, dynamic> json) {
    final rawDia = json['dia_semana'];
    final dia = rawDia is int
        ? rawDia
        : rawDia is String
        ? int.tryParse(rawDia.trim())
        : null;
    if (dia == null || dia < 0 || dia > 6) return null;

    return HorarioDiaDto(
      diaSemana: dia,
      abierto: json['abierto'] is bool ? json['abierto'] as bool : null,
      apertura: _optionalText(json['apertura']),
      cierre: _optionalText(json['cierre']),
    );
  }

  static String? _optionalText(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}

class ContactoDto {
  const ContactoDto({
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.horario,
    required this.nombreNegocio,
    required this.logoTipo,
    required this.logoParte1,
    required this.logoParte2,
    required this.logoUrl,
    required this.whatsappUrl,
    required this.googleMapsUrl,
    this.horariosPorDia = const [],
  });

  final String telefono;
  final String correo;
  final String direccion;
  final String horario;
  final String nombreNegocio;
  final String logoTipo;
  final String logoParte1;
  final String logoParte2;
  final String logoUrl;
  final String whatsappUrl;
  final String googleMapsUrl;
  final List<HorarioDiaDto> horariosPorDia;

  factory ContactoDto.fromJson(Map<String, dynamic> json) {
    return ContactoDto(
      telefono: (json['telefono'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      direccion: (json['direccion'] ?? '').toString(),
      horario: (json['horario'] ?? '').toString(),
      nombreNegocio: (json['nombre_negocio'] ?? 'Stylo Barber Connect')
          .toString(),
      logoTipo: (json['logo_tipo'] ?? 'texto').toString(),
      logoParte1: (json['logo_texto_parte1'] ?? 'Stylo').toString(),
      logoParte2: (json['logo_texto_parte2'] ?? 'Barber').toString(),
      logoUrl: (json['logo_url'] ?? '').toString(),
      whatsappUrl: (json['whatsapp_url'] ?? '').toString(),
      googleMapsUrl: (json['google_maps_url'] ?? '').toString(),
      horariosPorDia: _parseHorarios(json['horarios_por_dia']),
    );
  }

  /// Estado de hoy según `horarios_por_dia` (0 = lunes, como el backend).
  /// Devuelve `null` si el backend no publicó horario por día.
  HorarioHoy? horarioHoy(DateTime now) {
    if (horariosPorDia.isEmpty) return null;
    final dia = now.weekday - 1;
    final hoy = horariosPorDia.where((d) => d.diaSemana == dia).firstOrNull;
    if (hoy == null) return const HorarioHoy(EstadoHoy.sinDato);
    if (hoy.cerrado) return const HorarioHoy(EstadoHoy.cerrado);
    final apertura = HorarioHoy.hhmm(hoy.apertura);
    final cierre = HorarioHoy.hhmm(hoy.cierre);
    if (apertura == null || cierre == null) {
      return const HorarioHoy(EstadoHoy.sinDato);
    }
    final ahora = now.hour * 60 + now.minute;
    final estado = ahora < HorarioHoy._minutos(apertura)
        ? EstadoHoy.abrePronto
        : ahora < HorarioHoy._minutos(cierre)
        ? EstadoHoy.abierto
        : EstadoHoy.yaCerro;
    return HorarioHoy(estado, apertura: apertura, cierre: cierre);
  }

  static List<HorarioDiaDto> _parseHorarios(Object? raw) {
    if (raw is! List) return const [];
    final horarios = <HorarioDiaDto>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final horario = HorarioDiaDto.tryFromJson(item);
      if (horario != null) horarios.add(horario);
    }
    horarios.sort((a, b) => a.diaSemana.compareTo(b.diaSemana));
    return List<HorarioDiaDto>.unmodifiable(horarios);
  }

  static ContactoDto empty() => const ContactoDto(
    telefono: '',
    correo: '',
    direccion: '',
    horario: '',
    nombreNegocio: 'Stylo Barber Connect',
    logoTipo: 'texto',
    logoParte1: 'Stylo',
    logoParte2: 'Barber',
    logoUrl: '',
    whatsappUrl: '',
    googleMapsUrl: '',
  );
}

enum EstadoHoy { abierto, abrePronto, yaCerro, cerrado, sinDato }

/// Horario de hoy ya interpretado; el texto lo pone la vista.
class HorarioHoy {
  const HorarioHoy(this.estado, {this.apertura, this.cierre});

  final EstadoHoy estado;

  /// `HH:MM`, sin segundos.
  final String? apertura;
  final String? cierre;

  /// Normaliza `9:00`, `09:00` o `09:00:00` a `09:00`. Devuelve `null` si no
  /// es una hora válida.
  static String? hhmm(String? valor) {
    if (valor == null) return null;
    final partes = valor.trim().split(':');
    if (partes.length < 2) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static int _minutos(String hhmm) {
    final partes = hhmm.split(':');
    return int.parse(partes[0]) * 60 + int.parse(partes[1]);
  }
}
