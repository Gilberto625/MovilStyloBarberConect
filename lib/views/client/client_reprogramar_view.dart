import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/cita_models.dart';
import '../../viewmodels/client_citas_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import 'client_agendar_view.dart';
import 'client_widgets.dart';

/// Cliente › Reprogramar cita (S6-02, PM05): mismo servicio y barbero, otro
/// día u hora. Los horarios libres y la regla de anticipación los decide
/// Django; si el horario ya no está libre, se muestra su mensaje.
class ReprogramarCitaView extends StatefulWidget {
  const ReprogramarCitaView({super.key, required this.cita, this.hoy});

  final CitaDto cita;

  /// Solo para pruebas: fija el día de hoy.
  final DateTime? hoy;

  @override
  State<ReprogramarCitaView> createState() => _ReprogramarCitaViewState();
}

class _ReprogramarCitaViewState extends State<ReprogramarCitaView> {
  late DateTime _fecha;
  String? _hora;

  DateTime get _hoy {
    final h = widget.hoy ?? DateTime.now();
    return DateTime(h.year, h.month, h.day);
  }

  @override
  void initState() {
    super.initState();
    final actual = DateTime.tryParse(widget.cita.fecha);
    _fecha = actual != null && !actual.isBefore(_hoy) ? actual : _hoy;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClientCitasViewModel>().limpiarCambio();
      _cargarHorarios();
    });
  }

  Future<void> _cargarHorarios() async {
    final barberoId = widget.cita.barberoId;
    if (barberoId == null) return;
    await context.read<ClientCitasViewModel>().loadDisponibilidad(
      barberoId: barberoId,
      fecha: isoFecha(_fecha),
      duracion: widget.cita.duracionMinutos,
    );
  }

  Future<void> _elegirFecha(DateTime d) async {
    setState(() {
      _fecha = d;
      _hora = null;
    });
    await _cargarHorarios();
  }

  Future<void> _otraFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: _hoy,
      lastDate: _hoy.add(const Duration(days: 60)),
      helpText: 'Elige el nuevo día',
    );
    if (!mounted || picked == null) return;
    await _elegirFecha(picked);
  }

  Future<void> _confirmar() async {
    final hora = _hora;
    if (hora == null) return;
    final vm = context.read<ClientCitasViewModel>();
    final ok = await vm.reprogramarCita(
      widget.cita,
      fecha: isoFecha(_fecha),
      hora: horaCorta(hora),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(vm.cambioMensaje);
    } else {
      // El horario pudo ocuparse mientras tanto: se recargan los libres.
      setState(() => _hora = null);
      await _cargarHorarios();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClientCitasViewModel>();
    final theme = Theme.of(context).textTheme;
    final c = widget.cita;
    final hora = _hora;
    return Scaffold(
      appBar: AppBar(title: const Text('Reprogramar cita')),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.servicioNombre,
                      style: theme.titleMedium?.copyWith(
                        color: AppColors.ivory,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ahora: ${fechaLarga(c.fecha)} a las '
                      '${horaCorta(c.hora)} con ${c.barberoNombre}',
                      style: theme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            if (vm.cambioError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  AppSpacing.md,
                ),
                child: StatusBanner(
                  key: const Key('reprogramar_error'),
                  message: vm.cambioError!,
                  isError: true,
                ),
              ),
            Expanded(
              child: c.barberoId == null
                  ? const EmptyView(
                      icon: Icons.event_busy_outlined,
                      title: 'No se pueden consultar horarios',
                      message:
                          'Actualiza tus citas e intenta de nuevo, o '
                          'comunícate con la barbería.',
                    )
                  : SelectorHorario(
                      keyPrefix: 'reprogramar',
                      hoy: _hoy,
                      fecha: _fecha,
                      hora: hora,
                      onFecha: _elegirFecha,
                      onOtraFecha: _otraFecha,
                      onHora: (h) => setState(() => _hora = h),
                    ),
            ),
            if (hora != null)
              BarraAccion(
                key: const Key('reprogramar_confirmar'),
                label:
                    'Mover al ${fechaLarga(isoFecha(_fecha))}, '
                    '${horaCorta(hora)}',
                busy: vm.cambioBusy,
                onPressed: _confirmar,
              ),
          ],
        ),
      ),
    );
  }
}
