import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';
import 'package:stylo_barber_connect/core/storage/secure_token_storage.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/repositories/secretaria_repository.dart';
import 'package:stylo_barber_connect/routes/app_routes.dart';
import 'package:stylo_barber_connect/services/secretaria_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/auth_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/secretaria_hoy_viewmodel.dart';
import 'package:stylo_barber_connect/views/secretary/secretary_home_view.dart';

import 'mocks/mocks.mocks.dart';

import 'package:mockito/mockito.dart';

SecretariaCitaDto _cita({
  bool asistencia = true,
  bool cobrar = true,
  bool penalizado = false,
  double restante = 150,
}) => SecretariaCitaDto(
  id: 21,
  clienteId: 3,
  clienteNombre: 'Ana López Hernández',
  clienteTelefono: '7711234567',
  servicioNombre: 'Corte clásico',
  barberoNombre: 'Barbero Uno Prueba',
  fecha: '2030-01-15',
  hora: '10:00:00',
  duracionMinutos: 45,
  estado: 'confirmada',
  precioTotal: 150,
  anticipoPagado: 0,
  anticipoPendiente: 0,
  restante: restante,
  puedeCobrar: cobrar,
  puedeMarcarAsistencia: asistencia,
  clientePenalizado: penalizado,
  penalizacionPorcentaje: penalizado ? 50 : 0,
  penalizacionCitasRestantes: penalizado ? 2 : 0,
);

class _Repo extends SecretariaRepository {
  _Repo(this.citas)
    : super(
        SecretariaApiService(ApiClient(tokenStorage: SecureTokenStorage())),
      );

  List<SecretariaCitaDto> citas;
  Object? errorDia;
  int noAsistio = 0;
  final cobros = <({String metodo, double? efectivo, String? comprobante})>[];

  @override
  Future<SecretariaDiaDto> getCitasDia({String? fecha}) async {
    if (errorDia != null) throw errorDia!;
    return SecretariaDiaDto(
      fecha: '2030-01-15',
      esHoy: true,
      citas: citas,
      total: citas.length,
      pendientesAccion: citas.length,
      enCurso: 0,
      completadas: 0,
      noAsistio: 0,
    );
  }

  @override
  Future<Map<String, dynamic>> marcarNoAsistio(int citaId) async {
    noAsistio++;
    return {'ok': true, 'mensaje': 'Marcada como no asistió.'};
  }

  @override
  Future<Map<String, dynamic>> cobrar({
    required int citaId,
    required String metodoPago,
    String? comprobante,
    String? referencia,
    double? efectivoRecibido,
  }) async {
    cobros.add((
      metodo: metodoPago,
      efectivo: efectivoRecibido,
      comprobante: comprobante,
    ));
    return {'ok': true, 'mensaje': 'Cobro registrado.'};
  }
}

