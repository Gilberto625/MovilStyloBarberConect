// Guías de accesibilidad de Android en las pantallas principales (GH#19, PM10).
// Son las mismas revisiones que hace el informe previo al lanzamiento de Play:
// objetivos táctiles de 48 dp, controles con etiqueta y contraste de texto.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/models/barbero_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/barbero_agenda_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/client_citas_viewmodel.dart';
import 'package:stylo_barber_connect/views/auth/login_views.dart';
import 'package:stylo_barber_connect/views/barber/barbero_agenda_view.dart';
import 'package:stylo_barber_connect/views/client/client_citas_view.dart';
import 'package:stylo_barber_connect/views/client/client_reprogramar_view.dart';

import 'mocks/mocks.mocks.dart';

const _telefono = Size(412, 915);

CitaDto _cita() => CitaDto(
  id: 7,
  servicioId: 1,
  servicioNombre: 'Corte clásico',
  servicioImagen: '',
  fecha: '2026-11-04',
  hora: '12:00',
  duracionMinutos: 40,
  estado: 'confirmada',
  precioTotal: 150,
  anticipoPagado: 0,
  saldoPendiente: 150,
  notas: '',
  barberoNombre: 'Carlos Prueba',
  requierePago: false,
  barberoId: 3,
  puedeModificar: true,
  limiteModificacion: DateTime(2026, 11, 3, 12),
);

Future<void> _pump(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = _telefono;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Future<void> _cumpleGuias(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  testWidgets('GH#19 acceso', (tester) async {
    final semantics = tester.ensureSemantics();
    final auth = AuthViewModel(MockAuthRepository());
    await _pump(
      tester,
      ChangeNotifierProvider<AuthViewModel>.value(
        value: auth,
        child: MaterialApp(theme: AppTheme.guest(), home: const LoginView()),
      ),
    );
    await _cumpleGuias(tester);
    semantics.dispose();
  });

  testWidgets('GH#19 detalle de cita con reprogramar y cancelar', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repo = MockCitasRepository();
    await _pump(
      tester,
      ChangeNotifierProvider<ClientCitasViewModel>.value(
        value: ClientCitasViewModel(repo),
        child: MaterialApp(
          theme: AppTheme.panel(),
          home: CitaDetalleView(cita: _cita()),
        ),
      ),
    );
    await _cumpleGuias(tester);
    semantics.dispose();
  });

  testWidgets('GH#19 reprogramar', (tester) async {
    final semantics = tester.ensureSemantics();
    final repo = MockCitasRepository();
    when(
      repo.getDisponibilidad(
        barberoId: anyNamed('barberoId'),
        fecha: anyNamed('fecha'),
        duracion: anyNamed('duracion'),
      ),
    ).thenAnswer(
      (_) async => const [
        SlotDisponibilidad(hora: '15:00', disponible: true),
        SlotDisponibilidad(hora: '15:20', disponible: true),
      ],
    );
    await _pump(
      tester,
      ChangeNotifierProvider<ClientCitasViewModel>.value(
        value: ClientCitasViewModel(repo),
        child: MaterialApp(
          theme: AppTheme.panel(),
          home: ReprogramarCitaView(cita: _cita(), hoy: DateTime(2026, 11, 2)),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('reprogramar-hora-15:00')));
    await tester.pumpAndSettle();
    await _cumpleGuias(tester);
    semantics.dispose();
  });

  testWidgets('GH#19 agenda del barbero', (tester) async {
    final semantics = tester.ensureSemantics();
    final repo = MockBarberoRepository();
    when(repo.getAgenda(fecha: anyNamed('fecha'))).thenAnswer(
      (_) async => const BarberoAgendaDto(
        fecha: '2026-11-04',
        esHoy: true,
        citas: [
          BarberoCitaDto(
            id: 10,
            hora: '10:00',
            duracionMinutos: 40,
            servicioNombre: 'Corte clásico',
            clienteNombre: 'Ana Prueba',
            estado: 'confirmada',
            atencion: 'por_atender',
            notas: 'Degradado bajo',
            complementos: '',
            puedeIniciar: true,
            puedeTerminar: false,
          ),
          BarberoCitaDto(
            id: 11,
            hora: '11:00',
            duracionMinutos: 40,
            servicioNombre: 'Barba',
            clienteNombre: 'Beto Prueba',
            estado: 'en_curso',
            atencion: 'en_silla',
            notas: '',
            complementos: '',
            puedeIniciar: false,
            puedeTerminar: true,
          ),
        ],
      ),
    );
    await _pump(
      tester,
      MaterialApp(
        theme: AppTheme.panel(),
        home: ChangeNotifierProvider<BarberoAgendaViewModel>(
          create: (_) => BarberoAgendaViewModel(repo),
          child: const BarberoAgendaView(),
        ),
      ),
    );
    await _cumpleGuias(tester);
    semantics.dispose();
  });
}
