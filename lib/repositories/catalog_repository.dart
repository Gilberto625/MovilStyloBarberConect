import '../models/catalog_models.dart';
import '../services/catalog_api_service.dart';

abstract class CatalogRepository {
  Future<List<ServicioDto>> getServicios();
  Future<List<ProductoDto>> getProductos();
  Future<ContactoDto> getContacto();
  Future<
    ({
      ContactoDto contacto,
      List<ServicioDto> servicios,
      List<ProductoDto> productos,
    })
  >
  loadHomeGuest();
}

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._api);

  final CatalogApiService _api;

  @override
  Future<List<ServicioDto>> getServicios() => _api.fetchServicios();

  @override
  Future<List<ProductoDto>> getProductos() => _api.fetchProductos();

  @override
  Future<ContactoDto> getContacto() => _api.fetchContacto();

  @override
  Future<
    ({
      ContactoDto contacto,
      List<ServicioDto> servicios,
      List<ProductoDto> productos,
    })
  >
  loadHomeGuest() async {
    final results = await Future.wait([
      getContacto(),
      getServicios(),
      getProductos(),
    ]);
    return (
      contacto: results[0] as ContactoDto,
      servicios: results[1] as List<ServicioDto>,
      productos: results[2] as List<ProductoDto>,
    );
  }
}
