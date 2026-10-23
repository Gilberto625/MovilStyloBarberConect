class CitaDto {
  const CitaDto({
    required this.id,
    required this.servicioId,
    required this.servicioNombre,
    required this.servicioImagen,
    required this.fecha,
    required this.hora,
    required this.duracionMinutos,
    required this.estado,
    required this.precioTotal,
    required this.anticipoPagado,
    required this.saldoPendiente,
    required this.notas,
    required this.barberoNombre,
    required this.requierePago,
    this.barberoId,
    this.puedeModificar = false,
    this.motivoNoModificable = '',
    this.limiteModificacion,
  });

  final int id;
  final int servicioId;
  final String servicioNombre;
  final String servicioImagen;
  final String fecha;
  final String hora;
  final int duracionMinutos;
  final String estado;
  final double precioTotal;
  final double anticipoPagado;
  final double saldoPendiente;
  final String notas;
  final String barberoNombre;
  final bool requierePago;

  /// Empleado que atiende; sirve para pedir horarios al reprogramar.
  final int? barberoId;

  /// El backend decide si el cliente aún puede cancelar o reprogramar
  /// (estado y anticipación mínima). La app no recalcula esa regla.
  final bool puedeModificar;
  final String motivoNoModificable;

  /// Hasta cuándo se puede cambiar, en ISO 8601 con zona horaria.
  final DateTime? limiteModificacion;

  factory CitaDto.fromJson(Map<String, dynamic> json) {
    return CitaDto(
      id: _i(json['id']),
      servicioId: _i(json['servicio_id']),
      servicioNombre: (json['servicio_nombre'] ?? '').toString(),
      servicioImagen: (json['servicio_imagen'] ?? '').toString(),
      fecha: (json['fecha'] ?? '').toString(),
      hora: (json['hora'] ?? '').toString(),
      duracionMinutos: _i(json['duracion_minutos']),
      estado: (json['estado'] ?? '').toString(),
      precioTotal: _d(json['precio_total']),
      anticipoPagado: _d(json['anticipo_pagado']),
      saldoPendiente: _d(json['saldo_pendiente']),
      notas: (json['notas'] ?? '').toString(),
      barberoNombre: (json['barbero_nombre'] ?? 'Barbero').toString(),
      requierePago: json['requiere_pago'] == true,
      barberoId: int.tryParse('${json['barbero_id']}'),
      puedeModificar: json['puede_modificar'] == true,
      motivoNoModificable: (json['motivo_no_modificable'] ?? '').toString(),
      limiteModificacion: DateTime.tryParse(
        (json['limite_modificacion'] ?? '').toString(),
      ),
    );
  }

  static int _i(Object? v) => int.tryParse('$v') ?? 0;
  static double _d(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}

class BarberoDto {
  const BarberoDto({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.especialidades,
    required this.avatarUrl,
    required this.serviciosIds,
  });

  final int id;
  final String nombre;
  final String apellido;
  final String especialidades;
  final String avatarUrl;
  final List<int> serviciosIds;

  String get displayName {
    final n = '$nombre $apellido'.trim();
    return n.isEmpty ? 'Barbero' : n;
  }

  factory BarberoDto.fromJson(Map<String, dynamic> json) {
    final raw = json['servicios_ids'];
    final ids = <int>[];
    if (raw is List) {
      for (final e in raw) {
        final v = int.tryParse('$e');
        if (v != null) ids.add(v);
      }
    }
    return BarberoDto(
      id: CitaDto._i(json['id']),
      nombre: (json['nombre'] ?? '').toString(),
      apellido: (json['apellido'] ?? '').toString(),
      especialidades: (json['especialidades'] ?? '').toString(),
      avatarUrl: (json['avatar_url'] ?? '').toString(),
      serviciosIds: ids,
    );
  }
}

class SlotDisponibilidad {
  const SlotDisponibilidad({required this.hora, required this.disponible});

  final String hora;
  final bool disponible;

  factory SlotDisponibilidad.fromJson(Map<String, dynamic> json) {
    return SlotDisponibilidad(
      hora: (json['hora'] ?? '').toString(),
      disponible: json['disponible'] == true,
    );
  }
}

class PoliticaPagoDto {
  const PoliticaPagoDto({
    required this.requiereAnticipo,
    required this.porcentajeAnticipo,
    required this.penalizado,
    required this.totalInasistencias,
  });

  final bool requiereAnticipo;
  final double porcentajeAnticipo;
  final bool penalizado;
  final int totalInasistencias;

  factory PoliticaPagoDto.fromJson(Map<String, dynamic> json) {
    return PoliticaPagoDto(
      requiereAnticipo: json['requiere_anticipo'] == true,
      porcentajeAnticipo: CitaDto._d(json['porcentaje_anticipo']),
      penalizado: json['penalizado'] == true,
      totalInasistencias: CitaDto._i(json['total_inasistencias']),
    );
  }
}

class SecretariaCitaDto {
  const SecretariaCitaDto({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteTelefono,
    required this.servicioNombre,
    required this.barberoNombre,
    required this.fecha,
    required this.hora,
    required this.duracionMinutos,
    required this.estado,
    required this.precioTotal,
    required this.anticipoPagado,
    required this.anticipoPendiente,
    required this.restante,
    required this.puedeCobrar,
    required this.puedeMarcarAsistencia,
    required this.clientePenalizado,
    this.penalizacionPorcentaje = 0,
    this.penalizacionInasistencias = 0,
    this.penalizacionCitasRestantes = 0,
  });

  final int id;
  final int clienteId;
  final String clienteNombre;
  final String clienteTelefono;
  final String servicioNombre;
  final String barberoNombre;
  final String fecha;
  final String hora;
  final int duracionMinutos;
  final String estado;
  final double precioTotal;
  final double anticipoPagado;
  final double anticipoPendiente;
  final double restante;
  final bool puedeCobrar;
  final bool puedeMarcarAsistencia;
  final bool clientePenalizado;
  final double penalizacionPorcentaje;
  final int penalizacionInasistencias;
  final int penalizacionCitasRestantes;

  factory SecretariaCitaDto.fromJson(Map<String, dynamic> json) {
    final penalizacion = json['penalizacion'];
    final pen = penalizacion is Map
        ? Map<String, dynamic>.from(penalizacion)
        : const <String, dynamic>{};
    return SecretariaCitaDto(
      id: CitaDto._i(json['id']),
      clienteId: CitaDto._i(json['cliente_id']),
      clienteNombre: (json['cliente_nombre'] ?? 'Cliente').toString(),
      clienteTelefono: (json['cliente_telefono'] ?? '').toString(),
      servicioNombre: (json['servicio_nombre'] ?? '').toString(),
      barberoNombre: (json['barbero_nombre'] ?? 'Barbero').toString(),
      fecha: (json['fecha'] ?? '').toString(),
      hora: (json['hora'] ?? '').toString(),
      duracionMinutos: CitaDto._i(json['duracion_minutos']),
      estado: (json['estado'] ?? '').toString(),
      precioTotal: CitaDto._d(json['precio_total']),
      anticipoPagado: CitaDto._d(json['anticipo_pagado']),
      anticipoPendiente: CitaDto._d(json['anticipo_pendiente']),
      restante: CitaDto._d(json['restante']),
      puedeCobrar: json['puede_cobrar'] == true,
      puedeMarcarAsistencia: json['puede_marcar_asistencia'] == true,
      clientePenalizado: json['cliente_penalizado'] == true,
      penalizacionPorcentaje: CitaDto._d(pen['porcentaje_anticipo']),
      penalizacionInasistencias: CitaDto._i(pen['total_inasistencias']),
      penalizacionCitasRestantes: CitaDto._i(pen['citas_restantes']),
    );
  }
}

class SecretariaDiaDto {
  const SecretariaDiaDto({
    required this.fecha,
    required this.esHoy,
    required this.citas,
    required this.total,
    required this.pendientesAccion,
    required this.enCurso,
    required this.completadas,
    required this.noAsistio,
  });

  final String fecha;
  final bool esHoy;
  final List<SecretariaCitaDto> citas;
  final int total;
  final int pendientesAccion;
  final int enCurso;
  final int completadas;
  final int noAsistio;

  factory SecretariaDiaDto.fromJson(Map<String, dynamic> json) {
    final resumen = Map<String, dynamic>.from(json['resumen'] as Map? ?? {});
    final raw = json['citas'];
    final list = <SecretariaCitaDto>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          list.add(SecretariaCitaDto.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return SecretariaDiaDto(
      fecha: (json['fecha'] ?? '').toString(),
      esHoy: json['es_hoy'] == true,
      citas: list,
      total: CitaDto._i(resumen['total']),
      pendientesAccion: CitaDto._i(resumen['pendientes_accion']),
      enCurso: CitaDto._i(resumen['en_curso']),
      completadas: CitaDto._i(resumen['completadas']),
      noAsistio: CitaDto._i(resumen['no_asistio']),
    );
  }
}

class SecretariaClienteDto {
  const SecretariaClienteDto({
    required this.id,
    required this.nombreCompleto,
    required this.telefono,
    required this.email,
    required this.esAnonimo,
  });

  final int id;
  final String nombreCompleto;
  final String telefono;
  final String email;
  final bool esAnonimo;

  factory SecretariaClienteDto.fromJson(Map<String, dynamic> json) {
    return SecretariaClienteDto(
      id: CitaDto._i(json['id']),
      nombreCompleto: (json['nombre_completo'] ?? 'Cliente').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      esAnonimo: json['es_anonimo'] == true,
    );
  }
}

class SecretariaCitaResumenDto {
  const SecretariaCitaResumenDto({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.servicio,
    required this.barbero,
    required this.estado,
    required this.precioTotal,
    required this.creadoPor,
    required this.puedeEditar,
  });

  final int id;
  final String fecha;
  final String hora;
  final String servicio;
  final String barbero;
  final String estado;
  final double precioTotal;
  final String creadoPor;
  final bool puedeEditar;

  factory SecretariaCitaResumenDto.fromJson(Map<String, dynamic> json) {
    return SecretariaCitaResumenDto(
      id: CitaDto._i(json['id']),
      fecha: (json['fecha'] ?? '').toString(),
      hora: (json['hora'] ?? '').toString(),
      servicio: (json['servicio'] ?? '').toString(),
      barbero: (json['barbero'] ?? '').toString(),
      estado: (json['estado'] ?? '').toString(),
      precioTotal: CitaDto._d(json['precio_total']),
      creadoPor: (json['creado_por'] ?? '').toString(),
      puedeEditar: json['puede_editar'] == true,
    );
  }
}

class SecretariaCitaEditableDto {
  const SecretariaCitaEditableDto({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.barberoId,
    required this.servicioId,
    required this.servicioNombre,
    required this.servicioPrecio,
    required this.fecha,
    required this.hora,
    required this.duracionMinutos,
    required this.estado,
    required this.precioTotal,
    required this.notas,
    required this.anticipoPagado,
    required this.metodoAnticipo,
    required this.puedeEditar,
    required this.fechaMinima,
  });

  final int id;
  final int clienteId;
  final String clienteNombre;
  final int barberoId;
  final int servicioId;
  final String servicioNombre;
  final double servicioPrecio;
  final String fecha;
  final String hora;
  final int duracionMinutos;
  final String estado;
  final double precioTotal;
  final String notas;
  final double anticipoPagado;
  final String metodoAnticipo;
  final bool puedeEditar;
  final String fechaMinima;

  factory SecretariaCitaEditableDto.fromResponse(Map<String, dynamic> json) {
    final raw = json['cita'];
    final cita = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    return SecretariaCitaEditableDto(
      id: CitaDto._i(cita['id']),
      clienteId: CitaDto._i(cita['cliente_id']),
      clienteNombre: (cita['cliente_nombre'] ?? 'Cliente').toString(),
      barberoId: CitaDto._i(cita['barbero_id']),
      servicioId: CitaDto._i(cita['servicio_id']),
      servicioNombre: (cita['servicio_nombre'] ?? '').toString(),
      servicioPrecio: CitaDto._d(cita['servicio_precio']),
      fecha: (cita['fecha'] ?? '').toString(),
      hora: (cita['hora'] ?? '').toString(),
      duracionMinutos: CitaDto._i(cita['duracion_minutos']),
      estado: (cita['estado'] ?? '').toString(),
      precioTotal: CitaDto._d(cita['precio_total']),
      notas: (cita['notas'] ?? '').toString(),
      anticipoPagado: CitaDto._d(cita['anticipo_pagado']),
      metodoAnticipo: (cita['metodo_anticipo'] ?? 'ninguno').toString(),
      puedeEditar: cita['puede_editar'] == true,
      fechaMinima: (json['fecha_minima'] ?? '').toString(),
    );
  }
}
