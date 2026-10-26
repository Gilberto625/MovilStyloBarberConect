// Barbero › Mi agenda (S7-01..03, PM06) y guarda central de rutas (GH#70).
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
import 'package:stylo_barber_connect/models/barbero_models.dart';
import 'package:stylo_barber_connect/repositories/barbero_repository.dart';
import 'package:stylo_barber_connect/routes/app_routes.dart';
import 'package:stylo_barber_connect/routes/route_guard.dart';
import 'package:stylo_barber_connect/services/barbero_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/barbero_agenda_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/home_guest_viewmodel.dart';
import 'package:stylo_barber_connect/views/barber/barbero_agenda_view.dart';

import 'mocks/mocks.mocks.dart';
import 'support/memory_token_storage.dart';

BarberoCitaDto _cita(
  int id,
  String hora, {
  String atencion = 'por_atender',
  bool iniciar = true,
  bool terminar = false,
}) => BarberoCitaDto(
  id: id,
  hora: hora,
  duracionMinutos: 40,
  servicioNombre: 'Corte clásico',
  clienteNombre: 'Ana Prueba',
  estado: atencion == 'por_atender' ? 'confirmada' : 'en_curso',
  atencion: atencion,
  notas: 'Degradado bajo',
  complementos: '',
  puedeIniciar: iniciar,
  puedeTerminar: terminar,
);

BarberoAgendaDto _agenda(List<BarberoCitaDto> citas, {bool esHoy = true}) =>
    BarberoAgendaDto(fecha: '2026-11-04', esHoy: esHoy, citas: citas);

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Widget _app(BarberoAgendaViewModel vm) => MaterialApp(
  home: ChangeNotifierProvider<BarberoAgendaViewModel>.value(
    value: vm,
    child: const BarberoAgendaView(),
  ),
);

AuthViewModel _sesion(UserRole? rol) {
  final auth = AuthViewModel(MockAuthRepository());
  if (rol == null) {
    auth.phase = AuthPhase.guest;
  } else {
    auth
      ..phase = AuthPhase.authenticated
      ..user = AuthUser(
        id: 1,
        username: 'u',
        email: 'u@example.test',
        rol: rol,
      );
  }
  return auth;
}

