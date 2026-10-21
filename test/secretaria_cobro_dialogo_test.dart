import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';
import 'package:stylo_barber_connect/core/storage/secure_token_storage.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/repositories/secretaria_repository.dart';
import 'package:stylo_barber_connect/services/secretaria_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/secretaria_hoy_viewmodel.dart';
import 'package:stylo_barber_connect/views/secretary/secretary_home_view.dart';

const _cita = SecretariaCitaDto(
  id: 1,
  clienteId: 1,
  clienteNombre: 'Cliente Prueba',
  clienteTelefono: '',
  servicioNombre: 'Corte clásico',
  barberoNombre: 'Barbero Uno Prueba',
  fecha: '2026-10-20',
  hora: '10:00',
  duracionMinutos: 45,
  estado: 'en_curso',
  precioTotal: 150,
  anticipoPagado: 0,
  anticipoPendiente: 0,
  restante: 150,
  puedeCobrar: true,
  puedeMarcarAsistencia: false,
  clientePenalizado: false,
);

/// Solo responde lo que usa el cobro; el resto no se llama.
class _SecretariaCobro extends SecretariaRepository {
  _SecretariaCobro()
    : super(
        SecretariaApiService(ApiClient(tokenStorage: SecureTokenStorage())),
      );

  final cobros = <({String metodo, double? efectivo})>[];

  @override
  Future<SecretariaDiaDto> getCitasDia({String? fecha}) async =>
      const SecretariaDiaDto(
        fecha: '2026-10-20',
        esHoy: false,
        citas: [_cita],
        total: 1,
        pendientesAccion: 1,
        enCurso: 1,
        completadas: 0,
        noAsistio: 0,
      );

  @override
  Future<Map<String, dynamic>> cobrar({
    required int citaId,
    required String metodoPago,
    String? comprobante,
    String? referencia,
    double? efectivoRecibido,
  }) async {
    cobros.add((metodo: metodoPago, efectivo: efectivoRecibido));
    return {'ok': true, 'mensaje': 'Cobro registrado.'};
  }
}

Future<_SecretariaCobro> _abrirDetalle(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = _SecretariaCobro();
  final vm = SecretariaHoyViewModel(repo);
  addTearDown(vm.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<SecretariaHoyViewModel>.value(
      value: vm,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const SecretaryCitaDetailView(cita: _cita),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets(
    'cobrar en efectivo cierra el diálogo sin errores y cobra una vez',
    (tester) async {
      final repo = await _abrirDetalle(tester);

      await tester.tap(find.text('Cobrar restante'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Efectivo recibido'),
        '200',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cobrar'));
      // Deja correr la animación de salida del diálogo: ahí fallaba.
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(repo.cobros, [(metodo: 'efectivo', efectivo: 200.0)]);
      expect(find.text('Cobro registrado.'), findsOneWidget);
    },
  );

  testWidgets('cancelar el cobro no llama al servidor ni deja errores', (
    tester,
  ) async {
    final repo = await _abrirDetalle(tester);

    await tester.tap(find.text('Cobrar restante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repo.cobros, isEmpty);
    expect(find.text('Registrar cobro'), findsNothing);
  });

  testWidgets('efectivo insuficiente avisa y no cobra', (tester) async {
    final repo = await _abrirDetalle(tester);

    await tester.tap(find.text('Cobrar restante'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Efectivo recibido'),
      '100',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Cobrar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repo.cobros, isEmpty);
    expect(find.textContaining('El efectivo debe cubrir'), findsOneWidget);
  });
}
