import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/core/validation/validators.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/repositories/auth_repository.dart';
import 'package:stylo_barber_connect/routes/app_routes.dart';
import 'package:stylo_barber_connect/services/auth_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/views/auth/login_views.dart';
import 'package:stylo_barber_connect/views/auth/registro_views.dart';

import 'support/memory_token_storage.dart';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _datos = RegistroRequest(
  nombre: ' Ana ',
  apellidoPaterno: 'López',
  apellidoMaterno: 'Ruiz',
  username: 'ana.lopez',
  correo: 'Ana@Correo.MX',
  telefono: '(771) 123-4567',
  contrasena: 'Segura#2026',
  preguntaSecreta: '¿En qué ciudad naciste?',
  respuestaSecreta: ' Huejutla ',
  aceptaTerminos: true,
);

/// Backend simulado: registra peticiones y responde según la ruta.
class _Backend {
  _Backend({this.registro, this.verificacion});

  http.Response Function(http.Request)? registro;
  http.Response Function(http.Request)? verificacion;
  final peticiones = <http.Request>[];
  final storage = MemoryTokenStorage();

  late final repo = AuthRepository(
    api: AuthApiService(
      ApiClient(
        tokenStorage: storage,
        httpClient: MockClient((r) async {
          peticiones.add(r);
          switch (r.url.path) {
            case '/api/register/':
              return (registro ??
                  (_) => _json({
                    'ok': true,
                    'tempToken': 'tmp-1',
                    'destino': 'a***a@correo.mx',
                    'mensaje': 'Código OTP enviado a tu correo.',
                  }, 201))(r);
            case '/api/register/2fa/verificar/':
              return (verificacion ??
                  (_) => _json({
                    'ok': true,
                    'access': 'acc',
                    'refresh': 'ref',
                    'usuario': {
                      'id': 31,
                      'username': 'ana.lopez',
                      'email': 'ana@correo.mx',
                      'rol': 'cliente',
                    },
                  }, 200))(r);
            case '/api/reenviar-otp/':
              return _json({
                'ok': true,
                'mensaje': 'Código OTP reenviado.',
              }, 200);
          }
          return _json({'ok': false, 'error': 'ruta no simulada'}, 404);
        }),
        baseUrl: 'http://10.0.2.2:8000/api',
      ),
    ),
    storage: storage,
  );

  Map<String, dynamic> cuerpo(int i) =>
      jsonDecode(peticiones[i].body) as Map<String, dynamic>;
}

/// Servidor con `sinVerificacion`: cuenta verificada y sesión al momento.
http.Response _altaSinCodigo(http.Request _) => _json({
  'ok': true,
  'requiereVerificacion': false,
  'mensaje': 'Cuenta creada correctamente.',
  'access': 'acc-alta',
  'refresh': 'ref-alta',
  'usuario': {
    'id': 32,
    'username': 'ana.lopez',
    'email': 'ana@correo.mx',
    'rol': 'cliente',
  },
}, 201);

/// Servidor anterior que no pudo mandar el correo del código.
http.Response _altaSinCorreo(http.Request _) => _json({
  'ok': true,
  'requiereVerificacion': true,
  'tempToken': 'tmp-2',
  'destino': 'a****1@outlook.com',
  'email_enviado': false,
  'mensaje': 'No se pudo enviar el correo en este momento.',
}, 201);

