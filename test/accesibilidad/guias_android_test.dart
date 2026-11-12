// GH#19 QA-006 / PM10 / S8-03: guías de accesibilidad de Android en las
// pantallas críticas. Son las revisiones del informe previo al lanzamiento de
// Play: controles con etiqueta para TalkBack (labeledTapTargetGuideline),
// objetivos táctiles de 48×48 dp (androidTapTargetGuideline) y contraste de
// texto (textContrastGuideline).
//
// Las guías solo miran lo que está en pantalla. Por eso se pasan dos veces:
// 1. En la vista inicial del teléfono de referencia, de 360×640 y con texto
//    ×2.0, tal como la ve el usuario.
// 2. Con una superficie tan alta que la pantalla entera cabe sin scroll, para
//    revisar también los controles que quedan más abajo. Se comprueba que no
//    quedó nada fuera (maxScrollExtent = 0).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/arnes_accesibilidad.dart';

/// Ninguna lista vertical tiene contenido fuera de la vista.
void _todoALaVista(WidgetTester tester, String donde) {
  final scrolls = tester.stateList<ScrollableState>(find.byType(Scrollable));
  for (final st in scrolls) {
    if (st.widget.axisDirection != AxisDirection.down) continue;
    expect(
      st.position.maxScrollExtent,
      0,
      reason: 'En $donde queda contenido fuera de la vista',
    );
  }
}

void main() {
  fijarReloj();

  final vistaInicial = [
    telefono,
    pequena,
    Superficie('412x915 texto ×2.0', telefono.size, textScale: 2),
  ];
  final completas = [
    const Superficie('completa 360 de ancho', Size(360, 2600)),
    const Superficie(
      'completa 412 de ancho, texto ×2.0',
      Size(412, 5200),
      textScale: 2,
    ),
  ];

  for (final s in vistaInicial) {
    for (final e in escenarios) {
      testWidgets('QA-006 guías Android · ${e.id} · $s', (tester) async {
        final semantics = tester.ensureSemantics();
        await e.montar(tester, s);
        sinOverflow(tester, '${e.id} $s');
        await cumpleGuiasAndroid(tester);
        semantics.dispose();
      });
    }
  }

  for (final s in completas) {
    for (final e in escenarios) {
      testWidgets('QA-006 guías Android · ${e.id} · $s', (tester) async {
        final semantics = tester.ensureSemantics();
        await e.montar(tester, s);
        sinOverflow(tester, '${e.id} $s');
        _todoALaVista(tester, '${e.id} $s');
        for (final c in e.controles()) {
          expect(c, findsWidgets, reason: '$c no se construyó');
        }
        await cumpleGuiasAndroid(tester);
        semantics.dispose();
      });
    }
  }
}
