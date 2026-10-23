import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/barbero_models.dart';

/// Agenda del barbero. El empleado sale de la sesión: la app no manda ids.
class BarberoApiService {
  BarberoApiService(this._api);

  final ApiClient _api;

  Future<BarberoAgendaDto> agenda({String? fecha}) async {
    final raw = await _api.get(
      '/barbero/agenda/',
      query: fecha == null ? null : {'fecha': fecha},
    );
    final map = _ok(raw, 'No se pudo cargar tu agenda.');
    return BarberoAgendaDto.fromJson(map);
  }

  /// [accion] es `iniciar` o `terminar`.
  Future<Map<String, dynamic>> atencion(int citaId, String accion) async {
    final raw = await _api.post(
      '/barbero/citas/$citaId/atencion/',
      body: {'accion': accion},
    );
    return _ok(raw, 'No se pudo actualizar la cita.');
  }

  Map<String, dynamic> _ok(Object? raw, String fallback) {
    if (raw is! Map) throw ApiException(fallback);
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException((map['error'] ?? fallback).toString());
    }
    return map;
  }
}
