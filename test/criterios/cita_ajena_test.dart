// GH#23 / PM02: el cliente no puede cancelar ni reprogramar una cita ajena.
// Django responde 404 "Cita no encontrada." (cliente_cita_views.py) y la app
// lo trata como error de dominio, sin dar la cita por cambiada.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/repositories/citas_repository.dart';
import 'package:stylo_barber_connect/services/citas_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/client_citas_viewmodel.dart';

import '../support/memory_token_storage.dart';

const _citaAjena = 999;

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Servidor simulado: cualquier cambio sobre la cita ajena es 404.
({CitasRepository repo, List<http.Request> peticiones}) _servidor() {
  final peticiones = <http.Request>[];
  final api = ApiClient(
    tokenStorage: MemoryTokenStorage(access: 'token-cliente'),
    baseUrl: 'http://10.0.2.2:8000/api',
    httpClient: MockClient((r) async {
      peticiones.add(r);
      if (r.url.path.startsWith('/api/mis-citas/$_citaAjena/')) {
        return _json({'ok': false, 'error': 'Cita no encontrada.'}, 404);
      }
      return _json({'ok': true, 'citas': []}, 200);
    }),
  );
  return (repo: CitasRepository(CitasApiService(api)), peticiones: peticiones);
}

Matcher get _citaNoEncontrada => throwsA(
  isA<ApiException>()
      .having((e) => e.message, 'message', 'Cita no encontrada.')
      .having((e) => e.statusCode, 'statusCode', 404),
);

CitaDto get _cita => CitaDto.fromJson({
  'id': _citaAjena,
  'estado': 'confirmada',
  'fecha': '2026-11-20',
  'hora': '12:00',
  'barbero_id': 3,
  'puede_modificar': true,
});

void main() {
  group('GH#23 / PM02 cita ajena', () {
    test('GH#23 PM02 cancelar una cita ajena: 404 como ApiException con el mensaje '
        'del servidor', () async {
      final s = _servidor();
      await expectLater(
        s.repo.cancelarCita(_citaAjena, motivo: 'Prueba'),
        _citaNoEncontrada,
      );
      expect(
        s.peticiones.single.url.path,
        '/api/mis-citas/$_citaAjena/cancelar/',
      );
    });

    test('GH#23 PM02 reprogramar una cita ajena: 404 como ApiException con el '
        'mensaje del servidor', () async {
      final s = _servidor();
      await expectLater(
        s.repo.reprogramarCita(_citaAjena, fecha: '2026-11-21', hora: '13:00'),
        _citaNoEncontrada,
      );
      expect(
        s.peticiones.single.url.path,
        '/api/mis-citas/$_citaAjena/reprogramar/',
      );
    });

    test('GH#23 el ViewModel no da la cita ajena por cancelada ni '
        'reprogramada', () async {
      final s = _servidor();
      final vm = ClientCitasViewModel(s.repo);
      addTearDown(vm.dispose);

      expect(await vm.cancelarCita(_cita, motivo: 'Prueba'), isFalse);
      expect(vm.cambioError, 'Cita no encontrada.');
      expect(vm.cambioMensaje, isNull);
      expect(vm.cambioBusy, isFalse);

      expect(
        await vm.reprogramarCita(_cita, fecha: '2026-11-21', hora: '13:00'),
        isFalse,
      );
      expect(vm.cambioError, 'Cita no encontrada.');
      expect(vm.cambioMensaje, isNull);

      // Sin éxito no se recarga la lista como si algo hubiera cambiado.
      expect(
        s.peticiones.where((r) => r.url.path == '/api/mis-citas/'),
        isEmpty,
      );
    });
  });
}
