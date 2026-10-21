import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/repositories/auth_repository.dart';
import 'package:stylo_barber_connect/repositories/catalog_repository.dart';
import 'package:stylo_barber_connect/repositories/citas_repository.dart';
import 'package:stylo_barber_connect/repositories/secretaria_repository.dart';
import 'package:stylo_barber_connect/services/auth_api_service.dart';
import 'package:stylo_barber_connect/services/catalog_api_service.dart';
import 'package:stylo_barber_connect/services/citas_api_service.dart';
import 'package:stylo_barber_connect/services/secretaria_api_service.dart';

import '../support/memory_token_storage.dart';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Repository ↔ service ↔ ApiClient ↔ JSON, con un servidor simulado que
/// registra cada petición (I-REPO, S4-03).
class _Servidor {
  _Servidor(this.responder);

  final http.Response Function(http.Request request) responder;
  final peticiones = <http.Request>[];
  final storage = MemoryTokenStorage(access: 'token-prueba');

  ApiClient get api => ApiClient(
    tokenStorage: storage,
    httpClient: MockClient((request) async {
      peticiones.add(request);
      return responder(request);
    }),
    baseUrl: 'http://10.0.2.2:8000/api',
  );
}

Future<ApiException> _fallo(Future<dynamic> llamada) async {
  try {
    await llamada;
  } on ApiException catch (e) {
    return e;
  }
  fail('Se esperaba ApiException');
}