void main() {
  group('Contrato con Django', () {
    test('lee la agenda y manda la acción sin ids de empleado', () async {
      final peticiones = <http.Request>[];
      final api = ApiClient(
        tokenStorage: MemoryTokenStorage(access: 'token-prueba'),
        httpClient: MockClient((r) async {
          peticiones.add(r);
          if (r.method == 'GET') {
            return _json({
              'ok': true,
              'fecha': '2026-11-04',
              'es_hoy': true,
              'citas': [
                {
                  'id': 10,
                  'hora': '10:00',
                  'duracion_minutos': 40,
                  'servicio_nombre': 'Corte clásico',
                  'cliente_nombre': 'Ana Prueba',
                  'estado': 'confirmada',
                  'atencion': 'por_atender',
                  'notas': '',
                  'complementos': '',
                  'puede_iniciar': true,
                  'puede_terminar': false,
                },
              ],
            }, 200);
          }
          return _json({'ok': true, 'atencion': 'en_silla'}, 200);
        }),
        baseUrl: 'http://10.0.2.2:8000/api',
      );
      final repo = BarberoRepository(BarberoApiService(api));

      final agenda = await repo.getAgenda(fecha: '2026-11-04');
      await repo.iniciarAtencion(10);
      await repo.terminarAtencion(10);

      expect(agenda.esHoy, isTrue);
      expect(agenda.citas.single.puedeIniciar, isTrue);
      expect(agenda.citas.single.clienteNombre, 'Ana Prueba');
      expect(peticiones.map((r) => '${r.method} ${r.url.path}'), [
        'GET /api/barbero/agenda/',
        'POST /api/barbero/citas/10/atencion/',
        'POST /api/barbero/citas/10/atencion/',
      ]);
      expect(peticiones.first.url.queryParameters, {'fecha': '2026-11-04'});
      expect(jsonDecode(peticiones[1].body), {'accion': 'iniciar'});
      expect(jsonDecode(peticiones[2].body), {'accion': 'terminar'});
    });

    test(
      'un cliente recibe 403 y el mensaje llega como ApiException',
      () async {
        final api = ApiClient(
          tokenStorage: MemoryTokenStorage(access: 'token-prueba'),
          httpClient: MockClient(
            (_) async => _json({'ok': false, 'error': 'No autorizado.'}, 403),
          ),
          baseUrl: 'http://10.0.2.2:8000/api',
        );
        await expectLater(
          BarberoApiService(api).agenda(),
          throwsA(
            isA<ApiException>().having((e) => e.isForbidden, '403', true),
          ),
        );
      },
    );
  });

  group('BarberoAgendaViewModel', () {
    late MockBarberoRepository repo;
    late BarberoAgendaViewModel vm;

    setUp(() {
      repo = MockBarberoRepository();
      vm = BarberoAgendaViewModel(repo);
    });

    test('estados de carga: lista, vacía y error', () async {
      when(repo.getAgenda(fecha: anyNamed('fecha')))
          .thenAnswer((_) async => _agenda([_cita(10, '10:00')]));
      await vm.load();
      expect(vm.state, LoadState.ready);

      when(repo.getAgenda(fecha: anyNamed('fecha')))
          .thenAnswer((_) async => _agenda(const []));
      await vm.load(fecha: '2026-11-05');
      expect(vm.state, LoadState.empty);
      expect(vm.fecha, '2026-11-05');

      when(repo.getAgenda(fecha: anyNamed('fecha')))
          .thenThrow(ApiException('No autorizado.', statusCode: 403));
      await vm.load();
      expect(vm.state, LoadState.error);
      expect(vm.errorMessage, 'No autorizado.');
    });

    test('iniciar recarga lo que diga el servidor y no se repite', () async {
      when(repo.getAgenda(fecha: anyNamed('fecha')))
          .thenAnswer((_) async => _agenda([_cita(10, '10:00')]));
      final pendiente = Completer<Map<String, dynamic>>();
      when(repo.iniciarAtencion(10)).thenAnswer((_) => pendiente.future);

      final primero = vm.iniciar(_cita(10, '10:00'));
      expect(vm.citaOcupada, 10);
      expect(await vm.terminar(_cita(10, '10:00')), isFalse);
      pendiente.complete({'ok': true, 'mensaje': 'Atención iniciada.'});
      expect(await primero, isTrue);

      expect(vm.citaOcupada, isNull);
      expect(vm.accionMensaje, 'Atención iniciada.');
      verify(repo.iniciarAtencion(10)).called(1);
      verifyNever(repo.terminarAtencion(any));
      verify(repo.getAgenda(fecha: anyNamed('fecha'))).called(1);
    });

    test('un rechazo del servidor queda en accionError', () async {
      when(repo.terminarAtencion(10))
          .thenThrow(ApiException('Primero inicia la atención de esta cita.'));
      expect(await vm.terminar(_cita(10, '10:00')), isFalse);
      expect(vm.accionError, 'Primero inicia la atención de esta cita.');
      expect(vm.citaOcupada, isNull);
    });
  });

  group('Pantalla Mi agenda', () {
    late MockBarberoRepository repo;
    late BarberoAgendaViewModel vm;

    setUp(() {
      repo = MockBarberoRepository();
      vm = BarberoAgendaViewModel(repo);
    });

    testWidgets('PM06 muestra sus citas con la acción que toca a cada una', (
      tester,
    ) async {
      when(repo.getAgenda(fecha: anyNamed('fecha'))).thenAnswer(
        (_) async => _agenda([
          _cita(10, '10:00'),
          _cita(
            11,
            '11:00',
            atencion: 'en_silla',
            iniciar: false,
            terminar: true,
          ),
          _cita(12, '12:00', atencion: 'terminada', iniciar: false),
        ]),
      );
      await tester.pumpWidget(_app(vm));
      await tester.pumpAndSettle();

      expect(find.text('Mi agenda de hoy'), findsOneWidget);
      expect(find.text('Por atender'), findsOneWidget);
      expect(find.text('En la silla'), findsOneWidget);
      expect(find.text('Lista para cobrar'), findsOneWidget);
      expect(find.byKey(const ValueKey('barbero-iniciar-10')), findsOneWidget);
      expect(find.byKey(const ValueKey('barbero-terminar-11')), findsOneWidget);
      expect(find.byKey(const ValueKey('barbero-iniciar-12')), findsNothing);
      expect(find.byKey(const ValueKey('barbero-terminar-12')), findsNothing);
    });

    testWidgets('tocar "Pasó a la silla" llama al servidor y recarga', (
      tester,
    ) async {
      var cargas = 0;
      when(repo.getAgenda(fecha: anyNamed('fecha'))).thenAnswer((_) async {
        cargas++;
        return cargas == 1
            ? _agenda([_cita(10, '10:00')])
            : _agenda([
                _cita(
                  10,
                  '10:00',
                  atencion: 'en_silla',
                  iniciar: false,
                  terminar: true,
                ),
              ]);
      });
      when(
        repo.iniciarAtencion(10),
      ).thenAnswer((_) async => {'ok': true, 'mensaje': 'Atención iniciada.'});
      await tester.pumpWidget(_app(vm));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('barbero-iniciar-10')));
      await tester.pumpAndSettle();

      verify(repo.iniciarAtencion(10)).called(1);
      expect(find.text('Atención iniciada.'), findsOneWidget);
      expect(find.byKey(const ValueKey('barbero-terminar-10')), findsOneWidget);
    });

    testWidgets('otro día: solo consulta, sin botones', (tester) async {
      when(repo.getAgenda(fecha: anyNamed('fecha'))).thenAnswer(
        (_) async =>
            _agenda([_cita(10, '10:00', iniciar: false)], esHoy: false),
      );
      await tester.pumpWidget(_app(vm));
      await tester.pumpAndSettle();

      expect(find.text('Mi agenda'), findsOneWidget);
      expect(find.textContaining('solo se marca'), findsOneWidget);
      expect(find.byKey(const ValueKey('barbero-iniciar-10')), findsNothing);
    });

    testWidgets('vacía y error con reintento', (tester) async {
      when(repo.getAgenda(fecha: anyNamed('fecha')))
          .thenThrow(ApiException('No hay conexión con el servidor.'));
      await tester.pumpWidget(_app(vm));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo cargar tu agenda'), findsOneWidget);

      when(repo.getAgenda(fecha: anyNamed('fecha')))
          .thenAnswer((_) async => _agenda(const []));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Sin citas asignadas'), findsOneWidget);
    });
  });

  group('Rutas por rol', () {
    test('cada rol tiene su inicio', () {
      expect(AppRoutes.homeFor(UserRole.cliente), AppRoutes.clientHome);
      expect(AppRoutes.homeFor(UserRole.unknown), AppRoutes.clientHome);
      expect(AppRoutes.homeFor(UserRole.barbero), AppRoutes.barberHome);
      expect(AppRoutes.homeFor(UserRole.secretaria), AppRoutes.secretaryHome);
      expect(AppRoutes.homeFor(UserRole.admin), AppRoutes.secretaryHome);
    });

    Widget guardApp(AuthViewModel auth) => ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp(
        initialRoute: '/secreto',
        routes: {
          AppRoutes.login: (_) => const Text('ACCESO'),
          AppRoutes.clientHome: (_) => const Text('INICIO CLIENTE'),
          AppRoutes.barberHome: (_) => const Text('INICIO BARBERO'),
          AppRoutes.secretaryHome: (_) => const Text('INICIO SECRETARIA'),
          '/secreto': (_) => RouteGuard(
            permite: (r) => r.isStaffPanel,
            loginRoute: AppRoutes.login,
            homeFor: AppRoutes.homeFor,
            child: const Text('PANEL SECRETARIA'),
          ),
        },
      ),
    );

    testWidgets('GH#70 sin sesión, un panel manda al acceso', (tester) async {
      await tester.pumpWidget(guardApp(_sesion(null)));
      await tester.pumpAndSettle();
      expect(find.text('PANEL SECRETARIA'), findsNothing);
      expect(find.text('ACCESO'), findsOneWidget);
    });

    testWidgets('GH#70 un barbero no entra al panel de secretaría', (
      tester,
    ) async {
      await tester.pumpWidget(guardApp(_sesion(UserRole.barbero)));
      await tester.pumpAndSettle();
      expect(find.text('PANEL SECRETARIA'), findsNothing);
      expect(find.text('INICIO BARBERO'), findsOneWidget);
    });

    testWidgets('GH#70 un cliente no entra al panel de secretaría', (
      tester,
    ) async {
      await tester.pumpWidget(guardApp(_sesion(UserRole.cliente)));
      await tester.pumpAndSettle();
      expect(find.text('PANEL SECRETARIA'), findsNothing);
      expect(find.text('INICIO CLIENTE'), findsOneWidget);
    });

    testWidgets('GH#70 el rol correcto ve el panel', (tester) async {
      await tester.pumpWidget(guardApp(_sesion(UserRole.secretaria)));
      await tester.pumpAndSettle();
      expect(find.text('PANEL SECRETARIA'), findsOneWidget);
    });
  });
}
