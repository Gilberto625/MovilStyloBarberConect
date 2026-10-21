import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/client_citas_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/home_guest_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/secretaria_hoy_viewmodel.dart';

import '../mocks/mocks.mocks.dart';

const _cliente = AuthUser(
  id: 15,
  username: 'cliente.prueba',
  email: 'cliente.prueba@example.test',
  rol: UserRole.cliente,
);

const _cita = CitaDto(
  id: 41,
  servicioId: 3,
  servicioNombre: 'Corte clásico',
  servicioImagen: '',
  fecha: '2026-10-21',
  hora: '11:30',
  duracionMinutos: 45,
  estado: 'pendiente',
  precioTotal: 180,
  anticipoPagado: 0,
  saldoPendiente: 180,
  notas: '',
  barberoNombre: 'Ana Prueba',
  requierePago: false,
);

const _citaSecretaria = SecretariaCitaDto(
  id: 90,
  clienteId: 12,
  clienteNombre: 'Cliente Prueba',
  clienteTelefono: '',
  servicioNombre: 'Corte clásico',
  barberoNombre: 'Ana Prueba',
  fecha: '2026-10-19',
  hora: '10:00',
  duracionMinutos: 45,
  estado: 'pendiente',
  precioTotal: 180,
  anticipoPagado: 0,
  anticipoPendiente: 0,
  restante: 180,
  puedeCobrar: false,
  puedeMarcarAsistencia: true,
  clientePenalizado: false,
);

Future<bool> _reservar(ClientCitasViewModel vm) => vm.reservar(
  user: _cliente,
  barberoId: 7,
  servicioId: 3,
  duracionMinutos: 45,
  fecha: '2026-10-21',
  hora: '11:30',
  precioTotal: 180,
);

