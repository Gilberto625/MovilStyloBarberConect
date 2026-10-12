import 'package:flutter/foundation.dart';

import '../models/catalog_models.dart';
import '../models/cita_models.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/citas_repository.dart';
import '../repositories/secretaria_repository.dart';
import 'home_guest_viewmodel.dart';

class SecretariaGestionViewModel extends ChangeNotifier {
  SecretariaGestionViewModel({
    required SecretariaRepository secretaria,
    required CitasRepository citas,
    required CatalogRepository catalog,
  }) : _secretaria = secretaria,
       _citas = citas,
       _catalog = catalog;

  final SecretariaRepository _secretaria;
  final CitasRepository _citas;
  final CatalogRepository _catalog;

  LoadState serviciosState = LoadState.idle;
  LoadState clientesState = LoadState.idle;
  LoadState citasClienteState = LoadState.idle;
  LoadState editableState = LoadState.idle;
  String? errorMessage;
  String? mensaje;
  bool busy = false;
  bool barberosLoading = false;
  bool slotsLoading = false;

  List<ServicioDto> servicios = const [];
  List<SecretariaClienteDto> clientes = const [];
  List<BarberoDto> barberos = const [];
  List<SlotDisponibilidad> slots = const [];
  List<SecretariaCitaResumenDto> citasCliente = const [];
  PoliticaPagoDto? politica;
  SecretariaCitaEditableDto? editable;

  SecretariaClienteDto? cliente;
  ServicioDto? servicio;
  BarberoDto? barbero;
  String fecha = '';
  String? hora;
  String anticipoTexto = '';
  String metodoAnticipo = 'efectivo';
  String comprobante = '';
  String notas = '';

  int _busqueda = 0;

  List<ServicioDto> get serviciosReservables => servicios
      .where(
        (s) =>
            s.activo && !s.isPromocion && s.precio > 0 && s.duracionMinutos > 0,
      )
      .toList();

  List<SlotDisponibilidad> get horariosElegibles {
    final libres = slots.where((s) => s.disponible).toList();
    final actual = editable;
    final mismaCita =
        actual != null &&
        barbero?.id == actual.barberoId &&
        fecha == actual.fecha &&
        actual.hora.isNotEmpty;
    if (!mismaCita) return libres;
    final yaEsta = libres.any((s) => _hora(s.hora) == _hora(actual.hora));
    if (yaEsta) return libres;
    return [
      SlotDisponibilidad(hora: _hora(actual.hora), disponible: true),
      ...libres,
    ];
  }

  bool get puedeConfirmarCreacion =>
      cliente != null &&
      servicio != null &&
      barbero != null &&
      fecha.isNotEmpty &&
      hora != null &&
      !busy;

  void prepararNueva(String fechaInicial) {
    _limpiarSeleccion();
    fecha = fechaInicial;
    serviciosState = LoadState.idle;
    notifyListeners();
  }

