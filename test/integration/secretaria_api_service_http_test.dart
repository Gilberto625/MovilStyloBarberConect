import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';
import 'package:stylo_barber_connect/services/secretaria_api_service.dart';

import '../support/memory_token_storage.dart';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// BUG-01: buscar clientes, registrar cliente de paso, ver las citas de un
/// cliente y abrir una cita para reprogramar pasan por `ApiClient` real con un
/// servidor simulado. Antes fallaban con
/// `type '_Map<String, dynamic>' is not a subtype of type 'Future<dynamic>'`
/// porque la respuesta ya resuelta se pasaba a `_ok`, que espera un `Future`.
SecretariaApiService _servicio(
  http.Response Function(http.Request request) responder, [
  List<http.Request>? peticiones,
]) {
  return SecretariaApiService(
    ApiClient(
      tokenStorage: MemoryTokenStorage(access: 'token-secretaria'),
      httpClient: MockClient((request) async {
        peticiones?.add(request);
        return responder(request);
      }),
      baseUrl: 'http://10.0.2.2:8000/api',
    ),
  );
}

void main() {
  group('BUG-01 SecretariaApiService con ApiClient real', () {
    test('buscarClientes devuelve los clientes del servidor', () async {
      final peticiones = <http.Request>[];
      final api = _servicio(
        (_) => _json({
          'ok': true,
          'clientes': [
            {
              'id': 7,
              'nombre_completo': 'Cliente Prueba',
              'telefono': '0000000001',
              'email': 'cliente.prueba@example.test',
              'es_anonimo': false,
            },
          ],
        }, 200),
        peticiones,
      );

      final clientes = await api.buscarClientes('Cli');

      expect(clientes, hasLength(1));
      expect(clientes.single.id, 7);
      expect(clientes.single.nombreCompleto, 'Cliente Prueba');
      expect(peticiones.single.url.path, '/api/secretaria/clientes/');
      expect(peticiones.single.url.queryParameters['q'], 'Cli');
    });

    test('crearClientePaso devuelve el cliente creado', () async {
      final peticiones = <http.Request>[];
      final api = _servicio(
        (_) => _json({
          'ok': true,
          'cliente': {
            'id': 31,
            'nombre_completo': 'Juan Pérez',
            'telefono': '7710000000',
            'es_anonimo': true,
          },
        }, 201),
        peticiones,
      );

      final cliente = await api.crearClientePaso(
        nombres: 'Juan',
        apellido: 'Pérez',
        telefono: '7710000000',
      );

      expect(cliente.id, 31);
      expect(cliente.esAnonimo, isTrue);
      expect(peticiones.single.method, 'POST');
      expect(
        jsonDecode(peticiones.single.body),
        containsPair('modo', 'anonimo'),
      );
    });

    test('citasDeCliente devuelve las citas del cliente', () async {
      final api = _servicio(
        (_) => _json({
          'ok': true,
          'citas': [
            {
              'id': 1565,
              'fecha': '2026-11-07',
              'hora': '11:00',
              'servicio': 'Corte clásico',
              'barbero': 'Barbero Uno Prueba',
              'estado': 'confirmada',
              'precio_total': '150.00',
              'puede_editar': true,
            },
          ],
        }, 200),
      );

      final citas = await api.citasDeCliente(7);

      expect(citas.single.id, 1565);
      expect(citas.single.puedeEditar, isTrue);
    });

    test('citaEditable abre la cita para reprogramar', () async {
      final api = _servicio(
        (_) => _json({
          'ok': true,
          'fecha_minima': '2026-11-06',
          'cita': {
            'id': 1565,
            'cliente_id': 7,
            'cliente_nombre': 'Cliente Prueba',
            'barbero_id': 2,
            'servicio_id': 1,
            'servicio_nombre': 'Corte clásico',
            'servicio_precio': '150.00',
            'fecha': '2026-11-07',
            'hora': '11:00',
            'duracion_minutos': 45,
            'estado': 'confirmada',
            'precio_total': '150.00',
            'puede_editar': true,
          },
        }, 200),
      );

      final cita = await api.citaEditable(1565);

      expect(cita.id, 1565);
      expect(cita.clienteNombre, 'Cliente Prueba');
      expect(cita.fechaMinima, '2026-11-06');
    });

    test('un ok=false del servidor llega como ApiException', () async {
      final api = _servicio(
        (_) => _json({'ok': false, 'error': 'Cliente duplicado.'}, 200),
      );

      await expectLater(
        api.crearClientePaso(nombres: 'Juan', telefono: '7710000000'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Cliente duplicado.',
          ),
        ),
      );
    });
  });
}
