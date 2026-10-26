import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/catalog_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/models/pedido_models.dart';
import 'package:stylo_barber_connect/routes/app_routes.dart';
import 'package:stylo_barber_connect/services/pedidos_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/catalog_list_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/client_citas_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/tienda_viewmodel.dart';
import 'package:stylo_barber_connect/views/client/client_home_view.dart';
import 'package:stylo_barber_connect/views/client/client_widgets.dart';

import 'mocks/mocks.mocks.dart';
import 'support/memory_token_storage.dart';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ProductoDto _producto({int id = 5, int stock = 3, double precio = 180}) =>
    ProductoDto(
      id: id,
      nombre: 'Pomada mate $id',
      marca: 'Barber Shot',
      descripcion: '',
      precio: precio,
      categoria: 'cabello',
      stock: stock,
      imagenUrl: '',
      destacado: false,
    );

const _servicio = ServicioDto(
  id: 1,
  nombre: 'Corte Fade',
  descripcion: '',
  precio: 200,
  duracionMinutos: 60,
  categoria: 'corte',
  popular: true,
  activo: true,
  imagenUrl: '',
  bannerUrl: '',
);

const _barbero = BarberoDto(
  id: 7,
  nombre: 'Luis',
  apellido: 'Mora',
  especialidades: 'Fade y barba',
  avatarUrl: '',
  serviciosIds: [1],
);

CitaDto _cita({
  int id = 3,
  String estado = 'confirmada',
  String fecha = '2026-10-14',
}) => CitaDto(
  id: id,
  servicioId: 1,
  servicioNombre: 'Corte Fade',
  servicioImagen: '',
  fecha: fecha,
  hora: '11:00:00',
  duracionMinutos: 60,
  estado: estado,
  precioTotal: 200,
  anticipoPagado: 0,
  saldoPendiente: 200,
  notas: '',
  barberoNombre: 'Luis Mora',
  requierePago: false,
);

const _politicaLibre = PoliticaPagoDto(
  requiereAnticipo: false,
  porcentajeAnticipo: 0,
  penalizado: false,
  totalInasistencias: 0,
);

class _Entorno {
  _Entorno() {
    when(auth.restoreSession()).thenAnswer(
      (_) async => const AuthUser(
        id: 4,
        username: 'cliente.prueba',
        email: 'g@correo.mx',
        rol: UserRole.cliente,
      ),
    );
    when(auth.getPerfil()).thenAnswer(
      (_) async => PerfilDto.fromJson({
        'email': 'g@correo.mx',
        'username': 'Gilberto',
        'nombre': 'Gilberto',
        'apellido': 'Hernández',
      }),
    );
    when(citas.getMisCitas()).thenAnswer((_) async => misCitas);
    when(citas.getBarberos(servicioId: anyNamed('servicioId')))
        .thenAnswer((_) async => const [_barbero]);
    when(
      citas.getDisponibilidad(
        barberoId: anyNamed('barberoId'),
        fecha: anyNamed('fecha'),
        duracion: anyNamed('duracion'),
      ),
    ).thenAnswer(
      (_) async => const [
        SlotDisponibilidad(hora: '10:00', disponible: false),
        SlotDisponibilidad(hora: '11:30', disponible: true),
      ],
    );
    when(citas.getPoliticaPago(any)).thenAnswer((_) async => politica);
    when(catalogo.getServicios()).thenAnswer((_) async => const [_servicio]);
    when(catalogo.getProductos()).thenAnswer((_) async => productos);
  }

  final auth = MockAuthRepository();
  final citas = MockCitasRepository();
  final catalogo = MockCatalogRepository();
  final pedidos = MockPedidosRepository();
  List<CitaDto> misCitas = [_cita()];
  List<ProductoDto> productos = [_producto(), _producto(id: 6, stock: 0)];
  PoliticaPagoDto politica = _politicaLibre;
}

