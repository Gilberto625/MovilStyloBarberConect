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
    String message = 'Error del servidor ($statusCode).';
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final err =
          map['error'] ?? map['detail'] ?? map['mensaje'] ?? map['message'];
      if (err != null && err.toString().trim().isNotEmpty) {
        message = err.toString().trim();
      }
    } else if (decoded is String && decoded.trim().isNotEmpty) {
      message = decoded.trim();
    }
    return ApiException(message, statusCode: statusCode, body: decoded);
  }
}
