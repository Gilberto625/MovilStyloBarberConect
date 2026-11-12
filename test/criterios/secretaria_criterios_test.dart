// US-SEC-ALTA: el cliente de paso queda seleccionado con su nombre y Nueva
// cita solo ofrece horarios libres.
// US-SEC-EDITAR: si Django rechaza el horario al reprogramar, se muestra su
// mensaje y la cita no se da por reprogramada.
//
// SecretariaRepository va completo hasta ApiClient con un servidor simulado
// (respuestas con la forma de secretaria_cita_views.py y
// secretaria_editar_cita_views.py). Catálogo y disponibilidad son mocks.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/network/api_client.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/models/catalog_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/repositories/secretaria_repository.dart';
import 'package:stylo_barber_connect/services/secretaria_api_service.dart';
import 'package:stylo_barber_connect/viewmodels/secretaria_gestion_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/secretaria_hoy_viewmodel.dart';
import 'package:stylo_barber_connect/views/secretary/secretary_gestion_views.dart';

import '../mocks/mocks.mocks.dart';
import '../support/memory_token_storage.dart';

const _servicio = ServicioDto(
  id: 1,
  nombre: 'Corte clásico',
  descripcion: '',
  precio: 180,
  duracionMinutos: 40,
  categoria: 'corte',
  popular: false,
  activo: true,
  imagenUrl: '',
  bannerUrl: '',
);

const _barbero = BarberoDto(
  id: 2,
  nombre: 'Luis',
  apellido: 'Mora',
  especialidades: '',
  avatarUrl: '',
  serviciosIds: [1],
);

const _politicaLibre = PoliticaPagoDto(
  requiereAnticipo: false,
  porcentajeAnticipo: 0,
  penalizado: false,
  totalInasistencias: 0,
);

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

class _Entorno {
  _Entorno(this.responder, {required List<SlotDisponibilidad> horarios}) {
    final api = ApiClient(
      tokenStorage: MemoryTokenStorage(access: 'token-secretaria'),
      baseUrl: 'http://10.0.2.2:8000/api',
      httpClient: MockClient((r) async {
        peticiones.add(r);
        return responder(r);
      }),
    );
    secretaria = SecretariaRepository(SecretariaApiService(api));
    when(catalogo.getServicios()).thenAnswer((_) async => const [_servicio]);
    when(citas.getBarberos(servicioId: anyNamed('servicioId')))
        .thenAnswer((_) async => const [_barbero]);
    when(
      citas.getDisponibilidad(
        barberoId: anyNamed('barberoId'),
        fecha: anyNamed('fecha'),
        duracion: anyNamed('duracion'),
      ),
    ).thenAnswer((_) async => horarios);
    when(citas.getPoliticaPago(any)).thenAnswer((_) async => _politicaLibre);
  }

  final http.Response Function(http.Request) responder;
  final peticiones = <http.Request>[];
  final catalogo = MockCatalogRepository();
  final citas = MockCitasRepository();
  late final SecretariaRepository secretaria;
  late final gestion = SecretariaGestionViewModel(
    secretaria: secretaria,
    citas: citas,
    catalog: catalogo,
  );
  late final hoy = SecretariaHoyViewModel(secretaria);

  Iterable<http.Request> donde(String metodo, String ruta) =>
      peticiones.where((r) => r.method == metodo && r.url.path == '/api$ruta');
}

