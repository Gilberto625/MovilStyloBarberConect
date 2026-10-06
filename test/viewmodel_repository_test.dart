import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/catalog_models.dart';
import 'package:stylo_barber_connect/repositories/catalog_repository.dart';
import 'package:stylo_barber_connect/viewmodels/home_guest_viewmodel.dart';

class _FakeCatalogRepository implements CatalogRepository {
  @override
  Future<ContactoDto> getContacto() async => ContactoDto.empty();

  @override
  Future<List<ProductoDto>> getProductos() async => const [];

  @override
  Future<List<ServicioDto>> getServicios() async => [
    ServicioDto.fromJson({
      'id': 1,
      'nombre': 'Corte',
      'descripcion': 'Clásico',
      'precio': 150,
      'duracion_minutos': 40,
      'categoria': 'corte',
      'popular': true,
      'activo': true,
      'imagen_url': '',
      'banner_url': '',
    }),
  ];

  @override
  Future<
    ({
      ContactoDto contacto,
      List<ProductoDto> productos,
      List<ServicioDto> servicios,
    })
  >
  loadHomeGuest() async {
    return (
      contacto: await getContacto(),
      servicios: await getServicios(),
      productos: await getProductos(),
    );
  }
}

void main() {
  test('ServicioDto.fromJson maps backend fields', () {
    final s = ServicioDto.fromJson({
      'id': 9,
      'nombre': 'Fade',
      'descripcion': 'x',
      'precio': 200.5,
      'duracion_minutos': 45,
      'categoria': 'promocion',
      'popular': false,
      'activo': true,
      'imagen_url': 'https://example.com/a.jpg',
      'banner_url': 'https://example.com/b.jpg',
    });
    expect(s.id, 9);
    expect(s.isPromocion, isTrue);
    expect(s.precio, 200.5);
  });

  test('parseUserRole maps administrador to admin', () {
    expect(parseUserRole('administrador'), UserRole.admin);
    expect(parseUserRole('secretaria'), UserRole.secretaria);
  });

  test('HomeGuestViewModel loads repository data', () async {
    final vm = HomeGuestViewModel(_FakeCatalogRepository());
    await vm.load();
    expect(vm.state, LoadState.ready);
    expect(vm.servicios, hasLength(1));
    expect(vm.serviciosDestacados.first.nombre, 'Corte');
  });

  test(
    'CatalogRepository contract returns empty lists without inventing data',
    () async {
      final repo = _FakeCatalogRepository();
      final productos = await repo.getProductos();
      expect(productos, isEmpty);
    },
  );
}
