import '../models/barbero_models.dart';
import '../services/barbero_api_service.dart';

class BarberoRepository {
  BarberoRepository(this._api);

  final BarberoApiService _api;

  Future<BarberoAgendaDto> getAgenda({String? fecha}) =>
      _api.agenda(fecha: fecha);

  Future<Map<String, dynamic>> iniciarAtencion(int citaId) =>
      _api.atencion(citaId, 'iniciar');

  Future<Map<String, dynamic>> terminarAtencion(int citaId) =>
      _api.atencion(citaId, 'terminar');
}
