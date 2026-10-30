import '../models/auth_models.dart';
import '../models/cita_models.dart';
import '../models/privacidad_models.dart';
import '../services/auth_api_service.dart';
import '../services/catalog_api_service.dart';
import '../services/citas_api_service.dart';
import '../services/privacidad_api_service.dart';

/// Derechos ARCO con los endpoints que ya existen (GH#42, GH#43) y el aviso de
/// privacidad con opt-in guardado en Django (GH#41, GH#45) y la cancelación
/// de la cuenta (GH#44).
class PrivacidadRepository {
  PrivacidadRepository({
    required AuthApiService auth,
    required CitasApiService citas,
    required CatalogApiService publico,
    required PrivacidadApiService preferencias,
  }) : _auth = auth,
       _citas = citas,
       _publico = publico,
       _preferencias = preferencias;

  final AuthApiService _auth;
  final CitasApiService _citas;
  final CatalogApiService _publico;
  final PrivacidadApiService _preferencias;

  Future<PerfilDto> getPerfil() => _auth.perfil();

  Future<List<CitaDto>> getHistorialCitas() => _citas.misCitas();

  Future<PerfilDto> actualizarPerfil(PerfilUpdate cambios) =>
      _auth.actualizarPerfil(cambios);

  /// El bloque `privacidad` de `/public/legal/`, o `null` si no está publicado.
  Future<ContenidoLegalDto?> getAvisoPrivacidad() => _legal('privacidad');

  /// El bloque `terminos` de `/public/legal/` (el mismo que la web muestra en
  /// `/nosotros?tipo=terminos`), o `null` si no está publicado.
  Future<ContenidoLegalDto?> getTerminos() => _legal('terminos');

  Future<ContenidoLegalDto?> _legal(String tipo) async {
    final contenidos = await _publico.fetchContenidoLegal(tipo: tipo);
    for (final c in contenidos) {
      if (c.tipo == tipo && c.contenido.trim().isNotEmpty) return c;
    }
    return null;
  }

  /// Verificación por correo al iniciar sesión (`/perfil/2fa/`).
  Future<Preferencia2fa> getPreferencia2fa() => _auth.preferencia2fa();

  Future<Preferencia2fa> guardarPreferencia2fa(bool activo) =>
      _auth.guardarPreferencia2fa(email2fa: activo);

  /// Preferencias del usuario autenticado, desde el servidor.
  Future<ConsentimientoPrivacidad> getConsentimiento() =>
      _preferencias.preferencias();

  /// Guarda en el servidor y devuelve lo que quedó guardado (con su fecha).
  Future<ConsentimientoPrivacidad> guardarConsentimiento(
    ConsentimientoPrivacidad c,
  ) => _preferencias.guardarPreferencias(c);

  /// Bloquea la cuenta en el servidor; la sesión local la cierra quien llama.
  Future<CancelacionCuenta> cancelarCuenta({
    required String contrasena,
    String motivo = '',
  }) => _preferencias.cancelarCuenta(contrasena: contrasena, motivo: motivo);
}
