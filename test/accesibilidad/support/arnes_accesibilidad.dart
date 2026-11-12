// Arnés de las pruebas de accesibilidad (GH#19 QA-006, PM10, S8-03).
//
// Monta las pantallas críticas con repositorios falsos (sin red), igual que
// client_secretary_premium_test.dart, con el tema, el idioma y las rutas de la
// app real. Cada [Escenario] sabe llegar a su pantalla y qué controles clave
// tienen que poder alcanzarse.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/config/app_locale.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/barbero_models.dart';
import 'package:stylo_barber_connect/routes/app_routes.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/barbero_agenda_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/catalog_list_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/client_citas_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/home_guest_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/secretaria_gestion_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/secretaria_hoy_viewmodel.dart';
import 'package:stylo_barber_connect/views/auth/login_views.dart';
import 'package:stylo_barber_connect/views/auth/registro_views.dart';
import 'package:stylo_barber_connect/views/barber/barbero_agenda_view.dart';
import 'package:stylo_barber_connect/views/client/client_home_view.dart';
import 'package:stylo_barber_connect/views/client/client_widgets.dart';
import 'package:stylo_barber_connect/views/guest/guest_home_view.dart';
import 'package:stylo_barber_connect/views/secretary/secretary_shell.dart';

import '../../mocks/mocks.mocks.dart';
import 'fakes_accesibilidad.dart';

/// Superficie de prueba: tamaño lógico (dp) y escala de texto.
class Superficie {
  const Superficie(this.nombre, this.size, {this.textScale = 1});

  final String nombre;
  final Size size;
  final double textScale;

  @override
  String toString() => nombre;
}

/// Teléfono de referencia (Pixel 7, 412×915 dp).
const telefono = Superficie('412x915', Size(412, 915));

/// Pantalla pequeña del criterio S8-03.
const pequena = Superficie('360x640', Size(360, 640));

/// Contexto montado: repos falsos para revisar el resultado de un flujo.
class Montaje {
  Montaje(this.citas);

  final FakeCitas citas;
}

/// Una pantalla crítica y cómo llegar a ella.
class Escenario {
  const Escenario({
    required this.id,
    required this.nombre,
    required this.montar,
    required this.controles,
  });

  final String id;
  final String nombre;
  final Future<Montaje> Function(WidgetTester tester, Superficie s) montar;

  /// Controles clave que deben poder alcanzarse (con scroll si hace falta).
  /// Es una función: un `Finder` guarda su último resultado y no se comparte
  /// entre pruebas.
  final List<Finder> Function() controles;

  @override
  String toString() => '$id ($nombre)';
}

/// Fechas fijas para que "próximas" no dependa del día en que corre la prueba.
void fijarReloj() {
  setUp(() => relojCliente = () => DateTime(2026, 11, 11));
  tearDown(() => relojCliente = DateTime.now);
}

Future<AuthViewModel> _auth(UserRole rol) async {
  final auth = AuthViewModel(FakeAuth(rol: rol));
  await auth.bootstrap();
  return auth;
}

/// Monta [home] con todos los ViewModels de la app y las rutas reales.
Future<Montaje> montarApp(
  WidgetTester tester,
  Superficie s, {
  required Widget home,
  UserRole rol = UserRole.cliente,
  bool conSesion = true,
}) async {
  tester.view.physicalSize = s.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final citasRepo = FakeCitas();
  final catalogRepo = FakeCatalog();
  final secretariaRepo = FakeSecretaria();
  final auth = conSesion
      ? await _auth(rol)
      : AuthViewModel(FakeAuth(rol: rol, conSesion: false));
  final citas = ClientCitasViewModel(citasRepo);
  final catalog = CatalogListViewModel(catalogRepo);
  final guest = HomeGuestViewModel(catalogRepo);
  final hoy = SecretariaHoyViewModel(secretariaRepo);
  final gestion = SecretariaGestionViewModel(
    secretaria: secretariaRepo,
    citas: citasRepo,
    catalog: catalogRepo,
  );
  for (final vm in <ChangeNotifier>[
    auth,
    citas,
    catalog,
    guest,
    hoy,
    gestion,
  ]) {
    addTearDown(vm.dispose);
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider<ClientCitasViewModel>.value(value: citas),
        ChangeNotifierProvider<CatalogListViewModel>.value(value: catalog),
        ChangeNotifierProvider<HomeGuestViewModel>.value(value: guest),
        ChangeNotifierProvider<SecretariaHoyViewModel>.value(value: hoy),
        ChangeNotifierProvider<SecretariaGestionViewModel>.value(
          value: gestion,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.panel(),
        locale: AppLocale.locale,
        supportedLocales: AppLocale.supported,
        localizationsDelegates: AppLocale.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(s.textScale)),
          child: child!,
        ),
        home: home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return Montaje(citasRepo);
}

