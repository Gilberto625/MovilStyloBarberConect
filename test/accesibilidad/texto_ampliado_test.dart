// GH#19 QA-006 / PM10 / S8-03: texto ampliado (Ajustes › Tamaño de fuente).
// Con TextScaler 1.3 y 2.0 cada pantalla crítica se dibuja sin overflow, sus
// controles clave se alcanzan y la reserva se completa de punta a punta.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/arnes_accesibilidad.dart';

void main() {
  fijarReloj();

  for (final escala in const [1.3, 2.0]) {
    final s = Superficie(
      '412x915 texto ×$escala',
      telefono.size,
      textScale: escala,
    );

    testWidgets('PM10 reserva completa con texto ×$escala', (tester) async {
      final creadas = await completarReserva(tester, s);
      expect(creadas, 1);
      expect(find.textContaining('Cita creada (#9)'), findsOneWidget);
      sinOverflow(tester, 'reserva ×$escala');
    });

    for (final e in escenarios) {
      testWidgets('QA-006 ${e.id} con texto ×$escala sin overflow', (
        tester,
      ) async {
        await e.montar(tester, s);
        sinOverflow(tester, '${e.id} ×$escala');
        for (final c in e.controles()) {
          await alcanzar(tester, c);
          sinOverflow(tester, '${e.id} ×$escala al llegar a $c');
        }
      });
    }
  }

  testWidgets('QA-006 la escala de texto llega a la pantalla', (tester) async {
    await escenarios.first.montar(
      tester,
      Superficie('x2', telefono.size, textScale: 2),
    );
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(MediaQuery.textScalerOf(ctx).scale(10), 20);
  });
}
