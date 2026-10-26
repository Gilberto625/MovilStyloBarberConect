import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/models/catalog_models.dart';
import 'package:stylo_barber_connect/repositories/catalog_repository.dart';
import 'package:stylo_barber_connect/routes/app_routes.dart';
import 'package:stylo_barber_connect/viewmodels/home_guest_viewmodel.dart';
import 'package:stylo_barber_connect/views/guest/guest_contacto_view.dart';
import 'package:stylo_barber_connect/views/guest/guest_home_view.dart';
import 'package:stylo_barber_connect/views/guest/guest_premium_widgets.dart';
import 'package:stylo_barber_connect/widgets/common_widgets.dart';

typedef _HomeData = ({
  ContactoDto contacto,
  List<ServicioDto> servicios,
  List<ProductoDto> productos,
});

const _service = ServicioDto(
  id: 17,
  nombre: 'Corte clásico con acabado personalizado, lavado y peinado premium',
  descripcion: 'Servicio del catálogo de prueba con descripción extensa.',
  precio: 275.50,
  duracionMinutos: 45,
  categoria: 'corte',
  popular: true,
  activo: true,
  imagenUrl: '',
  bannerUrl: '',
);

const _product = ProductoDto(
  id: 23,
  nombre: 'Pomada profesional de fijación para peinados y acabado natural',
  marca: 'Marca profesional de barbería con un nombre especialmente largo',
  descripcion: 'Producto del catálogo de prueba.',
  precio: 189.90,
  categoria: 'cabello',
  stock: 4,
  imagenUrl: '',
  destacado: true,
);

ContactoDto _contact({
  List<Map<String, Object?>>? horarios,
  String horario = '',
  String whatsapp = '',
  String maps = '',
}) {
  return ContactoDto.fromJson({
    'telefono': '5550001234',
    'correo': 'contacto@example.invalid',
    'direccion':
        'Avenida del Estilo número 123, local 4, colonia Centro de la ciudad',
    'horario': horario,
    'nombre_negocio':
        'Tony Stylo Barbería y cuidado profesional del cabello y la barba',
    'logo_tipo': 'texto',
    'logo_texto_parte1': 'Tony Stylo',
    'logo_texto_parte2': 'Barbería',
    'logo_url': '',
    'whatsapp_url': whatsapp,
    'google_maps_url': maps,
    'horarios_por_dia': horarios ?? _wholeWeek,
  });
}

// Deliberately unordered: the parser and the UI must preserve the supplied
// values while presenting the actual week in Monday-to-Sunday order.
const _wholeWeek = <Map<String, Object?>>[
  {'dia_semana': 6, 'abierto': false},
  {'dia_semana': 3, 'abierto': true, 'apertura': '09:15', 'cierre': '18:45'},
  {'dia_semana': 0, 'abierto': true, 'apertura': '09:15', 'cierre': '18:45'},
  {'dia_semana': 5, 'abierto': true, 'apertura': '10:30', 'cierre': '16:00'},
  {'dia_semana': 1, 'abierto': true, 'apertura': '09:15', 'cierre': '18:45'},
  {'dia_semana': 4, 'abierto': true, 'apertura': '09:15', 'cierre': '18:45'},
  {'dia_semana': 2, 'abierto': true, 'apertura': '09:15', 'cierre': '18:45'},
];

_HomeData _readyData({ContactoDto? contacto}) => (
  contacto: contacto ?? _contact(),
  servicios: const [_service],
  productos: const [_product],
);

class _FixtureCatalogRepository implements CatalogRepository {
  _FixtureCatalogRepository({
    _HomeData? data,
    this.pending,
    this.failuresBeforeSuccess = 0,
  }) : data = data ?? _readyData();

  _HomeData data;
  final Completer<_HomeData>? pending;
  int failuresBeforeSuccess;
  int homeRequests = 0;

  @override
  Future<ContactoDto> getContacto() async => data.contacto;

  @override
  Future<List<ProductoDto>> getProductos() async => data.productos;

  @override
  Future<List<ServicioDto>> getServicios() async => data.servicios;

