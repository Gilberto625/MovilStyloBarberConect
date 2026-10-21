import '../models/auth_models.dart';
import '../models/cita_models.dart';
import '../models/privacidad_models.dart';
import '../services/auth_api_service.dart';
import '../services/catalog_api_service.dart';
import '../services/citas_api_service.dart';
import '../services/privacidad_api_service.dart';

/// Derechos ARCO con los endpoints que ya existen (GH#42, GH#43) y el aviso de
/// privacidad con opt-in guardado en Django (GH#41, GH#45). La cancelación
/// todavía no tiene endpoint.
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
  Future<ContenidoLegalDto?> getAvisoPrivacidad() async {
    final contenidos = await _publico.fetchContenidoLegal(tipo: 'privacidad');
    for (final c in contenidos) {
      if (c.tipo == 'privacidad' && c.contenido.trim().isNotEmpty) return c;
    }
    return null;
  }

  /// Preferencias del usuario autenticado, desde el servidor.
  Future<ConsentimientoPrivacidad> getConsentimiento() =>
      _preferencias.preferencias();

  /// Guarda en el servidor y devuelve lo que quedó guardado (con su fecha).
  Future<ConsentimientoPrivacidad> guardarConsentimiento(
    ConsentimientoPrivacidad c,
  ) => _preferencias.guardarPreferencias(c);
}
