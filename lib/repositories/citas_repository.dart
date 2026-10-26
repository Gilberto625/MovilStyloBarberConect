import '../models/cita_models.dart';
import '../services/citas_api_service.dart';

class CitasRepository {
  CitasRepository(this._api);

  final CitasApiService _api;

  Future<List<CitaDto>> getMisCitas() => _api.misCitas();

  Future<List<BarberoDto>> getBarberos({int? servicioId}) =>
      _api.barberos(servicioId: servicioId);

  Future<List<SlotDisponibilidad>> getDisponibilidad({
    required int barberoId,
    required String fecha,
    required int duracion,
  }) => _api.disponibilidad(
    barberoId: barberoId,
    fecha: fecha,
    duracion: duracion,
  );

  Future<PoliticaPagoDto> getPoliticaPago(int clienteId) =>
      _api.politicaPago(clienteId: clienteId);

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

  Future<Map<String, dynamic>> cancelarCita(int citaId, {String motivo = ''}) =>
      _api.cancelarCita(citaId, motivo: motivo);

  Future<Map<String, dynamic>> reprogramarCita(
    int citaId, {
    required String fecha,
    required String hora,
  }) => _api.reprogramarCita(citaId, fecha: fecha, hora: hora);
}
