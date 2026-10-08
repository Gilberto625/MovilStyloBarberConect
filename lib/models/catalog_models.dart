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
    );
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
