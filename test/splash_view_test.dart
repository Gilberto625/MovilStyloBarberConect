import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/views/splash/splash_view.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(const MaterialApp(home: SplashView()));
    await tester.pump();
    expect(tester.takeException(), isNull);
    final brand = tester
        .widgetList<RichText>(find.byType(RichText))
        .singleWhere((widget) => widget.text.toPlainText().contains('Stylo'));
    expect(brand.text.toPlainText(), 'Stylo Barber');
    expect(find.text('BARBERÍA'), findsOneWidget);
    expect(find.text('Cargando'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  }

  testWidgets('splash fits phone, tablet and landscape', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAt(tester, const Size(360, 800));
    await pumpAt(tester, const Size(800, 1280));
    await pumpAt(tester, const Size(800, 360));
  });
}
