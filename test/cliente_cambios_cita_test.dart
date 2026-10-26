// El cliente cancela o reprograma su propia cita (S6-02, S6-03, PM05) y
// ERR-06 (doble envío al reservar).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/repositories/citas_repository.dart';
import 'package:stylo_barber_connect/services/citas_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/client_citas_viewmodel.dart';
import 'package:stylo_barber_connect/views/client/client_citas_view.dart';
import 'package:stylo_barber_connect/views/client/client_reprogramar_view.dart';
import 'package:stylo_barber_connect/views/client/client_widgets.dart';

import 'mocks/mocks.mocks.dart';
import 'support/memory_token_storage.dart';

const _fueraDePlazo =
    'Los cambios se hacen con al menos 1 día de anticipación. Para esta '
    'cita, comunícate con la barbería.';

CitaDto _cita({bool puede = true, double anticipo = 0, int? barberoId = 3}) =>
    CitaDto(
      id: 7,
      servicioId: 1,
      servicioNombre: 'Corte clásico',
      servicioImagen: '',
      fecha: '2026-11-04',
      hora: '12:00',
      duracionMinutos: 40,
      estado: 'confirmada',
      precioTotal: 150,
      anticipoPagado: anticipo,
      saldoPendiente: 150 - anticipo,
      notas: '',
      barberoNombre: 'Carlos Prueba',
      requierePago: false,
      barberoId: barberoId,
      puedeModificar: puede,
      motivoNoModificable: puede ? '' : _fueraDePlazo,
      limiteModificacion: DateTime(2026, 11, 3, 12),
    );

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Raíz con un botón que abre [destino], para poder comprobar el regreso.
Widget _app(ClientCitasViewModel vm, Widget destino) {
  return ChangeNotifierProvider<ClientCitasViewModel>.value(
    value: vm,
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('abrir'),
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => destino)),
              child: const Text('Lista de citas'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _tocar(WidgetTester tester, Key key) async {
  // La lista del detalle es perezosa: puede que el botón aún no exista.
  if (find.byKey(key).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.byKey(key),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _abrir(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('abrir')));
  await tester.pumpAndSettle();
}

void main() {
  group('Contrato con Django', () {
    test('mis-citas lee si la cita se puede cambiar y hasta cuándo', () {
      final c = CitaDto.fromJson({
        'id': 7,
        'estado': 'confirmada',
        'barbero_id': 3,
        'puede_modificar': true,
        'motivo_no_modificable': '',
        'limite_modificacion': '2026-11-03T12:00:00-06:00',
      });
      expect(c.barberoId, 3);
      expect(c.puedeModificar, isTrue);
      // Hora de la barbería, sin importar la zona del teléfono.
      expect(c.limiteModificacion, DateTime(2026, 11, 3, 12));

      // Un backend anterior no manda los campos: no se ofrecen cambios.
      final viejo = CitaDto.fromJson({'id': 8, 'estado': 'confirmada'});
      expect(viejo.puedeModificar, isFalse);
      expect(viejo.barberoId, isNull);
      expect(viejo.limiteModificacion, isNull);
    });

    test(
      'cancelar y reprogramar van a la cita propia, sin ids de cliente',
      () async {
        final peticiones = <http.Request>[];
        final api = ApiClient(
          tokenStorage: MemoryTokenStorage(access: 'token-prueba'),
          httpClient: MockClient((r) async {
            peticiones.add(r);
            return _json({'ok': true, 'mensaje': 'Listo.'}, 200);
          }),
          baseUrl: 'http://10.0.2.2:8000/api',
        );
        final repo = CitasRepository(CitasApiService(api));

        await repo.cancelarCita(7, motivo: 'Viaje');
        await repo.reprogramarCita(7, fecha: '2026-11-04', hora: '15:00');

        expect(peticiones.map((r) => '${r.method} ${r.url.path}'), [
          'POST /api/mis-citas/7/cancelar/',
          'POST /api/mis-citas/7/reprogramar/',
        ]);
        expect(jsonDecode(peticiones[0].body), {'motivo': 'Viaje'});
        expect(jsonDecode(peticiones[1].body), {
          'fecha': '2026-11-04',
          'hora': '15:00',
        });
      },
    );

    test('un 409 llega con el mensaje del servidor', () async {
      final api = ApiClient(
        tokenStorage: MemoryTokenStorage(access: 'token-prueba'),
        httpClient: MockClient(
          (_) async => _json({
            'ok': false,
            'error': 'Ese horario ya está ocupado.',
          }, 409),
        ),
        baseUrl: 'http://10.0.2.2:8000/api',
      );
      final repo = CitasRepository(CitasApiService(api));
      await expectLater(
        repo.reprogramarCita(7, fecha: '2026-11-04', hora: '14:00'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Ese horario ya está ocupado.',
          ),
        ),
      );
    });
  });

  test('una cita abierta de un día que ya pasó no cuenta como próxima', () {
    relojCliente = () => DateTime(2026, 11, 4, 18);
    addTearDown(() => relojCliente = DateTime.now);
    CitaDto con(String fecha, String estado) =>
        CitaDto.fromJson({'id': 1, 'fecha': fecha, 'estado': estado});

    expect(esCitaProxima(con('2026-11-04', 'confirmada')), isTrue);
    expect(esCitaProxima(con('2026-11-05', 'pendiente')), isTrue);
    expect(esCitaProxima(con('2026-11-03', 'confirmada')), isFalse);
    expect(esCitaProxima(con('2026-11-05', 'cancelada')), isFalse);
  });

  group('ClientCitasViewModel', () {
    late MockCitasRepository repo;
    late ClientCitasViewModel vm;

    setUp(() {
      repo = MockCitasRepository();
      vm = ClientCitasViewModel(repo);
      when(repo.getMisCitas()).thenAnswer((_) async => [_cita()]);
    });

    test(
      'cancelar guarda el mensaje del servidor y recarga la lista',
      () async {
        when(repo.cancelarCita(7, motivo: anyNamed('motivo')))
            .thenAnswer((_) async => {'ok': true, 'mensaje': 'Cancelada.'});

        expect(await vm.cancelarCita(_cita(), motivo: 'Viaje'), isTrue);
        expect(vm.cambioMensaje, 'Cancelada.');
        expect(vm.cambioBusy, isFalse);
        verify(repo.cancelarCita(7, motivo: 'Viaje')).called(1);
        verify(repo.getMisCitas()).called(1);
      },
    );

    test('un error queda en cambioError y no recarga', () async {
      when(
        repo.reprogramarCita(
          7,
          fecha: anyNamed('fecha'),
          hora: anyNamed('hora'),
        ),
      ).thenThrow(ApiException('Ese horario ya está ocupado.'));

      final ok = await vm.reprogramarCita(
        _cita(),
        fecha: '2026-11-04',
        hora: '14:00',
      );
      expect(ok, isFalse);
      expect(vm.cambioError, 'Ese horario ya está ocupado.');
      verifyNever(repo.getMisCitas());
    });

    test('un segundo toque mientras se envía no repite la petición', () async {
      final pendiente = Completer<Map<String, dynamic>>();
      when(repo.cancelarCita(7, motivo: anyNamed('motivo')))
          .thenAnswer((_) => pendiente.future);

      final primero = vm.cancelarCita(_cita());
      expect(await vm.cancelarCita(_cita()), isFalse);
      pendiente.complete({'ok': true});
      expect(await primero, isTrue);
      verify(repo.cancelarCita(7, motivo: '')).called(1);
    });

    test('ERR-06: reservar dos veces seguidas crea una sola cita', () async {
      final pendiente = Completer<Map<String, dynamic>>();
      when(
        repo.crearCita(
          clienteId: anyNamed('clienteId'),
          barberoId: anyNamed('barberoId'),
          servicioId: anyNamed('servicioId'),
          duracionMinutos: anyNamed('duracionMinutos'),
          fecha: anyNamed('fecha'),
          hora: anyNamed('hora'),
          precioTotal: anyNamed('precioTotal'),
          anticipoPagado: anyNamed('anticipoPagado'),
        ),
      ).thenAnswer((_) => pendiente.future);
      const user = AuthUser(
        id: 1,
        username: 'ana',
        email: 'ana@example.test',
        rol: UserRole.cliente,
      );
      Future<bool> reservar() => vm.reservar(
        user: user,
        barberoId: 3,
        servicioId: 1,
        duracionMinutos: 40,
        fecha: '2026-11-04',
        hora: '12:00',
        precioTotal: 150,
      );

      final primero = reservar();
      expect(await reservar(), isFalse);
      pendiente.complete({'ok': true, 'id': 9});
      expect(await primero, isTrue);
      verify(
        repo.crearCita(
          clienteId: anyNamed('clienteId'),
          barberoId: anyNamed('barberoId'),
          servicioId: anyNamed('servicioId'),
          duracionMinutos: anyNamed('duracionMinutos'),
          fecha: anyNamed('fecha'),
          hora: anyNamed('hora'),
          precioTotal: anyNamed('precioTotal'),
          anticipoPagado: anyNamed('anticipoPagado'),
        ),
      ).called(1);
    });
  });

  group('Detalle de cita', () {
    late MockCitasRepository repo;
    late ClientCitasViewModel vm;

    setUp(() {
      repo = MockCitasRepository();
      vm = ClientCitasViewModel(repo);
      when(repo.getMisCitas()).thenAnswer((_) async => const []);
    });

    testWidgets('PA-06 con plazo: ofrece reprogramar y cancelar', (
      tester,
    ) async {
      await tester.pumpWidget(_app(vm, CitaDetalleView(cita: _cita())));
      await _abrir(tester);

      expect(find.byKey(const Key('cita_reprogramar')), findsOneWidget);
      expect(find.byKey(const Key('cita_cancelar')), findsOneWidget);
      expect(
        find.text(
          'Puedes moverla a otro horario o cancelarla hasta el martes 3 de '
          'noviembre a las 12:00.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('fuera de plazo: explica por qué y no ofrece botones', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(vm, CitaDetalleView(cita: _cita(puede: false))),
      );
      await _abrir(tester);

      expect(find.text(_fueraDePlazo), findsOneWidget);
      expect(find.byKey(const Key('cita_reprogramar')), findsNothing);
      expect(find.byKey(const Key('cita_cancelar')), findsNothing);
    });

    testWidgets('PA-06 cancelar: confirma, manda el motivo y regresa', (
      tester,
    ) async {
      when(repo.cancelarCita(7, motivo: anyNamed('motivo'))).thenAnswer(
        (_) async => {
          'ok': true,
          'mensaje': 'Tu cita quedó cancelada y el horario se liberó.',
        },
      );
      await tester.pumpWidget(
        _app(vm, CitaDetalleView(cita: _cita(anticipo: 75))),
      );
      await _abrir(tester);

      await _tocar(tester, const Key('cita_cancelar'));
      expect(find.text('¿Cancelar tu cita?'), findsOneWidget);
      expect(find.textContaining('de anticipo'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('cita_cancelar_motivo')),
        'Me surgió un viaje',
      );
      await tester.tap(find.byKey(const Key('cita_cancelar_confirmar')));
      await tester.pumpAndSettle();

      verify(repo.cancelarCita(7, motivo: 'Me surgió un viaje')).called(1);
      expect(find.byType(CitaDetalleView), findsNothing);
      expect(
        find.text('Tu cita quedó cancelada y el horario se liberó.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('conservar la cita no llama al servidor', (tester) async {
      await tester.pumpWidget(_app(vm, CitaDetalleView(cita: _cita())));
      await _abrir(tester);

      await _tocar(tester, const Key('cita_cancelar'));
      await tester.tap(find.byKey(const Key('cita_cancelar_conservar')));
      await tester.pumpAndSettle();

      verifyNever(repo.cancelarCita(any, motivo: anyNamed('motivo')));
      expect(find.byType(CitaDetalleView), findsOneWidget);
    });

    testWidgets('si el servidor rechaza la cancelación, se queda y lo dice', (
      tester,
    ) async {
      when(repo.cancelarCita(7, motivo: anyNamed('motivo')))
          .thenThrow(ApiException(_fueraDePlazo));
      await tester.pumpWidget(_app(vm, CitaDetalleView(cita: _cita())));
      await _abrir(tester);

      await _tocar(tester, const Key('cita_cancelar'));
      await tester.tap(find.byKey(const Key('cita_cancelar_confirmar')));
      await tester.pumpAndSettle();

      expect(find.byType(CitaDetalleView), findsOneWidget);
      expect(find.byKey(const Key('cita_cambio_error')), findsOneWidget);
    });
  });

  group('Reprogramar', () {
    late MockCitasRepository repo;
    late ClientCitasViewModel vm;
    final hoy = DateTime(2026, 11, 2);

    setUp(() {
      repo = MockCitasRepository();
      vm = ClientCitasViewModel(repo);
      when(repo.getMisCitas()).thenAnswer((_) async => const []);
      when(
        repo.getDisponibilidad(
          barberoId: 3,
          fecha: anyNamed('fecha'),
          duracion: 40,
        ),
      ).thenAnswer(
        (_) async => const [
          SlotDisponibilidad(hora: '14:00', disponible: false),
          SlotDisponibilidad(hora: '15:00', disponible: true),
        ],
      );
    });

    testWidgets('PA-06 elige otro horario libre del mismo barbero y regresa', (
      tester,
    ) async {
      when(
        repo.reprogramarCita(
          7,
          fecha: anyNamed('fecha'),
          hora: anyNamed('hora'),
        ),
      ).thenAnswer(
        (_) async => {
          'ok': true,
          'mensaje': 'Tu cita se movió al nuevo horario.',
        },
      );
      await tester.pumpWidget(
        _app(vm, ReprogramarCitaView(cita: _cita(), hoy: hoy)),
      );
      await _abrir(tester);

      // Abre en el día de la cita y solo muestra lo libre.
      verify(
        repo.getDisponibilidad(barberoId: 3, fecha: '2026-11-04', duracion: 40),
      ).called(1);
      expect(
        find.byKey(const ValueKey('reprogramar-hora-14:00')),
        findsNothing,
      );
      expect(find.byKey(const Key('reprogramar_confirmar')), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('reprogramar-dia-2026-11-05')),
      );
      await tester.pumpAndSettle();
      verify(
        repo.getDisponibilidad(barberoId: 3, fecha: '2026-11-05', duracion: 40),
      ).called(1);

      await tester.tap(find.byKey(const ValueKey('reprogramar-hora-15:00')));
      await tester.pumpAndSettle();
      expect(
        find.text('Mover al jueves 5 de noviembre, 15:00'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('reprogramar_confirmar')));
      await tester.pumpAndSettle();

      verify(repo.reprogramarCita(7, fecha: '2026-11-05', hora: '15:00'))
          .called(1);
      expect(find.byType(ReprogramarCitaView), findsNothing);
    });

    testWidgets('si el horario se ocupó, lo dice y recarga los libres', (
      tester,
    ) async {
      when(
        repo.reprogramarCita(
          7,
          fecha: anyNamed('fecha'),
          hora: anyNamed('hora'),
        ),
      ).thenThrow(ApiException('Ese horario ya está ocupado.'));
      await tester.pumpWidget(
        _app(vm, ReprogramarCitaView(cita: _cita(), hoy: hoy)),
      );
      await _abrir(tester);

      await tester.tap(find.byKey(const ValueKey('reprogramar-hora-15:00')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reprogramar_confirmar')));
      await tester.pumpAndSettle();

      expect(find.byType(ReprogramarCitaView), findsOneWidget);
      expect(find.text('Ese horario ya está ocupado.'), findsOneWidget);
      expect(find.byKey(const Key('reprogramar_confirmar')), findsNothing);
      verify(
        repo.getDisponibilidad(barberoId: 3, fecha: '2026-11-04', duracion: 40),
      ).called(2);
    });

    testWidgets('sin barbero en la respuesta no pide horarios', (tester) async {
      await tester.pumpWidget(
        _app(vm, ReprogramarCitaView(cita: _cita(barberoId: null), hoy: hoy)),
      );
      await _abrir(tester);

      expect(find.text('No se pueden consultar horarios'), findsOneWidget);
      verifyNever(
        repo.getDisponibilidad(
          barberoId: anyNamed('barberoId'),
          fecha: anyNamed('fecha'),
          duracion: anyNamed('duracion'),
        ),
      );
    });
  });
}
