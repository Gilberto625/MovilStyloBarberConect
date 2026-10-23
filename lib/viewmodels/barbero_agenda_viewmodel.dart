import 'package:flutter/foundation.dart';

import '../models/barbero_models.dart';
import '../repositories/barbero_repository.dart';
import 'home_guest_viewmodel.dart';

/// Barbero › Mi agenda (S7-01..03, PM06). Se crea por ruta, así no queda la
/// agenda de un barbero al cambiar de cuenta (PM09).
class BarberoAgendaViewModel extends ChangeNotifier {
  BarberoAgendaViewModel(this._repository);

  final BarberoRepository _repository;

  LoadState state = LoadState.idle;
  String? errorMessage;
  BarberoAgendaDto? agenda;

  /// Día consultado (AAAA-MM-DD); null es hoy según el servidor.
  String? fecha;

  /// Cita con una acción en curso; bloquea un segundo toque.
  int? citaOcupada;
  String? accionError;
  String? accionMensaje;

  List<BarberoCitaDto> get citas => agenda?.citas ?? const [];

  Future<void> load({String? fecha}) async {
    this.fecha = fecha;
    state = LoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      agenda = await _repository.getAgenda(fecha: fecha);
      state = citas.isEmpty ? LoadState.empty : LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
    notifyListeners();
  }

  Future<bool> iniciar(BarberoCitaDto cita) =>
      _accion(cita, () => _repository.iniciarAtencion(cita.id));

  Future<bool> terminar(BarberoCitaDto cita) =>
      _accion(cita, () => _repository.terminarAtencion(cita.id));

  Future<bool> _accion(
    BarberoCitaDto cita,
    Future<Map<String, dynamic>> Function() llamada,
  ) async {
    if (citaOcupada != null) return false;
    citaOcupada = cita.id;
    accionError = null;
    accionMensaje = null;
    notifyListeners();
    try {
      final result = await llamada();
      accionMensaje = (result['mensaje'] ?? '').toString();
    } catch (e) {
      accionError = e.toString();
      citaOcupada = null;
      notifyListeners();
      return false;
    }
    citaOcupada = null;
    // El estado nuevo sale del servidor, no de un cambio local.
    await load(fecha: fecha);
    return true;
  }
}
