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
import 'package:stylo_barber_connect/models/privacidad_models.dart';
import 'package:stylo_barber_connect/routes/app_routes.dart';
import 'package:stylo_barber_connect/services/privacidad_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/privacidad_viewmodels.dart';
import 'package:stylo_barber_connect/views/privacy/eliminar_cuenta_view.dart';
import 'package:stylo_barber_connect/views/privacy/privacidad_view.dart';

import 'mocks/mocks.mocks.dart';
import 'support/memory_token_storage.dart';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _hecho = CancelacionCuenta(
  folio: 'ARCO-C-20261021-A1B2C3',
  estado: 'bloqueada',
  fechaSupresion: '2026-11-20',
  mensaje: 'Tu cuenta quedó bloqueada.',
);

Future<(MockPrivacidadRepository, MockAuthRepository)> _pump(
  WidgetTester tester, {
  Widget home = const EliminarCuentaView(),
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = MockPrivacidadRepository();
  final authRepo = MockAuthRepository();
  when(authRepo.restoreSession()).thenAnswer(
    (_) async => const AuthUser(
      id: 4,
      username: 'cliente.prueba',
      email: 'c@example.test',
      rol: UserRole.cliente,
    ),
  );
  // Privacidad y mis datos lee el interruptor del código por correo.
  when(repo.getPreferencia2fa())
      .thenAnswer((_) async => const Preferencia2fa(email2fa: false));
  final auth = AuthViewModel(authRepo);
  await auth.bootstrap();
  addTearDown(auth.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider<EliminarCuentaViewModel>(
          create: (_) => EliminarCuentaViewModel(repo),
        ),
        ChangeNotifierProvider<Verificacion2faViewModel>(
          create: (_) => Verificacion2faViewModel(repo),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.panel(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        initialRoute: '/prueba',
        routes: {
          '/prueba': (_) => home,
          AppRoutes.guestHome: (_) =>
              const Scaffold(body: Text('inicio-invitado')),
          AppRoutes.eliminarCuenta: (_) =>
              const Scaffold(body: Text('pantalla-eliminar')),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (repo, authRepo);
}

Future<void> _escribir(WidgetTester tester, String key, String texto) async {
  await tester.enterText(find.byKey(Key(key)), texto);
  await tester.pump();
}

FilledButton _boton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const Key('eliminar_confirmar')));

/// La lista es perezosa: el botón se construye al acercarse.
Future<void> _verBoton(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('eliminar_confirmar')),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ARCO-M03 contrato HTTP de POST /privacidad/cancelacion/', () {
    late List<http.Request> peticiones;
    PrivacidadApiService servicio(http.Response Function(http.Request) r) {
      peticiones = [];
      return PrivacidadApiService(
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

    test('manda contraseña y motivo con Bearer y lee el folio', () async {
      final api = servicio(
        (_) => _json({
          'ok': true,
          'folio': 'ARCO-C-20261021-A1B2C3',
          'estado': 'bloqueada',
          'fecha_supresion': '2026-11-20',
          'mensaje': 'Tu cuenta quedó bloqueada.',
        }, 201),
      );
      final r = await api.cancelarCuenta(
        contrasena: 'Clave#1',
        motivo: ' Ya no ',
      );

      expect(r.folio, 'ARCO-C-20261021-A1B2C3');
      expect(r.fechaSupresion, '2026-11-20');
      final p = peticiones.single;
      expect(p.url.path, '/api/privacidad/cancelacion/');
      expect(p.method, 'POST');
      expect(p.headers['Authorization'], 'Bearer token-cliente');
      expect(jsonDecode(p.body), {'contrasena': 'Clave#1', 'motivo': 'Ya no'});
    });

    test('contraseña incorrecta llega con el mensaje del servidor', () async {
      final api = servicio(
        (_) =>
            _json({'ok': false, 'error': 'La contraseña no es correcta.'}, 401),
      );
      await expectLater(
        api.cancelarCuenta(contrasena: 'mala'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('contraseña'),
          ),
        ),
      );
    });

    test('sin folio no se da por hecha la cancelación', () async {
      final api = servicio((_) => _json({'ok': true}, 201));
      await expectLater(
        api.cancelarCuenta(contrasena: 'Clave#1'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('EliminarCuentaViewModel', () {
    test('solo envía con contraseña y la palabra ELIMINAR', () async {
      final repo = MockPrivacidadRepository();
      when(
        repo.cancelarCuenta(
          contrasena: anyNamed('contrasena'),
          motivo: anyNamed('motivo'),
        ),
      ).thenAnswer((_) async => _hecho);
      final vm = EliminarCuentaViewModel(repo);

      vm.setContrasena('Clave#1');
      expect(vm.puedeEnviar, isFalse);
      vm.setConfirmacion('eliminar');
      expect(vm.puedeEnviar, isTrue);

      expect(await vm.enviar(), isTrue);
      expect(vm.resultado?.folio, _hecho.folio);
      expect(vm.contrasena, isEmpty, reason: 'No se guarda la contraseña');
    });

    test('un error se muestra y no da resultado', () async {
      final repo = MockPrivacidadRepository();
      when(
        repo.cancelarCuenta(
          contrasena: anyNamed('contrasena'),
          motivo: anyNamed('motivo'),
        ),
      ).thenThrow(ApiException('La contraseña no es correcta.'));
      final vm = EliminarCuentaViewModel(repo)
        ..setContrasena('mala')
        ..setConfirmacion('ELIMINAR');

      expect(await vm.enviar(), isFalse);
      expect(vm.error, 'La contraseña no es correcta.');
      expect(vm.resultado, isNull);
    });
  });

  group('Pantalla Eliminar mi cuenta', () {
    testWidgets('ARCO-M03 confirma, muestra el folio y cierra la sesión', (
      tester,
    ) async {
      final (repo, authRepo) = await _pump(tester);
      when(
        repo.cancelarCuenta(
          contrasena: anyNamed('contrasena'),
          motivo: anyNamed('motivo'),
        ),
      ).thenAnswer((_) async => _hecho);
      await _verBoton(tester);

      expect(_boton(tester).onPressed, isNull);
      await _escribir(tester, 'eliminar_contrasena', 'Clave#1');
      expect(_boton(tester).onPressed, isNull);
      await _escribir(tester, 'eliminar_confirmacion', 'ELIMINAR');
      expect(_boton(tester).onPressed, isNotNull);

      await tester.ensureVisible(find.byKey(const Key('eliminar_confirmar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('eliminar_confirmar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('eliminar_hecho')), findsOneWidget);
      expect(find.text(_hecho.folio), findsOneWidget);
      expect(find.textContaining('2026-11-20'), findsOneWidget);
      verify(authRepo.logoutLocal()).called(1);

      await tester.tap(find.byKey(const Key('eliminar_salir')));
      await tester.pumpAndSettle();
      expect(find.text('inicio-invitado'), findsOneWidget);
    });

    testWidgets('si el servidor rechaza la contraseña no cierra la sesión', (
      tester,
    ) async {
      final (repo, authRepo) = await _pump(tester);
      when(
        repo.cancelarCuenta(
          contrasena: anyNamed('contrasena'),
          motivo: anyNamed('motivo'),
        ),
      ).thenThrow(ApiException('La contraseña no es correcta.'));
      await _escribir(tester, 'eliminar_contrasena', 'mala');
      await _escribir(tester, 'eliminar_confirmacion', 'ELIMINAR');
      await _verBoton(tester);
      await tester.tap(find.byKey(const Key('eliminar_confirmar')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('La contraseña no es correcta.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('La contraseña no es correcta.'), findsOneWidget);
      verifyNever(authRepo.logoutLocal());
    });

    testWidgets('ya cancelada, no hay flecha y Atrás lleva al inicio', (
      tester,
    ) async {
      final (repo, _) = await _pump(tester, home: const _Lanzador());
      when(
        repo.cancelarCuenta(
          contrasena: anyNamed('contrasena'),
          motivo: anyNamed('motivo'),
        ),
      ).thenAnswer((_) async => _hecho);
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);

      await _escribir(tester, 'eliminar_contrasena', 'Clave#1');
      await _escribir(tester, 'eliminar_confirmacion', 'ELIMINAR');
      await _verBoton(tester);
      await tester.tap(find.byKey(const Key('eliminar_confirmar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eliminar_hecho')), findsOneWidget);
      expect(
        find.byType(BackButton),
        findsNothing,
        reason: 'Una flecha que no hace nada confunde',
      );

      // Botón Atrás del sistema.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('inicio-invitado'), findsOneWidget);
    });

    testWidgets('Privacidad lleva a Eliminar mi cuenta', (tester) async {
      await _pump(tester, home: const PrivacidadView());
      await tester.tap(find.byKey(const Key('privacidad_eliminar_cuenta')));
      await tester.pumpAndSettle();
      expect(find.text('pantalla-eliminar'), findsOneWidget);
    });

    testWidgets('a 360x800 con texto 1.3 no desborda', (tester) async {
      await _pump(tester, size: const Size(360, 800), textScale: 1.3);
      expect(tester.takeException(), isNull);
    });
  });

  group('Perfil con la sesión ya cerrada', () {
    Future<(AuthViewModel, MockAuthRepository)> sesion() async {
      final repo = MockAuthRepository();
      when(repo.restoreSession()).thenAnswer(
        (_) async => const AuthUser(
          id: 4,
          username: 'cliente.prueba',
          email: 'c@example.test',
          rol: UserRole.cliente,
        ),
      );
      final auth = AuthViewModel(repo);
      await auth.bootstrap();
      return (auth, repo);
    }

    test('tras cerrar sesión no se pide el perfil ni queda error', () async {
      final (auth, repo) = await sesion();
      await auth.logout();

      expect(await auth.loadPerfil(), isNull);
      verifyNever(repo.getPerfil());
      expect(
        auth.errorMessage,
        isNull,
        reason: 'Un 401 aquí aparecía después en la pantalla de acceso',
      );
    });

    test('un 401 que llega después de cerrar sesión se descarta', () async {
      final (auth, repo) = await sesion();
      final respuesta = Completer<PerfilDto>();
      when(repo.getPerfil()).thenAnswer((_) => respuesta.future);

      final carga = auth.loadPerfil();
      await auth.logout();
      respuesta.completeError(
        ApiException('Las credenciales de autenticación no se proveyeron.'),
      );

      expect(await carga, isNull);
      expect(auth.errorMessage, isNull);
      expect(auth.perfil, isNull);
    });
  });
}

/// Abre Eliminar mi cuenta encima de otra pantalla, como en la app.
class _Lanzador extends StatelessWidget {
  const _Lanzador();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const EliminarCuentaView()),
        ),
        child: const Text('abrir'),
      ),
    );
  }
}
