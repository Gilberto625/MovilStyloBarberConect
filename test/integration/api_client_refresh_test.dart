import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';

import '../support/memory_token_storage.dart';

const _base = 'http://10.0.2.2:8000/api';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<ApiException> _fallo(Future<dynamic> llamada) async {
  try {
    await llamada;
  } on ApiException catch (e) {
    return e;
  }
  fail('Se esperaba ApiException');
}

void main() {
  group('I-401 ApiClient con MockClient (GH#69)', () {
    test('401 → refresh → reintento con el token nuevo', () async {
      final storage = MemoryTokenStorage(access: 'viejo', refresh: 'r1');
      final llamadas = <String>[];
      var sesionVencida = 0;
      final client = MockClient((request) async {
        llamadas.add('${request.method} ${request.url.path}');
        if (request.url.path == '/api/auth/token/refresh/') {
          expect(jsonDecode(request.body), {'refresh': 'r1'});
          expect(request.headers.containsKey('Authorization'), isFalse);
          return _json({'access': 'nuevo', 'refresh': 'r2'}, 200);
        }
        if (request.headers['Authorization'] == 'Bearer nuevo') {
          return _json({'ok': true, 'citas': []}, 200);
        }
        return _json({'detail': 'Token inválido'}, 401);
      });
      final api = ApiClient(
        tokenStorage: storage,
        httpClient: client,
        baseUrl: _base,
        onSessionExpired: () async => sesionVencida++,
      );

      final body = await api.get('/mis-citas/');

      expect(body, {'ok': true, 'citas': []});
      expect(llamadas, [
        'GET /api/mis-citas/',
        'POST /api/auth/token/refresh/',
        'GET /api/mis-citas/',
      ]);
      expect(storage.access, 'nuevo');
      expect(storage.refresh, 'r2', reason: 'rota el refresh si llega uno');
      expect(sesionVencida, 0);
    });

    test('refresh sin rotación guarda solo el access nuevo', () async {
      final storage = MemoryTokenStorage(access: 'viejo', refresh: 'r1');
      final client = MockClient((request) async {
        if (request.url.path == '/api/auth/token/refresh/') {
          return _json({'access': 'nuevo'}, 200);
        }
        return request.headers['Authorization'] == 'Bearer nuevo'
            ? _json({'ok': true}, 200)
            : _json({'detail': 'expirado'}, 401);
      });
      final api = ApiClient(
        tokenStorage: storage,
        httpClient: client,
        baseUrl: _base,
      );

      await api.get('/perfil/');

      expect(storage.access, 'nuevo');
      expect(storage.refresh, 'r1');
    });

    test(
      'refresh rechazado → borra tokens, avisa sesión vencida y lanza 401',
      () async {
        final storage = MemoryTokenStorage(access: 'viejo', refresh: 'r1');
        var sesionVencida = 0;
        var intentos = 0;
        final client = MockClient((request) async {
          if (request.url.path == '/api/auth/token/refresh/') {
            return _json({'detail': 'Token is blacklisted'}, 401);
          }
          intentos++;
          return _json({'detail': 'Token inválido'}, 401);
        });
        final api = ApiClient(
          tokenStorage: storage,
          httpClient: client,
          baseUrl: _base,
          onSessionExpired: () async => sesionVencida++,
        );

        final e = await _fallo(api.get('/mis-citas/'));

        expect(e.isUnauthorized, isTrue);
        expect(intentos, 1, reason: 'no reintenta sin token nuevo');
        expect(storage.clears, 1);
        expect(storage.access, isNull);
        expect(sesionVencida, 1);
      },
    );

    test('sin refresh guardado no llama al endpoint de refresh', () async {
      final storage = MemoryTokenStorage(access: 'viejo');
      final rutas = <String>[];
      var sesionVencida = 0;
      final client = MockClient((request) async {
        rutas.add(request.url.path);
        return _json({'detail': 'expirado'}, 401);
      });
      final api = ApiClient(
        tokenStorage: storage,
        httpClient: client,
        baseUrl: _base,
        onSessionExpired: () async => sesionVencida++,
      );

      await _fallo(api.get('/perfil/'));

      expect(rutas, ['/api/perfil/']);
      expect(sesionVencida, 1);
    });

    test(
      'un 401 en login (sin auth) no intenta refresh ni cierra sesión',
      () async {
        final storage = MemoryTokenStorage(refresh: 'r1');
        final rutas = <String>[];
        var sesionVencida = 0;
        final client = MockClient((request) async {
          rutas.add(request.url.path);
          expect(request.headers.containsKey('Authorization'), isFalse);
          return _json({
            'ok': false,
            'error': 'Credenciales incorrectas.',
          }, 401);
        });
        final api = ApiClient(
          tokenStorage: storage,
          httpClient: client,
          baseUrl: _base,
          onSessionExpired: () async => sesionVencida++,
        );

        final e = await _fallo(
          api.post('/login/', auth: false, body: {'email': 'a@example.test'}),
        );

        expect(e.message, 'Credenciales incorrectas.');
        expect(rutas, ['/api/login/']);
        expect(sesionVencida, 0);
        expect(storage.refresh, 'r1');
      },
    );

    test(
      'errores HTTP traen el mensaje de Django (error, detail o texto)',
      () async {
        final respuestas = <http.Response>[
          _json({'ok': false, 'error': 'Horario no disponible.'}, 400),
          _json({'detail': 'No tienes permiso.'}, 403),
          http.Response('Internal Server Error', 500),
          http.Response('', 502),
        ];
        final client = MockClient((_) async => respuestas.removeAt(0));
        final api = ApiClient(
          tokenStorage: MemoryTokenStorage(access: 'a'),
          httpClient: client,
          baseUrl: _base,
        );

        final e400 = await _fallo(api.post('/citas/', body: const {}));
        expect(e400.statusCode, 400);
        expect(e400.message, 'Horario no disponible.');

        final e403 = await _fallo(api.get('/secretaria/citas/dia/'));
        expect(e403.isForbidden, isTrue);
        expect(e403.message, 'No tienes permiso.');

        // Un 5xx sin mensaje de Django muestra un texto para la persona,
        // no el del servidor ("Internal Server Error").
        final e500 = await _fallo(api.get('/public/servicios/', auth: false));
        expect(e500.statusCode, 500);
        expect(e500.message, contains('no está disponible'));
        expect(e500.message, isNot(contains('Internal')));

        final e502 = await _fallo(api.get('/public/servicios/', auth: false));
        expect(
          e502.message,
          contains('no está disponible en este momento (502)'),
        );
      },
    );

    test('la query se codifica sobre la URL base', () async {
      late Uri url;
      final client = MockClient((request) async {
        url = request.url;
        return _json({'ok': true, 'horarios': []}, 200);
      });
      final api = ApiClient(
        tokenStorage: MemoryTokenStorage(access: 'a'),
        httpClient: client,
        baseUrl: _base,
      );

      await api.get(
        'disponibilidad/',
        query: {'fecha': '2026-10-21', 'barbero_id': '7'},
      );

      expect(url.path, '/api/disponibilidad/');
      expect(url.queryParameters, {'fecha': '2026-10-21', 'barbero_id': '7'});
    });
  });
}
