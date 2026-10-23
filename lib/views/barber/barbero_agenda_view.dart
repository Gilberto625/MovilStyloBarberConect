import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/barbero_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/barbero_agenda_viewmodel.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import '../client/client_widgets.dart';

/// Barbero › Mi agenda (S7-01..03, PM06): sus citas del día y el estado de
/// atención. Iniciar y terminar solo aplican a citas de hoy; "no asistió" y el
/// cobro siguen siendo de secretaría. Todo lo autoriza Django.
class BarberoAgendaView extends StatefulWidget {
  const BarberoAgendaView({super.key});

  @override
  State<BarberoAgendaView> createState() => _BarberoAgendaViewState();
}

class _BarberoAgendaViewState extends State<BarberoAgendaView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BarberoAgendaViewModel>().load();
    });
  }

  Future<void> _elegirFecha(BarberoAgendaViewModel vm) async {
    final actual = DateTime.tryParse(vm.agenda?.fecha ?? '') ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      helpText: 'Elige el día',
    );
    if (picked == null || !mounted) return;
    await vm.load(fecha: isoFecha(picked));
  }

  Future<void> _salir() async {
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.guestHome,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BarberoAgendaViewModel>();
    final agenda = vm.agenda;
    final header = ClientHeader(
      title: agenda == null || agenda.esHoy ? 'Mi agenda de hoy' : 'Mi agenda',
      subtitle: agenda == null
          ? 'Tus citas asignadas'
          : '${fechaLarga(agenda.fecha)}, ${_citasTexto(agenda.citas.length)}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Actualizar agenda',
            onPressed: vm.state == LoadState.loading
                ? null
                : () => vm.load(fecha: vm.fecha),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            key: const Key('barbero_cerrar_sesion'),
            tooltip: 'Cerrar sesión',
            onPressed: _salir,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );

    Widget cuerpo;
    if (agenda == null &&
        (vm.state == LoadState.loading || vm.state == LoadState.idle)) {
      cuerpo = const LoadingView(label: 'Cargando tu agenda…');
    } else if (agenda == null && vm.state == LoadState.error) {
      cuerpo = ErrorView(
        title: 'No se pudo cargar tu agenda',
        message: vm.errorMessage ?? 'Revisa tu conexión y reintenta.',
        onRetry: () => vm.load(fecha: vm.fecha),
      );
    } else {
      cuerpo = RefreshIndicator(
        onRefresh: () => vm.load(fecha: vm.fecha),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.xxxl,
          ),
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  key: const Key('barbero_otro_dia'),
                  onPressed: () => _elegirFecha(vm),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('Otro día'),
                ),
                if (vm.fecha != null)
                  TextButton(
                    key: const Key('barbero_hoy'),
                    onPressed: () => vm.load(),
                    child: const Text('Volver a hoy'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (vm.accionMensaje != null && vm.accionMensaje!.isNotEmpty)
              StatusBanner(tone: BannerTone.ok, message: vm.accionMensaje!),
            if (vm.accionError != null)
              StatusBanner(
                key: const Key('barbero_error'),
                message: vm.accionError!,
                isError: true,
              ),
            if (vm.errorMessage != null && agenda != null)
              StatusBanner(
                tone: BannerTone.aviso,
                message:
                    'No se pudo actualizar: ${vm.errorMessage}. '
                    'Mostramos lo último que cargaste.',
              ),
            if (agenda != null && !agenda.esHoy)
              const StatusBanner(
                tone: BannerTone.info,
                message:
                    'Puedes consultar otros días; la atención solo se marca '
                    'en las citas de hoy.',
              ),
            if (vm.citas.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xl),
                child: EmptyView(
                  icon: Icons.event_available_outlined,
                  title: 'Sin citas asignadas',
                  message:
                      'Cuando la barbería te asigne citas, aparecerán aquí.',
                ),
              ),
            for (final c in vm.citas) ...[
              _CitaBarberoCard(
                cita: c,
                ocupada: vm.citaOcupada == c.id,
                bloqueada: vm.citaOcupada != null,
                onIniciar: () => vm.iniciar(c),
                onTerminar: () => vm.terminar(c),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.panelBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (vm.state == LoadState.loading && agenda != null)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(child: cuerpo),
          ],
        ),
      ),
    );
  }

  static String _citasTexto(int n) => n == 1 ? '1 cita' : '$n citas';
}

class _CitaBarberoCard extends StatelessWidget {
  const _CitaBarberoCard({
    required this.cita,
    required this.ocupada,
    required this.bloqueada,
    required this.onIniciar,
    required this.onTerminar,
  });

  final BarberoCitaDto cita;
  final bool ocupada;
  final bool bloqueada;
  final VoidCallback onIniciar;
  final VoidCallback onTerminar;

  static String etiqueta(String atencion) => switch (atencion) {
    'por_atender' => 'Por atender',
    'en_silla' => 'En la silla',
    'terminada' => 'Lista para cobrar',
    'completada' => 'Cobrada',
    'no_asistio' => 'No asistió',
    _ => EstadoChip.etiqueta(atencion),
  };

  static Color color(String atencion) => switch (atencion) {
    'por_atender' => AppColors.gold,
    'en_silla' => AppColors.ok,
    'terminada' => AppColors.warn,
    'no_asistio' => AppColors.crit,
    _ => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final c = color(cita.atencion);
    final detalle = [
      if (cita.complementos.isNotEmpty) 'Con: ${cita.complementos}',
      if (cita.notas.isNotEmpty) cita.notas,
    ];
    return SurfaceCard(
      key: ValueKey('barbero-cita-${cita.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      horaCorta(cita.hora),
                      style: AppText.cifra(size: 20, weight: FontWeight.w800),
                    ),
                    Text(
                      '${cita.duracionMinutos} min',
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
                      cita.clienteNombre,
                      style: theme.titleMedium?.copyWith(
                        color: AppColors.ivory,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cita.servicioNombre,
                      style: theme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Semantics(
                      label: 'Atención: ${etiqueta(cita.atencion)}',
                      child: ExcludeSemantics(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs + 1,
                          ),
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(
                              c.withValues(alpha: 0.12),
                              AppColors.surfaceHigh,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            etiqueta(cita.atencion),
                            style: theme.labelMedium?.copyWith(color: c),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (detalle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              detalle.join('\n'),
              style: theme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
          if (cita.puedeIniciar || cita.puedeTerminar) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 48,
              child: cita.puedeIniciar
                  ? ElevatedButton.icon(
                      key: ValueKey('barbero-iniciar-${cita.id}'),
                      onPressed: bloqueada ? null : onIniciar,
                      icon: _icono(Icons.content_cut_rounded),
                      label: const Text('Pasó a la silla'),
                    )
                  : OutlinedButton.icon(
                      key: ValueKey('barbero-terminar-${cita.id}'),
                      onPressed: bloqueada ? null : onTerminar,
                      icon: _icono(Icons.check_circle_outline_rounded),
                      label: const Text('Terminé el servicio'),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _icono(IconData icon) => ocupada
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Icon(icon);
}
