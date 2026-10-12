import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stylo_barber_connect/core/errors/app_exception.dart';
import 'package:stylo_barber_connect/core/theme/app_theme.dart';
import 'package:stylo_barber_connect/models/catalog_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/repositories/catalog_repository.dart';
import 'package:stylo_barber_connect/repositories/citas_repository.dart';
import 'package:stylo_barber_connect/repositories/secretaria_repository.dart';
import 'package:stylo_barber_connect/viewmodels/home_guest_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/secretaria_gestion_viewmodel.dart';
import 'package:stylo_barber_connect/viewmodels/secretaria_hoy_viewmodel.dart';
import 'package:stylo_barber_connect/views/secretary/secretary_gestion_views.dart';

void main() {
  test('a short client query does not call the server', () async {
    final secretaria = _Secretaria();
    final vm = _vm(secretaria);
    await vm.buscarClientes('a');
    expect(secretaria.busquedas, 0);
    expect(vm.clientesState, LoadState.idle);
  });

  test('create stays local until the required fields exist', () async {
    final secretaria = _Secretaria();
    final vm = _vm(secretaria);
    final id = await vm.crearCita();
    expect(id, isNull);
    expect(vm.errorMessage, 'Selecciona un cliente.');
    expect(secretaria.creaciones, 0);
  });

  test('create returns the server id and blocks a second submit', () async {
    final secretaria = _Secretaria();
    final vm = _vm(secretaria);
    _seleccionar(vm);
    final primero = vm.crearCita();
    final segundo = await vm.crearCita();
    expect(segundo, isNull);
    secretaria.crearListo.complete({'ok': true, 'id': 44});
    expect(await primero, 44);
    expect(secretaria.creaciones, 1);
    expect(vm.mensaje, 'Cita creada (#44).');
  });

  test('a rejected schedule is not treated as created', () async {
    final secretaria = _Secretaria()
      ..crearError = ApiException('Ese horario ya está ocupado.');
    final vm = _vm(secretaria);
    _seleccionar(vm);
    final id = await vm.crearCita();
    expect(id, isNull);
    expect(vm.errorMessage, contains('ocupado'));
  });

  test('future client appointments surface an empty or error state', () async {
    final secretaria = _Secretaria()
      ..citasError = ApiException('No se pudieron buscar citas.');
    final vm = _vm(secretaria);
    await vm.cargarCitasCliente(4);
    expect(vm.citasClienteState, LoadState.error);
    secretaria.citasError = null;
    await vm.cargarCitasCliente(4);
    expect(vm.citasClienteState, LoadState.empty);
  });

  test('a past appointment is not updated', () async {
    final secretaria = _Secretaria()..puedeEditar = false;
    final vm = _vm(secretaria);
    await vm.cargarEditable(9);
    final ok = await vm.reprogramar();
    expect(ok, isFalse);
    expect(secretaria.actualizaciones, 0);
    expect(vm.errorMessage, contains('no permite modificar'));
  });

  test(
    'reschedule keeps the appointment hour when it is the same visit',
    () async {
      final citas = _Citas();
      final secretaria = _Secretaria();
      final vm = _vm(secretaria, citas: citas);
      await vm.cargarEditable(9);
      expect(vm.horariosElegibles.map((s) => s.hora), contains('10:00'));
      final ok = await vm.reprogramar();
      expect(ok, isTrue);
      expect(secretaria.actualizaciones, 1);
      expect(secretaria.ultimaHora, '10:00');
    },
  );

  testWidgets('confirm does not create a cita without a client', (
    tester,
  ) async {
    final secretaria = _Secretaria();
    final gestion = _vm(secretaria);
    final hoy = SecretariaHoyViewModel(secretaria);
    addTearDown(gestion.dispose);
    addTearDown(hoy.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SecretariaGestionViewModel>.value(
            value: gestion,
          ),
          ChangeNotifierProvider<SecretariaHoyViewModel>.value(value: hoy),
        ],
        child: MaterialApp(
          theme: AppTheme.guest(),
          home: const SecretaryNuevaCitaView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirmar cita'));
    await tester.tap(find.text('Confirmar cita'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona un cliente.'), findsWidgets);
    expect(secretaria.creaciones, 0);
  });
}

SecretariaGestionViewModel _vm(_Secretaria secretaria, {_Citas? citas}) {
  return SecretariaGestionViewModel(
    secretaria: secretaria,
    citas: citas ?? _Citas(),
    catalog: _Catalogo(),
  );
}

void _seleccionar(SecretariaGestionViewModel vm) {
  vm.cliente = const SecretariaClienteDto(
    id: 4,
    nombreCompleto: 'Ana López',
    telefono: '555',
    email: '',
    esAnonimo: false,
  );
  vm.servicio = const ServicioDto(
    id: 1,
    nombre: 'Corte clásico',
    descripcion: '',
    precio: 180,
    duracionMinutos: 45,
    categoria: 'corte',
    popular: false,
    activo: true,
    imagenUrl: '',
    bannerUrl: '',
  );
  vm.barbero = const BarberoDto(
    id: 2,
    nombre: 'Luis',
    apellido: 'Mora',
    especialidades: '',
    avatarUrl: '',
    serviciosIds: [1],
  );
  vm.fecha = '2026-10-13';
  vm.hora = '11:30';
}

class _Catalogo implements CatalogRepository {
  @override
  Future<List<ServicioDto>> getServicios() async => const [
    ServicioDto(
      id: 1,
      nombre: 'Corte clásico',
      descripcion: '',
      precio: 180,
      duracionMinutos: 45,
      categoria: 'corte',
      popular: false,
      activo: true,
      imagenUrl: '',
      bannerUrl: '',
    ),
  ];

  @override
  Future<ContactoDto> getContacto() => throw UnimplementedError();

  @override
  Future<List<ProductoDto>> getProductos() async => const [];

  @override
  Future<
    ({
      ContactoDto contacto,
      List<ProductoDto> productos,
      List<ServicioDto> servicios,
    })
  >
  loadHomeGuest() => throw UnimplementedError();
}

class _Citas implements CitasRepository {
  @override
  Future<List<BarberoDto>> getBarberos({int? servicioId}) async => const [
    BarberoDto(
      id: 2,
      nombre: 'Luis',
      apellido: 'Mora',
      especialidades: '',
      avatarUrl: '',
      serviciosIds: [1],
    ),
  ];

  @override
  Future<List<SlotDisponibilidad>> getDisponibilidad({
    required int barberoId,
    required String fecha,
    required int duracion,
  }) async => const [
    SlotDisponibilidad(hora: '10:00', disponible: false),
    SlotDisponibilidad(hora: '10:20', disponible: true),
  ];

  @override
  Future<PoliticaPagoDto> getPoliticaPago(int clienteId) async {
    return const PoliticaPagoDto(
      requiereAnticipo: false,
      porcentajeAnticipo: 0,
      penalizado: false,
      totalInasistencias: 0,
    );
  }

  @override
  Future<List<CitaDto>> getMisCitas() async => const [];

  @override
  Future<Map<String, dynamic>> crearCita({
    required int clienteId,
    required int barberoId,
    required int servicioId,
    required int duracionMinutos,
    required String fecha,
    required String hora,
    required double precioTotal,
    double anticipoPagado = 0,
    String metodoAnticipo = '',
    String comprobantePago = '',
    String notas = '',
  }) async => {'ok': true, 'id': 1};
}

class _Secretaria implements SecretariaRepository {
  int busquedas = 0;
  int creaciones = 0;
  int actualizaciones = 0;
  String? ultimaHora;
  Object? crearError;
  Object? citasError;
  bool puedeEditar = true;
  final crearListo = Completer<Map<String, dynamic>>();

  @override
  Future<List<SecretariaClienteDto>> buscarClientes(String q) async {
    busquedas += 1;
    return const [
      SecretariaClienteDto(
        id: 4,
        nombreCompleto: 'Ana López',
        telefono: '555',
        email: '',
        esAnonimo: false,
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> crearCita({
    required int clienteId,
    required int barberoId,
    required int servicioId,
    required int duracionMinutos,
    required String fecha,
    required String hora,
    required double precioTotal,
    double anticipoPagado = 0,
    String metodoAnticipo = '',
    String comprobantePago = '',
    String notas = '',
  }) {
    creaciones += 1;
    if (crearError != null) return Future.error(crearError!);
    if (!crearListo.isCompleted) return crearListo.future;
    return crearListo.future;
  }

  @override
  Future<SecretariaCitaEditableDto> citaEditable(int citaId) async {
    return SecretariaCitaEditableDto(
      id: citaId,
      clienteId: 4,
      clienteNombre: 'Ana López',
      barberoId: 2,
      servicioId: 1,
      servicioNombre: 'Corte clásico',
      servicioPrecio: 180,
      fecha: '2026-10-13',
      hora: '10:00',
      duracionMinutos: 45,
      estado: 'confirmada',
      precioTotal: 180,
      notas: '',
      anticipoPagado: 0,
      metodoAnticipo: 'ninguno',
      puedeEditar: puedeEditar,
      fechaMinima: '2026-10-12',
    );
  }

  @override
  Future<Map<String, dynamic>> actualizarCita({
    required int citaId,
    required int barberoId,
    required int servicioId,
    required String fecha,
    required String hora,
    required double precioTotal,
    required double anticipoPagado,
    required String metodoAnticipo,
    required String notas,
    bool cancelar = false,
  }) async {
    actualizaciones += 1;
    ultimaHora = hora;
    return {'ok': true, 'mensaje': 'Cita actualizada correctamente.'};
  }

  @override
  Future<List<SecretariaCitaResumenDto>> citasDeCliente(int clienteId) async {
    if (citasError != null) throw citasError!;
    return const [];
  }

  @override
  Future<SecretariaDiaDto> getCitasDia({String? fecha}) async {
    return const SecretariaDiaDto(
      fecha: '2026-10-12',
      esHoy: true,
      citas: [],
      total: 0,
      pendientesAccion: 0,
      enCurso: 0,
      completadas: 0,
      noAsistio: 0,
    );
  }

  @override
  Future<Map<String, dynamic>> marcarLlego(int citaId) async => {'ok': true};

  @override
  Future<Map<String, dynamic>> marcarNoAsistio(int citaId) async => {
    'ok': true,
  };

  @override
  Future<Map<String, dynamic>> cobrar({
    required int citaId,
    required String metodoPago,
    String? comprobante,
    String? referencia,
    double? efectivoRecibido,
  }) async => {'ok': true};

  @override
  Future<SecretariaClienteDto> crearClientePaso({
    required String nombres,
    String apellido = '',
    required String telefono,
  }) async {
    return SecretariaClienteDto(
      id: 8,
      nombreCompleto: nombres,
      telefono: telefono,
      email: '',
      esAnonimo: true,
    );
  }
}
