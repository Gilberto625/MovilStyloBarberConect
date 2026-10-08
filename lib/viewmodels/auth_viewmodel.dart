import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';

enum AuthPhase { bootstrapping, guest, needs2fa, authenticated }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);

  final AuthRepository _repository;

  AuthPhase phase = AuthPhase.bootstrapping;
  AuthUser? user;
  String? errorMessage;
  bool busy = false;

  String? pendingTempToken;
  String? pendingDestino;
  String? pendingMensaje;

  UserRole get role => user?.rol ?? UserRole.unknown;

  Future<void> bootstrap() async {
    phase = AuthPhase.bootstrapping;
    notifyListeners();
    final restored = await _repository.restoreSession();
    user = restored;
    phase = restored == null ? AuthPhase.guest : AuthPhase.authenticated;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.login(email: email, password: password);
      if (result is LoginRequires2FA) {
        pendingTempToken = result.tempToken;
        pendingDestino = result.destino;
        pendingMensaje = result.mensaje;
        phase = AuthPhase.needs2fa;
        busy = false;
        notifyListeners();
        return false;
      }
      if (result is LoginSuccess) {
        user = await _repository.completeLogin(result);
        pendingTempToken = null;
        phase = AuthPhase.authenticated;
        busy = false;
        notifyListeners();
        return true;
      }
      errorMessage = 'Respuesta de login no reconocida.';
    } catch (e) {
      errorMessage = e.toString();
    }
    busy = false;
    notifyListeners();
    return false;
  }

  Future<bool> verify2fa(String codigo) async {
    final token = pendingTempToken;
    if (token == null || token.isEmpty) {
      errorMessage = 'No hay verificación 2FA pendiente.';
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      user = await _repository.verify2fa(tempToken: token, codigo: codigo);
      pendingTempToken = null;
      phase = AuthPhase.authenticated;
      busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> resend2fa() async {
    final token = pendingTempToken;
    if (token == null) return;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.resend2fa(token);
      pendingMensaje = 'Código reenviado.';
    } catch (e) {
      errorMessage = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  void cancel2fa() {
    pendingTempToken = null;
    pendingDestino = null;
    pendingMensaje = null;
    phase = AuthPhase.guest;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repository.logoutLocal();
    user = null;
    phase = AuthPhase.guest;
    notifyListeners();
  }

  Future<PerfilDto?> loadPerfil() async {
    try {
      return await _repository.getPerfil();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
