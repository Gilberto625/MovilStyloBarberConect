import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../models/cita_models.dart';
import '../models/privacidad_models.dart';
import '../repositories/privacidad_repository.dart';
import 'home_guest_viewmodel.dart';

/// ARCO Acceso (GH#42): perfil e historial de citas del propio titular.
class MisDatosViewModel extends ChangeNotifier {
  MisDatosViewModel(this._repository);

  final PrivacidadRepository _repository;

  LoadState state = LoadState.idle;
  String? errorMessage;
  PerfilDto? perfil;
  List<CitaDto> citas = const [];

  /// Error solo del historial. El perfil se muestra aunque falle.
  String? citasError;

  Future<void> load() async {
    state = LoadState.loading;
    errorMessage = null;
    citasError = null;
    notifyListeners();
    try {
      perfil = await _repository.getPerfil();
    } catch (e) {
      perfil = null;
      errorMessage = e.toString();
      state = LoadState.error;
      notifyListeners();
      return;
    }
    try {
      citas = await _repository.getHistorialCitas();
    } catch (e) {
      citas = const [];
      citasError = e.toString();
    }
    state = LoadState.ready;
    notifyListeners();
  }
}

/// ARCO Rectificación (GH#43): `PUT /perfil/` con los campos que Django acepta.
class EditarPerfilViewModel extends ChangeNotifier {
  EditarPerfilViewModel(this._repository);

  final PrivacidadRepository _repository;

  LoadState state = LoadState.idle;
  String? errorMessage;
  PerfilDto? perfil;
  bool saving = false;

  Future<void> load() async {
    state = LoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      perfil = await _repository.getPerfil();
      state = LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
    notifyListeners();
  }

  /// Envía los cambios una sola vez. Conserva `avatar_url` y la dirección del
  /// perfil cargado para que el reemplazo completo de Django no los borre.
  Future<bool> guardar({
    required String nombre,
    required String apellido,
    required String telefono,
    required String fechaNacimiento,
    required String direccion,
  }) async {
    final base = perfil;
    if (base == null || saving) return false;
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      perfil = await _repository.actualizarPerfil(
        PerfilUpdate.desde(base).copyWith(
          nombre: nombre,
          apellido: apellido,
          telefono: telefono,
          fechaNacimiento: fechaNacimiento,
          direccion: direccion,
        ),
      );
      saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      saving = false;
      notifyListeners();
      return false;
    }
  }
}

/// Aviso de privacidad (6.6) y opt-in de finalidades secundarias (6.7, GH#41).
///
/// El aviso es público. Las preferencias viven en Django y son de la cuenta:
/// sin sesión se puede leer el aviso, pero no elegir.
class AvisoPrivacidadViewModel extends ChangeNotifier {
  AvisoPrivacidadViewModel(this._repository, {required this.autenticado});

  final PrivacidadRepository _repository;
  final bool autenticado;

  LoadState state = LoadState.idle;
  String? errorMessage;
  ContenidoLegalDto? aviso;

  /// Lo guardado en el servidor. Sin respuesta previa, todo apagado.
  ConsentimientoPrivacidad guardado = ConsentimientoPrivacidad.sinRespuesta;

  /// Lo que la persona va marcando antes de guardar.
  ConsentimientoPrivacidad borrador = ConsentimientoPrivacidad.sinRespuesta;

  /// Las preferencias ya llegaron del servidor (solo con sesión).
  bool preferenciasListas = false;

  /// Error al leer o guardar preferencias. El aviso se sigue mostrando.
  String? preferenciasError;
  bool saving = false;
  String? mensaje;

  /// Solo se puede elegir con sesión, con el aviso a la vista y con lo
  /// guardado ya cargado (para no pisarlo con valores por defecto).
  bool get puedeGuardar =>
      autenticado && state == LoadState.ready && preferenciasListas && !saving;

  /// El aviso cambió desde la última vez que se respondió.
  bool get avisoCambio =>
      guardado.respondido &&
      aviso != null &&
      guardado.versionAviso != aviso!.version;

