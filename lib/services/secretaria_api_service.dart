import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/cita_models.dart';

class SecretariaApiService {
  SecretariaApiService(this._api);

  final ApiClient _api;

  Future<SecretariaDiaDto> citasDelDia({String? fecha}) async {
    final query = <String, String>{};
    if (fecha != null && fecha.isNotEmpty) query['fecha'] = fecha;
    final raw = await _api.get(
      '/secretaria/citas/dia/',
      query: query.isEmpty ? null : query,
    );
    if (raw is! Map) throw ApiException('Respuesta de citas del día inválida.');
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudieron cargar citas del día.').toString(),
      );
    }
    return SecretariaDiaDto.fromJson(map);
  }

  Future<Map<String, dynamic>> asistencia({
    required int citaId,
    required String accion,
  }) async {
    final raw = await _api.post(
      '/secretaria/citas/$citaId/asistencia/',
      body: {'accion': accion},
    );
    if (raw is! Map) throw ApiException('Respuesta de asistencia inválida.');
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudo registrar asistencia.').toString(),
      );
    }
    return map;
  }

  Future<Map<String, dynamic>> cobrar({
    required int citaId,
    required String metodoPago,
    String? comprobante,
    String? referencia,
  }) async {
    final body = <String, dynamic>{'metodo_pago': metodoPago};
    // Backend espera `comprobante_pago` (URL o referencia textual).
    final proof = (comprobante ?? '').trim().isNotEmpty
        ? comprobante!.trim()
        : (referencia ?? '').trim();
    if (proof.isNotEmpty) {
      body['comprobante_pago'] = proof;
    }
    final raw = await _api.post(
      '/secretaria/citas/$citaId/cobrar/',
      body: body,
    );
    if (raw is! Map) throw ApiException('Respuesta de cobro inválida.');
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudo registrar el cobro.').toString(),
      );
    }
    return map;
  }
}
