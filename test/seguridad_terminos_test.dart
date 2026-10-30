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
import 'package:stylo_barber_connect/repositories/privacidad_repository.dart';
import 'package:stylo_barber_connect/services/auth_api_service.dart';
import 'package:stylo_barber_connect/services/catalog_api_service.dart';
import 'package:stylo_barber_connect/services/citas_api_service.dart';
import 'package:stylo_barber_connect/services/privacidad_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/home_guest_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/privacidad_viewmodels.dart';
import 'package:stylo_barber_connect/views/privacy/privacidad_view.dart';
import 'package:stylo_barber_connect/views/privacy/terminos_view.dart';

import 'mocks/mocks.mocks.dart';
import 'support/memory_token_storage.dart';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _terminos = ContenidoLegalDto(
  tipo: 'terminos',
  tipoDisplay: 'Términos y condiciones',
  titulo: 'Términos y condiciones',
  contenido: 'Al reservar aceptas las políticas de la barbería.',
);

/// Repositorio real sobre un backend simulado con MockClient.
class _Http {
  _Http(this.responder);

  final http.Response Function(http.Request) responder;
  final peticiones = <http.Request>[];

  late final _api = ApiClient(
    tokenStorage: MemoryTokenStorage(access: 'acc-sesion'),
    httpClient: MockClient((r) async {
      peticiones.add(r);
      return responder(r);
    }),
    baseUrl: 'http://10.0.2.2:8000/api',
  );

  late final repo = PrivacidadRepository(
    auth: AuthApiService(_api),
    citas: CitasApiService(_api),
    publico: CatalogApiService(_api),
    preferencias: PrivacidadApiService(_api),
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(theme: AppTheme.guest(), home: child));
  await tester.pumpAndSettle();
}

