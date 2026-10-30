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

  // Alta de cliente. Con un servidor que acepta `sinVerificacion` la sesión
  // se abre al momento; si no, queda pendiente hasta confirmar el código.
  String? registroTempToken;
  String? registroDestino;
  String? registroCorreo;
  String? registroMensaje;

  /// El servidor sí mandó el código del alta (`email_enviado`).
  bool registroEmailEnviado = true;

  bool get hayRegistroPendiente =>
      registroTempToken != null && registroTempToken!.isNotEmpty;

  /// Devuelve `true` si la cuenta se creó. Con [phase] en
  /// [AuthPhase.authenticated] ya hay sesión; si no, falta el código.
  Future<bool> registrar(RegistroRequest datos) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final resultado = await _repository.registrar(datos);
      switch (resultado) {
        case RegistroCompletado(:final sesion):
          // Igual que tras confirmar el código: tokens y usuario guardados.
          user = await _repository.completeLogin(sesion);
          cancelarRegistro(notify: false);
          phase = AuthPhase.authenticated;
        case RegistroPendiente():
          registroTempToken = resultado.tempToken;
          registroDestino = resultado.destino;
          registroEmailEnviado = resultado.emailEnviado;
          registroCorreo = datos.correo.trim().toLowerCase();
          registroMensaje = resultado.mensaje;
      }
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

  Future<bool> verificarRegistro(String codigo) async {
    final token = registroTempToken;
    if (token == null || token.isEmpty) {
      errorMessage = 'No hay un registro pendiente de confirmar.';
      notifyListeners();
      return false;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(codigo.trim())) {
      errorMessage = 'Escribe los 6 dígitos del código.';
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      user = await _repository.verificarRegistro(
        tempToken: token,
        codigo: codigo,
      );
      cancelarRegistro(notify: false);
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

  Future<void> reenviarCodigoRegistro() async {
    final correo = registroCorreo;
    if (correo == null || correo.isEmpty) return;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      registroMensaje = await _repository.reenviarCodigoRegistro(correo);
    } catch (e) {
      errorMessage = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  void cancelarRegistro({bool notify = true}) {
    registroTempToken = null;
    registroDestino = null;
    registroCorreo = null;
    registroMensaje = null;
    registroEmailEnviado = true;
    if (notify) notifyListeners();
  }

  /// Limpia el error al cambiar de pantalla de acceso.
  void limpiarError() {
    if (errorMessage == null) return;
    errorMessage = null;
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
    perfil = null;
    phase = AuthPhase.guest;
    notifyListeners();
  }

  /// Último perfil leído de `GET /perfil/` (para saludar por el nombre).
  PerfilDto? perfil;

  /// Nombre para saludar: el primer nombre del perfil o, si no hay, el
  /// usuario.
  String get nombreCorto {
    final nombre = perfil?.nombre.trim() ?? '';
    if (nombre.isNotEmpty) return nombre.split(RegExp(r'\s+')).first;
    return user?.username ?? 'cliente';
  }

  Future<PerfilDto?> loadPerfil() async {
    // Sin sesión no hay perfil que pedir: evita un 401 que después se
    // mostraría como error en la pantalla de acceso.
    if (phase == AuthPhase.guest) return null;
    try {
      final leido = await _repository.getPerfil();
      // Si la sesión se cerró mientras llegaba la respuesta, se descarta.
      if (phase == AuthPhase.guest) return null;
      perfil = leido;
      notifyListeners();
      return perfil;
    } catch (e) {
      if (phase == AuthPhase.guest) return null;
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
