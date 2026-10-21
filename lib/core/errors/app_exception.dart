class AppException implements Exception {
  AppException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final Object? body;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}

class ApiException extends AppException {
  ApiException(super.message, {super.statusCode, super.body});

  /// Parses Django envelopes: `{ "ok": false, "error": "..." }` or `{ "detail": "..." }`.
  factory ApiException.fromBody(int statusCode, Object? decoded) {
    String message = statusCode >= 500
        ? 'El servidor no está disponible en este momento ($statusCode). '
              'Intenta de nuevo en unos minutos.'
        : 'Error del servidor ($statusCode).';
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final err =
          map['error'] ?? map['detail'] ?? map['mensaje'] ?? map['message'];
      if (err != null && err.toString().trim().isNotEmpty) {
        message = err.toString().trim();
      }
    } else if (decoded is String &&
        statusCode < 500 &&
        _esTextoParaPersona(decoded)) {
      message = decoded.trim();
    }
    return ApiException(message, statusCode: statusCode, body: decoded);
  }

  /// Un texto plano corto de un 4xx sí se muestra. Una página HTML de error
  /// (proxy, Render, Django con DEBUG) o el texto de un 5xx no.
  static bool _esTextoParaPersona(String texto) {
    final t = texto.trim();
    return t.isNotEmpty && t.length <= 200 && !t.startsWith('<');
  }
}

/// No hubo respuesta del servidor: sin internet, servidor caído, DNS o TLS.
///
/// El mensaje es para la persona; el detalle técnico (IP, puerto, URL) no se
/// muestra.
class NetworkException extends AppException {
  NetworkException([super.message = sinConexion]);

  static const sinConexion =
      'No hay conexión con el servidor. Revisa tu internet e intenta de '
      'nuevo.';
}
