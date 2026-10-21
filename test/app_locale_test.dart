import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/core/config/app_locale.dart';

void main() {
  testWidgets('los componentes de Material salen en español de México', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: AppLocale.locale,
        supportedLocales: AppLocale.supported,
        localizationsDelegates: AppLocale.delegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDatePicker(
              context: context,
              initialDate: DateTime(2026, 10, 22),
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.textContaining('oct'), findsWidgets);
  });
}
