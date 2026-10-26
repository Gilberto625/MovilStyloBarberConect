import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/cita_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/client_citas_viewmodel.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import '../guest/guest_contacto_view.dart';
import 'client_reprogramar_view.dart';
import 'client_widgets.dart';

enum _Filtro { proximas, historial }

/// Cliente › Pantalla 6: Mis citas, separadas en próximas e historial.
class ClientCitasTab extends StatefulWidget {
  const ClientCitasTab({super.key, required this.onAgendar});

  final VoidCallback onAgendar;

  @override
  State<ClientCitasTab> createState() => _ClientCitasTabState();
}

class _ClientCitasTabState extends State<ClientCitasTab> {
  var _filtro = _Filtro.proximas;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClientCitasViewModel>();
    final proximas = vm.citas.where(esCitaProxima).toList()
      ..sort(
        (a, b) => '${a.fecha} ${a.hora}'.compareTo('${b.fecha} ${b.hora}'),
      );
    final historial = vm.citas.where((c) => !esCitaProxima(c)).toList()
      ..sort(
        (a, b) => '${b.fecha} ${b.hora}'.compareTo('${a.fecha} ${a.hora}'),
      );
    final visibles = _filtro == _Filtro.proximas ? proximas : historial;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClientHeader(
            title: 'Mis citas',
            subtitle: 'Lo que la barbería tiene registrado a tu nombre.',
            trailing: IconButton(
              tooltip: 'Actualizar citas',
              onPressed: vm.state == LoadState.loading ? null : vm.loadMisCitas,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          if (vm.citas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: SegmentedButton<_Filtro>(
                key: const Key('citas_filtro'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _Filtro.proximas,
                    label: Text('Próximas (${proximas.length})'),
                  ),
                  ButtonSegment(
                    value: _Filtro.historial,
                    label: Text('Historial (${historial.length})'),
                  ),
                ],
                selected: {_filtro},
                onSelectionChanged: (s) => setState(() => _filtro = s.first),
              ),
            ),
          Expanded(child: _cuerpo(context, vm, visibles)),
        ],
      ),
    );
  }

  Widget _cuerpo(
    BuildContext context,
    ClientCitasViewModel vm,
    List<CitaDto> visibles,
  ) {
    if (vm.citas.isEmpty &&
        (vm.state == LoadState.loading || vm.state == LoadState.idle)) {
      return const LoadingView(label: 'Cargando citas…');
    }
    if (vm.citas.isEmpty && vm.state == LoadState.error) {
      return ErrorView(
        title: 'No se pudieron cargar tus citas',
        message: vm.errorMessage ?? 'Revisa tu conexión y reintenta.',
        onRetry: vm.loadMisCitas,
      );
    }
    if (vm.citas.isEmpty) {
      return EmptyView(
        icon: Icons.event_available_outlined,
        title: 'Aún no tienes citas.',
        message: 'Agenda la primera y aparecerá aquí.',
        actionLabel: 'Agendar cita',
        onRetry: widget.onAgendar,
      );
    }
    return RefreshIndicator(
      onRefresh: vm.loadMisCitas,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.xxxl,
        ),
        children: [
          if (vm.errorMessage != null) ...[
            StatusBanner(
              tone: BannerTone.aviso,
              message:
                  'No se pudo actualizar: ${vm.errorMessage}. '
                  'Mostramos lo último que cargaste.',
            ),
          ],
          if (visibles.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: Text(
                _filtro == _Filtro.proximas
                    ? 'No tienes citas próximas.'
                    : 'Todavía no hay citas en tu historial.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.muted),
              ),
            ),
          for (final c in visibles) ...[
            CitaRow(
              cita: c,
              onTap: () => Navigator.push(
                context,
                AppRoutes.page<void>(CitaDetalleView(cita: c)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

/// Fila de cita de 72 dp o más: bloque de fecha, servicio, hora y estado.
class CitaRow extends StatelessWidget {
  const CitaRow({super.key, required this.cita, required this.onTap});

  final CitaDto cita;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final corta = fechaCorta(cita.fecha);
    return SurfaceCard(
      key: ValueKey('cita-${cita.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      semanticLabel:
          '${cita.servicioNombre}, ${fechaLarga(cita.fecha)} a las '
          '${horaCorta(cita.hora)}, ${EstadoChip.etiqueta(cita.estado)}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.appointmentRow - AppSpacing.md * 2,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: AppRadii.controlBorder,
                ),
                child: Column(
                  children: [
                    Text(
                      corta?.dia ?? '–',
                      style: AppText.cifra(size: 22, weight: FontWeight.w800),
                    ),
                    Text(
                      corta?.mes ?? '',
                      style: theme.labelSmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita.servicioNombre,
                      style: theme.titleMedium?.copyWith(
                        color: AppColors.ivory,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${horaCorta(cita.hora)} con ${cita.barberoNombre}',
                      style: theme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    EstadoChip(estado: cita.estado),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cliente › Pantalla 7: detalle de cita.
class CitaDetalleView extends StatelessWidget {
  const CitaDetalleView({super.key, required this.cita});

  final CitaDto cita;

  static String _limiteTexto(DateTime l) {
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '${fechaEnFrase(isoFecha(l))} a las $hh:$mm';
  }

  Future<void> _reprogramar(BuildContext context) async {
    context.read<ClientCitasViewModel>().limpiarCambio();
    final mensaje = await Navigator.push<String>(
      context,
      AppRoutes.page<String>(ReprogramarCitaView(cita: cita)),
    );
    if (!context.mounted || mensaje == null) return;
    _volverConMensaje(context, mensaje);
  }

  Future<void> _cancelar(BuildContext context) async {
    final vm = context.read<ClientCitasViewModel>()..limpiarCambio();
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => _CancelarCitaDialog(cita: cita),
    );
    if (!context.mounted || motivo == null) return;
    final ok = await vm.cancelarCita(cita, motivo: motivo);
    if (!context.mounted || !ok) return;
    _volverConMensaje(context, vm.cambioMensaje ?? 'Tu cita quedó cancelada.');
  }

  void _volverConMensaje(BuildContext context, String mensaje) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final abierta = !estadosCerrados.contains(cita.estado);
    // El contacto lo publica el backend; sin proveedor no se muestra.
    final contacto = Provider.of<HomeGuestViewModel?>(context)?.contacto;
    final tel = contacto == null ? null : enlaceTelefono(contacto.telefono);
    final wa = contacto == null ? null : enlaceWebSeguro(contacto.whatsappUrl);
    // Sin proveedor (pruebas de la vista sola) no se ofrecen cambios.
    final vm = Provider.of<ClientCitasViewModel?>(context);
    final ocupado = vm == null || vm.cambioBusy;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de cita')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xxxl,
          ),
          children: [
            CitaTicket(cita: cita),
            const SectionHeader(title: 'Pago'),
            SurfaceCard(
              child: Column(
                children: [
                  InfoRow(
                    label: 'Total',
                    value: moneyFormat.format(cita.precioTotal),
                    emphasis: true,
                  ),
                  if (cita.anticipoPagado > 0)
                    InfoRow(
                      label: 'Anticipo pagado',
                      value: moneyFormat.format(cita.anticipoPagado),
                    ),
                  InfoRow(
                    label: 'Por pagar',
                    value: moneyFormat.format(cita.saldoPendiente),
                  ),
                ],
              ),
            ),
            if (cita.notas.trim().isNotEmpty) ...[
              const SectionHeader(title: 'Notas'),
              Text(cita.notas, style: theme.bodyLarge),
            ],
            if (abierta && cita.puedeModificar && cita.barberoId != null) ...[
              const SectionHeader(title: '¿Necesitas cambiarla?'),
              Text(
                cita.limiteModificacion == null
                    ? 'Puedes moverla a otro horario o cancelarla.'
                    : 'Puedes moverla a otro horario o cancelarla hasta el '
                          '${_limiteTexto(cita.limiteModificacion!)}.',
                style: theme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              if (vm?.cambioError != null) ...[
                const SizedBox(height: AppSpacing.md),
                StatusBanner(
                  key: const Key('cita_cambio_error'),
                  message: vm!.cambioError!,
                  isError: true,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  FilledButton.icon(
                    key: const Key('cita_reprogramar'),
                    onPressed: ocupado ? null : () => _reprogramar(context),
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: const Text('Reprogramar'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('cita_cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.crit,
                      side: const BorderSide(color: AppColors.crit),
                    ),
                    onPressed: ocupado ? null : () => _cancelar(context),
                    icon: vm?.cambioBusy == true
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.event_busy_outlined),
                    label: const Text('Cancelar cita'),
                  ),
                ],
              ),
            ] else if (abierta) ...[
              const SectionHeader(title: '¿Necesitas cambiarla?'),
              Text(
                cita.motivoNoModificable.isNotEmpty
                    ? cita.motivoNoModificable
                    : 'Los cambios de esta cita los hace la barbería. Avisa con '
                          'tiempo: si faltas sin avisar, tus siguientes citas '
                          'pueden pedir un anticipo.',
                style: theme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              if (tel != null || wa != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    if (tel != null)
                      OutlinedButton.icon(
                        key: const Key('cita_llamar'),
                        onPressed: () => abrirEnlace(
                          context,
                          tel,
                          respaldo: contacto!.telefono,
                          que: 'el marcador',
                        ),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Llamar'),
                      ),
                    if (wa != null)
                      OutlinedButton.icon(
                        key: const Key('cita_whatsapp'),
                        onPressed: () => abrirEnlace(
                          context,
                          wa,
                          respaldo: contacto!.whatsappUrl,
                          que: 'WhatsApp',
                        ),
                        icon: const Icon(Icons.chat_outlined),
                        label: const Text('WhatsApp'),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirmación para cancelar: dice qué se libera y, si hubo anticipo, que lo
/// resuelve la barbería. Devuelve el motivo (puede ir vacío) o null si se
/// conserva la cita. El controlador vive en este State para que no se libere
/// mientras el diálogo termina de cerrarse (ERR-01).
class _CancelarCitaDialog extends StatefulWidget {
  const _CancelarCitaDialog({required this.cita});

  final CitaDto cita;

  @override
  State<_CancelarCitaDialog> createState() => _CancelarCitaDialogState();
}

class _CancelarCitaDialogState extends State<_CancelarCitaDialog> {
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final c = widget.cita;
    return AlertDialog(
      icon: const Icon(Icons.event_busy_outlined, color: AppColors.crit),
      title: const Text('¿Cancelar tu cita?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${c.servicioNombre}, ${fechaEnFrase(c.fecha)} a las '
              '${horaCorta(c.hora)}. El horario queda libre para otra persona.',
              style: theme.bodyLarge,
            ),
            if (c.anticipoPagado > 0) ...[
              const SizedBox(height: AppSpacing.md),
              StatusBanner(
                tone: BannerTone.aviso,
                message:
                    'Pagaste ${moneyFormat.format(c.anticipoPagado)} de '
                    'anticipo. La barbería te dirá qué sigue con ese pago.',
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('cita_cancelar_motivo'),
              controller: _motivo,
              maxLength: 300,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cita_cancelar_conservar'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Conservar cita'),
        ),
        FilledButton(
          key: const Key('cita_cancelar_confirmar'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.crit,
            foregroundColor: AppColors.onGold,
          ),
          onPressed: () => Navigator.pop(context, _motivo.text.trim()),
          child: const Text('Sí, cancelar'),
        ),
      ],
    );
  }
}
