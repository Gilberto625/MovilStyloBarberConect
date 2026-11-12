// GH#17: un error de red al reservar deja un mensaje claro, no da la cita por
// creada y permite reintentar.
// GH#25 / PM07-a: mientras la reserva se envía, "Confirmar reserva" no manda
// una segunda petición.
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
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/catalog_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/repositories/citas_repository.dart';
import 'package:stylo_barber_connect/services/citas_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/catalog_list_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/client_citas_viewmodel.dart';
import 'package:stylo_barber_connect/views/client/client_agendar_view.dart';

import '../mocks/mocks.mocks.dart';
import '../support/memory_token_storage.dart';

const _base = 'http://10.0.2.2:8000/api';

const _cliente = AuthUser(
  id: 15,
  username: 'cliente.prueba',
  email: 'cliente.prueba@example.test',
  rol: UserRole.cliente,
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

const _politicaLibre = PoliticaPagoDto(
  requiereAnticipo: false,
  porcentajeAnticipo: 0,
  penalizado: false,
  totalInasistencias: 0,
);

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<bool> _reservar(ClientCitasViewModel vm) => vm.reservar(
  user: _cliente,
  barberoId: 7,
  servicioId: 1,
  duracionMinutos: 60,
  fecha: '2026-11-12',
  hora: '11:30',
  precioTotal: 200,
);

/// `crearCita` del mock, con cualquier argumento.
Future<Map<String, dynamic>> _crearCitaCualquiera(MockCitasRepository repo) =>
    repo.crearCita(
      clienteId: anyNamed('clienteId'),
      barberoId: anyNamed('barberoId'),
      servicioId: anyNamed('servicioId'),
      duracionMinutos: anyNamed('duracionMinutos'),
      fecha: anyNamed('fecha'),
      hora: anyNamed('hora'),
      precioTotal: anyNamed('precioTotal'),
      anticipoPagado: anyNamed('anticipoPagado'),
    );

/// Agendar dentro de un Scaffold, con la sesión del cliente ya abierta.
Future<void> _pumpAgendar(
  WidgetTester tester, {
  required MockCitasRepository citas,
  required VoidCallback onBooked,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final catalogo = MockCatalogRepository();
  when(catalogo.getServicios()).thenAnswer((_) async => const [_servicio]);
  when(citas.getBarberos(servicioId: anyNamed('servicioId')))
      .thenAnswer((_) async => const [_barbero]);
  when(
    citas.getDisponibilidad(
      barberoId: anyNamed('barberoId'),
      fecha: anyNamed('fecha'),
      duracion: anyNamed('duracion'),
    ),
  ).thenAnswer(
    (_) async => const [SlotDisponibilidad(hora: '11:30', disponible: true)],
  );
  when(citas.getMisCitas()).thenAnswer((_) async => const []);

  final auth = AuthViewModel(MockAuthRepository())
    ..phase = AuthPhase.authenticated
    ..user = _cliente;
  final citasVm = ClientCitasViewModel(citas);
  final catalogVm = CatalogListViewModel(catalogo);
  addTearDown(auth.dispose);
  addTearDown(citasVm.dispose);
  addTearDown(catalogVm.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider<ClientCitasViewModel>.value(value: citasVm),
        ChangeNotifierProvider<CatalogListViewModel>.value(value: catalogVm),
      ],
      child: MaterialApp(
        theme: AppTheme.panel(),
        home: Scaffold(
          body: ClientAgendarTab(
            onBooked: onBooked,
            hoy: DateTime(2026, 11, 11),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Servicio → barbero → horario → resumen.
Future<void> _irAlResumen(WidgetTester tester) async {
  await tester.tap(find.text('Corte Fade'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Luis Mora'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('11:30'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('agendar_continuar')));
  await tester.pumpAndSettle();
  expect(find.text('Paso 4 de 4: Resumen'), findsOneWidget);
}

ElevatedButton _botonConfirmar(WidgetTester tester) =>
    tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byKey(const Key('agendar_confirmar')),
        matching: find.byType(ElevatedButton),
      ),
    );

void main() {
  group('GH#17 error de red al reservar', () {
    test('GH#17 sin conexión: mensaje claro, cita no creada y el reintento '
        'sí la crea', () async {
      // Pila real hasta ApiClient; el primer POST falla en el transporte.
      final posts = <http.Request>[];
      var falla = true;
      final api = ApiClient(
        tokenStorage: MemoryTokenStorage(access: 'token-prueba'),
        baseUrl: _base,
        httpClient: MockClient((r) async {
          if (r.method == 'POST' && r.url.path == '/api/citas/') {
            posts.add(r);
            if (falla) {
              throw http.ClientException(
                'SocketException: Connection refused, address = 10.0.2.2, '
                'port = 8000',
                r.url,
              );
            }
            return _json({'ok': true, 'id': 9}, 201);
          }
          return _json({'ok': true, 'citas': []}, 200);
        }),
      );
      final vm = ClientCitasViewModel(CitasRepository(CitasApiService(api)));
      addTearDown(vm.dispose);

      final ok = await _reservar(vm);

      expect(ok, isFalse);
      expect(vm.errorMessage, NetworkException.sinConexion);
      expect(vm.errorMessage, isNot(contains('10.0.2.2')));
      expect(vm.errorMessage, isNot(contains('SocketException')));
      expect(vm.bookingMessage, isNull, reason: 'No se da por creada.');
      expect(vm.bookingBusy, isFalse, reason: 'Se puede volver a intentar.');
      expect(posts, hasLength(1));

      // Vuelve la red: el mismo ViewModel reintenta y ahora sí se crea.
      falla = false;
      expect(await _reservar(vm), isTrue);
      expect(vm.errorMessage, isNull);
      expect(vm.bookingMessage, 'Cita creada (#9).');
      expect(posts, hasLength(2));
    });

    test('GH#17 NetworkException desde el repositorio no marca la cita como '
        'creada', () async {
      final repo = MockCitasRepository();
      when(_crearCitaCualquiera(repo)).thenThrow(NetworkException());
      final vm = ClientCitasViewModel(repo);
      addTearDown(vm.dispose);

      expect(await _reservar(vm), isFalse);
      expect(vm.errorMessage, NetworkException.sinConexion);
      expect(vm.bookingMessage, isNull);
      expect(vm.bookingBusy, isFalse);

      when(_crearCitaCualquiera(repo))
          .thenAnswer((_) async => {'ok': true, 'id': 10});
      expect(await _reservar(vm), isTrue);
      expect(vm.bookingMessage, 'Cita creada (#10).');
      verify(_crearCitaCualquiera(repo)).called(2);
    });
  });

  group('GH#25 / PM07-a doble envío al confirmar', () {
    testWidgets('GH#25 PM07-a mientras se envía, "Confirmar reserva" queda '
        'deshabilitado y se crea una sola cita', (tester) async {
      final citas = MockCitasRepository();
      final respuesta = Completer<Map<String, dynamic>>();
      when(citas.getPoliticaPago(any)).thenAnswer((_) async => _politicaLibre);
      when(_crearCitaCualquiera(citas)).thenAnswer((_) => respuesta.future);
      var reservadas = 0;
      await _pumpAgendar(tester, citas: citas, onBooked: () => reservadas++);
      await _irAlResumen(tester);

      await tester.tap(find.byKey(const Key('agendar_confirmar')));
      await tester.pump();
      expect(_botonConfirmar(tester).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('agendar_confirmar')),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 100));

      respuesta.complete({'ok': true, 'id': 9});
      await tester.pumpAndSettle();

      verify(_crearCitaCualquiera(citas)).called(1);
      expect(reservadas, 1);
      expect(find.text('Cita creada (#9).'), findsOneWidget);
    });

    testWidgets('GH#25 un segundo toque mientras se revisa la política no '
        'envía otra reserva', (tester) async {
      // La política se vuelve a pedir al confirmar. Con red lenta, esa
      // consulta tarda; el botón debe quedar bloqueado desde el primer toque.
      final citas = MockCitasRepository();
      final pendientes = <Completer<PoliticaPagoDto>>[];
      var consultas = 0;
      when(citas.getPoliticaPago(any)).thenAnswer((_) {
        consultas++;
        if (consultas == 1) return Future.value(_politicaLibre); // resumen
        final c = Completer<PoliticaPagoDto>();
        pendientes.add(c);
        return c.future;
      });
      when(_crearCitaCualquiera(citas))
          .thenAnswer((_) async => {'ok': true, 'id': 9});
      var reservadas = 0;
      await _pumpAgendar(tester, citas: citas, onBooked: () => reservadas++);
      await _irAlResumen(tester);

      await tester.tap(find.byKey(const Key('agendar_confirmar')));
      await tester.pump();
      final habilitadoDuranteEnvio = _botonConfirmar(tester).onPressed != null;
      await tester.tap(
        find.byKey(const Key('agendar_confirmar')),
        warnIfMissed: false,
      );
      await tester.pump();

      // Las respuestas llegan una por una, en el orden de los toques.
      while (pendientes.isNotEmpty) {
        pendientes.removeAt(0).complete(_politicaLibre);
        await tester.pumpAndSettle();
      }

      verify(_crearCitaCualquiera(citas)).called(1);
      expect(reservadas, 1);
      expect(
        habilitadoDuranteEnvio,
        isFalse,
        reason: 'El botón sigue activo mientras se revisa la política.',
      );
    });
  });
}
