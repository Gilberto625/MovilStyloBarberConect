// Verifica el certificate pinning contra servidores reales (GH#38, GH#39).
//
// Uso: dart run tool/verificar_pines.dart
//
// 1. El backend de producción debe responder con las raíces fijadas. Solo
//    hace un GET a un endpoint público de lectura.
// 2. Un sitio con otra autoridad (DigiCert) debe rechazarse.
//
// Sale con código 1 si algo no se cumple. El workflow `pinning.yml` lo corre
// cada semana para avisar antes de que una rotación de certificado en Render
// deje a la app sin conexión.
import 'dart:convert';
import 'dart:io';

import 'package:stylo_barber_connect/core/network/certificados_raiz.dart';

const _backend =
    'https://backendstylobarberconect-lo71.onrender.com/api/public/servicios/';
const _otraAutoridad = 'https://www.digicert.com/';

SecurityContext _contexto() {
  final contexto = SecurityContext(withTrustedRoots: false);
  for (final raiz in raicesFijadas) {
    contexto.setTrustedCertificatesBytes(utf8.encode(raiz.pem));
  }
  return contexto;
}

Future<void> main() async {
  final cliente = HttpClient(context: _contexto())
    ..connectionTimeout = const Duration(seconds: 90);
  var todoBien = true;

  stdout.writeln('Raíces fijadas: ${raicesFijadas.map((r) => r.nombre)}');

  // Render puede tardar en despertar el servicio gratuito.
  try {
    final peticion = await cliente.getUrl(Uri.parse(_backend));
    final respuesta = await peticion.close().timeout(
      const Duration(seconds: 120),
    );
    await respuesta.drain<void>();
    final hoja = respuesta.certificate;
    stdout.writeln(
      'OK backend: HTTP ${respuesta.statusCode}; certificado '
      '"${hoja?.subject}" emitido por "${hoja?.issuer}", vence '
      '${hoja?.endValidity.toIso8601String().substring(0, 10)}',
    );
    if (respuesta.statusCode != 200) todoBien = false;
    final fin = hoja?.endValidity;
    if (fin != null && fin.difference(DateTime.now()).inDays < 21) {
      stdout.writeln(
        'AVISO: el certificado del backend vence en menos de 21 días; '
        'revisa que el nuevo siga encadenando a una raíz fijada.',
      );
    }
  } on Exception catch (e) {
    todoBien = false;
    stdout.writeln(
      'FALLA backend: no conecta con las raíces fijadas '
      '(${e.runtimeType}). Revisa la cadena y docs/evaluacion/'
      'PINNING_ROTACION.md antes de publicar.',
    );
  }

  try {
    final peticion = await cliente.getUrl(Uri.parse(_otraAutoridad));
    await (await peticion.close()).drain<void>();
    todoBien = false;
    stdout.writeln(
      'FALLA control: ${Uri.parse(_otraAutoridad).host} se aceptó '
      'y no debía',
    );
  } on HandshakeException catch (e) {
    final motivo = (e.osError?.message ?? e.message)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    stdout.writeln(
      'OK control: ${Uri.parse(_otraAutoridad).host} rechazado en el '
      'handshake ($motivo)',
    );
  }

  cliente.close(force: true);
  exitCode = todoBien ? 0 : 1;
}
