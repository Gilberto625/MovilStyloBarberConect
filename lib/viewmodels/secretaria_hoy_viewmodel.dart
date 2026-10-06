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
  SecretariaDiaDto? dia;
  String filtroEstado = 'todas';

  List<SecretariaCitaDto> get citasFiltradas {
    final all = dia?.citas ?? const [];
    if (filtroEstado == 'todas') return all;
    return all.where((c) => c.estado == filtroEstado).toList();
  }

  Future<void> load({String? fecha}) async {
    state = LoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      dia = await _repository.getCitasDia(fecha: fecha);
      state = (dia?.citas.isEmpty ?? true) ? LoadState.empty : LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
    notifyListeners();
  }

  void setFiltro(String estado) {
    filtroEstado = estado;
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
  }) async {
    return _runAction(
      () => _repository.cobrar(
        citaId: citaId,
        metodoPago: metodoPago,
        comprobante: comprobante,
      ),
    );
  }

  Future<bool> _runAction(
    Future<Map<String, dynamic>> Function() action,
  ) async {
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
      await load(fecha: dia?.fecha);
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