  @override
  Future<_HomeData> loadHomeGuest() async {
    homeRequests += 1;
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess -= 1;
      throw StateError('No fue posible consultar el catálogo de prueba.');
    }
    if (pending != null) return pending!.future;
    return data;
  }
}

Finder get _verticalScroll => find
    .byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
    )
    .first;

Future<void> _pumpHome(
  WidgetTester tester,
  _FixtureCatalogRepository repository, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool settle = true,
  bool disableAnimations = false,
  DateTime Function()? clock,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final vm = HomeGuestViewModel(repository);
  addTearDown(vm.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<HomeGuestViewModel>.value(
      value: vm,
      child: MaterialApp(
        // Use local test fonts; AppTheme.guest() asks GoogleFonts for files.
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          scaffoldBackgroundColor: AppColors.guestBg,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            secondary: AppColors.museum,
            surface: AppColors.guestCard,
            onPrimary: AppColors.onGold,
            onSurface: AppColors.text,
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
            padding: const EdgeInsets.only(top: 24, bottom: 16),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 16),
          ),
          child: child!,
        ),
        home: GuestHomeView(clock: clock),
        routes: {
          '/login': (_) => const Scaffold(body: Text('mock-login')),
          '/servicios': (_) => const Scaffold(body: Text('mock-servicios')),
          '/productos': (_) => const Scaffold(body: Text('mock-productos')),
        },
        // Detalle de servicio y producto: las rutas reales de la app.
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    220,
    scrollable: _verticalScroll,
    maxScrolls: 35,
  );
  await tester.pumpAndSettle();
  expect(target, findsOneWidget);
  expect(tester.takeException(), isNull);
}

Finder _scheduleRow(int day) => find.byKey(ValueKey('guest-schedule-row-$day'));

