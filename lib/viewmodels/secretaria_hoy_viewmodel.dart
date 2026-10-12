import 'package:flutter/foundation.dart';

import '../models/cita_models.dart';
import '../repositories/secretaria_repository.dart';
import 'home_guest_viewmodel.dart';

class SecretariaHoyViewModel extends ChangeNotifier {
  SecretariaHoyViewModel(this._repository);

  final SecretariaRepository _repository;

  LoadState state = LoadState.idle;
  String? errorMessage;
  String? actionMessage;
  bool actionBusy = false;
  bool reloading = false;
  SecretariaDiaDto? dia;
  String? fechaSeleccionada;
  String filtroEstado = 'todas';
  String consulta = '';

  List<SecretariaCitaDto> get citasFiltradas {
    final q = consulta.trim().toLowerCase();
    return (dia?.citas ?? const <SecretariaCitaDto>[]).where((c) {
      if (filtroEstado != 'todas' && c.estado != filtroEstado) return false;
      if (q.isEmpty) return true;
      final blob =
          '${c.id} ${c.clienteNombre} ${c.clienteTelefono} ${c.servicioNombre} ${c.barberoNombre} ${c.hora}'
              .toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  Future<void> load({String? fecha, bool hoy = false}) async {
    if (hoy) {
      fechaSeleccionada = null;
    } else if (fecha != null) {
      fechaSeleccionada = fecha;
    }
    final previous = dia;
    final firstLoad = previous == null;
    if (firstLoad) state = LoadState.loading;
    reloading = !firstLoad;
    errorMessage = null;
    notifyListeners();
    try {
      dia = await _repository.getCitasDia(fecha: fechaSeleccionada);
      state = (dia?.citas.isEmpty ?? true) ? LoadState.empty : LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      if (firstLoad) {
        state = LoadState.error;
      } else {
        dia = previous;
      }
    }
    reloading = false;
    notifyListeners();
  }

  Future<void> mostrarHoy() => load(hoy: true);

  void setFiltro(String estado) {
    filtroEstado = estado;
    notifyListeners();
  }

  void setConsulta(String value) {
    consulta = value;
    notifyListeners();
  }

  Future<bool> marcarLlego(int citaId) async {
    return _runAction(() => _repository.marcarLlego(citaId));
  }

  Future<bool> marcarNoAsistio(int citaId) async {
    return _runAction(() => _repository.marcarNoAsistio(citaId));
  }

  Future<bool> cobrar({
    required int citaId,
    required String metodoPago,
    String? comprobante,
    double? efectivoRecibido,
  }) async {
    return _runAction(
      () => _repository.cobrar(
        citaId: citaId,
        metodoPago: metodoPago,
        comprobante: comprobante,
        efectivoRecibido: efectivoRecibido,
      ),
    );
  }

  Future<bool> _runAction(
    Future<Map<String, dynamic>> Function() action,
  ) async {
    if (actionBusy) return false;
    actionBusy = true;
    actionMessage = null;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await action();
      actionMessage =
          (result['mensaje'] ??
                  result['message'] ??
                  'Operación confirmada por el servidor.')
              .toString();
      await load();
      actionBusy = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      actionBusy = false;
      notifyListeners();
      return false;
    }
  }
}
