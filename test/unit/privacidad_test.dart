import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';
import 'package:stylo_barber_connect/core/storage/secure_token_storage.dart';
import 'package:stylo_barber_connect/core/validation/validators.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/models/privacidad_models.dart';
import 'package:stylo_barber_connect/services/auth_api_service.dart';
import 'package:stylo_barber_connect/services/catalog_api_service.dart';
import 'package:stylo_barber_connect/services/privacidad_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/home_guest_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/privacidad_viewmodels.dart';

import '../mocks/mocks.mocks.dart';
import '../support/privacidad_fixtures.dart';

final enServidorUtc = DateTime.utc(2026, 10, 19, 18, 30);

/// Tokens en memoria: ApiClient no toca el almacenamiento seguro real.
class _TokensEnMemoria extends SecureTokenStorage {
  String? access = 'access-de-prueba';

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => null;

  @override
  Future<void> clear() async => access = null;
}

void main() {
  setUpAll(() {
    provideDummy<PerfilDto>(perfilPrueba);
    provideDummy<ConsentimientoPrivacidad>(
      ConsentimientoPrivacidad.sinRespuesta,
    );
  });

  group('Validadores de PUT /perfil/ (mismas reglas que Django)', () {
    test('nombre obligatorio de al menos 2 caracteres', () {
      expect(validarNombre(''), 'Obligatorio');
      expect(validarNombre(' A '), 'Escribe al menos 2 caracteres');
      expect(validarNombre('Al'), isNull);
    });

    test('teléfono opcional de 10 a 15 dígitos, ignorando separadores', () {
      expect(validarTelefono(''), isNull);
      expect(validarTelefono('771 000 0000'), isNull);
      expect(validarTelefono('+52 (771) 000-0000'), isNull);
      expect(validarTelefono('12345'), 'Debe tener de 10 a 15 dígitos');
      expect(
        validarTelefono('1234567890123456'),
        'Debe tener de 10 a 15 dígitos',
      );
    });

    test('fecha opcional AAAA-MM-DD, real y no futura', () {
      final hoy = DateTime(2026, 10, 19);
      expect(validarFechaNacimiento('', hoy: hoy), isNull);
      expect(validarFechaNacimiento('1999-05-04', hoy: hoy), isNull);
      expect(validarFechaNacimiento('2026-10-19', hoy: hoy), isNull);
      expect(
        validarFechaNacimiento('2026-10-20', hoy: hoy),
        'No puede ser una fecha futura',
      );
      expect(
        validarFechaNacimiento('04/05/1999', hoy: hoy),
        'Usa el formato AAAA-MM-DD',
      );
      expect(
        validarFechaNacimiento('2026-02-31', hoy: hoy),
        'Usa el formato AAAA-MM-DD',
      );
    });
  });

  group('ARCO-M02 contrato HTTP de PUT /perfil/ (MockClient)', () {
    test(
      'envía PUT con Bearer y el cuerpo completo, y lee el perfil nuevo',
      () async {
        late http.Request enviada;
        final client = MockClient((request) async {
          enviada = request;
          return http.Response(
            jsonEncode({
              'ok': true,
              'perfil': {
                'email': 'cliente.prueba@example.test',
                'nombre': 'Cliente Editado',
                'telefono': '7719999999',
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });
        final api = AuthApiService(
          ApiClient(
            tokenStorage: _TokensEnMemoria(),
            httpClient: client,
            baseUrl: 'http://10.0.2.2:8000/api',
          ),
        );

        final perfil = await api.actualizarPerfil(
          PerfilUpdate.desde(perfilPrueba)
              .copyWith(nombre: ' Cliente Editado ', telefono: '7719999999'),
        );

        expect(enviada.method, 'PUT');
        expect(enviada.url.path, '/api/perfil/');
        expect(enviada.headers['Authorization'], 'Bearer access-de-prueba');
        expect(jsonDecode(enviada.body), {
          'nombre': 'Cliente Editado',
          'apellido': 'Prueba',
          'telefono': '7719999999',
          'fecha_nacimiento': '1999-05-04',
          'direccion': 'Calle Falsa #123',
          // Se reenvía para que el reemplazo completo de Django no lo borre.
          'avatar_url': 'https://cdn.example.test/avatar.png',
        });
        expect(perfil.nombre, 'Cliente Editado');
      },
    );

    test('un 400 de Django llega como ApiException con su mensaje', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'ok': false,
            'error': 'El teléfono debe tener entre 10 y 15 dígitos.',
          }),
          400,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      final api = AuthApiService(
        ApiClient(
          tokenStorage: _TokensEnMemoria(),
          httpClient: client,
          baseUrl: 'http://10.0.2.2:8000/api',
        ),
      );

      await expectLater(
        api.actualizarPerfil(PerfilUpdate.desde(perfilPrueba)),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.message,
                'message',
                'El teléfono debe tener entre 10 y 15 dígitos.',
              ),
        ),
      );
    });

    test(
      'el aviso se pide sin token a /public/legal/?tipo=privacidad',
      () async {
        late http.Request enviada;
        final client = MockClient((request) async {
          enviada = request;
          return http.Response(
            jsonEncode({
              'ok': true,
              'contenidos': [
                {
                  'tipo': 'privacidad',
                  'tipo_display': 'Política de privacidad',
                  'titulo': 'Aviso de privacidad',
                  'contenido': 'Texto del aviso.',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });
        final api = CatalogApiService(
          ApiClient(
            tokenStorage: _TokensEnMemoria(),
            httpClient: client,
            baseUrl: 'http://10.0.2.2:8000/api',
          ),
        );

        final contenidos = await api.fetchContenidoLegal(tipo: 'privacidad');

        expect(enviada.method, 'GET');
        expect(enviada.url.path, '/api/public/legal/');
        expect(enviada.url.queryParameters, {'tipo': 'privacidad'});
        expect(enviada.headers.containsKey('Authorization'), isFalse);
        expect(contenidos.single.titulo, 'Aviso de privacidad');
      },
    );
  });

  group('ARCO-M02 EditarPerfilViewModel (Mockito)', () {
    late MockPrivacidadRepository repo;
    late EditarPerfilViewModel vm;

    setUp(() async {
      repo = MockPrivacidadRepository();
      when(repo.getPerfil()).thenAnswer((_) async => perfilPrueba);
      vm = EditarPerfilViewModel(repo);
      await vm.load();
    });

    tearDown(() => vm.dispose());

    Future<bool> guardar() => vm.guardar(
      nombre: 'Cliente Editado',
      apellido: 'Prueba',
      telefono: '7719999999',
      fechaNacimiento: '1999-05-04',
      direccion: 'Calle Falsa #123',
    );

    test('guarda una vez y conserva avatar y dirección', () async {
      when(repo.actualizarPerfil(any)).thenAnswer((_) async => perfilPrueba);

      expect(await guardar(), isTrue);

      final enviado =
          verify(repo.actualizarPerfil(captureAny)).captured.single
              as PerfilUpdate;
      expect(enviado.nombre, 'Cliente Editado');
      expect(enviado.telefono, '7719999999');
      expect(enviado.avatarUrl, perfilPrueba.avatarUrl);
      expect(enviado.direccion, perfilPrueba.direccion);
      expect(vm.saving, isFalse);
    });

    test('el error del servidor se muestra y no se da por guardado', () async {
      when(repo.actualizarPerfil(any)).thenThrow(
        ApiException('No se pudo actualizar el perfil.', statusCode: 500),
      );

      expect(await guardar(), isFalse);
      expect(vm.errorMessage, 'No se pudo actualizar el perfil.');
      expect(vm.saving, isFalse);
    });

    test('un segundo toque mientras guarda no envía otro PUT', () async {
      when(repo.actualizarPerfil(any)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return perfilPrueba;
      });

      final primero = guardar();
      final segundo = await guardar();

      expect(segundo, isFalse);
      expect(await primero, isTrue);
      verify(repo.actualizarPerfil(any)).called(1);
    });

    test('sin perfil cargado no se envía nada', () async {
      final sinCargar = EditarPerfilViewModel(repo);
      expect(
        await sinCargar.guardar(
          nombre: 'Cliente',
          apellido: '',
          telefono: '',
          fechaNacimiento: '',
          direccion: '',
        ),
        isFalse,
      );
      verifyNever(repo.actualizarPerfil(any));
      sinCargar.dispose();
    });
  });

  group('ARCO-M01 MisDatosViewModel', () {
    late MockPrivacidadRepository repo;

    setUp(() => repo = MockPrivacidadRepository());

    test('si falla el historial, el perfil se muestra igual', () async {
      when(repo.getPerfil()).thenAnswer((_) async => perfilPrueba);
      when(repo.getHistorialCitas()).thenThrow(
        ApiException('No se pudieron cargar citas.', statusCode: 500),
      );
      final vm = MisDatosViewModel(repo);

      await vm.load();

      expect(vm.state, LoadState.ready);
      expect(vm.perfil?.email, perfilPrueba.email);
      expect(vm.citas, isEmpty);
      expect(vm.citasError, 'No se pudieron cargar citas.');
      vm.dispose();
    });

    test('si falla el perfil, queda en error y no pide el historial', () async {
      when(repo.getPerfil())
          .thenThrow(ApiException('Usuario no encontrado.', statusCode: 404));
      final vm = MisDatosViewModel(repo);

      await vm.load();

      expect(vm.state, LoadState.error);
      expect(vm.errorMessage, 'Usuario no encontrado.');
      verifyNever(repo.getHistorialCitas());
      vm.dispose();
    });
  });

  group('ARCO-M05 AvisoPrivacidadViewModel (opt-in en el servidor)', () {
    late MockPrivacidadRepository repo;
    final enServidor = DateTime.utc(2026, 10, 19, 18, 30);

    setUp(() {
      repo = MockPrivacidadRepository();
      when(repo.getAvisoPrivacidad()).thenAnswer((_) async => avisoPrueba);
      when(repo.getConsentimiento())
          .thenAnswer((_) async => ConsentimientoPrivacidad.sinRespuesta);
    });

    test(
      'con sesión: lee del servidor y sin respuesta previa todo apagado',
      () async {
        final vm = AvisoPrivacidadViewModel(repo, autenticado: true);

        await vm.load();

        expect(vm.state, LoadState.ready);
        expect(vm.preferenciasListas, isTrue);
        expect(vm.borrador.promociones, isFalse);
        expect(vm.borrador.recordatoriosWhatsapp, isFalse);
        expect(vm.borrador.analiticaPerfilado, isFalse);
        expect(vm.puedeGuardar, isTrue);
        verify(repo.getConsentimiento()).called(1);
        vm.dispose();
      },
    );

    test(
      'sin sesión: muestra el aviso, no pide preferencias ni guarda',
      () async {
        final vm = AvisoPrivacidadViewModel(repo, autenticado: false);

        await vm.load();
        vm.setPromociones(true);

        expect(vm.state, LoadState.ready);
        expect(vm.puedeGuardar, isFalse);
        expect(await vm.guardar(), isFalse);
        verifyNever(repo.getConsentimiento());
        verifyNever(repo.guardarConsentimiento(any));
        vm.dispose();
      },
    );

    test(
      'guardar manda la versión del aviso y usa lo que devuelve el servidor',
      () async {
        when(repo.guardarConsentimiento(any)).thenAnswer(
          (inv) async =>
              (inv.positionalArguments.first as ConsentimientoPrivacidad)
                  .copyWith(fecha: enServidor),
        );
        final vm = AvisoPrivacidadViewModel(repo, autenticado: true);
        await vm.load();

        vm.setPromociones(true);
        expect(await vm.guardar(), isTrue);

        final enviado =
            verify(repo.guardarConsentimiento(captureAny)).captured.single
                as ConsentimientoPrivacidad;
        expect(enviado.promociones, isTrue);
        expect(enviado.recordatoriosWhatsapp, isFalse);
        expect(enviado.versionAviso, avisoPrueba.version);
        expect(vm.guardado.fecha, enServidor);
        expect(vm.mensaje, 'Preferencias guardadas en tu cuenta.');
        vm.dispose();
      },
    );

    test('si el servidor rechaza el guardado, no se da por guardado', () async {
      when(repo.guardarConsentimiento(any)).thenThrow(
        ApiException(
          'acepta_promociones debe ser true o false.',
          statusCode: 400,
        ),
      );
      final vm = AvisoPrivacidadViewModel(repo, autenticado: true);
      await vm.load();

      vm.setPromociones(true);

      expect(await vm.guardar(), isFalse);
      expect(vm.preferenciasError, 'acepta_promociones debe ser true o false.');
      expect(vm.guardado.respondido, isFalse);
      expect(vm.saving, isFalse);
      vm.dispose();
    });

    test(
      'si fallan las preferencias, el aviso se ve y no se puede guardar',
      () async {
        when(
          repo.getConsentimiento(),
        ).thenThrow(ApiException('Error del servidor (500).', statusCode: 500));
        final vm = AvisoPrivacidadViewModel(repo, autenticado: true);

        await vm.load();

        expect(vm.state, LoadState.ready);
        expect(vm.aviso, isNotNull);
        expect(vm.preferenciasListas, isFalse);
        expect(vm.preferenciasError, 'Error del servidor (500).');
        expect(vm.puedeGuardar, isFalse);
        vm.dispose();
      },
    );

    test('sin aviso a la vista no se puede guardar consentimiento', () async {
      when(
        repo.getAvisoPrivacidad(),
      ).thenThrow(ApiException('Error del servidor (503).', statusCode: 503));
      final vm = AvisoPrivacidadViewModel(repo, autenticado: true);

      await vm.load();

      expect(vm.state, LoadState.error);
      expect(vm.puedeGuardar, isFalse);
      verifyNever(repo.getConsentimiento());
      vm.dispose();
    });

    test('si el aviso cambió desde la última respuesta, lo avisa', () async {
      when(repo.getConsentimiento()).thenAnswer(
        (_) async => ConsentimientoPrivacidad(
          promociones: true,
          fecha: enServidor,
          versionAviso: 'fnv1a-00000000',
        ),
      );
      final vm = AvisoPrivacidadViewModel(repo, autenticado: true);

      await vm.load();

      expect(vm.avisoCambio, isTrue);
      expect(vm.borrador.promociones, isTrue);
      vm.dispose();
    });

    test('la versión del aviso es estable y cambia con el texto', () {
      expect(avisoPrueba.version, avisoPrueba.version);
      const otro = ContenidoLegalDto(
        tipo: 'privacidad',
        tipoDisplay: 'Política de privacidad',
        titulo: 'Aviso de privacidad',
        contenido: 'Texto distinto.',
      );
      expect(otro.version, isNot(avisoPrueba.version));
      expect(avisoPrueba.version, startsWith('fnv1a-'));
    });

    test('el JSON sigue el contrato de /privacidad/preferencias/', () {
      final c = ConsentimientoPrivacidad.fromJson({
        'acepta_promociones': false,
        'acepta_recordatorios_whatsapp': true,
        'acepta_analitica_perfilado': 'true',
        'version_aviso': avisoPrueba.version,
        'fecha_respuesta': '2026-10-19T18:30:00+00:00',
        'respondido': true,
      });
      expect(c.recordatoriosWhatsapp, isTrue);
      expect(c.analiticaPerfilado, isFalse, reason: 'solo cuenta un true real');
      expect(c.fecha, enServidor);
      expect(c.toJson(), {
        'acepta_promociones': false,
        'acepta_recordatorios_whatsapp': true,
        'acepta_analitica_perfilado': false,
        'version_aviso': avisoPrueba.version,
      });
    });
  });

  group('ARCO-M05 contrato HTTP de /privacidad/preferencias/ (MockClient)', () {
    test('GET y PUT con Bearer; la fecha la pone el servidor', () async {
      final peticiones = <http.Request>[];
      final client = MockClient((request) async {
        peticiones.add(request);
        final body = request.method == 'PUT'
            ? {
                ...jsonDecode(request.body) as Map<String, dynamic>,
                'fecha_respuesta': '2026-10-19T18:30:00+00:00',
                'respondido': true,
              }
            : {
                'acepta_promociones': false,
                'acepta_recordatorios_whatsapp': false,
                'acepta_analitica_perfilado': false,
                'version_aviso': '',
                'fecha_respuesta': null,
                'respondido': false,
              };
        return http.Response(
          jsonEncode({'ok': true, 'preferencias': body}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = PrivacidadApiService(
        ApiClient(
          tokenStorage: _TokensEnMemoria(),
          httpClient: client,
          baseUrl: 'http://10.0.2.2:8000/api',
        ),
      );

      final inicial = await api.preferencias();
      final guardada = await api.guardarPreferencias(
        inicial.copyWith(recordatoriosWhatsapp: true, versionAviso: 'v1'),
      );

      expect(inicial.respondido, isFalse);
      expect(peticiones.map((r) => '${r.method} ${r.url.path}'), [
        'GET /api/privacidad/preferencias/',
        'PUT /api/privacidad/preferencias/',
      ]);
      expect(
        peticiones.every(
          (r) => r.headers['Authorization'] == 'Bearer access-de-prueba',
        ),
        isTrue,
      );
      expect(jsonDecode(peticiones.last.body), {
        'acepta_promociones': false,
        'acepta_recordatorios_whatsapp': true,
        'acepta_analitica_perfilado': false,
        'version_aviso': 'v1',
      });
      expect(guardada.recordatoriosWhatsapp, isTrue);
      expect(guardada.fecha, enServidorUtc);
    });

    test('un 400 de Django llega como ApiException', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'ok': false,
            'error': 'Falta el campo acepta_promociones.',
          }),
          400,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      final api = PrivacidadApiService(
        ApiClient(
          tokenStorage: _TokensEnMemoria(),
          httpClient: client,
          baseUrl: 'http://10.0.2.2:8000/api',
        ),
      );

      await expectLater(
        api.guardarPreferencias(ConsentimientoPrivacidad.sinRespuesta),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Falta el campo acepta_promociones.',
          ),
        ),
      );
    });
  });

  test('CitaDto vacío no rompe el historial', () {
    expect(CitaDto.fromJson(const {}).barberoNombre, 'Barbero');
  });
}