/// Cambia de pestaña con la barra inferior del invitado.
Future<void> _openTab(WidgetTester tester, String tab) async {
  await tester.tap(find.byKey(ValueKey('guest-nav-$tab')));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectUntruncatedText(WidgetTester tester, String value) {
  final text = tester.widget<Text>(find.text(value));
  expect(
    text.maxLines,
    isNull,
    reason: 'The complete catalog value must wrap.',
  );
  expect(text.overflow, isNot(TextOverflow.ellipsis));
}

void main() {
  group('Guest premium Home responsive', () {
    const sizes = [
      Size(360, 800),
      Size(390, 844),
      Size(800, 1280),
      Size(800, 360),
    ];

    for (final size in sizes) {
      for (final textScale in [1.0, 1.3]) {
        testWidgets('${size.width.toInt()}x${size.height.toInt()}, '
            'textScale $textScale, long names and safe areas', (tester) async {
          final repository = _FixtureCatalogRepository();
          await _pumpHome(tester, repository, size: size, textScale: textScale);

          expect(repository.homeRequests, 1);
          expect(tester.takeException(), isNull);
          await _reveal(tester, find.text('Reservar cita'));
          final reserveRect = tester.getRect(find.text('Reservar cita'));
          expect(reserveRect.top, greaterThanOrEqualTo(24));
          expect(reserveRect.bottom, lessThanOrEqualTo(size.height - 16));
          await _reveal(tester, find.text(_service.nombre));
          _expectUntruncatedText(tester, _service.nombre);
          await _reveal(tester, find.text(_product.nombre));
          _expectUntruncatedText(tester, _product.nombre);
          _expectUntruncatedText(tester, _product.marca);

          await _openTab(tester, 'servicios');
          await _reveal(tester, find.text(_service.nombre));
          _expectUntruncatedText(tester, _service.nombre);
          await _openTab(tester, 'productos');
          await _reveal(tester, find.text(_product.nombre));
          _expectUntruncatedText(tester, _product.nombre);
          await _openTab(tester, 'contacto');
          await _reveal(tester, _scheduleRow(6));
          expect(repository.homeRequests, 1);
        });
      }
    }

    testWidgets('service card leaves the next item visible at 360', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        _FixtureCatalogRepository(),
        size: const Size(360, 800),
      );
      await _reveal(tester, find.byType(GuestServiceCard));
      final card = tester.getSize(find.byType(GuestServiceCard));
      expect(card.width, lessThan(240));
      expect(card.width, greaterThan(180));
    });
  });

  group('Guest premium Home states', () {
    testWidgets('loading ends when the repository supplies the catalog', (
      tester,
    ) async {
      final pending = Completer<_HomeData>();
      final repository = _FixtureCatalogRepository(pending: pending);
      await _pumpHome(tester, repository, settle: false);

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(repository.homeRequests, 1);
      expect(tester.takeException(), isNull);

      pending.complete(_readyData());
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await _reveal(tester, find.text(_service.nombre));
    });

    testWidgets(
      'empty catalog keeps the real empty message and booking entry',
      (tester) async {
        final repository = _FixtureCatalogRepository(
          data: (
            contacto: ContactoDto.empty(),
            servicios: const [],
            productos: const [],
          ),
        );
        await _pumpHome(tester, repository);

        await _reveal(
          tester,
          find.text('No hay servicios ni productos publicados todavía.'),
        );
        await _reveal(tester, find.text('Reservar cita'));
        expect(find.text(_service.nombre), findsNothing);
        expect(find.text(_product.nombre), findsNothing);
      },
    );

    testWidgets('repository error is displayed with a retry action', (
      tester,
    ) async {
      final repository = _FixtureCatalogRepository(failuresBeforeSuccess: 1);
      await _pumpHome(tester, repository);

      expect(
        find.textContaining('No fue posible consultar el catálogo de prueba.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text(_service.nombre), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retry recovers the catalog through the same repository', (
      tester,
    ) async {
      final repository = _FixtureCatalogRepository(failuresBeforeSuccess: 1);
      await _pumpHome(tester, repository);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(repository.homeRequests, 2);
      expect(find.text('Reintentar'), findsNothing);
      await _reveal(tester, find.text(_service.nombre));
    });

    testWidgets('pull to refresh requests the catalog again', (tester) async {
      final repository = _FixtureCatalogRepository();
      await _pumpHome(tester, repository);

      await tester.drag(_verticalScroll, const Offset(0, 450));
      await tester.pumpAndSettle();

      expect(repository.homeRequests, 2);
      expect(tester.takeException(), isNull);
      await _reveal(tester, find.text(_service.nombre));
    });
  });

  group('Guest premium Home navigation', () {
    testWidgets('Tab reaches the first action and Enter opens login', (
      tester,
    ) async {
      await _pumpHome(tester, _FixtureCatalogRepository());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('mock-login'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final label in ['Reservar cita', 'Entrar']) {
      testWidgets('$label opens login without an authenticated operation', (
        tester,
      ) async {
        final repository = _FixtureCatalogRepository();
        await _pumpHome(tester, repository);
        await _reveal(tester, find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(find.text('mock-login'), findsOneWidget);
        expect(repository.homeRequests, 1);
        expect(tester.takeException(), isNull);
      });
    }

    for (final route in [
      (key: 'guest-services-all', tab: 'guest-servicios-tab'),
      (key: 'guest-products-all', tab: 'guest-productos-tab'),
    ]) {
      testWidgets('${route.key} switches to its tab without another request', (
        tester,
      ) async {
        final repository = _FixtureCatalogRepository();
        await _pumpHome(tester, repository);
        final action = find.byKey(ValueKey(route.key));
        await _reveal(tester, action);
        await tester.tap(action);
        await tester.pumpAndSettle();

        expect(find.byKey(ValueKey(route.tab)), findsOneWidget);
        expect(repository.homeRequests, 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Android back on another tab returns to Inicio first', (
      tester,
    ) async {
      await _pumpHome(tester, _FixtureCatalogRepository());
      await _openTab(tester, 'contacto');
      expect(_scheduleRow(0), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_scheduleRow(0), findsNothing);
      expect(find.byKey(const ValueKey('guest-reservar')), findsOneWidget);
    });
  });

  group('Guest premium Home real catalog values', () {
    testWidgets('service retains its supplied price and duration', (
      tester,
    ) async {
      await _pumpHome(tester, _FixtureCatalogRepository());
      await _reveal(tester, find.text(_service.nombre));

      expect(find.text(moneyFormat.format(_service.precio)), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('product retains its supplied name, brand and price', (
      tester,
    ) async {
      await _pumpHome(tester, _FixtureCatalogRepository());
      await _reveal(tester, find.text(_product.nombre));

      expect(find.text(_product.marca), findsOneWidget);
      expect(find.text(moneyFormat.format(_product.precio)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'supplied week is ordered and Sunday remains explicitly closed',
      (tester) async {
        await _pumpHome(tester, _FixtureCatalogRepository());
        await _openTab(tester, 'contacto');
        await _reveal(tester, _scheduleRow(0));
        const weekdays = [
          'Lunes',
          'Martes',
          'Miércoles',
          'Jueves',
          'Viernes',
          'Sábado',
          'Domingo',
        ];

        var previousTop = -1.0;
        for (var day = 0; day < weekdays.length; day += 1) {
          final row = _scheduleRow(day);
          await _reveal(tester, row);
          expect(
            find.descendant(of: row, matching: find.text(weekdays[day])),
            findsOneWidget,
          );
          // All rows are siblings in their content coordinate space. Local
          // positions avoid confusing scroll movement with actual row ordering.
          final box = tester.renderObject<RenderBox>(row);
          final top =
              box.localToGlobal(Offset.zero).dy +
              tester.state<ScrollableState>(_verticalScroll).position.pixels;
          expect(top, greaterThan(previousTop));
          previousTop = top;
        }
        expect(
          find.descendant(of: _scheduleRow(6), matching: find.text('Cerrado')),
          findsOneWidget,
        );
        expect(find.textContaining('10:30'), findsAtLeastNWidgets(1));
        expect(find.textContaining('16:00'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'partial schedule neither invents days nor marks unknown closed',
      (tester) async {
        final contacto = _contact(
          horarios: [
            {
              'dia_semana': 5,
              'abierto': true,
              'apertura': '10:30',
              'cierre': '16:00',
            },
            {
              'dia_semana': 0,
              'abierto': true,
              'apertura': '09:15',
              'cierre': '18:45',
            },
            {'dia_semana': 2},
          ],
        );
        await _pumpHome(
          tester,
          _FixtureCatalogRepository(data: _readyData(contacto: contacto)),
        );
        await _openTab(tester, 'contacto');
        await _reveal(tester, _scheduleRow(0));
        await _reveal(tester, _scheduleRow(2));
        await _reveal(tester, _scheduleRow(5));

        for (final absentDay in [1, 3, 4, 6]) {
          expect(_scheduleRow(absentDay), findsNothing);
        }
        expect(
          find.descendant(
            of: _scheduleRow(2),
            matching: find.text('Horario no publicado'),
          ),
          findsOneWidget,
        );
        expect(find.text('Cerrado'), findsNothing);
        expect(find.text('Martes'), findsNothing);
        expect(find.text('Domingo'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'legacy contact displays its supplied schedule without fake rows',
      (tester) async {
        const legacySchedule = 'Lun 11:00:00-16:30:00';
        final contacto = _contact(horarios: [], horario: legacySchedule);
        await _pumpHome(
          tester,
          _FixtureCatalogRepository(data: _readyData(contacto: contacto)),
        );
        await _openTab(tester, 'contacto');
        await _reveal(tester, find.text(legacySchedule));

        for (var day = 0; day < 7; day += 1) {
          expect(_scheduleRow(day), findsNothing);
        }
        expect(find.text('Cerrado'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Invitado: detalle de catálogo', () {
    testWidgets('PA-01 la tarjeta de servicio abre su detalle y Reservar '
        'lleva a iniciar sesión', (tester) async {
      final repository = _FixtureCatalogRepository();
      await _pumpHome(tester, repository);
      await _reveal(tester, find.byType(GuestServiceCard));
      await tester.tap(find.byType(GuestServiceCard));
      await tester.pumpAndSettle();

      expect(find.text('Qué incluye'), findsOneWidget);
      expect(find.text(_service.descripcion), findsOneWidget);
      expect(find.text(moneyFormat.format(_service.precio)), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('servicio-detalle-reservar')));
      await tester.pumpAndSettle();
      expect(find.text('mock-login'), findsOneWidget);
      expect(repository.homeRequests, 1);
    });

    testWidgets('Volver regresa del detalle al inicio', (tester) async {
      await _pumpHome(tester, _FixtureCatalogRepository());
      await _reveal(tester, find.byType(GuestServiceCard));
      await tester.tap(find.byType(GuestServiceCard));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('detalle-volver')));
      await tester.pumpAndSettle();

      expect(find.text('Qué incluye'), findsNothing);
      expect(find.byType(GuestServiceCard), findsOneWidget);
    });

    testWidgets('el producto se abre desde la cuadrícula con marca, precio y '
        'existencias', (tester) async {
      await _pumpHome(tester, _FixtureCatalogRepository());
      await _openTab(tester, 'productos');
      await tester.tap(find.byKey(ValueKey('producto-celda-${_product.id}')));
      await tester.pumpAndSettle();

      expect(find.text(_product.marca), findsOneWidget);
      expect(find.text(moneyFormat.format(_product.precio)), findsOneWidget);
      expect(find.text('Disponible, 4 piezas'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('producto-detalle-entrar')));
      await tester.pumpAndSettle();
      expect(find.text('mock-login'), findsOneWidget);
    });

    testWidgets('un producto agotado lo dice y no ofrece pedirlo', (
      tester,
    ) async {
      const agotado = ProductoDto(
        id: 24,
        nombre: 'Cera mate',
        marca: '',
        descripcion: '',
        precio: 150,
        categoria: 'cabello',
        stock: 0,
        imagenUrl: '',
        destacado: false,
      );
      await _pumpHome(
        tester,
        _FixtureCatalogRepository(
          data: (
            contacto: _contact(),
            servicios: const [_service],
            productos: const [agotado],
          ),
        ),
      );
      await _openTab(tester, 'productos');
      await tester.tap(find.byKey(const ValueKey('producto-celda-24')));
      await tester.pumpAndSettle();

      expect(find.text('Agotado'), findsOneWidget);
      expect(
        find.text('Este producto está agotado por ahora.'),
        findsOneWidget,
      );
      final boton = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('producto-detalle-entrar')),
      );
      expect(boton.onPressed, isNull);
    });
  });

  group('Invitado: contacto y estado de hoy', () {
    testWidgets('el inicio dice si la barbería está abierta ahora', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        _FixtureCatalogRepository(),
        clock: () => DateTime(2026, 10, 19, 10), // lunes
      );
      expect(
        find.text('Abierto ahora, cierra a las 18:45'),
        findsAtLeastNWidgets(1),
      );

      await _openTab(tester, 'contacto');
      expect(
        find.descendant(of: _scheduleRow(0), matching: find.text('Hoy')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _scheduleRow(1), matching: find.text('Hoy')),
        findsNothing,
      );
    });

    testWidgets('el domingo cerrado se anuncia sin inventar horario', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        _FixtureCatalogRepository(),
        clock: () => DateTime(2026, 10, 25, 12), // domingo
      );
      expect(find.text('Hoy no abrimos'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Abierto ahora'), findsNothing);
    });

    testWidgets('solo ofrece enlaces web seguros y, si no puede abrir, copia '
        'el dato', (tester) async {
      String? copiado;
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiado = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final abiertos = <Uri>[];
      final original = abrirUrlExterna;
      // El marcador no está disponible; el mapa sí abre.
      abrirUrlExterna = (uri) async {
        abiertos.add(uri);
        return uri.scheme != 'tel';
      };
      addTearDown(() => abrirUrlExterna = original);

      final contacto = _contact(
        whatsapp: 'javascript:alert(1)',
        maps: 'https://maps.google.com/?q=Tony+Stylo',
      );
      await _pumpHome(
        tester,
        _FixtureCatalogRepository(data: _readyData(contacto: contacto)),
      );
      await _openTab(tester, 'contacto');

      expect(find.byKey(const ValueKey('contacto-whatsapp')), findsNothing);
      expect(find.byKey(const ValueKey('contacto-mapa')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('contacto-llamar')));
      await tester.pumpAndSettle();

      expect(abiertos.single.toString(), 'tel:5550001234');
      expect(copiado, '5550001234');
      expect(
        find.textContaining('No se pudo abrir el marcador'),
        findsOneWidget,
      );

      copiado = null;
      await tester.tap(find.byKey(const ValueKey('contacto-mapa')));
      await tester.pumpAndSettle();
      expect(abiertos.last.host, 'maps.google.com');
      expect(copiado, isNull, reason: 'Si el mapa abre, no se copia nada.');
      expect(tester.takeException(), isNull);
    });

    test('ContactoDto.horarioHoy interpreta la hora real del día', () {
      final c = _contact();
      final lunes10 = c.horarioHoy(DateTime(2026, 10, 19, 10))!;
      expect(lunes10.estado, EstadoHoy.abierto);
      expect(lunes10.apertura, '09:15');
      expect(lunes10.cierre, '18:45');
      expect(
        c.horarioHoy(DateTime(2026, 10, 19, 9, 14))!.estado,
        EstadoHoy.abrePronto,
      );
      expect(
        c.horarioHoy(DateTime(2026, 10, 19, 18, 45))!.estado,
        EstadoHoy.yaCerro,
      );
      expect(
        c.horarioHoy(DateTime(2026, 10, 25, 12))!.estado,
        EstadoHoy.cerrado,
      );
    });

    test('sin día publicado no inventa; sin horario por día no hay estado', () {
      final parcial = _contact(
        horarios: [
          {'dia_semana': 5, 'abierto': true, 'apertura': '10:30'},
        ],
      );
      expect(
        parcial.horarioHoy(DateTime(2026, 10, 19, 10))!.estado,
        EstadoHoy.sinDato,
      );
      expect(
        parcial.horarioHoy(DateTime(2026, 10, 24, 12))!.estado,
        EstadoHoy.sinDato,
      );
      expect(_contact(horarios: []).horarioHoy(DateTime(2026, 10, 19)), isNull);
    });

    test('normaliza horas y rechaza valores inválidos', () {
      expect(HorarioHoy.hhmm('9:05'), '09:05');
      expect(HorarioHoy.hhmm('11:00:00'), '11:00');
      expect(HorarioHoy.hhmm('25:00'), isNull);
      expect(HorarioHoy.hhmm('abc'), isNull);
      expect(HorarioHoy.hhmm(null), isNull);
    });

    test('solo enlaces http(s) y teléfonos con dígitos', () {
      expect(enlaceWebSeguro('https://wa.me/525550001234'), isNotNull);
      expect(enlaceWebSeguro('javascript:alert(1)'), isNull);
      expect(enlaceWebSeguro('intent://scan/#Intent;scheme=zxing;end'), isNull);
      expect(enlaceWebSeguro(''), isNull);
      expect(enlaceTelefono('(555) 000-1234').toString(), 'tel:5550001234');
      expect(enlaceTelefono('12'), isNull);
    });
  });

  group('Invitado: motion', () {
    Iterable<double> opacidades(WidgetTester tester) => tester
        .widgetList<FadeTransition>(
          find.ancestor(
            of: find.byType(BrandTitle),
            matching: find.byType(FadeTransition),
          ),
        )
        .map((f) => f.opacity.value);

    testWidgets('la entrada anima una vez y termina visible', (tester) async {
      await _pumpHome(tester, _FixtureCatalogRepository(), settle: false);
      await tester.pump();
      expect(opacidades(tester).any((o) => o < 1), isTrue);
      await tester.pumpAndSettle();
      expect(opacidades(tester).every((o) => o == 1), isTrue);
    });

    testWidgets('con reducir movimiento todo aparece de inmediato', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        _FixtureCatalogRepository(),
        settle: false,
        disableAnimations: true,
      );
      await tester.pump();
      expect(find.byType(BrandTitle), findsOneWidget);
      expect(opacidades(tester).every((o) => o == 1), isTrue);
    });
  });
}
