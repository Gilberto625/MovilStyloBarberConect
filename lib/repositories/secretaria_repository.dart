import '../models/cita_models.dart';
import '../services/secretaria_api_service.dart';

class SecretariaRepository {
  SecretariaRepository(this._api);

  final SecretariaApiService _api;

  Future<SecretariaDiaDto> getCitasDia({String? fecha}) =>
      _api.citasDelDia(fecha: fecha);

  Future<Map<String, dynamic>> marcarLlego(int citaId) =>
      _api.asistencia(citaId: citaId, accion: 'llego');

  Future<Map<String, dynamic>> marcarNoAsistio(int citaId) =>
      _api.asistencia(citaId: citaId, accion: 'no_asistio');

  Future<Map<String, dynamic>> cobrar({
    required int citaId,
    required String metodoPago,
    String? comprobante,
    String? referencia,
  }) => _api.cobrar(
    citaId: citaId,
    metodoPago: metodoPago,
    comprobante: comprobante,
    referencia: referencia,
  );
}
