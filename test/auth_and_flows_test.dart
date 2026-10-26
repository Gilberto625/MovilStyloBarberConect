import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/repositories/auth_repository.dart';
import 'package:stylo_barber_connect/repositories/citas_repository.dart';
import 'package:stylo_barber_connect/repositories/secretaria_repository.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/client_citas_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/home_guest_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/secretaria_hoy_viewmodel.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.loginResult, this.loginError, this.restoreUser});

  LoginResult? loginResult;
  Object? loginError;
  AuthUser? restoreUser;
  bool logoutCalled = false;
  AuthUser? completed;

  @override
  AuthUser? get currentUser => completed ?? restoreUser;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    return loginResult ??
        LoginSuccess(
          access: 'a',
          refresh: 'r',
          user: AuthUser(
            id: 1,
            username: 'cli',
            email: email,
            rol: UserRole.cliente,
          ),
        );
  }

  @override
  Future<AuthUser> completeLogin(LoginSuccess success) async {
    completed = success.user;
    return success.user;
  }

  @override
  Future<AuthUser> verify2fa({
    required String tempToken,
    required String codigo,
  }) async {
    if (codigo != '123456') {
      throw ApiException('Código incorrecto o expirado.', statusCode: 400);
    }
    final user = AuthUser(
      id: 2,
      username: 'cli2',
      email: 'a@b.com',
      rol: UserRole.cliente,
    );
    completed = user;
    return user;
  }

  @override
  Future<void> resend2fa(String tempToken) async {}

  @override
  Future<RegistroPendiente> registrar(RegistroRequest datos) async =>
      throw UnimplementedError('registro no se usa en esta prueba');

  @override
  Future<AuthUser> verificarRegistro({
    required String tempToken,
    required String codigo,
  }) async => throw UnimplementedError('registro no se usa en esta prueba');

  @override
  Future<String> reenviarCodigoRegistro(String correo) async => '';

  @override
  Future<AuthUser?> restoreSession() async => restoreUser;

  @override
  Future<PerfilDto> getPerfil() async {
    throw ApiException('No autorizado.', statusCode: 401);
  }

  @override
  Future<void> logoutLocal() async {
    logoutCalled = true;
    completed = null;
    restoreUser = null;
  }
}

class _FakeCitasRepository implements CitasRepository {
  @override
  Future<Map<String, dynamic>> cancelarCita(int citaId, {String motivo = ''}) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> reprogramarCita(
    int citaId, {
    required String fecha,
    required String hora,
  }) => throw UnimplementedError();

  bool createCalled = false;
  Object? createError;

  @override
  Future<List<CitaDto>> getMisCitas() async => const [];

  @override
  Future<List<BarberoDto>> getBarberos({int? servicioId}) async => const [];

  @override
  Future<List<SlotDisponibilidad>> getDisponibilidad({
    required int barberoId,
    required String fecha,
    required int duracion,
  }) async => const [];

  @override
  Future<PoliticaPagoDto> getPoliticaPago(int clienteId) async =>
      const PoliticaPagoDto(
        requiereAnticipo: true,
        porcentajeAnticipo: 50,
        penalizado: true,
        totalInasistencias: 1,
      );

  @override
  Future<Map<String, dynamic>> crearCita({
    required int clienteId,
    required int barberoId,
    required int servicioId,
    required int duracionMinutos,
    required String fecha,
    required String hora,
    required double precioTotal,
    double anticipoPagado = 0,
    String metodoAnticipo = '',
    String comprobantePago = '',
    String notas = '',
  }) async {
    createCalled = true;
    if (createError != null) throw createError!;
    return {'ok': true, 'id': 99};
  }
}

class _FakeSecretariaRepository implements SecretariaRepository {
  Object? loadError;
  Object? actionError;
  String? lastFecha;

  @override
  Future<SecretariaDiaDto> getCitasDia({String? fecha}) async {
    lastFecha = fecha;
    if (loadError != null) throw loadError!;
    return SecretariaDiaDto.fromJson({
      'fecha': '2026-10-06',
      'es_hoy': true,
      'resumen': {
        'total': 1,
        'pendientes_accion': 1,
        'en_curso': 0,
        'completadas': 0,
        'no_asistio': 0,
      },
      'citas': [
        {
          'id': 10,
          'cliente_id': 1,
          'cliente_nombre': 'Ana',
          'cliente_telefono': '555',
          'servicio_nombre': 'Corte',
          'barbero_nombre': 'Tony',
          'fecha': '2026-10-06',
          'hora': '10:00',
          'duracion_minutos': 30,
          'estado': 'confirmada',
          'precio_total': 170,
          'anticipo_pagado': 0,
          'anticipo_pendiente': 0,
          'restante': 170,
          'puede_cobrar': true,
          'puede_marcar_asistencia': true,
          'cliente_penalizado': false,
        },
      ],
    });
  }