  Future<void> cargarServicios() async {
    serviciosState = LoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      servicios = await _catalog.getServicios();
      serviciosState = serviciosReservables.isEmpty
          ? LoadState.empty
          : LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      serviciosState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> buscarClientes(String consulta) async {
    final q = consulta.trim();
    final token = ++_busqueda;
    if (q.length < 2) {
      clientes = const [];
      clientesState = LoadState.idle;
      errorMessage = null;
      notifyListeners();
      return;
    }
    clientesState = LoadState.loading;
    notifyListeners();
    try {
      final lista = await _secretaria.buscarClientes(q);
      if (token != _busqueda) return;
      clientes = lista;
      clientesState = lista.isEmpty ? LoadState.empty : LoadState.ready;
    } catch (e) {
      if (token != _busqueda) return;
      errorMessage = e.toString();
      clientesState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> elegirCliente(SecretariaClienteDto value) async {
    cliente = value;
    politica = null;
    notifyListeners();
    try {
      politica = await _citas.getPoliticaPago(value.id);
    } catch (e) {
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<bool> registrarClientePaso({
    required String nombres,
    String apellido = '',
    required String telefono,
  }) async {
    if (busy) return false;
    if (nombres.trim().length < 2) {
      errorMessage = 'El nombre debe tener al menos 2 caracteres.';
      notifyListeners();
      return false;
    }
    final digits = telefono.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      errorMessage = 'Teléfono inválido (10 a 15 dígitos).';
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final creado = await _secretaria.crearClientePaso(
        nombres: nombres.trim(),
        apellido: apellido.trim(),
        telefono: digits,
      );
      cliente = creado;
      try {
        politica = await _citas.getPoliticaPago(creado.id);
      } catch (e) {
        errorMessage = e.toString();
      }
      busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> elegirServicio(ServicioDto value) async {
    servicio = value;
    barbero = null;
    hora = null;
    slots = const [];
    barberosLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      barberos = await _citas.getBarberos(servicioId: value.id);
    } catch (e) {
      errorMessage = e.toString();
      barberos = const [];
    }
    barberosLoading = false;
    notifyListeners();
  }

  Future<void> elegirBarbero(BarberoDto value) async {
    barbero = value;
    hora = null;
    notifyListeners();
    await _cargarHorarios();
  }

  Future<void> elegirFecha(String value) async {
    fecha = value;
    hora = null;
    notifyListeners();
    await _cargarHorarios();
  }

  void elegirHora(String value) {
    hora = _hora(value);
    notifyListeners();
  }

  void setAnticipoTexto(String value) => anticipoTexto = value;

  void setMetodoAnticipo(String value) {
    metodoAnticipo = value;
    notifyListeners();
  }

  void setComprobante(String value) => comprobante = value;

  void setNotas(String value) => notas = value;

  Future<int?> crearCita() async {
    if (busy) return null;
    final validacion = _validarNueva();
    if (validacion != null) {
      errorMessage = validacion;
      notifyListeners();
      return null;
    }
    final servicioActual = servicio!;
    final anticipo = _anticipo() ?? 0;
    busy = true;
    errorMessage = null;
    mensaje = null;
    notifyListeners();
    try {
      final result = await _secretaria.crearCita(
        clienteId: cliente!.id,
        barberoId: barbero!.id,
        servicioId: servicioActual.id,
        duracionMinutos: servicioActual.duracionMinutos,
        fecha: fecha,
        hora: hora!,
        precioTotal: _precioNueva(servicioActual),
        anticipoPagado: anticipo,
        metodoAnticipo: anticipo > 0 ? metodoAnticipo : '',
        comprobantePago: anticipo > 0 && metodoAnticipo == 'transferencia'
            ? comprobante.trim()
            : '',
        notas: notas.trim(),
      );
      final id = _entero(result['id']);
      mensaje = 'Cita creada (#$id).';
      busy = false;
      notifyListeners();
      return id;
    } catch (e) {
      errorMessage = e.toString();
      busy = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> cargarCitasCliente(int clienteId) async {
    citasClienteState = LoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      citasCliente = await _secretaria.citasDeCliente(clienteId);
      citasClienteState = citasCliente.isEmpty
          ? LoadState.empty
          : LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      citasClienteState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> cargarEditable(int citaId) async {
    _limpiarSeleccion();
    editableState = LoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      editable = await _secretaria.citaEditable(citaId);
      final actual = editable!;
      if (!actual.puedeEditar) {
        editableState = LoadState.ready;
        notifyListeners();
        return;
      }
      fecha = actual.fecha;
      hora = _hora(actual.hora);
      notas = actual.notas;
      await cargarServicios();
      final coincidencia = servicios.where((s) => s.id == actual.servicioId);
      if (coincidencia.isNotEmpty) {
        await elegirServicio(coincidencia.first);
      } else if (actual.servicioId > 0) {
        servicio = ServicioDto(
          id: actual.servicioId,
          nombre: actual.servicioNombre,
          descripcion: '',
          precio: actual.servicioPrecio > 0
              ? actual.servicioPrecio
              : actual.precioTotal,
          duracionMinutos: actual.duracionMinutos,
          categoria: '',
          popular: false,
          activo: true,
          imagenUrl: '',
          bannerUrl: '',
        );
        barberos = await _citas.getBarberos(servicioId: actual.servicioId);
      }
      final barberoActual = barberos.where((b) => b.id == actual.barberoId);
      if (barberoActual.isNotEmpty) {
        barbero = barberoActual.first;
      } else if (actual.barberoId > 0) {
        barbero = BarberoDto(
          id: actual.barberoId,
          nombre: 'Barbero',
          apellido: '#${actual.barberoId}',
          especialidades: '',
          avatarUrl: '',
          serviciosIds: const [],
        );
      }
      hora = _hora(actual.hora);
      await _cargarHorarios();
      editableState = LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      editableState = LoadState.error;
    }
    notifyListeners();
  }

  Future<bool> reprogramar() async {
    final actual = editable;
    if (busy || actual == null) return false;
    if (!actual.puedeEditar) {
      errorMessage = 'El servidor no permite modificar esta cita.';
      notifyListeners();
      return false;
    }
    if (servicio == null || barbero == null || hora == null || fecha.isEmpty) {
      errorMessage = 'Elige servicio, barbero, fecha y un horario disponible.';
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    mensaje = null;
    notifyListeners();
    try {
      final result = await _secretaria.actualizarCita(
        citaId: actual.id,
        barberoId: barbero!.id,
        servicioId: servicio!.id,
        fecha: fecha,
        hora: hora!,
        precioTotal: _precioEdicion(actual),
        anticipoPagado: actual.anticipoPagado,
        metodoAnticipo: actual.metodoAnticipo,
        notas: notas.trim(),
      );
      mensaje = (result['mensaje'] ?? 'Cita actualizada correctamente.')
          .toString();
      busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelarCita() async {
    final actual = editable;
    if (busy || actual == null || !actual.puedeEditar) return false;
    if (servicio == null || barbero == null || hora == null || fecha.isEmpty) {
      errorMessage = 'No hay datos suficientes para cancelar esta cita.';
      notifyListeners();
      return false;
    }
    busy = true;
    errorMessage = null;
    mensaje = null;
    notifyListeners();
    try {
      final result = await _secretaria.actualizarCita(
        citaId: actual.id,
        barberoId: barbero!.id,
        servicioId: servicio!.id,
        fecha: actual.fecha,
        hora: _hora(actual.hora),
        precioTotal: actual.precioTotal,
        anticipoPagado: actual.anticipoPagado,
        metodoAnticipo: actual.metodoAnticipo,
        notas: actual.notas,
        cancelar: true,
      );
      mensaje = (result['mensaje'] ?? 'Cita actualizada correctamente.')
          .toString();
      busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      busy = false;
      notifyListeners();
      return false;
    }
  }

  double anticipoMinimo(double precio) {
    final pol = politica;
    if (pol == null || (!pol.penalizado && !pol.requiereAnticipo)) return 0;
    final minimo = precio * pol.porcentajeAnticipo / 100;
    return minimo < 0.01 && pol.penalizado ? 0.01 : minimo;
  }

  Future<void> _cargarHorarios() async {
    final servicioActual = servicio;
    final barberoActual = barbero;
    if (servicioActual == null || barberoActual == null || fecha.isEmpty) {
      return;
    }
    slotsLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      slots = await _citas.getDisponibilidad(
        barberoId: barberoActual.id,
        fecha: fecha,
        duracion: servicioActual.duracionMinutos,
      );
    } catch (e) {
      errorMessage = e.toString();
      slots = const [];
    }
    slotsLoading = false;
    notifyListeners();
  }

  String? _validarNueva() {
    if (cliente == null) return 'Selecciona un cliente.';
    if (servicio == null) return 'Selecciona un servicio.';
    if (barbero == null) return 'Selecciona un barbero.';
    if (fecha.isEmpty) return 'Selecciona una fecha.';
    if (hora == null) return 'Selecciona un horario disponible.';
    final precio = _precioNueva(servicio!);
    final anticipo = _anticipo();
    if (anticipo == null) return 'El anticipo no es un monto válido.';
    final minimo = anticipoMinimo(precio);
    if (minimo > 0 && anticipo + 0.001 < minimo) {
      return 'Cliente penalizado: el anticipo mínimo es ${minimo.toStringAsFixed(2)}.';
    }
    if (anticipo > precio) return 'El anticipo no puede superar el precio.';
    if (anticipo > 0 &&
        metodoAnticipo == 'transferencia' &&
        comprobante.trim().isEmpty) {
      return 'La transferencia requiere comprobante o referencia.';
    }
    return null;
  }

  double _precioNueva(ServicioDto value) => value.precio;

  double _precioEdicion(SecretariaCitaEditableDto actual) {
    if (servicio?.id == actual.servicioId) return actual.precioTotal;
    return servicio?.precio ?? actual.precioTotal;
  }

  double? _anticipo() {
    final raw = anticipoTexto.trim().replaceAll(',', '.');
    if (raw.isEmpty) return 0;
    return double.tryParse(raw);
  }

  void _limpiarSeleccion() {
    cliente = null;
    servicio = null;
    barbero = null;
    hora = null;
    anticipoTexto = '';
    metodoAnticipo = 'efectivo';
    comprobante = '';
    notas = '';
    politica = null;
    editable = null;
    barberos = const [];
    slots = const [];
    clientes = const [];
    mensaje = null;
    errorMessage = null;
    busy = false;
  }

  static String _hora(String value) {
    final raw = value.trim();
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  static int _entero(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
