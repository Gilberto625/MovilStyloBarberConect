import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/cita_models.dart';
import '../repositories/citas_repository.dart';
import 'home_guest_viewmodel.dart';

class ClientCitasViewModel extends ChangeNotifier {
  ClientCitasViewModel(this._repository);

  final CitasRepository _repository;

  LoadState state = LoadState.idle;
  String? errorMessage;
  List<CitaDto> citas = const [];
  List<BarberoDto> barberos = const [];
  List<SlotDisponibilidad> slots = const [];
  PoliticaPagoDto? politica;
  bool bookingBusy = false;
  bool barberosLoading = false;
  bool slotsLoading = false;
  String? bookingMessage;

  Future<void> loadMisCitas() async {
    state = LoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      citas = await _repository.getMisCitas();
      state = citas.isEmpty ? LoadState.empty : LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadBarberos({int? servicioId}) async {
    barberosLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      barberos = await _repository.getBarberos(servicioId: servicioId);
    } catch (e) {
      errorMessage = e.toString();
      barberos = const [];
    }
    barberosLoading = false;
    notifyListeners();
  }

  Future<void> loadDisponibilidad({
    required int barberoId,
    required String fecha,
    required int duracion,
  }) async {
    slotsLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      slots = await _repository.getDisponibilidad(
        barberoId: barberoId,
        fecha: fecha,
        duracion: duracion,
      );
    } catch (e) {
      errorMessage = e.toString();
      slots = const [];
    }
    slotsLoading = false;
    notifyListeners();
  }

  Future<void> loadPolitica(int clienteId) async {
    try {
      politica = await _repository.getPoliticaPago(clienteId);
    } catch (e) {
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> reservar({
    required AuthUser user,
    required int barberoId,
    required int servicioId,
    required int duracionMinutos,
    required String fecha,
    required String hora,
    required double precioTotal,
  }) async {
    bookingBusy = true;
    bookingMessage = null;
    errorMessage = null;
    notifyListeners();
    try {
      // Backend ignores client_id from body and forces authenticated user,
      // but still requires a positive cliente_id in the payload validation.
      final result = await _repository.crearCita(
        clienteId: user.id,
        barberoId: barberoId,
        servicioId: servicioId,
        duracionMinutos: duracionMinutos,
        fecha: fecha,
        hora: hora,
        precioTotal: precioTotal,
        anticipoPagado: 0,
      );
      bookingMessage = 'Cita creada (#${result['id'] ?? ''}).';
      bookingBusy = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      bookingBusy = false;
      notifyListeners();
      return false;
    }
  }
}