  @override
  Future<Map<String, dynamic>> marcarLlego(int citaId) async {
    if (actionError != null) throw actionError!;
    return {'ok': true, 'mensaje': 'Cliente en curso'};
  }

  @override
  Future<Map<String, dynamic>> marcarNoAsistio(int citaId) async {
    if (actionError != null) throw actionError!;
    return {'ok': true, 'mensaje': 'Inasistencia registrada'};
  }

  @override
  Future<Map<String, dynamic>> cobrar({
    required int citaId,
    required String metodoPago,
    String? comprobante,
    String? referencia,
    double? efectivoRecibido,
  }) async {
    if (actionError != null) throw actionError!;
    return {'ok': true, 'mensaje': 'Cobro registrado'};
  }

  @override
  Future<List<SecretariaClienteDto>> buscarClientes(String q) async => const [];

  @override
  Future<SecretariaClienteDto> crearClientePaso({
    required String nombres,
    String apellido = '',
    required String telefono,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> crearCita({
    required int clienteId,
    required int barberoId,
    required int servicioId,
    required int duracionMinutos,
    required String fecha,
    required String hora,
    required double precioTotal,
    double anticipoPagado = 0,
    String metodoAnticipo = '',
    String comprobantePago = '',
    String notas = '',
  }) async => {'ok': true, 'id': 1};

  @override
  Future<List<SecretariaCitaResumenDto>> citasDeCliente(int clienteId) async =>
      const [];

  @override
  Future<SecretariaCitaEditableDto> citaEditable(int citaId) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> actualizarCita({
    required int citaId,
    required int barberoId,
    required int servicioId,
    required String fecha,
    required String hora,
    required double precioTotal,
    required double anticipoPagado,
    required String metodoAnticipo,
    required String notas,
    bool cancelar = false,
  }) async => {'ok': true, 'mensaje': 'Cita actualizada correctamente.'};
}

void main() {
  group('ApiException', () {
    test('parses ok/error envelope', () {
      final e = ApiException.fromBody(400, {
        'ok': false,
        'error': 'Campo inválido',
      });
      expect(e.message, 'Campo inválido');
      expect(e.statusCode, 400);
    });

    test('parses detail envelope', () {
      final e = ApiException.fromBody(403, {'detail': 'No autorizado.'});
      expect(e.isForbidden, isTrue);
      expect(e.message, 'No autorizado.');
    });

    test('marks unauthorized', () {
      final e = ApiException('Sesión expirada', statusCode: 401);
      expect(e.isUnauthorized, isTrue);
    });
  });

  group('AuthViewModel', () {
    test('login success navigates to authenticated cliente', () async {
      final repo = _FakeAuthRepository(
        loginResult: LoginSuccess(
          access: 'access',
          refresh: 'refresh',
          user: const AuthUser(
            id: 7,
            username: 'cliente1',
            email: 'c@t.com',
            rol: UserRole.cliente,
          ),
        ),
      );
      final vm = AuthViewModel(repo);
      final ok = await vm.login(email: 'c@t.com', password: 'x');
      expect(ok, isTrue);
      expect(vm.phase, AuthPhase.authenticated);
      expect(vm.role, UserRole.cliente);
      expect(vm.busy, isFalse);
    });

    test('login requires 2FA without inventing tokens', () async {
      final repo = _FakeAuthRepository(
        loginResult: const LoginRequires2FA(
          tempToken: 'temp',
          destino: 'c***@mail.com',
          mensaje: 'código enviado',
        ),
      );
      final vm = AuthViewModel(repo);
      final ok = await vm.login(email: 'c@t.com', password: 'x');
      expect(ok, isFalse);
      expect(vm.phase, AuthPhase.needs2fa);
      expect(vm.pendingTempToken, 'temp');
      expect(vm.user, isNull);
    });

    test('login error keeps guest and surfaces message', () async {
      final repo = _FakeAuthRepository(
        loginError: ApiException('Credenciales incorrectas.', statusCode: 401),
      );
      final vm = AuthViewModel(repo);
      final ok = await vm.login(email: 'bad', password: 'bad');
      expect(ok, isFalse);
      expect(vm.errorMessage, contains('Credenciales incorrectas'));
      expect(vm.phase, isNot(AuthPhase.authenticated));
    });

    test('verify2fa success and failure', () async {
      final repo = _FakeAuthRepository(
        loginResult: const LoginRequires2FA(
          tempToken: 'temp',
          destino: 'x',
          mensaje: 'y',
        ),
      );
      final vm = AuthViewModel(repo);
      await vm.login(email: 'a', password: 'b');
      expect(await vm.verify2fa('000000'), isFalse);
      expect(vm.errorMessage, isNotNull);
      expect(await vm.verify2fa('123456'), isTrue);
      expect(vm.phase, AuthPhase.authenticated);
    });

    test('logout clears session locally', () async {
      final repo = _FakeAuthRepository(
        restoreUser: const AuthUser(
          id: 1,
          username: 'sec',
          email: 's@t.com',
          rol: UserRole.secretaria,
        ),
      );
      final vm = AuthViewModel(repo);
      await vm.bootstrap();
      expect(vm.role.isStaffPanel, isTrue);
      await vm.logout();
      expect(repo.logoutCalled, isTrue);
      expect(vm.phase, AuthPhase.guest);
      expect(vm.user, isNull);
    });
  });

  group('ClientCitasViewModel', () {
    test('empty mis citas yields empty state', () async {
      final vm = ClientCitasViewModel(_FakeCitasRepository());
      await vm.loadMisCitas();
      expect(vm.state, LoadState.empty);
    });

    test('crear cita failure does not claim success', () async {
      final repo = _FakeCitasRepository()
        ..createError = ApiException('Barbero no válido.', statusCode: 400);
      final vm = ClientCitasViewModel(repo);
      final ok = await vm.reservar(
        user: const AuthUser(
          id: 1,
          username: 'u',
          email: 'u@t.com',
          rol: UserRole.cliente,
        ),
        barberoId: 1,
        servicioId: 1,
        duracionMinutos: 30,
        fecha: '2026-10-10',
        hora: '10:00',
        precioTotal: 170,
      );
      expect(ok, isFalse);
      expect(vm.errorMessage, contains('Barbero no válido'));
      expect(repo.createCalled, isTrue);
    });

    test('politica de anticipo se carga del backend', () async {
      final vm = ClientCitasViewModel(_FakeCitasRepository());
      await vm.loadPolitica(1);
      expect(vm.politica?.requiereAnticipo, isTrue);
      expect(vm.politica?.porcentajeAnticipo, 50);
    });
  });

  group('SecretariaHoyViewModel', () {
    test('loads day citas and filters', () async {
      final vm = SecretariaHoyViewModel(_FakeSecretariaRepository());
      await vm.load();
      expect(vm.state, LoadState.ready);
      expect(vm.citasFiltradas, hasLength(1));
      vm.setFiltro('completada');
      expect(vm.citasFiltradas, isEmpty);
    });

    test('server error is not treated as success', () async {
      final repo = _FakeSecretariaRepository()
        ..loadError = ApiException(
          'No se pudieron cargar citas del día.',
          statusCode: 500,
        );
      final vm = SecretariaHoyViewModel(repo);
      await vm.load();
      expect(vm.state, LoadState.error);
      expect(vm.errorMessage, contains('No se pudieron cargar'));
    });

    test('keeps the selected date on reload', () async {
      final repo = _FakeSecretariaRepository();
      final vm = SecretariaHoyViewModel(repo);
      await vm.load(fecha: '2026-11-02');
      expect(vm.fechaSeleccionada, '2026-11-02');
      expect(repo.lastFecha, '2026-11-02');
      await vm.load();
      expect(repo.lastFecha, '2026-11-02');
      await vm.mostrarHoy();
      expect(vm.fechaSeleccionada, isNull);
      expect(repo.lastFecha, isNull);
    });

    test('search matches client, service or barber', () async {
      final vm = SecretariaHoyViewModel(_FakeSecretariaRepository());
      await vm.load();
      vm.setConsulta('tony');
      expect(vm.citasFiltradas, hasLength(1));
      vm.setConsulta('fade');
      expect(vm.citasFiltradas, isEmpty);
    });

    test('asistencia failure surfaces error', () async {
      final repo = _FakeSecretariaRepository()
        ..actionError = ApiException('Acción inválida.', statusCode: 400);
      final vm = SecretariaHoyViewModel(repo);
      await vm.load();
      final ok = await vm.marcarLlego(10);
      expect(ok, isFalse);
      expect(vm.errorMessage, contains('Acción inválida'));
    });
  });
}
