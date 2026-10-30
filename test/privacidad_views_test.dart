import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/models/privacidad_models.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/privacidad_viewmodels.dart';
import 'package:stylo_barber_connect/views/auth/login_views.dart';
import 'package:stylo_barber_connect/views/privacy/aviso_privacidad_view.dart';
import 'package:stylo_barber_connect/views/privacy/editar_perfil_view.dart';
import 'package:stylo_barber_connect/views/privacy/mis_datos_view.dart';
import 'package:stylo_barber_connect/views/privacy/privacidad_view.dart';

import 'mocks/mocks.mocks.dart';
import 'support/privacidad_fixtures.dart';

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

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  double textScale = 1,
  Map<String, WidgetBuilder> routes = const {},
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.guest(),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: child,
      routes: routes,
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

void main() {
  late MockPrivacidadRepository repo;

  setUpAll(() {
    provideDummy<PerfilDto>(perfilPrueba);
    provideDummy<ConsentimientoPrivacidad>(
      ConsentimientoPrivacidad.sinRespuesta,
    );
    provideDummy<LoginResult>(
      const LoginSuccess(
        access: '',
        refresh: '',
        user: AuthUser(id: 0, username: '', email: '', rol: UserRole.unknown),
      ),
    );
  });

  setUp(() => repo = MockPrivacidadRepository());

  Widget misDatos() => ChangeNotifierProvider(
    create: (_) => MisDatosViewModel(repo),
    child: const MisDatosView(),
  );

  Widget editar() => ChangeNotifierProvider(
    create: (_) => EditarPerfilViewModel(repo),
    child: const EditarPerfilView(),
  );

  Widget aviso({bool autenticado = true}) => ChangeNotifierProvider(
    create: (_) => AvisoPrivacidadViewModel(repo, autenticado: autenticado),
    child: const AvisoPrivacidadView(),
  );

  group('ARCO-M01 Mis datos', () {
    testWidgets('muestra carga, luego perfil e historial del titular', (
      tester,
    ) async {
      final perfil = Completer<PerfilDto>();
      when(repo.getPerfil()).thenAnswer((_) => perfil.future);
      when(repo.getHistorialCitas()).thenAnswer((_) async => [_cita]);

      await _pump(tester, misDatos(), settle: false);
      await tester.pump();
      expect(find.text('Cargando tus datos…'), findsOneWidget);

      perfil.complete(perfilPrueba);
      await tester.pumpAndSettle();

      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('7710000000'), findsOneWidget);
      expect(find.text('Historial de citas (1)'), findsOneWidget);
      expect(find.text('Corte clásico'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('historial vacío y datos sin registrar se dicen claro', (
      tester,
    ) async {
      when(repo.getPerfil()).thenAnswer(
        (_) async => const PerfilDto(
          email: 'cliente.prueba@example.test',
          username: 'cliente.prueba',
          nombre: 'Cliente',
          apellido: '',
          telefono: '',
          fechaNacimiento: '',
          avatarUrl: '',
          direccion: '',
        ),
      );
      when(repo.getHistorialCitas()).thenAnswer((_) async => []);

      await _pump(tester, misDatos());

      expect(find.text('Aún no tienes citas registradas.'), findsOneWidget);
      expect(find.text('Sin registrar'), findsNWidgets(4));
    });

    testWidgets('error del servidor ofrece reintentar y vuelve a pedir', (
      tester,
    ) async {
      when(repo.getPerfil()).thenThrow(
        ApiException('No se pudo cargar el perfil.', statusCode: 500),
      );

      await _pump(tester, misDatos());
      expect(find.text('No se pudo cargar el perfil.'), findsOneWidget);

      when(repo.getPerfil()).thenAnswer((_) async => perfilPrueba);
      when(repo.getHistorialCitas()).thenAnswer((_) async => []);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Cliente'), findsOneWidget);
      verify(repo.getPerfil()).called(2);
    });
  });

  group('ARCO-M02 Corregir mis datos', () {
    setUp(() {
      when(repo.getPerfil()).thenAnswer((_) async => perfilPrueba);
    });

    testWidgets('un teléfono inválido no llega al servidor', (tester) async {
      await _pump(tester, editar());

      await tester.enterText(find.byKey(const Key('editar_telefono')), '123');
      await tester.tap(find.byKey(const Key('editar_perfil_guardar')));
      await tester.pumpAndSettle();

      expect(find.text('Debe tener de 10 a 15 dígitos'), findsOneWidget);
      verifyNever(repo.actualizarPerfil(any));
    });

    testWidgets('guardar envía un PUT y regresa con true', (tester) async {
      when(repo.actualizarPerfil(any)).thenAnswer((_) async => perfilPrueba);
      Object? resultado;
      await _pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                resultado = await Navigator.push<Object?>(
                  context,
                  MaterialPageRoute<Object?>(builder: (_) => editar()),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('editar_nombre')),
        'Cliente Editado',
      );
      await tester.tap(find.byKey(const Key('editar_perfil_guardar')));
      await tester.pumpAndSettle();

      final enviado =
          verify(repo.actualizarPerfil(captureAny)).captured.single
              as PerfilUpdate;
      expect(enviado.nombre, 'Cliente Editado');
      expect(enviado.avatarUrl, perfilPrueba.avatarUrl);
      expect(resultado, isTrue);
      expect(find.text('Datos actualizados.'), findsOneWidget);
    });

    testWidgets('el rechazo del servidor se muestra y no cierra', (
      tester,
    ) async {
      when(repo.actualizarPerfil(any)).thenThrow(
        ApiException(
          'La fecha de nacimiento no puede ser futura.',
          statusCode: 400,
        ),
      );
      await _pump(tester, editar());

      await tester.tap(find.byKey(const Key('editar_perfil_guardar')));
      await tester.pumpAndSettle();

      expect(
        find.text('La fecha de nacimiento no puede ser futura.'),
        findsOneWidget,
      );
      expect(find.byType(EditarPerfilView), findsOneWidget);
    });

    testWidgets('360×800 con texto 1.3 sin overflow', (tester) async {
      await _pump(tester, editar(), size: const Size(360, 800), textScale: 1.3);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const Key('editar_perfil_guardar')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ARCO-M05 Aviso de privacidad y opt-in', () {
    setUp(() {
      when(repo.getConsentimiento())
          .thenAnswer((_) async => ConsentimientoPrivacidad.sinRespuesta);
    });

    testWidgets('muestra el aviso y los permisos empiezan apagados', (
      tester,
    ) async {
      when(repo.getAvisoPrivacidad()).thenAnswer((_) async => avisoPrueba);

      await _pump(tester, aviso());

      expect(find.text('Aviso de privacidad'), findsWidgets);
      expect(find.text(avisoPrueba.contenido), findsOneWidget);
      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switches, hasLength(3));
      expect(switches.every((s) => s.value == false), isTrue);
    });

    testWidgets('activar uno y guardar lo persiste con la versión del aviso', (
      tester,
    ) async {
      when(repo.getAvisoPrivacidad()).thenAnswer((_) async => avisoPrueba);
      when(repo.guardarConsentimiento(any)).thenAnswer(
        (inv) async =>
            inv.positionalArguments.first as ConsentimientoPrivacidad,
      );
      await _pump(tester, aviso());

      await tester.scrollUntilVisible(
        find.byKey(const Key('aviso_guardar_preferencias')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('aviso_opt_whatsapp')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('aviso_guardar_preferencias')));
      await tester.pumpAndSettle();

      final c =
          verify(repo.guardarConsentimiento(captureAny)).captured.single
              as ConsentimientoPrivacidad;
      expect(c.recordatoriosWhatsapp, isTrue);
      expect(c.promociones, isFalse);
      expect(c.versionAviso, avisoPrueba.version);
      expect(find.text('Preferencias guardadas en tu cuenta.'), findsOneWidget);
    });

    testWidgets('error de red: reintentar y nada que guardar', (tester) async {
      when(
        repo.getAvisoPrivacidad(),
      ).thenThrow(ApiException('Error del servidor (503).', statusCode: 503));

      await _pump(tester, aviso());

      expect(find.text('Error del servidor (503).'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);
    });

    testWidgets('sin sesión: aviso visible, sin permisos y sin pedirlos', (
      tester,
    ) async {
      when(repo.getAvisoPrivacidad()).thenAnswer((_) async => avisoPrueba);

      await _pump(tester, aviso(autenticado: false));

      expect(find.text(avisoPrueba.contenido), findsOneWidget);
      expect(find.byKey(const Key('aviso_requiere_sesion')), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);
      verifyNever(repo.getConsentimiento());
    });

    testWidgets('si fallan las preferencias, se ve el error y reintentar', (
      tester,
    ) async {
      when(repo.getAvisoPrivacidad()).thenAnswer((_) async => avisoPrueba);
      when(
        repo.getConsentimiento(),
      ).thenThrow(ApiException('Error del servidor (500).', statusCode: 500));

      await _pump(tester, aviso());

      expect(find.text(avisoPrueba.contenido), findsOneWidget);
      expect(find.text('Error del servidor (500).'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);
    });

    testWidgets('aviso no publicado muestra estado vacío', (tester) async {
      when(repo.getAvisoPrivacidad()).thenAnswer((_) async => null);

      await _pump(tester, aviso());

      expect(
        find.text('El aviso de privacidad aún no está publicado.'),
        findsOneWidget,
      );
    });

    testWidgets('360×800 con texto 1.3 sin overflow', (tester) async {
      when(repo.getAvisoPrivacidad()).thenAnswer((_) async => avisoPrueba);
      await _pump(tester, aviso(), size: const Size(360, 800), textScale: 1.3);
      await tester.scrollUntilVisible(
        find.byKey(const Key('aviso_guardar_preferencias')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Entradas a privacidad', () {
    testWidgets('el centro de privacidad lleva a sus tres pantallas', (
      tester,
    ) async {
      when(repo.getPreferencia2fa())
          .thenAnswer((_) async => const Preferencia2fa(email2fa: false));
      await _pump(
        tester,
        ChangeNotifierProvider(
          create: (_) => Verificacion2faViewModel(repo),
          child: const PrivacidadView(),
        ),
        routes: {
          '/privacidad/mis-datos': (_) => const Text('ruta-mis-datos'),
          '/privacidad/editar-perfil': (_) => const Text('ruta-editar'),
          '/aviso-privacidad': (_) => const Text('ruta-aviso'),
        },
      );

      await tester.tap(find.byKey(const Key('privacidad_mis_datos')));
      await tester.pumpAndSettle();
      expect(find.text('ruta-mis-datos'), findsOneWidget);
    });

    testWidgets('el login enlaza al aviso de privacidad', (tester) async {
      final auth = AuthViewModel(MockAuthRepository());
      addTearDown(auth.dispose);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthViewModel>.value(
          value: auth,
          child: MaterialApp(
            home: const LoginView(),
            routes: {'/aviso-privacidad': (_) => const Text('ruta-aviso')},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final enlace = find.byKey(const Key('login_aviso_privacidad'));
      await tester.ensureVisible(enlace);
      await tester.tap(enlace);
      await tester.pumpAndSettle();
      expect(find.text('ruta-aviso'), findsOneWidget);
    });
  });
}
