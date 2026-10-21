import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:stylo_barber_connect/core/network/certificados_raiz.dart';
import 'package:stylo_barber_connect/core/network/cliente_http.dart';

/// DER de un certificado PEM.
List<int> _der(String pem) => base64.decode(
  pem
      .replaceAll('-----BEGIN CERTIFICATE-----', '')
      .replaceAll('-----END CERTIFICATE-----', '')
      .replaceAll(RegExp(r'\s'), ''),
);

/// Genera con openssl, en una carpeta temporal, una autoridad propia y un
/// certificado de servidor para `localhost`. Las claves son efímeras: se
/// crean al correr la prueba y se borran al final; no se versionan.
Future<Directory?> _certificadosEfimeros() async {
  final dir = await Directory.systemTemp.createTemp('pinning_');
  Future<bool> openssl(List<String> args) async {
    try {
      final r = await Process.run('openssl', args, workingDirectory: dir.path);
      return r.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  await File('${dir.path}/san.cnf')
      .writeAsString('subjectAltName=DNS:localhost,IP:127.0.0.1\n');
  final ok =
      await openssl([
        'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1', //
        '-subj', '/CN=Autoridad de prueba', '-keyout', 'ca.key',
        '-out', 'ca.pem',
      ]) &&
      await openssl([
        'req', '-newkey', 'rsa:2048', '-nodes', '-subj', '/CN=localhost', //
        '-keyout', 'servidor.key', '-out', 'servidor.csr',
      ]) &&
      await openssl([
        'x509', '-req', '-in', 'servidor.csr', '-CA', 'ca.pem', //
        '-CAkey', 'ca.key', '-CAcreateserial', '-days', '1',
        '-extfile', 'san.cnf', '-out', 'servidor.pem',
      ]);
  if (!ok) {
    await dir.delete(recursive: true);
    return null;
  }
  return dir;
}

/// Motivo para saltar las pruebas con servidor TLS, o `false` si hay openssl.
Object get _sinOpenssl {
  try {
    return Process.runSync('openssl', ['version']).exitCode == 0
        ? false
        : 'openssl no responde';
  } on ProcessException {
    return 'openssl no está instalado en este equipo';
  }
}

void main() {
  group('GH#39 raíces fijadas y su rotación', () {
    test('cada PEM coincide con la huella SHA-256 documentada', () {
      for (final raiz in raicesFijadas) {
        expect(
          sha256.convert(_der(raiz.pem)).toString(),
          raiz.sha256Certificado,
          reason: raiz.nombre,
        );
      }
    });

    test('raíz actual del backend más respaldos de otra autoridad', () {
      final nombres = raicesFijadas.map((r) => r.nombre).toList();
      expect(nombres.first, 'GTS Root R4', reason: 'Render: WE1 → GTS R4');
      expect(nombres, containsAll(['ISRG Root X1', 'ISRG Root X2']));
      expect(nombres.toSet(), hasLength(nombres.length));
    });

    test('ninguna raíz vence antes de 2030', () {
      for (final raiz in raicesFijadas) {
        expect(
          DateTime.parse(raiz.vence).isAfter(DateTime(2030)),
          isTrue,
          reason: raiz.nombre,
        );
      }
    });

    test('el contexto TLS acepta todas las raíces', () {
      expect(contextoFijado, returnsNormally);
    });
  });

  group('GH#38 cuándo aplica el pinning', () {
    final https = Uri.parse('https://api.ejemplo.test/api');
    final http0 = Uri.parse('http://10.0.2.2:8000/api');

    test('en release siempre, aunque se intente desactivar', () {
      expect(
        pinningActivo(base: https, release: true, desactivado: true),
        isTrue,
      );
    });

    test('en debug sí, salvo que se desactive a propósito', () {
      expect(
        pinningActivo(base: https, release: false, desactivado: false),
        isTrue,
      );
      expect(
        pinningActivo(base: https, release: false, desactivado: true),
        isFalse,
      );
    });

    test('el backend local por HTTP no usa TLS', () {
      expect(
        pinningActivo(base: http0, release: true, desactivado: false),
        isFalse,
      );
    });

    test('el cliente de la API con HTTPS es el cliente fijado', () {
      expect(crearClienteHttp(https), isA<IOClient>());
    });
  });

  group(
    'GH#38 servidor TLS con un certificado no permitido',
    skip: _sinOpenssl,
    () {
      Directory? dir;
      HttpServer? servidor;
      late Uri url;

      setUpAll(() async {
        dir = await _certificadosEfimeros();
        if (dir == null) fail('openssl no pudo generar los certificados');
        final contexto = SecurityContext()
          ..useCertificateChain('${dir!.path}/servidor.pem')
          ..usePrivateKey('${dir!.path}/servidor.key');
        servidor = await HttpServer.bindSecure('127.0.0.1', 0, contexto);
        servidor!.listen((peticion) {
          peticion.response
            ..headers.contentType = ContentType.json
            ..write('{"ok": true}')
            ..close();
        });
        url = Uri.parse(
          'https://localhost:${servidor!.port}/api/public/servicios/',
        );
      });

      tearDownAll(() async {
        await servidor?.close(force: true);
        await dir?.delete(recursive: true);
      });

      test(
        'control: confiando en su autoridad, el servidor responde',
        () async {
          final propio = SecurityContext(withTrustedRoots: false)
            ..setTrustedCertificates('${dir!.path}/ca.pem');
          final cliente = IOClient(HttpClient(context: propio));
          addTearDown(cliente.close);

          final r = await cliente.get(url);

          expect(r.statusCode, 200);
        },
      );

      test('con pinning se rechaza en el handshake', () async {
        final cliente = IOClient(HttpClient(context: contextoFijado()));
        addTearDown(cliente.close);

        await expectLater(
          cliente.get(url),
          throwsA(
            predicate<Object>(
              (e) =>
                  e is HandshakeException ||
                  (e is http.ClientException &&
                      e.message.contains('CERTIFICATE_VERIFY_FAILED')),
              'falla de verificación del certificado',
            ),
          ),
        );
      });
    },
  );
}