  Future<void> load() async {
    state = LoadState.loading;
    errorMessage = null;
    mensaje = null;
    notifyListeners();
    try {
      aviso = await _repository.getAvisoPrivacidad();
      state = aviso == null ? LoadState.empty : LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
    if (autenticado && state == LoadState.ready) {
      await cargarPreferencias();
      return;
    }
    notifyListeners();
  }

  Future<void> cargarPreferencias() async {
    preferenciasError = null;
    try {
      guardado = await _repository.getConsentimiento();
      borrador = guardado;
      preferenciasListas = true;
    } catch (e) {
      preferenciasListas = false;
      preferenciasError = e.toString();
    }
    notifyListeners();
  }

  void setPromociones(bool value) =>
      _editar(borrador.copyWith(promociones: value));

  void setRecordatoriosWhatsapp(bool value) =>
      _editar(borrador.copyWith(recordatoriosWhatsapp: value));

  void setAnaliticaPerfilado(bool value) =>
      _editar(borrador.copyWith(analiticaPerfilado: value));

  void _editar(ConsentimientoPrivacidad value) {
    borrador = value;
    mensaje = null;
    notifyListeners();
  }

  Future<bool> guardar() async {
    final avisoActual = aviso;
    if (!puedeGuardar || avisoActual == null) return false;
    saving = true;
    preferenciasError = null;
    notifyListeners();
    try {
      final enServidor = await _repository.guardarConsentimiento(
        borrador.copyWith(versionAviso: avisoActual.version),
      );
      guardado = enServidor;
      borrador = enServidor;
      mensaje = 'Preferencias guardadas en tu cuenta.';
      saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      preferenciasError = e.toString();
      saving = false;
      notifyListeners();
      return false;
    }
  }
}

/// Perfil › Privacidad › Eliminar mi cuenta (ARCO GH#44, requisito de Play).
/// Pide la contraseña y escribir "ELIMINAR" antes de llamar al servidor.
class EliminarCuentaViewModel extends ChangeNotifier {
  EliminarCuentaViewModel(this._repository);

  static const palabraConfirmacion = 'ELIMINAR';

  final PrivacidadRepository _repository;

  String contrasena = '';
  String confirmacion = '';
  String motivo = '';
  bool enviando = false;
  String? error;
  CancelacionCuenta? resultado;

  bool get puedeEnviar =>
      !enviando &&
      contrasena.isNotEmpty &&
      confirmacion.trim().toUpperCase() == palabraConfirmacion;

  void setContrasena(String v) {
    contrasena = v;
    notifyListeners();
  }

  void setConfirmacion(String v) {
    confirmacion = v;
    notifyListeners();
  }

  void setMotivo(String v) => motivo = v;

  Future<bool> enviar() async {
    if (!puedeEnviar) return false;
    enviando = true;
    error = null;
    notifyListeners();
    try {
      resultado = await _repository.cancelarCuenta(
        contrasena: contrasena,
        motivo: motivo,
      );
      contrasena = '';
      enviando = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      enviando = false;
      notifyListeners();
      return false;
    }
  }
}

/// Términos de uso desde `/public/legal/?tipo=terminos`. Son públicos: se
/// leen sin sesión, por ejemplo antes de crear la cuenta.
class TerminosViewModel extends ChangeNotifier {
  TerminosViewModel(this._repository);

  final PrivacidadRepository _repository;

  LoadState state = LoadState.idle;
  String? errorMessage;
  ContenidoLegalDto? terminos;

  Future<void> load() async {
    state = LoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      terminos = await _repository.getTerminos();
      state = terminos == null ? LoadState.empty : LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
    notifyListeners();
  }
}

/// Perfil › Privacidad › "Pedir código por correo al iniciar sesión"
/// (`/perfil/2fa/`). Apagado por defecto; el valor manda el servidor.
class Verificacion2faViewModel extends ChangeNotifier {
  Verificacion2faViewModel(this._repository);

  final PrivacidadRepository _repository;

  LoadState state = LoadState.idle;
  String? errorMessage;
  Preferencia2fa? preferencia;
  bool guardando = false;

  /// Error al guardar. Se conserva el valor anterior del servidor.
  String? errorGuardar;
  String? mensaje;

  bool get activo => preferencia?.email2fa ?? false;

  bool get puedeCambiar =>
      state == LoadState.ready &&
      !guardando &&
      (preferencia?.puedeGestionar ?? false);

  Future<void> load() async {
    state = LoadState.loading;
    errorMessage = null;
    errorGuardar = null;
    mensaje = null;
    notifyListeners();
    try {
      preferencia = await _repository.getPreferencia2fa();
      state = LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
    notifyListeners();
  }

  /// Guarda en el servidor y muestra lo que quedó guardado.
  Future<bool> cambiar(bool valor) async {
    if (!puedeCambiar || valor == activo) return false;
    guardando = true;
    errorGuardar = null;
    mensaje = null;
    notifyListeners();
    try {
      final guardada = await _repository.guardarPreferencia2fa(valor);
      // El PUT no trae `puede_gestionar`: se conserva el de la lectura.
      preferencia = Preferencia2fa(
        email2fa: guardada.email2fa,
        puedeGestionar: preferencia?.puedeGestionar ?? true,
        motivoBloqueo: preferencia?.motivoBloqueo ?? '',
        proveedorAuth: guardada.proveedorAuth,
      );
      mensaje = guardada.email2fa
          ? 'Listo. Te pediremos un código al iniciar sesión.'
          : 'Listo. Entrarás solo con tu contraseña.';
      guardando = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorGuardar = e.toString();
      guardando = false;
      notifyListeners();
      return false;
    }
  }
}
