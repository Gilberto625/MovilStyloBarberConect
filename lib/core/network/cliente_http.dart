import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'certificados_raiz.dart';

/// Solo para builds debug o profile contra un servidor HTTPS de pruebas con
/// otra autoridad: `--dart-define=DESACTIVAR_PINNING=true`. En release no
/// tiene efecto.
const _desactivarFueraDeRelease = bool.fromEnvironment('DESACTIVAR_PINNING');

/// Decide si las peticiones a [base] van con certificate pinning.
///
/// - HTTP (backend local en el emulador): no aplica, no hay TLS.
/// - HTTPS en release: siempre.
/// - HTTPS en debug o profile: sí, salvo que se desactive a propósito.
bool pinningActivo({
  required Uri base,
  bool release = kReleaseMode,
  bool desactivado = _desactivarFueraDeRelease,
}) {
  if (base.scheme != 'https') return false;
  if (release) return true;
  return !desactivado;
}

/// Contexto TLS que confía **solo** en [raicesFijadas], no en las autoridades
/// del sistema. La verificación del nombre del host sigue activa.
SecurityContext contextoFijado([List<RaizFijada> raices = raicesFijadas]) {
  final contexto = SecurityContext(withTrustedRoots: false);
  for (final raiz in raices) {
    contexto.setTrustedCertificatesBytes(utf8.encode(raiz.pem));
  }
  return contexto;
}

/// Cliente HTTP para la API. Con pinning, un certificado que no encadena a
/// una raíz fijada se rechaza en el handshake, antes de mandar el token.
///
/// No hay `badCertificateCallback`: nunca se acepta un certificado inválido.
http.Client crearClienteHttp(Uri base) {
  if (!pinningActivo(base: base)) return http.Client();
  return IOClient(HttpClient(context: contextoFijado()));
}
