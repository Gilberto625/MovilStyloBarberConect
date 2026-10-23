/// Cita de la agenda del barbero (`GET /api/barbero/agenda/`).
class BarberoCitaDto {
  const BarberoCitaDto({
    required this.id,
    required this.hora,
    required this.duracionMinutos,
    required this.servicioNombre,
    required this.clienteNombre,
    required this.estado,
    required this.atencion,
    required this.notas,
    required this.complementos,
    required this.puedeIniciar,
    required this.puedeTerminar,
  });

  final int id;
  final String hora;
  final int duracionMinutos;
  final String servicioNombre;
  final String clienteNombre;
  final String estado;

  /// `por_atender`, `en_silla`, `terminada`, `completada` o `no_asistio`.
  final String atencion;
  final String notas;
  final String complementos;

  /// Las decide el servidor: solo citas de hoy y en el estado correcto.
  final bool puedeIniciar;
  final bool puedeTerminar;

  factory BarberoCitaDto.fromJson(Map<String, dynamic> json) {
    return BarberoCitaDto(
      id: int.tryParse('${json['id']}') ?? 0,
      hora: (json['hora'] ?? '').toString(),
      duracionMinutos: int.tryParse('${json['duracion_minutos']}') ?? 0,
      servicioNombre: (json['servicio_nombre'] ?? '').toString(),
      clienteNombre: (json['cliente_nombre'] ?? 'Cliente').toString(),
      estado: (json['estado'] ?? '').toString(),
      atencion: (json['atencion'] ?? '').toString(),
      notas: (json['notas'] ?? '').toString(),
      complementos: (json['complementos'] ?? '').toString(),
      puedeIniciar: json['puede_iniciar'] == true,
      puedeTerminar: json['puede_terminar'] == true,
    );
  }
}

class BarberoAgendaDto {
  const BarberoAgendaDto({
    required this.fecha,
    required this.esHoy,
    required this.citas,
  });

  final String fecha;
  final bool esHoy;
  final List<BarberoCitaDto> citas;

  factory BarberoAgendaDto.fromJson(Map<String, dynamic> json) {
    final raw = json['citas'];
    return BarberoAgendaDto(
      fecha: (json['fecha'] ?? '').toString(),
      esHoy: json['es_hoy'] == true,
      citas: raw is List
          ? raw
                .whereType<Map>()
                .map(
                  (e) => BarberoCitaDto.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}