Future<(SecretariaHoyViewModel, _Repo)> _pump(
  WidgetTester tester,
  _Repo repo, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final authRepo = MockAuthRepository();
  when(authRepo.restoreSession()).thenAnswer(
    (_) async => const AuthUser(
      id: 9,
      username: 'secretaria.prueba',
      email: 's@example.test',
      rol: UserRole.secretaria,
    ),
  );
  final auth = AuthViewModel(authRepo);
  await auth.bootstrap();
  final vm = SecretariaHoyViewModel(repo);
  addTearDown(auth.dispose);
  addTearDown(vm.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ChangeNotifierProvider<SecretariaHoyViewModel>.value(value: vm),
      ],
      child: MaterialApp(
        theme: AppTheme.panel(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const SecretaryHomeView(),
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (vm, repo);
}

Future<void> _abrirDetalle(WidgetTester tester) async {
  await _tocar(tester, const ValueKey('agenda-cita-21'));
}

final _lista = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .last;

/// Desplaza la lista (perezosa) hasta que aparezca el elemento.
Future<void> _ver(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: _lista);
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, Key key) async {
  await _ver(tester, find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  group('Hoy', () {
    testWidgets('dice "1 cita" y muestra la hora de actualización', (
      tester,
    ) async {
      await _pump(tester, _Repo([_cita()]));

      expect(find.textContaining('1 cita'), findsOneWidget);
      expect(find.textContaining('1 citas'), findsNothing);
      expect(
        find.textContaining('En línea, actualizado a las'),
        findsOneWidget,
      );
      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('si falla la recarga avisa sin borrar la agenda', (
      tester,
    ) async {
      final (vm, repo) = await _pump(tester, _Repo([_cita()]));
      repo.errorDia = ApiException('Sin conexión.');
      await vm.load();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hoy_sin_conexion')), findsOneWidget);
      expect(find.text('Ana López Hernández'), findsOneWidget);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('Hoy y detalle a 360x800 con texto $scale', (tester) async {
        await _pump(
          tester,
          _Repo([_cita(penalizado: true)]),
          size: const Size(360, 800),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        await _abrirDetalle(tester);
        expect(tester.takeException(), isNull);
        await _ver(tester, find.textContaining('anticipo del 50 %'));
        expect(find.textContaining('anticipo del 50 %'), findsOneWidget);
        await _ver(tester, find.byKey(const Key('detalle_no_asistio')));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('No asistió (confirmación fuerte)', () {
    testWidgets('no se puede confirmar sin marcar la casilla', (tester) async {
      final (_, repo) = await _pump(tester, _Repo([_cita()]));
      await _abrirDetalle(tester);
      await _tocar(tester, const Key('detalle_no_asistio'));

      expect(find.text('¿Marcar como no asistió?'), findsOneWidget);
      final boton = tester.widget<FilledButton>(
        find.byKey(const Key('no_asistio_confirmar')),
      );
      expect(boton.onPressed, isNull);

      await tester.tap(find.byKey(const Key('no_asistio_check')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('no_asistio_confirmar')));
      await tester.pumpAndSettle();

      expect(repo.noAsistio, 1);
    });

    testWidgets('cancelar no llama al servidor', (tester) async {
      final (_, repo) = await _pump(tester, _Repo([_cita()]));
      await _abrirDetalle(tester);
      await _tocar(tester, const Key('detalle_no_asistio'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.noAsistio, 0);
      expect(find.text('Cita #21'), findsOneWidget);
    });
  });

  group('Cobro', () {
    testWidgets('calcula el cambio y cobra lo recibido', (tester) async {
      final (_, repo) = await _pump(tester, _Repo([_cita()]));
      await _abrirDetalle(tester);
      await _ver(tester, find.text('Cobrar \$150.00'));
      expect(find.text('Cobrar \$150.00'), findsOneWidget);
      await _tocar(tester, const Key('detalle_cobrar'));

      await tester.enterText(find.byKey(const Key('cobro_recibido')), '200');
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('cobro_cambio'))).data,
        '\$50.00',
      );
      await tester.tap(find.text('Exacto'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('cobro_cambio'))).data,
        '\$0.00',
      );
      await tester.tap(find.byKey(const Key('cobro_confirmar')));
      await tester.pumpAndSettle();

      expect(repo.cobros.single.metodo, 'efectivo');
      expect(repo.cobros.single.efectivo, 150);
    });

    testWidgets('transferencia exige comprobante; tarjeta no manda efectivo', (
      tester,
    ) async {
      final (_, repo) = await _pump(tester, _Repo([_cita()]));
      await _abrirDetalle(tester);
      await _tocar(tester, const Key('detalle_cobrar'));

      await tester.tap(find.text('Transferencia'));
      await tester.pumpAndSettle();
      expect(
        find.text('La transferencia requiere comprobante o referencia.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('cobro_confirmar')))
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('Tarjeta'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cobro_confirmar')));
      await tester.pumpAndSettle();

      expect(repo.cobros.single.metodo, 'tarjeta');
      expect(repo.cobros.single.efectivo, isNull);
    });
  });
}