void main() {
  group('U-MOCK ClientCitasViewModel', () {
    late MockCitasRepository repo;
    late ClientCitasViewModel vm;

    setUp(() {
      repo = MockCitasRepository();
      vm = ClientCitasViewModel(repo);
    });

    tearDown(() => vm.dispose());

    test('mis citas: lista con datos queda ready y consulta una vez', () async {
      when(repo.getMisCitas()).thenAnswer((_) async => [_cita]);
      await vm.loadMisCitas();
      expect(vm.state, LoadState.ready);
      expect(vm.citas.single.id, 41);
      verify(repo.getMisCitas()).called(1);
    });

    test('mis citas: lista vacía queda empty', () async {
      when(repo.getMisCitas()).thenAnswer((_) async => []);
      await vm.loadMisCitas();
      expect(vm.state, LoadState.empty);
    });

    test(
      'mis citas: un 500 del servidor queda en error con su mensaje',
      () async {
        when(repo.getMisCitas()).thenThrow(
          ApiException('No se pudieron cargar citas.', statusCode: 500),
        );
        await vm.loadMisCitas();
        expect(vm.state, LoadState.error);
        expect(vm.errorMessage, 'No se pudieron cargar citas.');
      },
    );

    test(
      'mis citas: un timeout queda en error, no en carga infinita',
      () async {
        when(repo.getMisCitas())
            .thenAnswer((_) => Future.error(TimeoutException('sin respuesta')));
        await vm.loadMisCitas();
        expect(vm.state, LoadState.error);
        expect(vm.errorMessage, contains('sin respuesta'));
      },
    );

    test('reservar envía los datos elegidos una sola vez', () async {
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
      ).thenAnswer((_) async => {'id': 77});

      final ok = await _reservar(vm);

      expect(ok, isTrue);
      expect(vm.bookingBusy, isFalse);
      expect(vm.bookingMessage, 'Cita creada (#77).');
      verify(
        repo.crearCita(
          clienteId: 15,
          barberoId: 7,
          servicioId: 3,
          duracionMinutos: 45,
          fecha: '2026-10-21',
          hora: '11:30',
          precioTotal: 180,
          anticipoPagado: 0,
        ),
      ).called(1);
    });

    test(
      'reservar con 409 (horario ocupado) no da la cita por creada',
      () async {
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
        ).thenThrow(ApiException('Horario no disponible.', statusCode: 409));

        final ok = await _reservar(vm);

        expect(ok, isFalse);
        expect(vm.bookingMessage, isNull);
        expect(vm.errorMessage, 'Horario no disponible.');
        expect(vm.bookingBusy, isFalse);
      },
    );
  });

  group('U-MOCK AuthViewModel', () {
    late MockAuthRepository repo;
    late AuthViewModel vm;

    // LoginResult es sealed: Mockito no puede inventar un valor de relleno.
    setUpAll(
      () => provideDummy<LoginResult>(
        const LoginSuccess(access: '', refresh: '', user: _cliente),
      ),
    );

    setUp(() {
      repo = MockAuthRepository();
      vm = AuthViewModel(repo);
    });

    tearDown(() => vm.dispose());

    test(
      'login exitoso guarda la sesión una vez y entra autenticado',
      () async {
        const success = LoginSuccess(access: 'a', refresh: 'r', user: _cliente);
        when(
          repo.login(email: anyNamed('email'), password: anyNamed('password')),
        ).thenAnswer((_) async => success);
        when(repo.completeLogin(success)).thenAnswer((_) async => _cliente);

        final ok = await vm.login(email: 'cliente@example.test', password: 'x');

        expect(ok, isTrue);
        expect(vm.phase, AuthPhase.authenticated);
        expect(vm.role, UserRole.cliente);
        verify(repo.completeLogin(success)).called(1);
      },
    );

    test('login con 2FA no guarda tokens todavía', () async {
      when(repo.login(email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer(
            (_) async => const LoginRequires2FA(
              tempToken: 't',
              destino: 'c***@example.test',
              mensaje: 'Te enviamos un código.',
            ),
          );

      final ok = await vm.login(email: 'cliente@example.test', password: 'x');

      expect(ok, isFalse);
      expect(vm.phase, AuthPhase.needs2fa);
      expect(vm.pendingDestino, 'c***@example.test');
      verifyNever(repo.completeLogin(any));
    });

    test(
      'credenciales incorrectas (401) dejan el mensaje del servidor',
      () async {
        when(
          repo.login(email: anyNamed('email'), password: anyNamed('password')),
        ).thenThrow(ApiException('Credenciales incorrectas.', statusCode: 401));

        final ok = await vm.login(email: 'cliente@example.test', password: 'x');

        expect(ok, isFalse);
        expect(vm.busy, isFalse);
        expect(vm.errorMessage, 'Credenciales incorrectas.');
        expect(vm.phase, isNot(AuthPhase.authenticated));
      },
    );

    test('logout borra la sesión local una vez y vuelve a invitado', () async {
      await vm.logout();
      verify(repo.logoutLocal()).called(1);
      expect(vm.user, isNull);
      expect(vm.phase, AuthPhase.guest);
    });
  });

  group('U-MOCK SecretariaHoyViewModel', () {
    late MockSecretariaRepository repo;
    late SecretariaHoyViewModel vm;

    setUp(() {
      repo = MockSecretariaRepository();
      vm = SecretariaHoyViewModel(repo);
      when(repo.getCitasDia(fecha: anyNamed('fecha'))).thenAnswer(
        (_) async => const SecretariaDiaDto(
          fecha: '2026-10-19',
          esHoy: true,
          citas: [_citaSecretaria],
          total: 1,
          pendientesAccion: 1,
          enCurso: 0,
          completadas: 0,
          noAsistio: 0,
        ),
      );
    });

    tearDown(() => vm.dispose());

    test(
      'PM07 un segundo toque en Llegó mientras se envía no duplica',
      () async {
        final pendiente = Completer<Map<String, dynamic>>();
        when(repo.marcarLlego(90)).thenAnswer((_) => pendiente.future);

        final primero = vm.marcarLlego(90);
        final segundo = await vm.marcarLlego(90);
        pendiente.complete({'mensaje': 'Llegada registrada.'});

        expect(segundo, isFalse);
        expect(await primero, isTrue);
        expect(vm.actionMessage, 'Llegada registrada.');
        verify(repo.marcarLlego(90)).called(1);
      },
    );

    test(
      'no asistió rechazado por el servidor (403) no recarga ni penaliza',
      () async {
        when(repo.marcarNoAsistio(90))
            .thenThrow(ApiException('No autorizado.', statusCode: 403));

        final ok = await vm.marcarNoAsistio(90);

        expect(ok, isFalse);
        expect(vm.errorMessage, 'No autorizado.');
        expect(vm.actionBusy, isFalse);
        verifyNever(repo.getCitasDia(fecha: anyNamed('fecha')));
      },
    );
  });
}
