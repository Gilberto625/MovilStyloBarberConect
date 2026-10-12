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
    double? efectivoRecibido,
  }) => _api.cobrar(
    citaId: citaId,
    metodoPago: metodoPago,
    comprobante: comprobante,
    referencia: referencia,
    efectivoRecibido: efectivoRecibido,
  );

  Future<List<SecretariaClienteDto>> buscarClientes(String q) =>
      _api.buscarClientes(q);

  Future<SecretariaClienteDto> crearClientePaso({
    required String nombres,
    String apellido = '',
    required String telefono,
  }) => _api.crearClientePaso(
    nombres: nombres,
    apellido: apellido,
    telefono: telefono,
  );

  Future<Map<String, dynamic>> crearCita({
    required int clienteId,
    required int barberoId,
    required int servicioId,
    required int duracionMinutos,
    required String fecha,
    required String hora,
    required double precioTotal,
    double anticipoPagado = 0,
    String metodoAnticipo = '',
    String comprobantePago = '',
    String notas = '',
  }) {
    return _api.crearCita({
      'cliente_id': clienteId,
      'barbero_id': barberoId,
      'servicio_id': servicioId,
      'duracion_minutos': duracionMinutos,
      'fecha': fecha,
      'hora': hora,
      'precio_total': precioTotal,
      'anticipo_pagado': anticipoPagado,
      if (metodoAnticipo.isNotEmpty) 'metodo_anticipo': metodoAnticipo,
      if (comprobantePago.isNotEmpty) 'comprobante_pago': comprobantePago,
      if (notas.isNotEmpty) 'notas': notas,
    });
  }

  Future<List<SecretariaCitaResumenDto>> citasDeCliente(int clienteId) =>
      _api.citasDeCliente(clienteId);

  Future<SecretariaCitaEditableDto> citaEditable(int citaId) =>
      _api.citaEditable(citaId);

  Future<Map<String, dynamic>> actualizarCita({
    required int citaId,
    required int barberoId,
    required int servicioId,
    required String fecha,
    required String hora,
    required double precioTotal,
    required double anticipoPagado,
    required String metodoAnticipo,
    required String notas,
    bool cancelar = false,
  }) {
    return _api.actualizarCita(
      citaId: citaId,
      body: {
        'barbero_id': barberoId,
        'servicio_id': servicioId,
        'fecha': fecha,
        'hora': hora,
        'precio_total': precioTotal,
        'anticipo_pagado': anticipoPagado,
        'metodo_anticipo': metodoAnticipo.isEmpty ? 'ninguno' : metodoAnticipo,
        'notas': notas,
        if (cancelar) 'cancelar': true,
      },
    );
  }
}