void main() {
  group('CatalogRepository', () {
    test(
      '200: servicios con sobre, productos como arreglo y contacto',
      () async {
        final s = _Servidor((r) {
          switch (r.url.path) {
            case '/api/public/servicios/':
              return _json({
                'ok': true,
                'servicios': [
                  {
                    'id': 1,
                    'nombre': 'Corte',
                    'precio': '150.00',
                    'duracion_minutos': 45,
                  },
                ],
              }, 200);
            case '/api/public/productos/':
              return _json([
                {'id': 9, 'nombre': 'Cera', 'precio': 199, 'stock': 3},
              ], 200);
            default:
              return _json({
                'nombre_negocio': 'Tony Stylo',
                'telefono': '7710000000',
              }, 200);
          }
        });
        final repo = CatalogRepositoryImpl(CatalogApiService(s.api));

        final home = await repo.loadHomeGuest();

        expect(home.servicios.single.precio, 150);
        expect(home.productos.single.nombre, 'Cera');
        expect(home.contacto.nombreNegocio, 'Tony Stylo');
        expect(
          s.peticiones.every((r) => !r.headers.containsKey('Authorization')),
          isTrue,
          reason: 'el catálogo es público',
        );
      },
    );

    test('500 del catálogo llega como error, no como lista vacía', () async {
      final s = _Servidor(
        (_) => _json({
          'detail':
              'La estructura de base de datos requerida no esta disponible',
        }, 503),
      );
      final repo = CatalogRepositoryImpl(CatalogApiService(s.api));

      final e = await _fallo(repo.getServicios());

      expect(e.statusCode, 503);
      expect(e.message, contains('estructura de base de datos'));
    });
  });

  group('CitasRepository', () {
    test('200: mis citas con Bearer', () async {
      final s = _Servidor(
        (_) => _json({
          'ok': true,
          'citas': [
            {'id': 41, 'servicio_nombre': 'Corte', 'estado': 'pendiente'},
          ],
        }, 200),
      );
      final citas = await CitasRepository(CitasApiService(s.api)).getMisCitas();

      expect(citas.single.id, 41);
      expect(
        s.peticiones.single.headers['Authorization'],
        'Bearer token-prueba',
      );
    });

    test('crear cita envía el cuerpo que espera Django', () async {
      final s = _Servidor((_) => _json({'ok': true, 'id': 77}, 201));
      final repo = CitasRepository(CitasApiService(s.api));

      final r = await repo.crearCita(
        clienteId: 15,
        barberoId: 7,
        servicioId: 3,
        duracionMinutos: 45,
        fecha: '2026-10-21',
        hora: '11:30',
        precioTotal: 180,
      );

      expect(r['id'], 77);
      final req = s.peticiones.single;
      expect('${req.method} ${req.url.path}', 'POST /api/citas/');
      expect(jsonDecode(req.body), {
        'cliente_id': 15,
        'barbero_id': 7,
        'servicio_id': 3,
        'duracion_minutos': 45,
        'fecha': '2026-10-21',
        'hora': '11:30',
        'precio_total': 180.0,
        'anticipo_pagado': 0.0,
      });
    });

    test('400 y 409 al crear cita no se toman como creadas', () async {
      final respuestas = [
        _json({'ok': false, 'error': 'Faltan campos obligatorios.'}, 400),
        _json({'ok': false, 'error': 'El horario ya no está disponible.'}, 409),
      ];
      final s = _Servidor((_) => respuestas.removeAt(0));
      final repo = CitasRepository(CitasApiService(s.api));
      Future<Map<String, dynamic>> crear() => repo.crearCita(
        clienteId: 15,
        barberoId: 7,
        servicioId: 3,
        duracionMinutos: 45,
        fecha: '2026-10-21',
        hora: '11:30',
        precioTotal: 180,
      );

      expect((await _fallo(crear())).message, 'Faltan campos obligatorios.');
      final e409 = await _fallo(crear());
      expect(e409.statusCode, 409);
      expect(e409.message, 'El horario ya no está disponible.');
    });

    test('un 200 con ok:false también es error', () async {
      final s = _Servidor(
        (_) =>
            _json({'ok': false, 'error': 'Barbero sin horario ese día.'}, 200),
      );
      final repo = CitasRepository(CitasApiService(s.api));

      final e = await _fallo(
        repo.getDisponibilidad(barberoId: 7, fecha: '2026-10-25', duracion: 45),
      );

      expect(e.message, 'Barbero sin horario ese día.');
      expect(s.peticiones.single.url.queryParameters, {
        'barbero_id': '7',
        'fecha': '2026-10-25',
        'duracion': '45',
      });
    });
  });

  group('SecretariaRepository', () {
    test(
      '403 de citas del día (rol sin permiso) llega como prohibido',
      () async {
        final s = _Servidor(
          (_) => _json({
            'detail': 'No tienes permiso para realizar esta acción.',
          }, 403),
        );
        final e = await _fallo(
          SecretariaRepository(SecretariaApiService(s.api)).getCitasDia(),
        );

        expect(e.isForbidden, isTrue);
      },
    );

    test(
      'no asistió y cobrar mandan la acción y el método correctos',
      () async {
        final s = _Servidor(
          (_) => _json({'ok': true, 'mensaje': 'Listo.'}, 200),
        );
        final repo = SecretariaRepository(SecretariaApiService(s.api));

        await repo.marcarNoAsistio(90);
        await repo.cobrar(
          citaId: 90,
          metodoPago: 'efectivo',
          efectivoRecibido: 200,
        );

        final asistencia = s.peticiones[0];
        expect(asistencia.url.path, '/api/secretaria/citas/90/asistencia/');
        expect(jsonDecode(asistencia.body), {'accion': 'no_asistio'});
        final cobro = s.peticiones[1];
        expect(cobro.url.path, '/api/secretaria/citas/90/cobrar/');
        expect(jsonDecode(cobro.body), {
          'metodo_pago': 'efectivo',
          'efectivo_recibido': 200.0,
        });
      },
    );

    test('500 al cobrar no se toma como cobrado', () async {
      final s = _Servidor((_) => http.Response('Internal Server Error', 500));
      final e = await _fallo(
        SecretariaRepository(SecretariaApiService(s.api))
            .cobrar(citaId: 90, metodoPago: 'efectivo'),
      );

      expect(e.statusCode, 500);
    });
  });

  group('AuthRepository', () {
    test('login con 2FA no guarda tokens; login directo sí', () async {
      final respuestas = [
        _json({
          'ok': true,
          'requires2fa': true,
          'tempToken': 't',
          'destino': 'c***e@example.test',
        }, 200),
        _json({
          'ok': true,
          'access': 'a1',
          'refresh': 'r1',
          'usuario': {
            'id': 15,
            'username': 'cliente.prueba',
            'email': 'c@example.test',
            'rol': 'cliente',
          },
        }, 200),
      ];
      final s = _Servidor((_) => respuestas.removeAt(0));
      s.storage.access = null;
      final repo = AuthRepository(
        api: AuthApiService(s.api),
        storage: s.storage,
      );

      final primero = await repo.login(email: 'c@example.test', password: 'x');
      expect(primero, isA<LoginRequires2FA>());
      expect(s.storage.access, isNull);

      final segundo = await repo.login(email: 'c@example.test', password: 'x');
      final user = await repo.completeLogin(segundo as LoginSuccess);
      expect(user.rol, UserRole.cliente);
      expect(s.storage.access, 'a1');
      expect(s.storage.role, 'cliente');
    });

    test('logout local borra tokens y datos de sesión (PM09)', () async {
      final s = _Servidor((_) => _json({}, 200));
      s.storage
        ..refresh = 'r1'
        ..role = 'cliente'
        ..userJson = '{}';
      final repo = AuthRepository(
        api: AuthApiService(s.api),
        storage: s.storage,
      );

      await repo.logoutLocal();

      expect(s.storage.access, isNull);
      expect(s.storage.refresh, isNull);
      expect(s.storage.userJson, isNull);
      expect(repo.currentUser, isNull);
      expect(
        s.peticiones,
        isEmpty,
        reason: 'Django no tiene endpoint de logout',
      );
    });
  });
}