Future<void> _pump(
  WidgetTester tester,
  _Entorno e, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final auth = AuthViewModel(e.auth);
  await auth.bootstrap();
  final citas = ClientCitasViewModel(e.citas);
  final catalog = CatalogListViewModel(e.catalogo);
  addTearDown(auth.dispose);
  addTearDown(citas.dispose);
  addTearDown(catalog.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider<ClientCitasViewModel>.value(value: citas),
        ChangeNotifierProvider<CatalogListViewModel>.value(value: catalog),
      ],
      child: MaterialApp(
        theme: AppTheme.panel(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: ClientHomeShell(
          crearTienda: (_) =>
              TiendaViewModel(catalogo: e.catalogo, pedidos: e.pedidos),
        ),
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tab(WidgetTester tester, String tab) async {
  await tester.tap(find.byKey(ValueKey('cliente-nav-$tab')));
  await tester.pumpAndSettle();
}

void main() {
  // Las citas de estas pruebas tienen fechas fijas de octubre de 2026.
  setUp(() => relojCliente = () => DateTime(2026, 10, 1));
  tearDown(() => relojCliente = DateTime.now);

  group('Fechas legibles', () {
    test('fecha larga, corta, ISO y hora sin segundos', () {
      expect(fechaLarga('2026-10-14'), 'Miércoles 14 de octubre');
      expect(fechaLarga('sin fecha'), 'sin fecha');
      expect(fechaCorta('2026-10-14'), (dia: '14', mes: 'oct'));
      expect(isoFecha(DateTime(2026, 3, 5)), '2026-03-05');
      expect(horaCorta('9:05:00'), '09:05');
    });
  });

  group('Contrato de pedidos (PedidosView)', () {
    late List<http.Request> peticiones;
    PedidosApiService servicio(http.Response Function(http.Request) r) {
      peticiones = [];
      return PedidosApiService(
        ApiClient(
          tokenStorage: MemoryTokenStorage(access: 'token-cliente'),
          httpClient: MockClient((req) async {
            peticiones.add(req);
            return r(req);
          }),
          baseUrl: 'http://10.0.2.2:8000/api',
        ),
      );
    }

    test('crear: items, recoger en local, efectivo y con Bearer', () async {
      final api = servicio(
        (_) => _json({
          'ok': true,
          'pedido_id': 41,
          'estado': 'pendiente',
          'total': 360.0,
        }, 200),
      );
      final creado = await api.crearPedido(
        lineas: [CarritoLinea(producto: _producto(), cantidad: 2)],
        notas: ' Paso a las 6 ',
      );

      expect(creado.pedidoId, 41);
      expect(creado.total, 360);
      final r = peticiones.single;
      expect(r.url.path, '/api/pedidos/crear/');
      expect(r.headers['Authorization'], 'Bearer token-cliente');
      expect(jsonDecode(r.body), {
        'items': [
          {'producto_id': 5, 'cantidad': 2},
        ],
        'metodo_entrega': 'recoger_local',
        'metodo_pago': 'efectivo',
        'notas': 'Paso a las 6',
      });
    });

    test('stock insuficiente llega con el mensaje del servidor', () async {
      final api = servicio(
        (_) => _json({
          'ok': false,
          'error': 'Stock insuficiente para Pomada. Disponible: 1.',
        }, 400),
      );
      expect(
        () => api.crearPedido(
          lineas: [CarritoLinea(producto: _producto(), cantidad: 2)],
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Stock insuficiente'),
          ),
        ),
      );
    });

    test('mis pedidos con items', () async {
      final api = servicio(
        (_) => _json({
          'ok': true,
          'pedidos': [
            {
              'id': 41,
              'estado': 'pendiente',
              'total': 360.0,
              'fecha_creacion': '2026-10-20T18:00:00',
              'items': [
                {
                  'producto_id': 5,
                  'producto_nombre': 'Pomada mate',
                  'cantidad': 2,
                  'precio_unitario': 180.0,
                  'subtotal': 360.0,
                },
              ],
            },
          ],
        }, 200),
      );
      final lista = await api.misPedidos();
      expect(lista.single.piezas, 2);
      expect(lista.single.items.single.nombre, 'Pomada mate');
      expect(peticiones.single.method, 'GET');
    });
  });

  group('TiendaViewModel', () {
    test('no pasa de las existencias y quita la línea al llegar a cero', () {
      final e = _Entorno();
      final vm = TiendaViewModel(catalogo: e.catalogo, pedidos: e.pedidos);
      final p = _producto(stock: 2);

      expect(vm.agregar(p), isTrue);
      expect(vm.agregar(p), isTrue);
      expect(vm.agregar(p), isFalse);
      expect(vm.piezas, 2);
      expect(vm.totalEstimado, 360);
      expect(vm.agregar(_producto(id: 6, stock: 0)), isFalse);

      vm.quitarUno(p.id);
      vm.quitarUno(p.id);
      expect(vm.carritoVacio, isTrue);
    });

    test('un pedido fallido conserva el carrito y muestra el error', () async {
      final e = _Entorno();
      when(
        e.pedidos.crearPedido(
          lineas: anyNamed('lineas'),
          notas: anyNamed('notas'),
        ),
      ).thenThrow(ApiException('Stock insuficiente.'));
      final vm = TiendaViewModel(catalogo: e.catalogo, pedidos: e.pedidos);
      vm.agregar(_producto());

      expect(await vm.hacerPedido(), isFalse);
      expect(vm.piezas, 1);
      expect(vm.pedidoError, 'Stock insuficiente.');
    });
  });

  group('Panel del cliente', () {
    testWidgets('la próxima cita se ve como boleto con hora y fecha legibles', (
      tester,
    ) async {
      await _pump(tester, _Entorno());

      // Saluda con el nombre del perfil, no con el usuario.
      expect(find.text('Hola, Gilberto'), findsOneWidget);
      expect(find.textContaining('cliente.prueba'), findsNothing);
      final boleto = find.byKey(const Key('inicio_proxima_cita'));
      expect(boleto, findsOneWidget);
      expect(
        find.descendant(of: boleto, matching: find.text('11:00')),
        findsOneWidget,
      );
      expect(find.text('Miércoles 14 de octubre'), findsOneWidget);
      expect(find.text('Confirmada'), findsOneWidget);
    });

    testWidgets('Mis citas separa próximas e historial', (tester) async {
      final e = _Entorno()
        ..misCitas = [
          _cita(),
          _cita(id: 4, estado: 'completada', fecha: '2026-09-01'),
        ];
      await _pump(tester, e);
      await _tab(tester, 'citas');

      expect(find.byKey(const ValueKey('cita-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('cita-4')), findsNothing);
      await tester.tap(find.text('Historial (1)'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cita-4')), findsOneWidget);
      expect(find.text('Completada'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cita-4')));
      await tester.pumpAndSettle();
      expect(find.text('Detalle de cita'), findsOneWidget);
      expect(find.text('Por pagar'), findsOneWidget);
      expect(
        find.text('¿Necesitas cambiarla?'),
        findsNothing,
        reason: 'Una cita cerrada no ofrece cambios.',
      );
    });

    testWidgets('Agendar: Atrás retrocede un paso antes de salir', (
      tester,
    ) async {
      await _pump(tester, _Entorno());
      await _tab(tester, 'agendar');
      await tester.tap(find.text('Corte Fade'));
      await tester.pumpAndSettle();
      expect(find.text('Paso 2 de 4: Barbero'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Paso 1 de 4: Servicio'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Hola, Gilberto'), findsOneWidget);
    });

    testWidgets('Agendar: solo se ofrecen horarios libres', (tester) async {
      await _pump(tester, _Entorno());
      await _tab(tester, 'agendar');
      await tester.tap(find.text('Corte Fade'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Luis Mora'));
      await tester.pumpAndSettle();

      expect(find.text('11:30'), findsOneWidget);
      expect(find.text('10:00'), findsNothing);
      expect(find.byKey(const Key('agendar_continuar')), findsNothing);
    });

    testWidgets('Agendar: con anticipo obligatorio no deja confirmar', (
      tester,
    ) async {
      final e = _Entorno()
        ..politica = const PoliticaPagoDto(
          requiereAnticipo: true,
          porcentajeAnticipo: 50,
          penalizado: true,
          totalInasistencias: 2,
        );
      await _pump(tester, e);
      await _tab(tester, 'agendar');
      await tester.tap(find.text('Corte Fade'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Luis Mora'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('11:30'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('agendar_continuar')));
      await tester.pumpAndSettle();

      expect(find.textContaining('anticipo del 50 %'), findsOneWidget);
      final boton = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('agendar_confirmar')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(boton.onPressed, isNull);
      verifyNever(
        e.citas.crearCita(
          clienteId: anyNamed('clienteId'),
          barberoId: anyNamed('barberoId'),
          servicioId: anyNamed('servicioId'),
          duracionMinutos: anyNamed('duracionMinutos'),
          fecha: anyNamed('fecha'),
          hora: anyNamed('hora'),
          precioTotal: anyNamed('precioTotal'),
          anticipoPagado: anyNamed('anticipoPagado'),
        ),
      );
    });

    testWidgets('PA-09 tienda: agregar, carrito y pedido creado en Django', (
      tester,
    ) async {
      final e = _Entorno();
      when(
        e.pedidos.crearPedido(
          lineas: anyNamed('lineas'),
          notas: anyNamed('notas'),
        ),
      ).thenAnswer(
        (_) async =>
            const PedidoCreado(pedidoId: 41, estado: 'pendiente', total: 180),
      );
      when(e.pedidos.misPedidos()).thenAnswer((_) async => const []);
      await _pump(tester, e);
      await _tab(tester, 'tienda');

      expect(find.text('Agotado'), findsOneWidget);
      expect(find.byKey(const ValueKey('tienda-agregar-6')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('tienda-agregar-5')));
      await tester.pumpAndSettle();
      expect(find.text('Ver carrito (1)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tienda_ver_carrito')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('carrito-linea-5')), findsOneWidget);
      await tester.tap(find.byKey(const Key('carrito_pedir')));
      await tester.pumpAndSettle();

      expect(find.text('Pedido #41 recibido'), findsOneWidget);
      final llamada = verify(
        e.pedidos.crearPedido(
          lineas: captureAnyNamed('lineas'),
          notas: anyNamed('notas'),
        ),
      )..called(1);
      final lineas = llamada.captured.single as List<CarritoLinea>;
      expect(lineas.single.producto.id, 5);
      expect(lineas.single.cantidad, 1);
    });

    for (final tab in ['inicio', 'agendar', 'citas', 'tienda', 'perfil']) {
      testWidgets('$tab a 360x800 con texto 1.3 no desborda', (tester) async {
        final e = _Entorno();
        when(e.auth.getPerfil()).thenAnswer(
          (_) async => PerfilDto.fromJson({
            'email': 'gilberto.hernandez.hernandez@correo-largo.mx',
            'username': 'gilberto',
            'nombre': 'Gilberto',
            'apellido': 'Hernández Hernández',
          }),
        );
        await _pump(tester, e, size: const Size(360, 800), textScale: 1.3);
        await _tab(tester, tab);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
