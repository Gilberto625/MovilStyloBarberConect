/// Tamaño y encuadre de las fotos del catálogo que se piden a Cloudinary.
///
/// El backend publica la foto original, que puede ser de 12 MP y vertical.
/// Recortarla en el teléfono a una tarjeta horizontal dejaba la pared arriba
/// y cortaba la cara. La app pide a Cloudinary una versión del tamaño que se
/// muestra y, cuando hay recorte, centrada en el contenido (`g_auto`: rostro,
/// corte, producto). Son pocas variantes fijas para que el CDN las tenga en
/// caché para todos los teléfonos.
library;

class VarianteImagen {
  const VarianteImagen._(this.ancho, {this.proporcion});

  /// Ancho en píxeles de la imagen que se pide.
  final int ancho;

  /// Ancho entre alto del recorte. `null`: sin recorte, solo se reduce.
  final double? proporcion;

  /// Tarjeta del carrusel de servicios (16:10).
  static const tarjeta = VarianteImagen._(720, proporcion: 16 / 10);

  /// Miniatura cuadrada de listas (servicios, agendar).
  static const miniatura = VarianteImagen._(240, proporcion: 1);

  /// Foto grande del detalle de un servicio (5:4).
  static const detalle = VarianteImagen._(1080, proporcion: 5 / 4);

  /// Fondo de la portada del inicio (4:3; el resto lo ajusta la vista).
  static const portada = VarianteImagen._(1080, proporcion: 4 / 3);

  /// Banner de promoción: lleva texto, así que no se recorta por contenido.
  static const banner = VarianteImagen._(1080);

  /// Producto en la tienda: se muestra completo, solo se reduce.
  static const producto = VarianteImagen._(720);

  /// Producto en su detalle.
  static const productoDetalle = VarianteImagen._(1080);

  /// Producto en una fila con miniatura.
  static const productoMiniatura = VarianteImagen._(240);

  /// Segmento de transformación de Cloudinary.
  String get transformacion {
    final p = proporcion;
    if (p == null) return 'c_limit,w_$ancho,q_auto';
    return 'c_fill,g_auto,ar_${_decimal(p)},w_$ancho,q_auto';
  }

  static String _decimal(double valor) {
    var texto = valor.toStringAsFixed(3);
    texto = texto.replaceFirst(RegExp(r'0+$'), '');
    return texto.endsWith('.') ? texto.substring(0, texto.length - 1) : texto;
  }
}

/// URL de la [variante] si la foto está en Cloudinary; si no, la misma URL.
///
/// Inserta la transformación justo después de `/image/upload/`, que es donde
/// Cloudinary la espera. No reescribe el resto de la ruta.
String urlVariante(String url, VarianteImagen variante) {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'res.cloudinary.com') {
    return url;
  }
  const marca = '/image/upload/';
  final i = url.indexOf(marca);
  if (i < 0) return url;
  final corte = i + marca.length;
  return '${url.substring(0, corte)}${variante.transformacion}/'
      '${url.substring(corte)}';
}