/// Abre [destino] desde una raíz, como lo hace el panel de secretaría.
Future<void> _abrir(
  WidgetTester tester,
  _Entorno e,
  Widget destino, {
  bool asentar = true,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(e.gestion.dispose);
  addTearDown(e.hoy.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SecretariaGestionViewModel>.value(
          value: e.gestion,
        ),
        ChangeNotifierProvider<SecretariaHoyViewModel>.value(value: e.hoy),
      ],
      child: MaterialApp(
        theme: AppTheme.panel(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => destino)),
                child: const Text('Panel'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Panel'));
  if (asentar) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _confirmarDialogo(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
  await tester.pumpAndSettle();
}

Finder _chip(String texto) => find.widgetWithText(ChoiceChip, texto);

/// GET de `/secretaria/citas/{id}/editar/` con la forma de Django.
Map<String, dynamic> _editable(int id, String cliente) => {
  'ok': true,
  'cita': {
    'id': id,
    'cliente_id': 4,
    'cliente_nombre': cliente,
    'barbero_id': 2,
    'servicio_id': 1,
    'servicio_nombre': 'Corte clásico',
    'servicio_precio': 180,
    'fecha': '2026-11-20',
    'hora': '10:00',
    'duracion_minutos': 40,
    'estado': 'confirmada',
    'precio_total': 180,
    'notas': '',
    'anticipo_pagado': 0,
    'metodo_anticipo': 'ninguno',
    'puede_editar': true,
  },
  'fecha_minima': '2026-11-11',
};

/// Cita 9 (Ana López) y cita 5 (Pedro Ruiz). Reprogramar la 9 choca con
/// otra cita: 400 "Ese horario ya está ocupado.".
_Entorno _entornoEdicion() => _Entorno(
  (r) {
    final editar = RegExp(r'^/api/secretaria/citas/(\d+)/editar/$')
        .firstMatch(r.url.path);
    if (editar != null) {
      if (r.method == 'PUT') {
        return _json({
          'ok': false,
          'error': 'Ese horario ya está ocupado.',
        }, 400);
      }
      final id = int.parse(editar.group(1)!);
      return _json(_editable(id, id == 9 ? 'Ana López' : 'Pedro Ruiz'), 200);
    }
    return _json({'ok': true, 'fecha': '2026-11-20', 'citas': []}, 200);
  },
  horarios: const [
    SlotDisponibilidad(hora: '10:00', disponible: false),
    SlotDisponibilidad(hora: '11:00', disponible: true),
  ],
);

void main() {
  testWidgets('US-SEC-ALTA el cliente de paso queda seleccionado y Nueva cita '
      'solo ofrece horarios libres', (tester) async {
    final e = _Entorno(
      (r) {
        if (r.method == 'POST' && r.url.path == '/api/secretaria/clientes/') {
          return _json({
            'ok': true,
            'cliente': {
              'id': 31,
              'nombre_completo': 'Juan Pérez',
              'nombres': 'Juan',
              'apellido': 'Pérez',
              'telefono': '7711234567',
              'email': '',
              'es_anonimo': true,
            },
            'mensaje': 'Cliente de paso registrado para esta cita.',
          }, 201);
        }
        if (r.url.path == '/api/secretaria/citas/crear/') {
          return _json({'ok': true, 'id': 77}, 201);
        }
        return _json({'ok': true, 'fecha': '2026-11-11', 'citas': []}, 200);
      },
      horarios: const [
        SlotDisponibilidad(hora: '10:00', disponible: false),
        SlotDisponibilidad(hora: '10:20', disponible: true),
        SlotDisponibilidad(hora: '11:00', disponible: false),
        SlotDisponibilidad(hora: '11:40', disponible: true),
      ],
    );
    await _abrir(tester, e, const SecretaryNuevaCitaView());

    // Alta del cliente de paso.
    await tester.tap(find.text('Registrar cliente de paso'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Juan');
    await tester.enterText(
      find.widgetWithText(TextField, 'Apellido paterno'),
      'Pérez',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Teléfono'),
      '771 123 4567',
    );
    await tester.tap(find.text('Registrar cliente'));
    await tester.pumpAndSettle();
    await _confirmarDialogo(tester);

    final alta = e.donde('POST', '/secretaria/clientes/').single;
    expect(jsonDecode(alta.body), {
      'modo': 'anonimo',
      'nombres': 'Juan',
      'apellido_paterno': 'Pérez',
      'telefono': '7711234567',
    });
    expect(find.text('Seleccionado: Juan Pérez'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('Juan Pérez'),
      ),
      findsOneWidget,
    );
    expect(e.gestion.cliente?.id, 31);
    expect(e.gestion.errorMessage, isNull);
    // El aviso se va solo y deja libre el botón del pie.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Servicio y barbero: aparecen solo los horarios disponibles.
    await tester.tap(find.text('Corte clásico'));
    await tester.pumpAndSettle();
    await tester.tap(_chip('Luis Mora'));
    await tester.pumpAndSettle();

    expect(_chip('10:20'), findsOneWidget);
    expect(_chip('11:40'), findsOneWidget);
    expect(_chip('10:00'), findsNothing);
    expect(_chip('11:00'), findsNothing);

    // La cita sale a nombre del cliente de paso recién creado.
    await tester.tap(_chip('10:20'));
    await tester.pumpAndSettle();
    expect(find.text('Resumen'), findsOneWidget);
    await tester.tap(find.text('Confirmar cita'));
    await tester.pumpAndSettle();
    await _confirmarDialogo(tester);

    final crear = e.donde('POST', '/secretaria/citas/crear/').single;
    final cuerpo = jsonDecode(crear.body) as Map<String, dynamic>;
    expect(cuerpo['cliente_id'], 31);
    expect(cuerpo['hora'], '10:20');
  });

  testWidgets('US-SEC-EDITAR si el servidor rechaza el horario, se ve su '
      'mensaje y la cita no queda reprogramada', (tester) async {
    final e = _entornoEdicion();
    await _abrir(tester, e, const SecretaryReprogramarView(citaId: 9));
    expect(find.text('Reprogramar #9'), findsOneWidget);
    expect(find.text('Ana López'), findsOneWidget);

    await tester.tap(_chip('11:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambio'));
    await tester.pumpAndSettle();
    await _confirmarDialogo(tester);

    // Se pidió el cambio una vez, con el horario elegido.
    final put = e.donde('PUT', '/secretaria/citas/9/editar/').single;
    expect((jsonDecode(put.body) as Map)['hora'], '11:00');

    // El mensaje de Django se ve (aviso en pantalla y snackbar).
    expect(find.text('Ese horario ya está ocupado.'), findsNWidgets(2));
    expect(e.gestion.errorMessage, 'Ese horario ya está ocupado.');
    expect(e.gestion.mensaje, isNull);

    // No se da por reprogramada: sigue en la pantalla y no recarga el día.
    expect(find.text('Reprogramar #9'), findsOneWidget);
    expect(find.text('Panel'), findsNothing);
    expect(e.donde('GET', '/secretaria/citas/dia/'), isEmpty);
    final guardar = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Guardar cambio'),
    );
    expect(guardar.onPressed, isNotNull, reason: 'Puede elegir otro horario.');
  });
  testWidgets('US-SEC-EDITAR abrir Reprogramar muestra la carga primero y no '
      'avisa a los oyentes durante la construcción', (tester) async {
    final e = _entornoEdicion();
    // La secretaria ya había abierto otra cita (el ViewModel es de la app).
    await e.gestion.cargarEditable(5);
    expect(e.gestion.editable?.clienteNombre, 'Pedro Ruiz');

    await _abrir(
      tester,
      e,
      const SecretaryReprogramarView(citaId: 9),
      asentar: false,
    );
    // Primer cuadro de la ruta (aún fuera de escena por la transición):
    // carga, nunca los datos de la cita anterior.
    expect(find.text('Cargando cita…', skipOffstage: false), findsOneWidget);
    expect(find.text('Pedro Ruiz', skipOffstage: false), findsNothing);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Ana López'), findsOneWidget);
    expect(find.text('Pedro Ruiz'), findsNothing);
    expect(e.donde('GET', '/secretaria/citas/9/editar/'), hasLength(1));
  });
}
