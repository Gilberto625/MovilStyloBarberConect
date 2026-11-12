// CORE-001 (GH#68): resolución de APP_ENV + API_BASE_URL y etiqueta visible
// solo fuera de producción. Ver docs/AMBIENTES.md.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/core/config/app_config.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/main.dart';
import 'package:stylo_barber_connect/widgets/etiqueta_ambiente.dart';

AmbienteConfig _resolver(String env, [String url = '']) =>
    AmbienteConfig.resolver(appEnv: env, apiBaseUrl: url);

Matcher _invalido(String fragmento) => throwsA(
  isA<AmbienteInvalido>().having(
    (e) => e.mensaje,
    'mensaje',
    contains(fragmento),
  ),
);

Future<void> _pumpEtiqueta(WidgetTester tester, AmbienteConfig a) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.panel(),
      home: Scaffold(body: EtiquetaAmbiente(ambiente: a)),
    ),
  );
}

void main() {
  group('CORE-001 resolución por ambiente', () {
    test('dev: valor por defecto, Django local del emulador', () {
      for (final env in ['', 'dev', ' DEV ']) {
        final a = _resolver(env);
        expect(a.env, AppEnv.dev, reason: '"$env"');
        expect(a.apiBaseUrl, 'http://10.0.2.2:8000/api');
        expect(a.esProd, isFalse);
        expect(a.etiqueta, 'DEV');
      }
    });

    test('dev acepta otra URL (dispositivo en LAN) y quita la barra final', () {
      final a = _resolver('dev', 'http://192.168.1.20:8000/api/');
      expect(a.apiBaseUrl, 'http://192.168.1.20:8000/api');
    });

    test('staging: exige API_BASE_URL porque no hay servidor propio', () {
      expect(() => _resolver('staging'), _invalido('API_BASE_URL'));
      final a = _resolver('staging', 'http://10.0.2.2:8000/api');
      expect(a.env, AppEnv.staging);
      expect(a.apiBaseUrl, 'http://10.0.2.2:8000/api');
      expect(a.etiqueta, 'STAGING');
      expect(a.esProd, isFalse);
    });

    test('prod: Render por HTTPS y sin etiqueta', () {
      final a = _resolver('prod');
      expect(a.env, AppEnv.prod);
      expect(
        a.apiBaseUrl,
        'https://backendstylobarberconect-lo71.onrender.com/api',
      );
      expect(Uri.parse(a.apiBaseUrl).scheme, 'https');
      expect(a.esProd, isTrue);
      expect(a.etiqueta, isNull);
    });

    test('prod exige HTTPS', () {
      expect(
        () => _resolver('prod', 'http://10.0.2.2:8000/api'),
        _invalido('HTTPS'),
      );
      expect(
        _resolver('prod', 'https://api.example.test/api').apiBaseUrl,
        'https://api.example.test/api',
      );
    });

    test('APP_ENV desconocido es un error claro', () {
      for (final env in ['produccion', 'qa', 'production']) {
        expect(() => _resolver(env), _invalido('dev, staging o prod'));
      }
    });

    test('API_BASE_URL sin esquema http(s) o sin host es un error', () {
      expect(() => _resolver('dev', 'ftp://x.test/api'), _invalido('URL'));
      expect(() => _resolver('dev', '10.0.2.2:8000/api'), _invalido('URL'));
      expect(() => _resolver('staging', 'https:///api'), _invalido('URL'));
    });
  });

  group('CORE-001 la app identifica el ambiente', () {
    testWidgets('dev muestra DEV y el host de la API', (tester) async {
      await _pumpEtiqueta(tester, _resolver('dev'));
      expect(find.byKey(const Key('etiqueta_ambiente')), findsOneWidget);
      expect(find.text('DEV · 10.0.2.2:8000'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Ambiente DEV, API 10.0.2.2:8000'),
        findsOneWidget,
      );
    });

    testWidgets('staging muestra STAGING', (tester) async {
      await _pumpEtiqueta(
        tester,
        _resolver('staging', 'https://staging.example.test/api'),
      );
      expect(find.text('STAGING · staging.example.test'), findsOneWidget);
    });

    testWidgets('prod no muestra nada', (tester) async {
      await _pumpEtiqueta(tester, _resolver('prod'));
      expect(find.byKey(const Key('etiqueta_ambiente')), findsNothing);
      expect(find.textContaining('DEV'), findsNothing);
      expect(find.textContaining('STAGING'), findsNothing);
      expect(find.textContaining('onrender'), findsNothing);
    });

    testWidgets('configuración inválida: pantalla con el motivo', (
      tester,
    ) async {
      await tester.pumpWidget(
        const AmbienteInvalidoApp(mensaje: 'APP_ENV="qa" no es válido.'),
      );
      expect(find.text('Configuración de ambiente no válida'), findsOneWidget);
      expect(find.text('APP_ENV="qa" no es válido.'), findsOneWidget);
    });
  });
}
