import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

Future<AppException> _fallo(Future<dynamic> llamada) async {
  try {
    await llamada;
  } on AppException catch (e) {
    return e;
  }
  fail('Se esperaba AppException');
}

/// El texto que ve la persona no lleva detalles técnicos ni del servidor.
Matcher get _sinDetalleTecnico => isNot(
  anyOf(
    contains('Exception'),
    contains('10.0.2.2'),
    contains('8000'),
    contains('errno'),
    contains('<'),
  ),
);

void main() {
  group('Errores de red en ApiClient', () {
    test(
      'sin internet: mensaje para la persona, sin IP ni excepción',
      () async {
        final api = ApiClient(
          tokenStorage: MemoryTokenStorage(),
          baseUrl: _base,
          httpClient: MockClient(
            (_) async => throw http.ClientException(
              'SocketException: Connection failed (OS Error: Network is '
              'unreachable, errno = 101), address = 10.0.2.2, port = 8000',
              Uri.parse('$_base/public/contacto/'),
            ),
          ),
        );

        final e = await _fallo(api.get('/public/contacto/', auth: false));

        expect(e, isA<NetworkException>());
        expect(e.toString(), NetworkException.sinConexion);
        expect(e.toString(), _sinDetalleTecnico);
      },
    );

    test('socket, TLS y tiempo agotado también son NetworkException', () async {
      for (final falla in <Exception>[
        const SocketException('Failed host lookup'),
        const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
        TimeoutException('lento'),
      ]) {
        final api = ApiClient(
          tokenStorage: MemoryTokenStorage(),
          baseUrl: _base,
          httpClient: MockClient((_) async => throw falla),
        );
        final e = await _fallo(api.get('/public/servicios/', auth: false));
        expect(
          e,
          isA<NetworkException>(),
          reason: falla.runtimeType.toString(),
        );
        expect(e.toString(), _sinDetalleTecnico);
      }
    });

    test('una página HTML de error no llega a la pantalla', () async {
      final api = ApiClient(
        tokenStorage: MemoryTokenStorage(),
        baseUrl: _base,
        httpClient: MockClient(
          (_) async => http.Response(
            '<!DOCTYPE html><html><body><h1>502 Bad Gateway</h1></body></html>',
            502,
            headers: {'content-type': 'text/html'},
          ),
        ),
      );

      final e = await _fallo(api.get('/public/servicios/', auth: false));

      expect(e, isA<ApiException>());
      expect(e.statusCode, 502);
      expect(e.toString(), contains('no está disponible'));
      expect(e.toString(), _sinDetalleTecnico);
    });

    test('el mensaje de Django se sigue mostrando tal cual', () async {
      final api = ApiClient(
        tokenStorage: MemoryTokenStorage(),
        baseUrl: _base,
        httpClient: MockClient(
          (_) async => _json({'ok': false, 'error': 'Horario ocupado.'}, 409),
        ),
      );
      final e = await _fallo(api.post('/citas/', body: {}));
      expect(e.toString(), 'Horario ocupado.');
    });

    test('un texto plano corto sí se muestra', () async {
      final api = ApiClient(
        tokenStorage: MemoryTokenStorage(),
        baseUrl: _base,
        httpClient: MockClient(
          (_) async => http.Response('Demasiadas solicitudes.', 429),
        ),
      );
      final e = await _fallo(api.get('/public/servicios/', auth: false));
      expect(e.toString(), 'Demasiadas solicitudes.');
    });

    test(
      'si la red falla al renovar el token, la sesión no se cierra',
      () async {
        final storage = MemoryTokenStorage(access: 'viejo', refresh: 'r1');
        var sesionVencida = 0;
        final api = ApiClient(
          tokenStorage: storage,
          baseUrl: _base,
          onSessionExpired: () async => sesionVencida++,
          httpClient: MockClient((request) async {
            if (request.url.path == '/api/auth/token/refresh/') {
              throw http.ClientException('Connection reset by peer');
            }
            return _json({'detail': 'Token expirado'}, 401);
          }),
        );

        final e = await _fallo(api.get('/mis-citas/'));

        expect(e, isA<NetworkException>());
        expect(sesionVencida, 0);
        expect(storage.clears, 0);
        expect(
          storage.refresh,
          'r1',
          reason: 'Se reintenta cuando vuelva la red',
        );
      },
    );
  });
}
