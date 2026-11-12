// GH#19 QA-006 / PM10 / S8-03: pantalla pequeña de 360×640 dp. Ninguna
// pantalla crítica se desborda y todos sus controles clave se pueden tocar
// (con scroll si hace falta). También con texto ×1.3, el caso más común, y
// con ×2.0, el peor caso.
import 'package:flutter_test/flutter_test.dart';

import 'support/arnes_accesibilidad.dart';

void main() {
  fijarReloj();

  final grande = Superficie('360x640 texto ×1.3', pequena.size, textScale: 1.3);

  final maxima = Superficie('360x640 texto ×2.0', pequena.size, textScale: 2);

  for (final s in [pequena, grande, maxima]) {
    testWidgets('S8-03 reserva completa en $s', (tester) async {
      expect(await completarReserva(tester, s), 1);
      sinOverflow(tester, 'reserva $s');
    });

    for (final e in escenarios) {
      testWidgets('S8-03 ${e.id} en $s: sin overflow y alcanzable', (
        tester,
      ) async {
        await e.montar(tester, s);
        sinOverflow(tester, '${e.id} $s');
        for (final c in e.controles()) {
          await alcanzar(tester, c);
          sinOverflow(tester, '${e.id} $s al llegar a $c');
        }
      });
    }
  }
}
