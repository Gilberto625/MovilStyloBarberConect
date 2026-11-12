// S7-01: la agenda del barbero muestra carga, vacío y error con reintento.
// Vacío y error con reintento ya los cubre `test/barbero_agenda_test.dart`
// › "vacía y error con reintento"; aquí se agrega el estado de carga, al
// abrir y al reintentar.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/models/barbero_models.dart';
import 'package:stylo_barber_connect/viewmodels/barbero_agenda_viewmodel.dart';
import 'package:stylo_barber_connect/views/barber/barbero_agenda_view.dart';

import '../mocks/mocks.mocks.dart';

BarberoAgendaDto get _vacia =>
    const BarberoAgendaDto(fecha: '2026-11-11', esHoy: true, citas: []);

void main() {
  testWidgets('S7-01 muestra la carga al abrir y al reintentar, luego error '
      'y vacío', (tester) async {
    final repo = MockBarberoRepository();
    final respuestas = <Completer<BarberoAgendaDto>>[];
    when(repo.getAgenda(fecha: anyNamed('fecha'))).thenAnswer((_) {
      final c = Completer<BarberoAgendaDto>();
      respuestas.add(c);
      return c.future;
    });
    final vm = BarberoAgendaViewModel(repo);
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<BarberoAgendaViewModel>.value(
          value: vm,
          child: const BarberoAgendaView(),
        ),
      ),
    );
    await tester.pump();

    // Carga inicial.
    expect(find.text('Cargando tu agenda…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);

    // Error de red: mensaje y reintento.
    respuestas.removeAt(0).completeError(NetworkException());
    await tester.pumpAndSettle();
    expect(find.text('No se pudo cargar tu agenda'), findsOneWidget);
    expect(find.text(NetworkException.sinConexion), findsOneWidget);
    expect(find.text('Cargando tu agenda…'), findsNothing);

    // Reintentar vuelve a mostrar la carga mientras responde el servidor.
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(find.text('Cargando tu agenda…'), findsOneWidget);
    expect(find.text('No se pudo cargar tu agenda'), findsNothing);

    respuestas.removeAt(0).complete(_vacia);
    await tester.pumpAndSettle();
    expect(find.text('Sin citas asignadas'), findsOneWidget);
    expect(find.text('Cargando tu agenda…'), findsNothing);
    verify(repo.getAgenda(fecha: anyNamed('fecha'))).called(2);
  });
}
