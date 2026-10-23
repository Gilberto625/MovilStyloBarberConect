import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/cita_models.dart';

class CitasApiService {
  CitasApiService(this._api);

  final ApiClient _api;

  Future<List<CitaDto>> misCitas() async {
    final raw = await _api.get('/mis-citas/');
    if (raw is! Map) throw ApiException('Respuesta de citas inválida.');
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudieron cargar citas.').toString(),
      );
    }
    final list = map['citas'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => CitaDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<BarberoDto>> barberos({int? servicioId}) async {
    final query = <String, String>{};
    if (servicioId != null) query['servicio_id'] = '$servicioId';
    final raw = await _api.get(
      '/barberos/',
      query: query.isEmpty ? null : query,
    );
    if (raw is! Map) throw ApiException('Respuesta de barberos inválida.');
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudieron cargar barberos.').toString(),
      );
    }
    final list = map['barberos'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => BarberoDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<SlotDisponibilidad>> disponibilidad({
    required int barberoId,
    required String fecha,
    required int duracion,
  }) async {
    final raw = await _api.get(
      '/disponibilidad/',
      query: {
        'barbero_id': '$barberoId',
        'fecha': fecha,
        'duracion': '$duracion',
      },
    );
    if (raw is! Map) {
      throw ApiException('Respuesta de disponibilidad inválida.');
    }
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudo consultar disponibilidad.').toString(),
      );
    }
    final list = map['horarios'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => SlotDisponibilidad.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PoliticaPagoDto> politicaPago({required int clienteId}) async {
    final raw = await _api.get(
      '/citas/politica-pago/',
      query: {'cliente_id': '$clienteId'},
    );
    if (raw is! Map) throw ApiException('Respuesta de política inválida.');
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudo cargar política de pago.').toString(),
      );
    }
    return PoliticaPagoDto.fromJson(map);
  }

  Future<Map<String, dynamic>> crearCita(Map<String, dynamic> body) async {
    final raw = await _api.post('/citas/', body: body);
    if (raw is! Map) {
      throw ApiException('Respuesta de creación de cita inválida.');
    }
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudo crear la cita.').toString(),
      );
    }
    return map;
  }

  Future<Map<String, dynamic>> cancelarCita(int citaId, {String motivo = ''}) =>
      _accionCita('/mis-citas/$citaId/cancelar/', {
        if (motivo.isNotEmpty) 'motivo': motivo,
      }, 'No se pudo cancelar la cita.');

  Future<Map<String, dynamic>> reprogramarCita(
    int citaId, {
    required String fecha,
    required String hora,
  }) => _accionCita('/mis-citas/$citaId/reprogramar/', {
    'fecha': fecha,
    'hora': hora,
  }, 'No se pudo reprogramar la cita.');

  Future<Map<String, dynamic>> _accionCita(
    String path,
    Map<String, dynamic> body,
    String fallback,
  ) async {
    final raw = await _api.post(path, body: body);
    if (raw is! Map) throw ApiException(fallback);
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException((map['error'] ?? fallback).toString());
    }
    return map;
  }
}
