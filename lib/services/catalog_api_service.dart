import '../core/network/api_client.dart';
import '../models/catalog_models.dart';

class CatalogApiService {
  CatalogApiService(this._api);

  final ApiClient _api;

  Future<List<ServicioDto>> fetchServicios() async {
    final raw = await _api.get('/public/servicios/', auth: false);
    final list = _extractList(raw, key: 'servicios');
    return list
        .whereType<Map>()
        .map((e) => ServicioDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ProductoDto>> fetchProductos() async {
    final raw = await _api.get('/public/productos/', auth: false);
    // Backend returns a bare array (not {ok, productos}).
    final list = raw is List ? raw : _extractList(raw, key: 'productos');
    return list
        .whereType<Map>()
        .map((e) => ProductoDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ContactoDto> fetchContacto() async {
    final raw = await _api.get('/public/contacto/', auth: false);
    if (raw is Map) {
      return ContactoDto.fromJson(Map<String, dynamic>.from(raw));
    }
    return ContactoDto.empty();
  }

  List<dynamic> _extractList(dynamic raw, {required String key}) {
    if (raw is List) return raw;
    if (raw is Map && raw[key] is List) return raw[key] as List;
    return const [];
  }
}