Future<void> _pump(
  WidgetTester tester,
  AuthViewModel auth, {
  String inicial = AppRoutes.registro,
  Size size = const Size(360, 800),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthViewModel>.value(
      value: auth,
      child: MaterialApp(
        theme: AppTheme.panel(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        initialRoute: inicial,
        routes: {
          AppRoutes.registro: (_) => const RegistroView(),
          AppRoutes.registroVerificar: (_) => const VerificarRegistroView(),
          AppRoutes.login: (_) => const LoginView(),
          AppRoutes.clientHome: (_) =>
              const Scaffold(body: Text('panel-cliente')),
          AppRoutes.avisoPrivacidad: (_) => const Scaffold(body: Text('aviso')),
          AppRoutes.terminos: (_) => const Scaffold(body: Text('terminos')),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, String key, String texto) async {
  final campo = find.byKey(Key(key));
  await tester.ensureVisible(campo);
  await tester.pumpAndSettle();
  await tester.enterText(campo, texto);
}

Future<void> _llenar(WidgetTester tester) async {
  await _escribir(tester, 'registro_nombre', 'Ana');
  await _escribir(tester, 'registro_paterno', 'López');
  await _escribir(tester, 'registro_materno', 'Ruiz');
  await _escribir(tester, 'registro_telefono', '7711234567');
  await _escribir(tester, 'registro_usuario', 'ana.lopez');
  await _escribir(tester, 'registro_correo', 'ana@correo.mx');
  await _escribir(tester, 'registro_contrasena', 'Segura#2026');
  await _escribir(tester, 'registro_confirmacion', 'Segura#2026');
  final pregunta = find.byKey(const Key('registro_pregunta'));
  await tester.ensureVisible(pregunta);
  await tester.pumpAndSettle();
  await tester.tap(pregunta);
  await tester.pumpAndSettle();
  await tester.tap(find.text('¿En qué ciudad naciste?').last);
  await tester.pumpAndSettle();
  await _escribir(tester, 'registro_respuesta', 'Huejutla');
  final acepta = find.byKey(const Key('registro_acepta'));
  await tester.ensureVisible(acepta);
  await tester.pumpAndSettle();
  await tester.tap(acepta);
  await tester.pump();
}

Future<void> _crear(WidgetTester tester) async {
  final boton = find.byKey(const Key('registro_crear'));
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

void main() {
  group('Contrato de registro (POST /register/)', () {
    test('envía los campos de Django normalizados y sin Bearer', () async {
      final b = _Backend();
      final resultado = await b.repo.registrar(_datos);

      // Servidor anterior: ignora sinVerificacion y pide el código.
      final pendiente = resultado as RegistroPendiente;
      expect(pendiente.tempToken, 'tmp-1');
      expect(pendiente.destino, 'a***a@correo.mx');
      expect(pendiente.emailEnviado, isTrue);
      final r = b.peticiones.single;
      expect(r.method, 'POST');
      expect(r.headers.containsKey('Authorization'), isFalse);
      expect(b.cuerpo(0), {
        'nombre': 'Ana',
        'apellidopaterno': 'López',
        'apellidomaterno': 'Ruiz',
        'username': 'ana.lopez',
        'correo': 'ana@correo.mx',
        'telefono': '7711234567',
        'contrasena': 'Segura#2026',
        'preguntasecreta': '¿En qué ciudad naciste?',
        'respuestasecreta': 'Huejutla',
        'aceptaTerminos': true,
        'sinVerificacion': true,
      });
    });

    test('409 llega con el mensaje del servidor', () async {
      final b = _Backend(
        registro: (_) =>
            _json({'ok': false, 'error': 'El correo ya está registrado.'}, 409),
      );
      expect(
        () => b.repo.registrar(_datos),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'El correo ya está registrado.',
          ),
        ),
      );
    });

    test('confirmar el código guarda la sesión del cliente', () async {
      final b = _Backend();
      final user = await b.repo.verificarRegistro(
        tempToken: 'tmp-1',
        codigo: ' 123456 ',
      );

      expect(user.rol, UserRole.cliente);
      expect(b.cuerpo(0), {'tempToken': 'tmp-1', 'codigo': '123456'});
      expect(b.storage.access, 'acc');
      expect(b.storage.refresh, 'ref');
    });

    test('ok:false con 200 no guarda tokens y explica qué pasó', () async {
      final b = _Backend(
        verificacion: (_) => _json({
          'ok': false,
          'error': 'Cuenta verificada, pero no se pudo iniciar sesión.',
        }, 200),
      );
      await expectLater(
        b.repo.verificarRegistro(tempToken: 'tmp-1', codigo: '123456'),
        throwsA(isA<ApiException>()),
      );
      expect(b.storage.access, isNull);
    });

    test('reenviar manda solo el correo', () async {
      final b = _Backend();
      final msg = await b.repo.reenviarCodigoRegistro(' Ana@Correo.mx ');
      expect(msg, 'Código OTP reenviado.');
      expect(b.cuerpo(0), {'correo': 'ana@correo.mx'});
    });
  });

  group('AuthViewModel: alta', () {
    test('registrar deja el alta pendiente y confirmar abre sesión', () async {
      final b = _Backend();
      final vm = AuthViewModel(b.repo);

      expect(await vm.registrar(_datos), isTrue);
      expect(vm.hayRegistroPendiente, isTrue);
      expect(vm.registroCorreo, 'ana@correo.mx');

      expect(await vm.verificarRegistro('123456'), isTrue);
      expect(vm.phase, AuthPhase.authenticated);
      expect(vm.role, UserRole.cliente);
      expect(vm.hayRegistroPendiente, isFalse);
    });

    test('un código incompleto no llega al servidor', () async {
      final b = _Backend();
      final vm = AuthViewModel(b.repo);
      await vm.registrar(_datos);
      b.peticiones.clear();

      expect(await vm.verificarRegistro('12a'), isFalse);
      expect(vm.errorMessage, 'Escribe los 6 dígitos del código.');
      expect(b.peticiones, isEmpty);
    });
  });

  group('Registro sin código (sinVerificacion)', () {
    test('con tokens devuelve la sesión y no pide código', () async {
      final b = _Backend(registro: _altaSinCodigo);
      final resultado = await b.repo.registrar(_datos);

      expect(resultado, isA<RegistroCompletado>());
      final sesion = (resultado as RegistroCompletado).sesion;
      expect(sesion.access, 'acc-alta');
      expect(sesion.refresh, 'ref-alta');
      expect(sesion.user.rol, UserRole.cliente);
      expect(b.cuerpo(0)['sinVerificacion'], isTrue);
    });

    test('sin usuario en la respuesta no se da por creada', () async {
      final b = _Backend(
        registro: (_) => _json({
          'ok': true,
          'requiereVerificacion': false,
          'access': 'acc-alta',
          'refresh': 'ref-alta',
        }, 201),
      );
      await expectLater(b.repo.registrar(_datos), throwsA(isA<ApiException>()));
      expect(b.storage.access, isNull);
    });

    test('email_enviado:false llega al pendiente', () async {
      final b = _Backend(registro: _altaSinCorreo);
      final pendiente = await b.repo.registrar(_datos) as RegistroPendiente;
      expect(pendiente.tempToken, 'tmp-2');
      expect(pendiente.emailEnviado, isFalse);
    });

    test('el ViewModel guarda la sesión igual que tras el código', () async {
      final b = _Backend(registro: _altaSinCodigo);
      final vm = AuthViewModel(b.repo);

      expect(await vm.registrar(_datos), isTrue);
      expect(vm.phase, AuthPhase.authenticated);
      expect(vm.role, UserRole.cliente);
      expect(vm.user?.username, 'ana.lopez');
      expect(vm.hayRegistroPendiente, isFalse);
      expect(b.storage.access, 'acc-alta');
      expect(b.storage.refresh, 'ref-alta');
      expect(b.peticiones.map((r) => r.url.path), ['/api/register/']);
    });

    test('servidor anterior: queda pendiente del código', () async {
      final b = _Backend();
      final vm = AuthViewModel(b.repo);

      expect(await vm.registrar(_datos), isTrue);
      expect(vm.phase, isNot(AuthPhase.authenticated));
      expect(vm.hayRegistroPendiente, isTrue);
      expect(vm.registroEmailEnviado, isTrue);
      expect(b.storage.access, isNull);
    });
  });

  group('Validadores del alta (reglas de RegisterView)', () {
    test('contraseña: los cinco requisitos', () {
      expect(
        requisitosContrasena('abc').where((r) => r.cumple).map((r) => r.regla),
        ['Una minúscula'],
      );
      expect(
        requisitosContrasena('Segura#2026').every((r) => r.cumple),
        isTrue,
      );
      expect(validarContrasenaNueva('Segura2026'), isNotNull);
      expect(validarContrasenaNueva('Segura#2026'), isNull);
    });

    test('usuario, correo, teléfono y confirmación', () {
      expect(validarUsuario('ana'), isNotNull);
      expect(validarUsuario('ana lopez'), isNotNull);
      expect(validarUsuario('ana.lopez'), isNull);
      expect(validarCorreo('ana@correo'), 'Correo no válido');
      expect(validarCorreo('ana@correo.mx'), isNull);
      expect(validarTelefonoObligatorio(''), 'Obligatorio');
      expect(validarTelefonoObligatorio('77112'), isNotNull);
      expect(validarTelefonoObligatorio('771 123 4567'), isNull);
      expect(validarConfirmacion('a', 'b'), 'Las contraseñas no coinciden');
      expect(validarConfirmacion('Segura#2026', 'Segura#2026'), isNull);
    });
  });

  group('Pantallas de registro', () {
    testWidgets('PA-08 alta completa: formulario, código y panel del cliente', (
      tester,
    ) async {
      final b = _Backend();
      final auth = AuthViewModel(b.repo);
      addTearDown(auth.dispose);
      await _pump(tester, auth);

      await _llenar(tester);
      await _crear(tester);

      expect(find.text('Confirma tu correo'), findsOneWidget);
      expect(find.textContaining('a***a@correo.mx'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.tap(find.byKey(const Key('registro_verificar')));
      await tester.pumpAndSettle();

      expect(find.text('panel-cliente'), findsOneWidget);
      expect(b.storage.access, 'acc');
      expect(b.peticiones.map((r) => r.url.path), [
        '/api/register/',
        '/api/register/2fa/verificar/',
      ]);
    });

    testWidgets('PA-08b alta sin código: del formulario directo al panel', (
      tester,
    ) async {
      final b = _Backend(registro: _altaSinCodigo);
      final auth = AuthViewModel(b.repo);
      addTearDown(auth.dispose);
      await _pump(tester, auth);

      await _llenar(tester);
      await _crear(tester);

      expect(find.text('panel-cliente'), findsOneWidget);
      expect(find.text('Confirma tu correo'), findsNothing);
      expect(b.storage.access, 'acc-alta');
      expect(b.peticiones.map((r) => r.url.path), ['/api/register/']);
    });

    testWidgets('si el correo no salió, no dice "Enviado a"', (tester) async {
      final b = _Backend(registro: _altaSinCorreo);
      final auth = AuthViewModel(b.repo);
      addTearDown(auth.dispose);
      await _pump(tester, auth);

      await _llenar(tester);
      await _crear(tester);

      expect(find.text('Confirma tu correo'), findsOneWidget);
      expect(
        find.text('No se pudo enviar el correo en este momento.'),
        findsOneWidget,
      );
      expect(find.textContaining('Enviado a'), findsNothing);
      expect(find.textContaining('a****1@outlook.com'), findsNothing);
    });

    testWidgets('C el enlace a los términos de uso se ve y abre su pantalla', (
      tester,
    ) async {
      final auth = AuthViewModel(_Backend().repo);
      addTearDown(auth.dispose);
      await _pump(tester, auth);

      final enlace = find.byKey(const Key('registro_leer_terminos'));
      await tester.ensureVisible(enlace);
      await tester.pumpAndSettle();
      expect(find.text('Leer los términos de uso'), findsOneWidget);
      expect(find.byKey(const Key('registro_leer_aviso')), findsOneWidget);

      await tester.tap(enlace);
      await tester.pumpAndSettle();
      expect(find.text('terminos'), findsOneWidget);
    });

    testWidgets('vacío: marca cada campo y no llama al servidor', (
      tester,
    ) async {
      final b = _Backend();
      final auth = AuthViewModel(b.repo);
      addTearDown(auth.dispose);
      await _pump(tester, auth);

      await _crear(tester);

      expect(find.text('Obligatorio'), findsWidgets);
      expect(b.peticiones, isEmpty);
      final acepta = find.text('Necesitas aceptar para crear la cuenta');
      await tester.ensureVisible(acepta);
      await tester.pumpAndSettle();
      expect(acepta, findsOneWidget);
    });

    testWidgets('el servidor rechaza el correo y el mensaje se ve', (
      tester,
    ) async {
      final b = _Backend(
        registro: (_) =>
            _json({'ok': false, 'error': 'El correo ya está registrado.'}, 409),
      );
      final auth = AuthViewModel(b.repo);
      addTearDown(auth.dispose);
      await _pump(tester, auth);

      await _llenar(tester);
      await _crear(tester);

      expect(find.text('El correo ya está registrado.'), findsOneWidget);
      expect(find.text('Confirma tu correo'), findsNothing);
    });

    testWidgets('los requisitos se marcan mientras se escribe', (tester) async {
      final auth = AuthViewModel(_Backend().repo);
      addTearDown(auth.dispose);
      await _pump(tester, auth);
      final semantics = tester.ensureSemantics();

      await _escribir(tester, 'registro_contrasena', 'abc');
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Una mayúscula: pendiente'), findsOneWidget);
      expect(find.bySemanticsLabel('Una minúscula: cumplido'), findsOneWidget);

      await _escribir(tester, 'registro_contrasena', 'Abc#1234');
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp(r': pendiente$')), findsNothing);
      semantics.dispose();
    });

    testWidgets('a 360x800 con texto 1.3 no desborda', (tester) async {
      final auth = AuthViewModel(_Backend().repo);
      addTearDown(auth.dispose);
      await _pump(tester, auth, textScale: 1.3);
      await _llenar(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Regístrate desde el login abre el alta', (tester) async {
      final auth = AuthViewModel(_Backend().repo);
      addTearDown(auth.dispose);
      await _pump(tester, auth, inicial: AppRoutes.login);

      final link = find.byKey(const Key('login_registro'));
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await tester.tap(link);
      await tester.pumpAndSettle();

      expect(find.text('Crea tu cuenta'), findsOneWidget);
    });
  });
}
