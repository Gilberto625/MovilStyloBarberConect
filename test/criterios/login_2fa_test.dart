// GH#11 / GH#20: criterios del acceso que faltaban por automatizar.
// - "Entrar" no envía dos veces ante un doble toque.
// - La pantalla de verificación 2FA solo aparece cuando el ViewModel la pide.
// - Un OTP inválido muestra el mensaje del servidor sin exponer el código ni
//   los tokens.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/repositories/auth_repository.dart';
import 'package:stylo_barber_connect/services/auth_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/views/auth/login_views.dart';

import '../mocks/mocks.mocks.dart';
import '../support/memory_token_storage.dart';

const _base = 'http://10.0.2.2:8000/api';

// Valores inventados para la prueba; no son credenciales reales.
const _tempToken = 'tmp-2fa-prueba-7f3a9c';
const _otp = '482913';

const _cliente = AuthUser(
  id: 15,
  username: 'cliente.prueba',
  email: 'cliente.prueba@example.test',
  rol: UserRole.cliente,
);

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Rutas que se abren desde el acceso.
class _Rutas extends NavigatorObserver {
  final nombres = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      nombres.add(route.settings.name);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      nombres.add(newRoute?.settings.name);
}

Future<void> _pumpLogin(
  WidgetTester tester,
  AuthViewModel auth, {
  _Rutas? rutas,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthViewModel>.value(
      value: auth,
      child: MaterialApp(
        theme: AppTheme.guest(),
        navigatorObservers: [?rutas],
        home: const LoginView(),
        routes: {
          '/cliente': (_) => const Scaffold(body: Text('cliente-home')),
          '/login': (_) => const LoginView(),
          '/verify-2fa': (_) => const Verify2FAView(),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _escribirCredenciales(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login_cuenta')),
    'cliente.prueba@example.test',
  );
  await tester.enterText(find.byKey(const Key('login_password')), 'Clave#123');
}

/// Pila real (repositorio, servicio y ApiClient) contra un servidor simulado.
({
  AuthViewModel auth,
  MemoryTokenStorage storage,
  List<http.Request> peticiones,
})
_pilaReal(http.Response Function(http.Request) responder) {
  final storage = MemoryTokenStorage();
  final peticiones = <http.Request>[];
  final api = ApiClient(
    tokenStorage: storage,
    baseUrl: _base,
    httpClient: MockClient((r) async {
      peticiones.add(r);
      return responder(r);
    }),
  );
  final auth = AuthViewModel(
    AuthRepository(api: AuthApiService(api), storage: storage),
  );
  return (auth: auth, storage: storage, peticiones: peticiones);
}

/// Textos visibles de la pantalla. No incluye lo que la persona escribe en
/// un campo (EditableText), solo etiquetas, mensajes y avisos.
List<String> _textosVisibles(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .toList();

void main() {
  // LoginResult es sealed: Mockito necesita un valor de relleno.
  setUpAll(
    () => provideDummy<LoginResult>(
      const LoginSuccess(access: '', refresh: '', user: _cliente),
    ),
  );

  group('GH#11 / GH#20 acceso', () {
    testWidgets('GH#11 doble toque en "Entrar" llama una sola vez al '
        'repositorio de auth', (tester) async {
      final repo = MockAuthRepository();
      final respuesta = Completer<LoginResult>();
      when(repo.login(email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) => respuesta.future);
      when(repo.completeLogin(any)).thenAnswer((_) async => _cliente);
      final auth = AuthViewModel(repo)..phase = AuthPhase.guest;
      addTearDown(auth.dispose);
      await _pumpLogin(tester, auth);
      await _escribirCredenciales(tester);

      // Dos toques separados por un intervalo típico de doble toque.
      await tester.tap(find.byKey(const Key('login_entrar')));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(
        find.byKey(const Key('login_entrar')),
        warnIfMissed: false,
      );
      // Y un "Enter" en el teclado mientras sigue enviando.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 80));

      final boton = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('login_entrar')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(boton.onPressed, isNull, reason: 'Deshabilitado mientras envía.');

      respuesta.complete(
        const LoginSuccess(access: 'a', refresh: 'r', user: _cliente),
      );
      await tester.pumpAndSettle();

      verify(
        repo.login(email: 'cliente.prueba@example.test', password: 'Clave#123'),
      ).called(1);
      expect(find.text('cliente-home'), findsOneWidget);
    });

    testWidgets('GH#20 si el servidor pide 2FA, el login abre la '
        'verificación y no guarda tokens', (tester) async {
      final pila = _pilaReal(
        (_) => _json({
          'ok': true,
          'requires2fa': true,
          'tempToken': _tempToken,
          'destino': 'c***a@example.test',
          'mensaje': 'Te enviamos un código de verificación.',
        }, 200),
      );
      addTearDown(pila.auth.dispose);
      pila.auth.phase = AuthPhase.guest;
      final rutas = _Rutas();
      await _pumpLogin(tester, pila.auth, rutas: rutas);
      await _escribirCredenciales(tester);

      await tester.tap(find.byKey(const Key('login_entrar')));
      await tester.pumpAndSettle();

      expect(pila.auth.phase, AuthPhase.needs2fa);
      expect(rutas.nombres, contains('/verify-2fa'));
      expect(rutas.nombres, isNot(contains('/cliente')));
      expect(find.text('Verificación'), findsOneWidget);
      expect(find.byKey(const Key('2fa_verificar')), findsOneWidget);
      expect(pila.storage.access, isNull);
      // El token temporal nunca se pinta.
      expect(
        _textosVisibles(tester).where((t) => t.contains(_tempToken)),
        isEmpty,
      );
    });

    testWidgets('GH#20 un login normal va al panel y nunca abre la '
        'verificación 2FA', (tester) async {
      final pila = _pilaReal(
        (_) => _json({
          'ok': true,
          'access': 'access-prueba',
          'refresh': 'refresh-prueba',
          'usuario': {
            'id': 15,
            'username': 'cliente.prueba',
            'email': 'cliente.prueba@example.test',
            'rol': 'cliente',
          },
        }, 200),
      );
      addTearDown(pila.auth.dispose);
      pila.auth.phase = AuthPhase.guest;
      final rutas = _Rutas();
      await _pumpLogin(tester, pila.auth, rutas: rutas);
      await _escribirCredenciales(tester);

      await tester.tap(find.byKey(const Key('login_entrar')));
      await tester.pumpAndSettle();

      expect(pila.auth.phase, AuthPhase.authenticated);
      expect(rutas.nombres, isNot(contains('/verify-2fa')));
      expect(find.byType(Verify2FAView), findsNothing);
      expect(find.text('cliente-home'), findsOneWidget);
    });

    testWidgets('GH#20 OTP inválido muestra el mensaje del servidor sin '
        'exponer el código ni los tokens', (tester) async {
      final pila = _pilaReal((r) {
        if (r.url.path.endsWith('/login/')) {
          return _json({
            'ok': true,
            'requires2fa': true,
            'tempToken': _tempToken,
            'destino': 'c***a@example.test',
          }, 200);
        }
        return _json({
          'ok': false,
          'error': 'Código incorrecto o vencido.',
        }, 400);
      });
      addTearDown(pila.auth.dispose);
      pila.auth.phase = AuthPhase.guest;
      await _pumpLogin(tester, pila.auth);
      await _escribirCredenciales(tester);
      await tester.tap(find.byKey(const Key('login_entrar')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), _otp);
      await tester.tap(find.byKey(const Key('2fa_verificar')));
      await tester.pumpAndSettle();

      // El código sí viajó al servidor, con el token temporal en el cuerpo.
      final verificar = pila.peticiones.last;
      expect(verificar.url.path, '/api/login/2fa/verificar/');
      expect(jsonDecode(verificar.body), {
        'tempToken': _tempToken,
        'codigo': _otp,
      });

      expect(find.text('Código incorrecto o vencido.'), findsOneWidget);
      final textos = _textosVisibles(tester);
      expect(textos.where((t) => t.contains(_otp)), isEmpty);
      expect(textos.where((t) => t.contains(_tempToken)), isEmpty);
      expect(textos.where((t) => t.contains('Bearer')), isEmpty);

      // Sigue en la verificación, sin sesión, y puede intentar de nuevo.
      expect(pila.auth.phase, AuthPhase.needs2fa);
      expect(pila.auth.user, isNull);
      expect(pila.storage.access, isNull);
      expect(find.text('Verificación'), findsOneWidget);
      final verificarBoton = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('2fa_verificar')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(verificarBoton.onPressed, isNotNull);
    });
  });
}
