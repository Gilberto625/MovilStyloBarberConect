import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/models/catalog_models.dart';
import 'package:stylo_barber_connect/repositories/catalog_repository.dart';
import 'package:stylo_barber_connect/viewmodels/home_guest_viewmodel.dart';
import 'package:stylo_barber_connect/views/guest/guest_home_view.dart';
import 'package:stylo_barber_connect/widgets/common_widgets.dart';

class _EmptyRepo implements CatalogRepository {
  @override
  Future<ContactoDto> getContacto() async => ContactoDto.empty();

  @override
  Future<List<ProductoDto>> getProductos() async => const [];

  @override
  Future<List<ServicioDto>> getServicios() async => const [];

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
      contacto: ContactoDto.empty(),
      servicios: const <ServicioDto>[],
      productos: const <ProductoDto>[],
    );
  }
}

void main() {
  testWidgets('Guest home shows brand and empty catalog message', (
    tester,
  ) async {
    final vm = HomeGuestViewModel(_EmptyRepo());
    await tester.pumpWidget(
      ChangeNotifierProvider<HomeGuestViewModel>.value(
        value: vm,
        child: MaterialApp(
          home: const GuestHomeView(),
          routes: {
            '/login': (_) => const Scaffold(body: Text('login-page')),
            '/servicios': (_) => const Scaffold(body: Text('servicios')),
            '/productos': (_) => const Scaffold(body: Text('productos')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BrandTitle), findsOneWidget);
    expect(
      find.textContaining('No hay servicios ni productos'),
      findsOneWidget,
    );
    expect(find.text('Reservar cita'), findsOneWidget);
  });
}
