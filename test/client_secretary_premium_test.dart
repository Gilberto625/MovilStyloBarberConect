import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/catalog_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/repositories/auth_repository.dart';
import 'package:stylo_barber_connect/repositories/catalog_repository.dart';
import 'package:stylo_barber_connect/repositories/citas_repository.dart';
import 'package:stylo_barber_connect/repositories/secretaria_repository.dart';
import 'package:stylo_barber_connect/routes/app_routes.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/catalog_list_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/client_citas_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/secretaria_hoy_viewmodel.dart';
import 'package:stylo_barber_connect/views/client/client_home_view.dart';
import 'package:stylo_barber_connect/views/secretary/secretary_home_view.dart';

void main() {
  testWidgets('client home empty, next appointment and error retry', (
    tester,
  ) async {
    final citas = _FakeCitas();
    final auth = await _auth(username: 'Gilberto');
    await _pump(
      tester,
      size: const Size(360, 800),
      auth: auth,
      citasRepo: citas,
      home: const ClientHomeShell(),
    );
    expect(find.text('Hola, Gilberto'), findsOneWidget);
    expect(find.text('Sin cita próxima'), findsOneWidget);

    await tester.tap(find.text('Citas'));
    await tester.pumpAndSettle();
    citas.misCitas = [_cita()];
    await tester.tap(find.byTooltip('Actualizar citas'));
    await tester.pumpAndSettle();
    expect(find.text('Corte clásico'), findsOneWidget);
    // La fecha se muestra legible ("14 oct"), no como 2026-10-14.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cita-3')),
        matching: find.text('oct'),
      ),
      findsOneWidget,
    );
    expect(find.text('2026-10-14'), findsNothing);

    citas.misCitas = const [];
    citas.citasError = ApiException('Sin conexión.');
    await tester.tap(find.byTooltip('Actualizar citas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sin conexión.'), findsWidgets);

    citas.citasError = null;
    await tester.tap(find.byTooltip('Actualizar citas'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes citas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('booking uses real selections and confirms without a fake slot', (
    tester,
  ) async {
    final citas = _FakeCitas()..misCitas = [_cita()];
    final auth = await _auth();
    final catalog = _FakeCatalog();
    await _pump(
      tester,
      size: const Size(390, 844),
      auth: auth,
      citasRepo: citas,
      catalogRepo: catalog,
      home: const ClientHomeShell(),
    );
    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();
    expect(find.text('Corte clásico'), findsOneWidget);
    expect(find.text('Confirmar reserva'), findsNothing);

    await tester.tap(find.text('Corte clásico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luis Mora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('11:30'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar reserva'), findsNothing);
    // Paso 4: el resumen se revisa antes de confirmar.
    await tester.tap(find.byKey(const Key('agendar_continuar')));
    await tester.pumpAndSettle();
    expect(find.text('Luis Mora'), findsOneWidget);
    expect(find.text('Confirmar reserva'), findsOneWidget);
    await tester.tap(find.text('Confirmar reserva'));
    await tester.pumpAndSettle();
    expect(citas.created, 1);
    expect(find.textContaining('Cita creada (#9)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('booking surfaces a server conflict', (tester) async {
    final citas = _FakeCitas()
      ..misCitas = [_cita()]
      ..createError = ApiException('Ese horario ya no está disponible.');
    final auth = await _auth();
    await _pump(
      tester,
      size: const Size(390, 844),
      auth: auth,
      citasRepo: citas,
      home: const ClientHomeShell(),
    );
    await tester.tap(find.text('Agendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corte clásico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luis Mora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('11:30'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agendar_continuar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar reserva'));
    await tester.pumpAndSettle();
    expect(citas.created, 0);
    // El usuario sigue en el resumen para elegir otro horario.
    expect(find.text('Paso 4 de 4: Resumen'), findsOneWidget);
    expect(find.textContaining('ya no está disponible'), findsWidgets);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('profile shows only supplied fields', (tester) async {
    final auth = await _auth();
    final citas = _FakeCitas();
    await _pump(
      tester,
      size: const Size(360, 800),
      textScale: 1.3,
      auth: auth,
      citasRepo: citas,
      home: const ClientHomeShell(),
    );
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Gilberto Hernández'), findsOneWidget);
    expect(find.textContaining('gilberto'), findsWidgets);
    expect(find.textContaining('correo'), findsWidgets);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(find.textContaining('inventado'), findsNothing);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('profile keeps a long email on a narrow screen', (tester) async {
    const email = 'bartholomew.fitzgerald@northwind-holdings.example.com';
    final auth = await _auth(email: email);
    final citas = _FakeCitas();
    await _pump(
      tester,
      size: const Size(360, 800),
      textScale: 1.3,
      auth: auth,
      citasRepo: citas,
      home: const ClientHomeShell(),
    );
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.textContaining('bartholomew'), findsOneWidget);
    expect(find.textContaining('northwind-holdings'), findsOneWidget);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('client and secretary layouts avoid overflow', (tester) async {
    for (final size in const [Size(800, 1280), Size(800, 360)]) {
      final auth = await _auth(role: UserRole.secretaria);
      final citas = _FakeCitas()
        ..misCitas = [
          _cita(nombre: 'Servicio con nombre largo de demostración'),
        ];
      final secretaria = _FakeSecretaria();
      await _pump(
        tester,
        size: size,
        textScale: 1.3,
        auth: auth,
        citasRepo: citas,
        secretariaRepo: secretaria,
        home: const ClientHomeShell(),
      );
      expect(find.text('Hola, Gilberto'), findsOneWidget);
      expect(tester.takeException(), isNull);
      auth.dispose();

      final staff = await _auth(role: UserRole.secretaria);
      final day = _FakeSecretaria();
      await _pump(
        tester,
        size: size,
        textScale: 1.3,
        auth: staff,
        secretariaRepo: day,
        home: const SecretaryHomeView(),
      );
      expect(find.text('Operación'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Ana López'),
        80,
        scrollable: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      expect(find.text('Ana López'), findsOneWidget);
      expect(tester.takeException(), isNull);
      staff.dispose();
    }
  });

  testWidgets('secretary hides actions the backend did not authorize', (
    tester,
  ) async {
    final auth = await _auth(role: UserRole.secretaria);
    final day = _FakeSecretaria();
    await _pump(
      tester,
      size: const Size(390, 844),
      auth: auth,
      secretariaRepo: day,
      home: const SecretaryHomeView(),
    );
    expect(find.text('1'), findsWidgets);
    expect(find.text('Ana López'), findsOneWidget);
    await tester.tap(find.text('Ana López'));
    await tester.pumpAndSettle();
    expect(find.text('Cliente llegó'), findsNothing);
    expect(find.text('Cobrar restante'), findsNothing);
    expect(find.text('Cita #15'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
    expect(find.text('Volver a la agenda'), findsOneWidget);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('secretary search filters the loaded day', (tester) async {
    final auth = await _auth(role: UserRole.secretaria);
    await _pump(
      tester,
      size: const Size(390, 844),
      auth: auth,
      secretariaRepo: _FakeSecretaria(),
      home: const SecretaryHomeView(),
    );
    expect(find.text('Ana López'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'nadie');
    await tester.pump();
    expect(find.text('Ana López'), findsNothing);
    expect(
      find.text('Ninguna cita coincide con la búsqueda o el filtro.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pump();
    expect(find.text('Ana López'), findsOneWidget);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('client role cannot open the secretary panel', (tester) async {
    final auth = await _auth();
    await _pump(
      tester,
      size: const Size(360, 800),
      auth: auth,
      home: const SecretaryHomeView(),
    );
    expect(find.text('No autorizado para secretaría.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
  required AuthViewModel auth,
  _FakeCitas? citasRepo,
  _FakeCatalog? catalogRepo,
  _FakeSecretaria? secretariaRepo,
  required Widget home,
}) async {
  final citas = ClientCitasViewModel(citasRepo ?? _FakeCitas());
  final catalog = CatalogListViewModel(catalogRepo ?? _FakeCatalog());
  final secretaria = SecretariaHoyViewModel(
    secretariaRepo ?? _FakeSecretaria(),
  );
  addTearDown(citas.dispose);
  addTearDown(catalog.dispose);
  addTearDown(secretaria.dispose);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: auth),
          ChangeNotifierProvider<ClientCitasViewModel>.value(value: citas),
          ChangeNotifierProvider<CatalogListViewModel>.value(value: catalog),
          ChangeNotifierProvider<SecretariaHoyViewModel>.value(
            value: secretaria,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.guest(),
          home: home,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<AuthViewModel> _auth({
  String username = 'Gilberto',
  String email = 'gilberto@correo.com',
  UserRole role = UserRole.cliente,
}) async {
  final auth = AuthViewModel(
    _FakeAuth(
      user: AuthUser(id: 4, username: username, email: email, rol: role),
    ),
  );
  await auth.bootstrap();
  return auth;
}

CitaDto _cita({String nombre = 'Corte clásico'}) {
  return CitaDto(
    id: 3,
    servicioId: 1,
    servicioNombre: nombre,
    servicioImagen: '',
    fecha: '2026-10-14',
    hora: '11:00',
    duracionMinutos: 45,
    estado: 'confirmada',
    precioTotal: 180,
    anticipoPagado: 0,
    saldoPendiente: 180,
    notas: '',
    barberoNombre: 'Luis Mora',
    requierePago: false,
  );
}

class _FakeAuth implements AuthRepository {
  _FakeAuth({required this.user});

  final AuthUser user;

  @override
  AuthUser? get currentUser => user;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async => LoginSuccess(access: 'a', refresh: 'r', user: user);

  @override
  Future<AuthUser> completeLogin(LoginSuccess success) async => success.user;

  @override
  Future<AuthUser> verify2fa({
    required String tempToken,
    required String codigo,
  }) async => user;

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
  Future<AuthUser?> restoreSession() async => user;

  @override
  Future<PerfilDto> getPerfil() async {
    return PerfilDto(
      email: user.email,
      username: user.username,
      nombre: 'Gilberto',
      apellido: 'Hernández',
      telefono: '',
      fechaNacimiento: '',
      avatarUrl: '',
      direccion: '',
    );
  }

  @override
  Future<void> logoutLocal() async {}
}

class _FakeCitas implements CitasRepository {
  List<CitaDto> misCitas = const [];
  Object? citasError;
  Object? createError;
  int created = 0;

  @override
  Future<List<CitaDto>> getMisCitas() async {
    if (citasError != null) throw citasError!;
    return misCitas;
  }

  @override
  Future<List<BarberoDto>> getBarberos({int? servicioId}) async {
    return const [
      BarberoDto(
        id: 8,
        nombre: 'Luis',
        apellido: 'Mora',
        especialidades: 'Corte',
        avatarUrl: '',
        serviciosIds: [1],
      ),
    ];
  }

  @override
  Future<List<SlotDisponibilidad>> getDisponibilidad({
    required int barberoId,
    required String fecha,
    required int duracion,
  }) async {
    return const [
      SlotDisponibilidad(hora: '11:30', disponible: true),
      SlotDisponibilidad(hora: '12:00', disponible: false),
    ];
  }

  @override
  Future<PoliticaPagoDto> getPoliticaPago(int clienteId) async {
    return const PoliticaPagoDto(
      requiereAnticipo: false,
      porcentajeAnticipo: 0,
      penalizado: false,
      totalInasistencias: 0,
    );
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
  }) async {
    if (createError != null) throw createError!;
    created += 1;
    return {'ok': true, 'id': 9};
  }
}

class _FakeCatalog implements CatalogRepository {
  @override
  Future<List<ServicioDto>> getServicios() async {
    return const [
      ServicioDto(
        id: 1,
        nombre: 'Corte clásico',
        descripcion: 'Corte de máquina y tijera.',
        precio: 180,
        duracionMinutos: 45,
        categoria: 'corte',
        popular: true,
        activo: true,
        imagenUrl: '',
        bannerUrl: '',
      ),
    ];
  }

  @override
  Future<List<ProductoDto>> getProductos() async => const [];

  @override
  Future<ContactoDto> getContacto() async {
    return const ContactoDto(
      telefono: '',
      correo: '',
      direccion: '',
      horario: '',
      nombreNegocio: 'Tony Stylo',
      logoTipo: '',
      logoParte1: '',
      logoParte2: '',
      logoUrl: '',
      whatsappUrl: '',
      googleMapsUrl: '',
    );
  }

  @override
  Future<
    ({
      ContactoDto contacto,
      List<ServicioDto> servicios,
      List<ProductoDto> productos,
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

class _FakeSecretaria implements SecretariaRepository {
  @override
  Future<SecretariaDiaDto> getCitasDia({String? fecha}) async {
    return SecretariaDiaDto(
      fecha: '2026-10-12',
      esHoy: true,
      citas: [
        SecretariaCitaDto(
          id: 15,
          clienteId: 4,
          clienteNombre: 'Ana López',
          clienteTelefono: '',
          servicioNombre: 'Corte clásico',
          barberoNombre: 'Luis Mora',
          fecha: '2026-10-12',
          hora: '10:00',
          duracionMinutos: 45,
          estado: 'confirmada',
          precioTotal: 180,
          anticipoPagado: 0,
          anticipoPendiente: 0,
          restante: 180,
          puedeCobrar: false,
          puedeMarcarAsistencia: false,
          clientePenalizado: false,
        ),
      ],
      total: 1,
      pendientesAccion: 1,
      enCurso: 0,
      completadas: 0,
      noAsistio: 0,
    );
  }

  @override
  Future<Map<String, dynamic>> marcarLlego(int citaId) async => {'ok': true};

  @override
  Future<Map<String, dynamic>> marcarNoAsistio(int citaId) async => {
    'ok': true,
  };

  @override
  Future<Map<String, dynamic>> cobrar({
    required int citaId,
    required String metodoPago,
    String? comprobante,
    String? referencia,
    double? efectivoRecibido,
  }) async => {'ok': true};

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
  }) async => {'ok': true};
}
