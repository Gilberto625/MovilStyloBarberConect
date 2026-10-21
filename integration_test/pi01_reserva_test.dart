// PI-01 (Actividad 3, GH#17, PM03): crear una cita en la app y verla en
// "Mis citas" con los mismos datos; después ese horario ya no se ofrece
// (la disponibilidad sale del backend). El rechazo 409 se prueba con
// MockClient en test/integration.
//
// Corre en emulador contra el backend LOCAL con datos de prueba
// (backend: manage.py sembrar_datos_prueba). Nunca contra producción:
//
//   flutter test integration_test/pi01_reserva_test.dart -d emulator-5554 \
//     --dart-define=API_BASE_URL=http://10.0.2.2:8000/api \
//     --dart-define=TEST_CLIENT_USER=cliente.prueba@example.test \
//     --dart-define=TEST_CLIENT_PASS=<contraseña de prueba, no se versiona>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stylo_barber_connect/core/config/app_config.dart';
import 'package:stylo_barber_connect/main.dart' as app;

const _usuario = String.fromEnvironment('TEST_CLIENT_USER');
const _password = String.fromEnvironment('TEST_CLIENT_PASS');

// Datos que crea la semilla del backend local.
const _servicio = 'Corte clásico';
const _barbero = 'Barbero Uno Prueba';

/// Bombea frames hasta que aparezca [finder] o se acabe el tiempo. La red real
/// no termina en un pumpAndSettle.
Future<void> _esperar(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final limite = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(limite)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('No apareció a tiempo: $finder');
}

Future<void> _tocarVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PI-01 crear cita y verla en Mis citas (backend local)', (
    tester,
  ) async {
    expect(
      AppConfig.apiBaseUrl,
      isNot(contains('onrender.com')),
      reason: 'PI-01 escribe datos: solo backend local o de pruebas.',
    );
    expect(
      _usuario.isNotEmpty && _password.isNotEmpty,
      isTrue,
      reason: 'Faltan --dart-define TEST_CLIENT_USER / TEST_CLIENT_PASS.',
    );

    await app.main();

    // Splash -> inicio de invitado, o directo al panel si quedó sesión.
    final agendar = find.text('Agendar');
    await _esperar(
      tester,
      find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'Entrar' || w.data == 'Agendar'),
      ),
      timeout: const Duration(seconds: 60),
    );
    if (agendar.evaluate().isEmpty) {
      await tester.tap(find.text('Entrar').first);
      await _esperar(tester, find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField).at(0), _usuario);
      await tester.enterText(find.byType(TextFormField).at(1), _password);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await _esperar(tester, agendar);
    }

    // Agendar: servicio -> barbero -> primer horario libre -> confirmar.
    await tester.tap(agendar.last);
    await _esperar(tester, find.text(_servicio));
    await _tocarVisible(tester, find.text(_servicio));
    await _esperar(tester, find.text(_barbero));
    await _tocarVisible(tester, find.text(_barbero));
    await _esperar(tester, find.byType(ChoiceChip));

    final chip = find.byType(ChoiceChip).first;
    final hora = ((tester.widget<ChoiceChip>(chip).label as Text).data ?? '')
        .trim();
    expect(hora, isNotEmpty);
    await _tocarVisible(tester, chip);
    await _esperar(tester, find.text('Confirmar reserva'));

    // La fecha que eligió la app aparece en el resumen como AAAA-MM-DD.
    final resumen = find.textContaining(' · $hora · ');
    await tester.dragUntilVisible(
      resumen,
      find.byType(ListView).first,
      const Offset(0, -250),
    );
    expect(resumen, findsOneWidget);
    final fecha = (tester.widget<Text>(resumen).data ?? '').split(' · ').first;

    await tester.tap(find.text('Confirmar reserva'));
    await _esperar(tester, find.textContaining('Cita creada'));

    // Mis citas muestra la cita con el mismo servicio, fecha y hora.
    await tester.tap(find.text('Citas').last);
    await _esperar(tester, find.text(_servicio));
    expect(find.textContaining(fecha), findsWidgets);
    expect(find.textContaining(hora), findsWidgets);

    // El horario reservado ya no se ofrece para ese barbero y fecha.
    await tester.tap(agendar.last);
    await _esperar(tester, find.text(_servicio));
    await _tocarVisible(tester, find.text(_servicio));
    await _esperar(tester, find.text(_barbero));
    await _tocarVisible(tester, find.text(_barbero));
    await _esperar(tester, find.byType(ChoiceChip));
    expect(
      find.widgetWithText(ChoiceChip, hora),
      findsNothing,
      reason: 'el horario reservado no debe seguir disponible',
    );
  });
}
