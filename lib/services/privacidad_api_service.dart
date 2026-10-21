import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/privacidad_models.dart';

/// `/api/privacidad/preferencias/`: opt-in de finalidades secundarias del
/// usuario autenticado (GH#41, GH#45). Django solo opera sobre su propia cuenta.
class PrivacidadApiService {
  PrivacidadApiService(this._api);

  final ApiClient _api;

  Future<ConsentimientoPrivacidad> preferencias() async {
    return _desde(await _api.get('/privacidad/preferencias/'));
  }

  Future<ConsentimientoPrivacidad> guardarPreferencias(
    ConsentimientoPrivacidad preferencias,
  ) async {
    return _desde(
      await _api.put('/privacidad/preferencias/', body: preferencias.toJson()),
    );
  }

  ConsentimientoPrivacidad _desde(Object? raw) {
    if (raw is! Map) throw ApiException('Respuesta de preferencias inválida.');
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudieron cargar tus preferencias.').toString(),
      );
    }
    final pref = map['preferencias'];
    if (pref is! Map) throw ApiException('Respuesta de preferencias inválida.');
    return ConsentimientoPrivacidad.fromJson(Map<String, dynamic>.from(pref));
  }
}
