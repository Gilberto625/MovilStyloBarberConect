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
    double? efectivoRecibido,
  }) async {
    final body = <String, dynamic>{'metodo_pago': metodoPago};
    if (efectivoRecibido != null) {
      body['efectivo_recibido'] = efectivoRecibido;
    }
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

  Future<List<SecretariaClienteDto>> buscarClientes(String q) async {
    final map = await _ok(
      await _api.get('/secretaria/clientes/', query: {'q': q}),
      'Respuesta de clientes inválida.',
      'No se pudieron buscar clientes.',
    );
    final raw = map['clientes'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => SecretariaClienteDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<SecretariaClienteDto> crearClientePaso({
    required String nombres,
    String apellido = '',
    required String telefono,
  }) async {
    final map = await _ok(
      await _api.post(
        '/secretaria/clientes/',
        body: {
          'modo': 'anonimo',
          'nombres': nombres,
          'apellido_paterno': apellido,
          'telefono': telefono,
        },
      ),
      'Respuesta de cliente inválida.',
      'No se pudo registrar el cliente.',
    );
    final raw = map['cliente'];
    if (raw is! Map) throw ApiException('Respuesta de cliente inválida.');
    return SecretariaClienteDto.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<Map<String, dynamic>> crearCita(Map<String, dynamic> body) {
    return _ok(
      _api.post('/secretaria/citas/crear/', body: body),
      'Respuesta de creación inválida.',
      'No se pudo crear la cita.',
    );
  }

  Future<List<SecretariaCitaResumenDto>> citasDeCliente(int clienteId) async {
    final map = await _ok(
      await _api.get(
        '/secretaria/citas/buscar/',
        query: {'cliente_id': '$clienteId'},
      ),
      'Respuesta de citas del cliente inválida.',
      'No se pudieron buscar citas.',
    );
    final raw = map['citas'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (e) =>
              SecretariaCitaResumenDto.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<SecretariaCitaEditableDto> citaEditable(int citaId) async {
    final map = await _ok(
      await _api.get('/secretaria/citas/$citaId/editar/'),
      'Respuesta de cita inválida.',
      'No se pudo cargar la cita.',
    );
    return SecretariaCitaEditableDto.fromResponse(map);
  }

  Future<Map<String, dynamic>> actualizarCita({
    required int citaId,
    required Map<String, dynamic> body,
  }) {
    return _ok(
      _api.put('/secretaria/citas/$citaId/editar/', body: body),
      'Respuesta de actualización inválida.',
      'No se pudo actualizar la cita.',
    );
  }

  Future<Map<String, dynamic>> _ok(
    Future<dynamic> request,
    String invalid,
    String fallback,
  ) async {
    final raw = await request;
    if (raw is! Map) throw ApiException(invalid);
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException((map['error'] ?? fallback).toString());
    }
    return map;
  }
}