void main() {
  group('B contrato de /perfil/2fa/ (MockClient)', () {
    test('GET con Bearer: apagado por defecto', () async {
      final b = _Http(
        (_) => _json({
          'ok': true,
          'email_2fa': false,
          'puede_gestionar': true,
          'motivo_bloqueo': '',
          'proveedor_auth': 'local',
        }, 200),
      );

      final pref = await b.repo.getPreferencia2fa();

      expect(pref.email2fa, isFalse);
      expect(pref.puedeGestionar, isTrue);
      expect(pref.proveedorAuth, 'local');
      final r = b.peticiones.single;
      expect(r.method, 'GET');
      expect(r.url.path, '/api/perfil/2fa/');
      expect(r.headers['Authorization'], 'Bearer acc-sesion');
    });

    test('PUT manda {email_2fa} y lee lo guardado', () async {
      final b = _Http(
        (_) => _json({
          'ok': true,
          'email_2fa': true,
          'proveedor_auth': 'local',
        }, 200),
      );

      final pref = await b.repo.guardarPreferencia2fa(true);

      expect(pref.email2fa, isTrue);
      expect(pref.puedeGestionar, isTrue);
      final r = b.peticiones.single;
      expect(r.method, 'PUT');
      expect(r.url.path, '/api/perfil/2fa/');
      expect(jsonDecode(r.body), {'email_2fa': true});
    });

    test('ok:false o sin email_2fa llega como ApiException', () async {
      final sinCampo = _Http((_) => _json({'ok': true}, 200));
      await expectLater(
        sinCampo.repo.getPreferencia2fa(),
        throwsA(isA<ApiException>()),
      );
      final rechazo = _Http(
        (_) =>
            _json({'ok': false, 'error': "Campo 'email_2fa' requerido."}, 400),
      );
      await expectLater(
        rechazo.repo.guardarPreferencia2fa(false),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('C términos desde /public/legal/', () {
    test('pide tipo=terminos sin Bearer y devuelve ese bloque', () async {
      final b = _Http(
        (_) => _json({
          'ok': true,
          'contenidos': [
            {
              'tipo': 'terminos',
              'tipo_display': 'Términos y condiciones',
              'titulo': 'Términos y condiciones',
              'contenido': 'Texto de los términos.',
            },
          ],
        }, 200),
      );

      final t = await b.repo.getTerminos();

      expect(t?.contenido, 'Texto de los términos.');
      final r = b.peticiones.single;
      expect(r.url.path, '/api/public/legal/');
      expect(r.url.queryParameters['tipo'], 'terminos');
      expect(r.headers.containsKey('Authorization'), isFalse);
    });

    test('sin términos publicados devuelve null', () async {
      final b = _Http((_) => _json({'ok': true, 'contenidos': []}, 200));
      expect(await b.repo.getTerminos(), isNull);
    });
  });

  group('B Verificacion2faViewModel (Mockito)', () {
    late MockPrivacidadRepository repo;

    setUp(() => repo = MockPrivacidadRepository());

    test('carga apagado y al activarlo guarda en el servidor', () async {
      when(repo.getPreferencia2fa())
          .thenAnswer((_) async => const Preferencia2fa(email2fa: false));
      when(repo.guardarPreferencia2fa(true))
          .thenAnswer((_) async => const Preferencia2fa(email2fa: true));
      final vm = Verificacion2faViewModel(repo);

      await vm.load();
      expect(vm.state, LoadState.ready);
      expect(vm.activo, isFalse);

      expect(await vm.cambiar(true), isTrue);
      expect(vm.activo, isTrue);
      expect(vm.mensaje, isNotNull);
      verify(repo.guardarPreferencia2fa(true)).called(1);
    });

    test('si el guardado falla, conserva el valor del servidor', () async {
      when(repo.getPreferencia2fa())
          .thenAnswer((_) async => const Preferencia2fa(email2fa: false));
      when(
        repo.guardarPreferencia2fa(any),
      ).thenThrow(ApiException('No se pudo actualizar la configuración 2FA.'));
      final vm = Verificacion2faViewModel(repo);
      await vm.load();

      expect(await vm.cambiar(true), isFalse);
      expect(vm.activo, isFalse);
      expect(vm.errorGuardar, contains('No se pudo actualizar'));
      expect(vm.guardando, isFalse);
    });

    test('error al leer deja el estado de error y no deja cambiar', () async {
      when(repo.getPreferencia2fa()).thenThrow(ApiException('Sin conexión.'));
      final vm = Verificacion2faViewModel(repo);
      await vm.load();

      expect(vm.state, LoadState.error);
      expect(vm.errorMessage, contains('Sin conexión.'));
      expect(await vm.cambiar(true), isFalse);
      verifyNever(repo.guardarPreferencia2fa(any));
    });

    test('sin permiso para gestionarlo no se envía nada', () async {
      when(repo.getPreferencia2fa()).thenAnswer(
        (_) async => const Preferencia2fa(
          email2fa: false,
          puedeGestionar: false,
          motivoBloqueo: 'Tu cuenta usa inicio de sesión externo.',
        ),
      );
      final vm = Verificacion2faViewModel(repo);
      await vm.load();

      expect(vm.puedeCambiar, isFalse);
      expect(await vm.cambiar(true), isFalse);
      verifyNever(repo.guardarPreferencia2fa(any));
    });
  });

  group('B interruptor en Privacidad y mis datos', () {
    late MockPrivacidadRepository repo;

    setUp(() => repo = MockPrivacidadRepository());

    Widget privacidad() => ChangeNotifierProvider(
      create: (_) => Verificacion2faViewModel(repo),
      child: const PrivacidadView(),
    );

    Future<void> verSwitch(WidgetTester tester) async {
      await tester.ensureVisible(
        find.byKey(const Key('privacidad_2fa_switch')),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('empieza apagado y al tocarlo se activa en el servidor', (
      tester,
    ) async {
      when(repo.getPreferencia2fa())
          .thenAnswer((_) async => const Preferencia2fa(email2fa: false));
      when(repo.guardarPreferencia2fa(true))
          .thenAnswer((_) async => const Preferencia2fa(email2fa: true));

      await _pump(tester, privacidad());
      await verSwitch(tester);

      expect(
        find.text('Pedir código por correo al iniciar sesión'),
        findsOneWidget,
      );
      SwitchListTile tile() => tester.widget<SwitchListTile>(
        find.byKey(const Key('privacidad_2fa_switch')),
      );
      expect(tile().value, isFalse);

      await tester.tap(find.byKey(const Key('privacidad_2fa_switch')));
      await tester.pumpAndSettle();

      expect(tile().value, isTrue);
      expect(find.byKey(const Key('privacidad_2fa_mensaje')), findsOneWidget);
      verify(repo.guardarPreferencia2fa(true)).called(1);
    });

    testWidgets('mientras carga muestra el estado de carga', (tester) async {
      final pendiente = Completer<Preferencia2fa>();
      when(repo.getPreferencia2fa()).thenAnswer((_) => pendiente.future);

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.guest(), home: privacidad()),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Cargando tu seguridad…'), findsOneWidget);
      expect(find.byKey(const Key('privacidad_2fa_switch')), findsNothing);

      pendiente.complete(const Preferencia2fa(email2fa: true));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('privacidad_2fa_switch')), findsOneWidget);
    });

    testWidgets('si falla la lectura, muestra el error y reintenta', (
      tester,
    ) async {
      var llamadas = 0;
      when(repo.getPreferencia2fa()).thenAnswer((_) async {
        llamadas++;
        if (llamadas == 1) throw ApiException('Sin conexión.');
        return const Preferencia2fa(email2fa: false);
      });

      await _pump(tester, privacidad());
      final reintentar = find.byKey(const Key('privacidad_2fa_reintentar'));
      await tester.ensureVisible(reintentar);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('privacidad_2fa_error')), findsOneWidget);

      await tester.tap(reintentar);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('privacidad_2fa_switch')), findsOneWidget);
      expect(llamadas, 2);
    });
  });

  group('C pantalla de términos de uso', () {
    late MockPrivacidadRepository repo;

    setUp(() => repo = MockPrivacidadRepository());

    Widget terminos() => ChangeNotifierProvider(
      create: (_) => TerminosViewModel(repo),
      child: const TerminosView(),
    );

    testWidgets('muestra el texto publicado', (tester) async {
      when(repo.getTerminos()).thenAnswer((_) async => _terminos);
      await _pump(tester, terminos());

      expect(find.text('Términos de uso'), findsOneWidget);
      expect(find.text(_terminos.contenido), findsOneWidget);
    });

    testWidgets('sin publicar muestra el estado vacío', (tester) async {
      when(repo.getTerminos()).thenAnswer((_) async => null);
      await _pump(tester, terminos());

      expect(
        find.text('Los términos de uso aún no están publicados.'),
        findsOneWidget,
      );
    });

    testWidgets('error de red con reintento', (tester) async {
      var llamadas = 0;
      when(repo.getTerminos()).thenAnswer((_) async {
        llamadas++;
        if (llamadas == 1) throw ApiException('Sin conexión.');
        return _terminos;
      });
      await _pump(tester, terminos());
      expect(find.textContaining('Sin conexión.'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text(_terminos.contenido), findsOneWidget);
    });
  });
}