/// El primer `Scrollable` vertical que contiene a [objetivo], o el primero
/// de la pantalla si [objetivo] aún no está construido (lista perezosa).
Finder _scrollVertical() => find
    .byWidgetPredicate(
      (w) =>
          w is Scrollable &&
          (w.axisDirection == AxisDirection.down ||
              w.axisDirection == AxisDirection.up),
    )
    .hitTestable()
    .first;

/// Lleva [objetivo] a la vista con scroll si hace falta y comprueba que se
/// puede tocar (no queda tapado ni fuera de la pantalla).
Future<void> alcanzar(WidgetTester tester, Finder objetivo) async {
  if (objetivo.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      objetivo,
      120,
      scrollable: _scrollVertical(),
      maxScrolls: 60,
    );
  }
  await tester.ensureVisible(objetivo.first);
  await tester.pumpAndSettle();
  expect(
    objetivo.first.hitTestable(),
    findsOneWidget,
    reason: 'No se puede tocar $objetivo',
  );
}

/// [alcanzar] y tocar.
Future<void> tocar(WidgetTester tester, Finder objetivo) async {
  await alcanzar(tester, objetivo);
  await tester.tap(objetivo.first.hitTestable());
  await tester.pumpAndSettle();
}

/// Las tres guías de Android que revisa el informe previo al lanzamiento.
Future<void> cumpleGuiasAndroid(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

/// Sin excepciones de layout (incluye `RenderFlex overflowed`).
void sinOverflow(WidgetTester tester, String donde) {
  final e = tester.takeException();
  expect(e, isNull, reason: 'Excepción en $donde: $e');
}

// ---------------------------------------------------------------------------
// Flujos
// ---------------------------------------------------------------------------

Future<Montaje> _cliente(WidgetTester t, Superficie s) =>
    montarApp(t, s, home: const ClientHomeShell());

Future<Montaje> _agendarPaso(WidgetTester t, Superficie s, int paso) async {
  final m = await _cliente(t, s);
  await tocar(t, find.byKey(const ValueKey('cliente-nav-agendar')));
  sinOverflow(t, 'agendar paso 1');
  if (paso >= 2) {
    await tocar(t, find.byKey(const ValueKey('agendar-servicio-1')));
    sinOverflow(t, 'agendar paso 2');
  }
  if (paso >= 3) {
    await tocar(t, find.byKey(const ValueKey('agendar-barbero-8')));
    await tocar(t, find.byKey(const ValueKey('agendar-hora-11:30')));
    sinOverflow(t, 'agendar paso 3');
  }
  if (paso >= 4) {
    await tocar(t, find.byKey(const Key('agendar_continuar')));
    sinOverflow(t, 'agendar paso 4');
  }
  return m;
}

/// Reserva completa: Agendar → servicio → barbero → hora → resumen →
/// confirmar. Devuelve cuántas citas creó el repositorio falso.
Future<int> completarReserva(WidgetTester t, Superficie s) async {
  final m = await _agendarPaso(t, s, 4);
  await tocar(t, find.byKey(const Key('agendar_confirmar')));
  sinOverflow(t, 'confirmar reserva');
  return m.citas.creadas;
}

Future<Montaje> _barbero(WidgetTester t, Superficie s) {
  final repo = MockBarberoRepository();
  when(repo.getAgenda(fecha: anyNamed('fecha')))
      .thenAnswer((_) async => agendaBarbero);
  return montarApp(
    t,
    s,
    rol: UserRole.barbero,
    home: ChangeNotifierProvider<BarberoAgendaViewModel>(
      create: (_) => BarberoAgendaViewModel(repo),
      child: const BarberoAgendaView(),
    ),
  );
}

Future<Montaje> _detalleCliente(WidgetTester t, Superficie s) async {
  final m = await _cliente(t, s);
  await tocar(t, find.byKey(const ValueKey('cliente-nav-citas')));
  await tocar(t, find.byKey(const ValueKey('cita-3')));
  return m;
}

Future<Montaje> _detalleSecretaria(WidgetTester t, Superficie s) async {
  final m = await montarApp(
    t,
    s,
    home: const SecretaryShell(),
    rol: UserRole.secretaria,
  );
  await tocar(t, find.byKey(const ValueKey('agenda-cita-15')));
  return m;
}

/// Pantallas críticas de GH#19 / S8-03.
final escenarios = <Escenario>[
  Escenario(
    id: 'login',
    nombre: 'Inicio de sesión',
    montar: (t, s) =>
        montarApp(t, s, home: const LoginView(), conSesion: false),
    controles: () => [
      find.byKey(const Key('login_cuenta')),
      find.byKey(const Key('login_password')),
      find.byKey(const Key('login_entrar')),
      find.byKey(const Key('login_registro')),
    ],
  ),
  Escenario(
    id: 'registro',
    nombre: 'Registro',
    montar: (t, s) =>
        montarApp(t, s, home: const RegistroView(), conSesion: false),
    controles: () => [
      find.byKey(const Key('registro_nombre')),
      find.byKey(const Key('registro_correo')),
      find.byKey(const Key('registro_contrasena')),
      find.byKey(const Key('registro_respuesta')),
      find.byKey(const Key('registro_acepta')),
      find.byKey(const Key('registro_crear')),
    ],
  ),
  Escenario(
    id: 'invitado',
    nombre: 'Inicio de invitado',
    montar: (t, s) =>
        montarApp(t, s, home: const GuestHomeView(), conSesion: false),
    controles: () => [
      find.byKey(const ValueKey('guest-reservar')),
      find.byKey(const ValueKey('guest-services-all')),
      find.byKey(const ValueKey('guest-nav-entrar')),
    ],
  ),
  Escenario(
    id: 'cliente_inicio',
    nombre: 'Inicio de cliente',
    montar: _cliente,
    controles: () => [
      find.byKey(const Key('inicio_proxima_cita')),
      find.byKey(const Key('inicio_reservar')),
      find.byKey(const Key('inicio_mis_citas')),
      find.byKey(const ValueKey('cliente-nav-perfil')),
    ],
  ),
  Escenario(
    id: 'agendar_1',
    nombre: 'Agendar paso 1: servicio',
    montar: (t, s) => _agendarPaso(t, s, 1),
    controles: () => [find.byKey(const ValueKey('agendar-servicio-1'))],
  ),
  Escenario(
    id: 'agendar_2',
    nombre: 'Agendar paso 2: barbero',
    montar: (t, s) => _agendarPaso(t, s, 2),
    controles: () => [
      find.byKey(const Key('agendar_atras')),
      find.byKey(const ValueKey('agendar-barbero-8')),
    ],
  ),
  Escenario(
    id: 'agendar_3',
    nombre: 'Agendar paso 3: día y hora',
    montar: (t, s) => _agendarPaso(t, s, 3),
    controles: () => [
      find.byKey(const Key('agendar_otra_fecha')),
      find.byKey(const ValueKey('agendar-hora-11:30')),
      find.byKey(const Key('agendar_continuar')),
    ],
  ),
  Escenario(
    id: 'agendar_4',
    nombre: 'Agendar paso 4: resumen',
    montar: (t, s) => _agendarPaso(t, s, 4),
    controles: () => [
      find.byKey(const Key('agendar_atras')),
      find.byKey(const Key('agendar_confirmar')),
    ],
  ),
  Escenario(
    id: 'mis_citas',
    nombre: 'Mis citas',
    montar: (t, s) async {
      final m = await _cliente(t, s);
      await tocar(t, find.byKey(const ValueKey('cliente-nav-citas')));
      return m;
    },
    controles: () => [
      find.byKey(const Key('citas_filtro')),
      find.byKey(const ValueKey('cita-3')),
      find.byTooltip('Actualizar citas'),
    ],
  ),
  Escenario(
    id: 'detalle_cita',
    nombre: 'Detalle de cita',
    montar: _detalleCliente,
    controles: () => [
      find.byKey(const Key('cita_reprogramar')),
      find.byKey(const Key('cita_cancelar')),
      find.byTooltip('Atrás'),
    ],
  ),
  Escenario(
    id: 'cancelar_cita',
    nombre: 'Diálogo para cancelar la cita',
    montar: (t, s) async {
      final m = await _detalleCliente(t, s);
      await tocar(t, find.byKey(const Key('cita_cancelar')));
      return m;
    },
    controles: () => [
      find.byKey(const Key('cita_cancelar_motivo')),
      find.byKey(const Key('cita_cancelar_conservar')),
      find.byKey(const Key('cita_cancelar_confirmar')),
    ],
  ),
  Escenario(
    id: 'cliente_perfil',
    nombre: 'Perfil del cliente',
    montar: (t, s) async {
      final m = await _cliente(t, s);
      await tocar(t, find.byKey(const ValueKey('cliente-nav-perfil')));
      return m;
    },
    controles: () => [
      find.byKey(const Key('perfil_privacidad')),
      find.byKey(const Key('perfil_cerrar_sesion')),
      // Las pruebas corren sin APP_ENV, o sea en dev: la etiqueta se ve.
      find.byKey(const Key('etiqueta_ambiente')),
    ],
  ),
  Escenario(
    id: 'secretaria_hoy',
    nombre: 'Hoy de secretaría',
    montar: (t, s) =>
        montarApp(t, s, home: const SecretaryShell(), rol: UserRole.secretaria),
    controles: () => [
      find.byKey(const Key('hoy_fecha')),
      find.byKey(const Key('hoy_nueva_cita')),
      find.byKey(const ValueKey('agenda-cita-15')),
      find.byKey(const ValueKey('secretaria-nav-1')),
    ],
  ),
  Escenario(
    id: 'secretaria_detalle',
    nombre: 'Detalle de cita (secretaría)',
    montar: _detalleSecretaria,
    controles: () => [
      find.byKey(const Key('detalle_llego')),
      find.byKey(const Key('detalle_cobrar')),
      find.byKey(const Key('detalle_no_asistio')),
    ],
  ),
  Escenario(
    id: 'secretaria_cobro',
    nombre: 'Hoja de cobro (secretaría)',
    montar: (t, s) async {
      final m = await _detalleSecretaria(t, s);
      await tocar(t, find.byKey(const Key('detalle_cobrar')));
      return m;
    },
    controles: () => [
      find.byKey(const Key('cobro_metodo')),
      find.byKey(const Key('cobro_confirmar')),
    ],
  ),
  Escenario(
    id: 'secretaria_no_asistio',
    nombre: 'Confirmación de no asistió (secretaría)',
    montar: (t, s) async {
      final m = await _detalleSecretaria(t, s);
      await tocar(t, find.byKey(const Key('detalle_no_asistio')));
      return m;
    },
    controles: () => [
      find.byKey(const Key('no_asistio_check')),
      find.byKey(const Key('no_asistio_confirmar')),
    ],
  ),
  Escenario(
    id: 'barbero_agenda',
    nombre: 'Agenda del barbero',
    montar: _barbero,
    controles: () => [
      find.byKey(const ValueKey('barbero-iniciar-10')),
      find.byKey(const ValueKey('barbero-terminar-11')),
      find.byKey(const Key('barbero_cerrar_sesion')),
    ],
  ),
];

/// Agenda del barbero con una cita por atender y otra en la silla.
const agendaBarbero = BarberoAgendaDto(
  fecha: '2026-11-11',
  esHoy: true,
  citas: [
    BarberoCitaDto(
      id: 10,
      hora: '10:00',
      duracionMinutos: 40,
      servicioNombre: 'Corte clásico',
      clienteNombre: 'Ana Prueba',
      estado: 'confirmada',
      atencion: 'por_atender',
      notas: 'Degradado bajo',
      complementos: '',
      puedeIniciar: true,
      puedeTerminar: false,
    ),
    BarberoCitaDto(
      id: 11,
      hora: '11:00',
      duracionMinutos: 40,
      servicioNombre: 'Barba',
      clienteNombre: 'Beto Prueba',
      estado: 'en_curso',
      atencion: 'en_silla',
      notas: '',
      complementos: '',
      puedeIniciar: false,
      puedeTerminar: true,
    ),
  ],
);
