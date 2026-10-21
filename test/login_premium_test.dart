import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/repositories/auth_repository.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/views/auth/login_views.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.loginResult,
    this.loginError,
    this.hangLogin = false,
  });

  LoginResult? loginResult;
  Object? loginError;
  bool hangLogin;
  int resendCalls = 0;
  final Completer<LoginResult> _gate = Completer<LoginResult>();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    if (hangLogin) return _gate.future;
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
  Future<AuthUser> completeLogin(LoginSuccess success) async => success.user;

  @override
  Future<AuthUser> verify2fa({
    required String tempToken,
    required String codigo,
  }) async {
    return AuthUser(
      id: 2,
      username: 'cli2',
      email: 'a@b.com',
      rol: UserRole.cliente,
    );
  }

  @override
  Future<void> resend2fa(String tempToken) async {
    resendCalls += 1;
  }

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
  Future<AuthUser?> restoreSession() async => null;

  @override
  Future<PerfilDto> getPerfil() async {
    throw ApiException('No autorizado.', statusCode: 401);
  }

  @override
  Future<void> logoutLocal() async {}
}

Future<void> _pumpLogin(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
  required AuthViewModel auth,
  Widget? home,
}) async {
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
      child: ChangeNotifierProvider<AuthViewModel>.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.guest(),
          home: home ?? const LoginView(),
          routes: {
            '/cliente': (_) => const Scaffold(body: Text('cliente-home')),
            '/secretaria': (_) => const Scaffold(body: Text('secretaria-home')),
            '/login': (_) => const LoginView(),
            '/verify-2fa': (_) => const Verify2FAView(),
          },
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  testWidgets('login fits phone, large phone, tablet and landscape', (
    tester,
  ) async {
    for (final size in const [
      Size(360, 800),
      Size(390, 844),
      Size(800, 1280),
      Size(800, 360),
    ]) {
      final auth = AuthViewModel(_FakeAuthRepository());
      await _pumpLogin(tester, size: size, auth: auth);
      expect(tester.takeException(), isNull);
      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      auth.dispose();
    }
  });

  testWidgets('login stays readable with enlarged text', (tester) async {
    final auth = AuthViewModel(_FakeAuthRepository());
    await _pumpLogin(
      tester,
      size: const Size(360, 800),
      textScale: 1.3,
      auth: auth,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Inicia sesión'), findsOneWidget);
    auth.dispose();
  });

  testWidgets('password visibility toggles without losing the field', (
    tester,
  ) async {
    final auth = AuthViewModel(_FakeAuthRepository());
    await _pumpLogin(tester, size: const Size(390, 844), auth: auth);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('empty login fields show validation', (tester) async {
    final auth = AuthViewModel(_FakeAuthRepository());
    await _pumpLogin(tester, size: const Size(360, 800), auth: auth);
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Obligatorio'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('login loading keeps the button size and shows a spinner', (
    tester,
  ) async {
    final auth = AuthViewModel(_FakeAuthRepository(hangLogin: true));
    await _pumpLogin(tester, size: const Size(360, 800), auth: auth);
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secreto');
    final antes = tester.getSize(find.byKey(const Key('login_entrar')));
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    // La etiqueta cede al spinner con un fundido corto (AppMotion.quick).
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Entrar'), findsNothing);
    expect(tester.getSize(find.byKey(const Key('login_entrar'))), antes);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('login error is announced in a live region', (tester) async {
    final auth = AuthViewModel(
      _FakeAuthRepository(loginError: ApiException('Credenciales inválidas.')),
    );
    await _pumpLogin(tester, size: const Size(360, 800), auth: auth);
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'mala');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Credenciales inválidas.'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('2FA accepts six digits, masks destination and resends', (
    tester,
  ) async {
    final repo = _FakeAuthRepository(
      loginResult: const LoginRequires2FA(
        tempToken: 'temp',
        destino: 'jorge@correo.com',
        mensaje: 'Revisa tu correo.',
      ),
    );
    final auth = AuthViewModel(repo);
    await auth.login(email: 'a@b.com', password: 'x');
    await _pumpLogin(
      tester,
      size: const Size(360, 800),
      auth: auth,
      home: const Verify2FAView(),
    );
    expect(find.textContaining('jorge@correo.com'), findsNothing);
    expect(find.textContaining('j***@correo.com'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1234567');
    expect(find.text('123456'), findsOneWidget);
    await tester.tap(find.text('Reenviar código'));
    await tester.pumpAndSettle();
    expect(repo.resendCalls, 1);
    expect(find.text('Código reenviado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('2FA wide layout does not overflow', (tester) async {
    final auth = AuthViewModel(
      _FakeAuthRepository(
        loginResult: const LoginRequires2FA(
          tempToken: 'temp',
          destino: '5520301120',
          mensaje: 'Código enviado.',
        ),
      ),
    );
    await auth.login(email: 'a@b.com', password: 'x');
    await _pumpLogin(
      tester,
      size: const Size(800, 360),
      textScale: 1.3,
      auth: auth,
      home: const Verify2FAView(),
    );
    expect(find.textContaining('***1120'), findsOneWidget);
    expect(find.textContaining('5520301120'), findsNothing);
    expect(find.text('Verificar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });

  testWidgets('login rejects a malformed email and can return home', (
    tester,
  ) async {
    final auth = AuthViewModel(_FakeAuthRepository());
    await _pumpLogin(
      tester,
      size: const Size(390, 844),
      auth: auth,
      home: const LoginView(),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'correo@');
    await tester.enterText(find.byType(TextFormField).at(1), 'secreta');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Correo no válido'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);
    expect(tester.takeException(), isNull);
    auth.dispose();
  });
}
