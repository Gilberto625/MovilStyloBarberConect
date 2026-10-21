import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/auth_models.dart';
import '../../models/cita_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../viewmodels/secretaria_hoy_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/press_scale.dart';
import '../client/client_widgets.dart';
import '../guest/guest_contacto_view.dart';

String _citasTexto(int n) => n == 1 ? '1 cita' : '$n citas';

String _horaMinuto(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Secretaría › Pantalla 1 (y 2, sin señal): agenda del día.
class SecretaryHomeView extends StatefulWidget {
  const SecretaryHomeView({super.key});

  @override
  State<SecretaryHomeView> createState() => _SecretaryHomeViewState();
}

class _SecretaryHomeViewState extends State<SecretaryHomeView> {
  final _buscar = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SecretariaHoyViewModel>().load();
    });
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha(SecretariaHoyViewModel vm) async {
    final actual = _fechaInicial(vm);
    final picked = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      helpText: 'Agenda de otro día',
    );
    if (picked == null || !mounted) return;
    await vm.load(fecha: isoFecha(picked));
  }

  DateTime _fechaInicial(SecretariaHoyViewModel vm) {
    final raw = vm.dia?.fecha ?? vm.fechaSeleccionada;
    if (raw != null && raw.length >= 10) {
      final parsed = DateTime.tryParse(raw.substring(0, 10));
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  Future<void> _salir(AuthViewModel auth) async {
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.guestHome,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (!auth.role.isStaffPanel) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No autorizado para secretaría.'),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.guestHome,
                  (_) => false,
                ),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.panelBg,
      body: SafeArea(
        bottom: false,
        child: Consumer<SecretariaHoyViewModel>(
          builder: (context, vm, _) {
            final dia = vm.dia;
            final header = ClientHeader(
              title: dia == null || dia.esHoy ? 'Hoy' : 'Día seleccionado',
              subtitle: dia == null
                  ? 'Agenda de la barbería'
                  : '${fechaLarga(dia.fecha)}, ${_citasTexto(dia.total)}',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Actualizar día',
                    onPressed: vm.reloading ? null : () => vm.load(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: () => _salir(auth),
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
            );
            if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
              return Column(
                children: [
                  header,
                  const Expanded(
                    child: LoadingView(label: 'Cargando citas del día…'),
                  ),
                ],
              );
            }
            if (vm.state == LoadState.error) {
              return Column(
                children: [
                  header,
                  Expanded(
                    child: ErrorView(
                      title: 'No se pudo cargar la agenda',
                      message:
                          vm.errorMessage ?? 'Revisa tu conexión y reintenta.',
                      onRetry: vm.load,
                    ),
                  ),
                ],
              );
            }
            final sinCitas = dia?.citas.isEmpty ?? true;
            return RefreshIndicator(
              onRefresh: vm.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                children: [
                  header,
                  if (vm.reloading) const LinearProgressIndicator(minHeight: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.page,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Conexion(vm: vm),
                        if (vm.actionMessage != null)
                          StatusBanner(
                            tone: BannerTone.ok,
                            message: vm.actionMessage!,
                          ),
                        if (vm.errorMessage != null && !vm.sinConexion)
                          StatusBanner(
                            message: vm.errorMessage!,
                            isError: true,
                          ),
                        _Metricas(dia: dia),
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            OutlinedButton.icon(
                              key: const Key('hoy_fecha'),
                              onPressed: vm.reloading
                                  ? null
                                  : () => _elegirFecha(vm),
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: const Text('Otro día'),
                            ),
                            if (vm.fechaSeleccionada != null)
                              TextButton(
                                onPressed: vm.reloading ? null : vm.mostrarHoy,
                                child: const Text('Volver a hoy'),
                              ),
                            ElevatedButton.icon(
                              key: const Key('hoy_nueva_cita'),
                              onPressed: () => SecretaryNav.open(
                                context,
                                1,
                                AppRoutes.secretaryNuevaCita,
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Nueva cita'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _buscar,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            labelText: 'Buscar cliente, servicio o barbero',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                          onChanged: vm.setConsulta,
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.md,
                      AppSpacing.page,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        for (final f in const [
                          ('todas', 'Todas'),
                          ('pendiente', 'Pendientes'),
                          ('confirmada', 'Confirmadas'),
                          ('en_curso', 'En sala'),
                          ('completada', 'Completadas'),
                          ('no_asistio', 'No asistió'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.sm,
                            ),
                            child: FilterChip(
                              label: Text(f.$2),
                              selected: vm.filtroEstado == f.$1,
                              onSelected: (_) => vm.setFiltro(f.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (vm.citasFiltradas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        AppSpacing.xxl,
                        AppSpacing.page,
                        0,
                      ),
                      child: Column(
                        children: [
                          Text(
                            sinCitas ? 'No hay citas para esta fecha.' : 'Ninguna cita coincide con la búsqueda o el filtro.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.muted),
                          ),
                          if (sinCitas) ...[
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton(
                              onPressed: vm.load,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    for (final c in vm.citasFiltradas)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          0,
                          AppSpacing.page,
                          AppSpacing.md,
                        ),
                        child: _CitaTile(cita: c),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Indicador de conexión (Pantallas 1 y 2): en línea con la hora de la
/// última lectura, o sin señal mostrando la agenda anterior.
class _Conexion extends StatelessWidget {
  const _Conexion({required this.vm});

  final SecretariaHoyViewModel vm;

  @override
  Widget build(BuildContext context) {
    final cuando = vm.actualizadoEn;
    if (vm.sinConexion) {
      return StatusBanner(
        key: const Key('hoy_sin_conexion'),
        tone: BannerTone.aviso,
        message:
            'Sin conexión. Ves la agenda de las '
            '${cuando == null ? '—' : _horaMinuto(cuando)}; las acciones '
            'necesitan internet.',
      );
    }
    if (cuando == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.ok,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'En línea, actualizado a las ${_horaMinuto(cuando)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metricas extends StatelessWidget {
  const _Metricas({required this.dia});

  final SecretariaDiaDto? dia;

  @override
  Widget build(BuildContext context) {
    final d = dia;
    final items = [
      ('Por atender', d?.pendientesAccion ?? 0, AppColors.warn),
      ('En sala', d?.enCurso ?? 0, AppColors.museum),
      ('Atendidas', d?.completadas ?? 0, AppColors.ok),
      ('No asistió', d?.noAsistio ?? 0, AppColors.crit),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              label: '${items[i].$1}: ${items[i].$2}',
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadii.controlBorder,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${items[i].$2}',
                        style: AppText.cifra(
                          size: 22,
                          color: items[i].$2 == 0
                              ? AppColors.muted
                              : items[i].$3,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].$1,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Fila de la agenda: hora a la izquierda, cliente y servicio, estado.
class _CitaTile extends StatelessWidget {
  const _CitaTile({required this.cita});

  final SecretariaCitaDto cita;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return SurfaceCard(
      key: ValueKey('agenda-cita-${cita.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      semanticLabel:
          '${horaCorta(cita.hora)}, ${cita.clienteNombre}, '
          '${cita.servicioNombre}, ${EstadoChip.etiqueta(cita.estado)}',
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.secretaryCitaDetail,
        arguments: cita,
      ),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.appointmentRow - AppSpacing.md * 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  cita.hora.isEmpty ? '—' : horaCorta(cita.hora),
                  style: AppText.cifra(size: 20, weight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita.clienteNombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleMedium?.copyWith(
                        color: AppColors.ivory,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cita.servicioNombre} con ${cita.barberoNombre}',
                      style: theme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        EstadoChip(estado: cita.estado),
                        if (cita.restante > 0 && cita.puedeCobrar)
                          Text(
                            'Por cobrar ${moneyFormat.format(cita.restante)}',
                            style: AppText.cifra(
                              size: 13,
                              color: AppColors.goldSoft,
                              weight: FontWeight.w600,
                            ),
                          ),
                        if (cita.clientePenalizado)
                          const _Etiqueta(
                            texto: 'Con penalización',
                            color: AppColors.warn,
                          ),
                      ],
                    ),
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

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_amber_rounded, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            texto,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Secretaría › Pantalla 3: detalle de cita con sus acciones.
class SecretaryCitaDetailView extends StatelessWidget {
  const SecretaryCitaDetailView({super.key, required this.cita});

  final SecretariaCitaDto cita;

  SecretariaCitaDto _visible(SecretariaHoyViewModel vm) {
    for (final item in vm.dia?.citas ?? const <SecretariaCitaDto>[]) {
      if (item.id == cita.id) return item;
    }
    return cita;
  }

  Future<void> _llego(BuildContext context, SecretariaCitaDto actual) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar llegada'),
        content: Text(
          '${actual.clienteNombre} pasa a "En sala". El cambio se guarda solo '
          'si el servidor lo acepta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            key: const Key('llegada_confirmar'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final vm = context.read<SecretariaHoyViewModel>();
    final success = await vm.marcarLlego(actual.id);
    if (!context.mounted) return;
    _avisar(context, vm, success);
    if (success) Navigator.pop(context);
  }

  Future<void> _noAsistio(
    BuildContext context,
    SecretariaCitaDto actual,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _NoAsistioDialog(cita: actual),
    );
    if (ok != true || !context.mounted) return;
    final vm = context.read<SecretariaHoyViewModel>();
    final success = await vm.marcarNoAsistio(actual.id);
    if (!context.mounted) return;
    _avisar(context, vm, success);
    if (success) Navigator.pop(context);
  }

  Future<void> _cobrar(BuildContext context, SecretariaCitaDto actual) async {
    // La hoja es dueña de sus controladores y los libera en su dispose,
    // después de la animación de salida (ERR-01).
    final datos = await showModalBottomSheet<_DatosCobro>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CobroSheet(cita: actual),
    );
    if (datos == null || !context.mounted) return;
    final vm = context.read<SecretariaHoyViewModel>();
    final success = await vm.cobrar(
      citaId: actual.id,
      metodoPago: datos.metodo,
      comprobante: datos.comprobante.isEmpty ? null : datos.comprobante,
      efectivoRecibido: datos.efectivo,
    );
    if (!context.mounted) return;
    _avisar(context, vm, success);
    if (success) Navigator.pop(context);
  }

  void _avisar(BuildContext context, SecretariaHoyViewModel vm, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (vm.actionMessage ?? 'Listo.')
              : (vm.errorMessage ?? 'No se pudo completar la acción.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SecretariaHoyViewModel>();
    final actual = _visible(vm);
    final theme = Theme.of(context).textTheme;
    final tel = enlaceTelefono(actual.clienteTelefono);
    final penalizacion = actual.clientePenalizado
        ? (actual.penalizacionPorcentaje > 0
              ? 'Penalización activa: anticipo del '
                    '${actual.penalizacionPorcentaje.toStringAsFixed(0)} %. '
                    'Le faltan ${actual.penalizacionCitasRestantes} citas '
                    'asistidas para liberarla.'
              : 'Cliente con penalización de anticipo.')
        : null;
    final sinAcciones = !actual.puedeMarcarAsistencia && !actual.puedeCobrar;
    return Scaffold(
      backgroundColor: AppColors.panelBg,
      appBar: AppBar(title: Text('Cita #${actual.id}')),
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
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: AppRadii.cardBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          horaCorta(actual.hora),
                          style: AppText.cifra(
                            size: 36,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                      EstadoChip(estado: actual.estado),
                    ],
                  ),
                  Text(
                    fechaLarga(actual.fecha),
                    style: theme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Iniciales(nombre: actual.clienteNombre),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(actual.clienteNombre, style: theme.titleLarge),
                            if (actual.clienteTelefono.isNotEmpty)
                              Text(
                                actual.clienteTelefono,
                                style: AppText.cifra(
                                  size: 14,
                                  color: AppColors.muted,
                                  weight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (tel != null)
                        IconButton(
                          key: const Key('detalle_llamar'),
                          tooltip: 'Llamar a ${actual.clienteNombre}',
                          onPressed: () => abrirEnlace(
                            context,
                            tel,
                            respaldo: actual.clienteTelefono,
                            que: 'el marcador',
                          ),
                          icon: const Icon(
                            Icons.call_outlined,
                            color: AppColors.goldSoft,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (penalizacion != null) ...[
              const SizedBox(height: AppSpacing.md),
              StatusBanner(tone: BannerTone.aviso, message: penalizacion),
            ],
            const SectionHeader(title: 'Servicio'),
            SurfaceCard(
              child: Column(
                children: [
                  InfoRow(label: 'Servicio', value: actual.servicioNombre),
                  InfoRow(label: 'Barbero', value: actual.barberoNombre),
                  InfoRow(
                    label: 'Duración',
                    value: '${actual.duracionMinutos} min',
                  ),
                  InfoRow(label: 'Identificador', value: '${actual.id}'),
                ],
              ),
            ),
            const SectionHeader(title: 'Pago'),
            SurfaceCard(
              child: Column(
                children: [
                  InfoRow(
                    label: 'Precio',
                    value: moneyFormat.format(actual.precioTotal),
                  ),
                  InfoRow(
                    label: 'Anticipo pagado',
                    value: moneyFormat.format(actual.anticipoPagado),
                  ),
                  if (actual.anticipoPendiente > 0)
                    InfoRow(
                      label: 'Anticipo pendiente',
                      value: moneyFormat.format(actual.anticipoPendiente),
                    ),
                  InfoRow(
                    label: 'Restante',
                    value: moneyFormat.format(actual.restante),
                    emphasis: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (actual.puedeMarcarAsistencia) ...[
              _Accion(
                key: const Key('detalle_llego'),
                label: 'Cliente llegó',
                icon: Icons.how_to_reg_outlined,
                busy: vm.actionBusy,
                onPressed: () => _llego(context, actual),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (actual.puedeCobrar) ...[
              _Accion(
                key: const Key('detalle_cobrar'),
                label: 'Cobrar ${moneyFormat.format(actual.restante)}',
                icon: Icons.payments_outlined,
                busy: vm.actionBusy,
                onPressed: () => _cobrar(context, actual),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (actual.puedeMarcarAsistencia)
              _Accion(
                key: const Key('detalle_no_asistio'),
                label: 'No asistió',
                icon: Icons.person_off_outlined,
                busy: vm.actionBusy,
                peligro: true,
                onPressed: () => _noAsistio(context, actual),
              ),
            if (sinAcciones)
              Text(
                'Esta cita no tiene acciones autorizadas por el servidor.',
                style: theme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            const SizedBox(height: AppSpacing.lg),
            if (_fechaEditable(actual.fecha))
              OutlinedButton.icon(
                key: const Key('detalle_reprogramar'),
                onPressed: vm.actionBusy
                    ? null
                    : () => Navigator.pushNamed(
                        context,
                        AppRoutes.secretaryReprogramar,
                        arguments: actual.id,
                      ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ivory,
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Reprogramar'),
              )
            else
              Text(
                'Las citas de fechas pasadas no se pueden modificar.',
                style: theme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver a la agenda'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Accion extends StatelessWidget {
  const _Accion({
    super.key,
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
    this.peligro = false,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback onPressed;
  final bool peligro;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );
    return PressScale(
      enabled: !busy,
      child: SizedBox(
        width: double.infinity,
        child: peligro
            ? OutlinedButton(
                onPressed: busy ? null : onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.crit,
                  side: const BorderSide(color: AppColors.crit),
                ),
                child: child,
              )
            : ElevatedButton(onPressed: busy ? null : onPressed, child: child),
      ),
    );
  }
}

/// Secretaría › Pantalla 4: confirmación fuerte de inasistencia. Marcar
/// "No asistió" penaliza al cliente en el backend.
class _NoAsistioDialog extends StatefulWidget {
  const _NoAsistioDialog({required this.cita});

  final SecretariaCitaDto cita;

  @override
  State<_NoAsistioDialog> createState() => _NoAsistioDialogState();
}

class _NoAsistioDialogState extends State<_NoAsistioDialog> {
  var _confirmado = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final c = widget.cita;
    return AlertDialog(
      icon: const Icon(Icons.person_off_outlined, color: AppColors.crit),
      title: const Text('¿Marcar como no asistió?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${c.clienteNombre}, ${c.servicioNombre} a las '
              '${horaCorta(c.hora)}.',
              style: theme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            StatusBanner(
              isError: true,
              message: c.clientePenalizado
                  ? 'El cliente ya tiene penalización: esta falta la refuerza '
                        'según la política de la barbería.'
                  : 'Esto puede activar una penalización: sus siguientes '
                        'citas pedirían un anticipo.',
            ),
            Text(
              'Solo márcalo si el cliente no llegó ni avisó. No se puede '
              'deshacer desde la app.',
              style: theme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            CheckboxListTile(
              key: const Key('no_asistio_check'),
              value: _confirmado,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _confirmado = v ?? false),
              title: const Text('Confirmo que el cliente no llegó'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('no_asistio_confirmar'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.crit,
            foregroundColor: AppColors.onGold,
          ),
          onPressed: _confirmado ? () => Navigator.pop(context, true) : null,
          child: const Text('Marcar no asistió'),
        ),
      ],
    );
  }
}

/// Lo que la secretaria capturó en la hoja de cobro.
class _DatosCobro {
  const _DatosCobro({
    required this.metodo,
    required this.comprobante,
    required this.efectivo,
  });

  final String metodo;
  final String comprobante;
  final double? efectivo;
}

/// Secretaría › Pantalla 5: cobro con cálculo del cambio.
class _CobroSheet extends StatefulWidget {
  const _CobroSheet({required this.cita});

  final SecretariaCitaDto cita;

  @override
  State<_CobroSheet> createState() => _CobroSheetState();
}

class _CobroSheetState extends State<_CobroSheet> {
  String _metodo = 'efectivo';
  final _comprobante = TextEditingController();
  late final _recibido = TextEditingController(
    text: widget.cita.restante > 0
        ? widget.cita.restante.toStringAsFixed(2)
        : '',
  );

  @override
  void initState() {
    super.initState();
    _recibido.addListener(() => setState(() {}));
    _comprobante.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comprobante.dispose();
    _recibido.dispose();
    super.dispose();
  }

  double get _restante => widget.cita.restante;

  double? get _efectivo =>
      double.tryParse(_recibido.text.trim().replaceAll(',', '.'));

  /// Mensaje que impide cobrar, o `null` si todo está en orden.
  String? get _bloqueo {
    if (_metodo == 'transferencia' && _comprobante.text.trim().isEmpty) {
      return 'La transferencia requiere comprobante o referencia.';
    }
    if (_metodo == 'efectivo' && _restante > 0) {
      final e = _efectivo;
      if (e == null || e + 0.001 < _restante) {
        final falta = e == null ? _restante : _restante - e;
        return 'Faltan ${moneyFormat.format(falta)}. El efectivo debe cubrir '
            '${moneyFormat.format(_restante)}.';
      }
    }
    return null;
  }

  /// Vuelve a validar al tocar: el monto pudo cambiar en el mismo cuadro.
  void _confirmar() {
    if (_bloqueo != null) {
      setState(() {});
      return;
    }
    Navigator.pop(
      context,
      _DatosCobro(
        metodo: _metodo,
        comprobante: _comprobante.text.trim(),
        efectivo: _metodo == 'efectivo' && _restante > 0 ? _efectivo : null,
      ),
    );
  }

  void _monto(double valor) {
    _recibido.text = valor.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final bloqueo = _bloqueo;
    final e = _efectivo;
    final cambio = (_metodo == 'efectivo' && e != null && e >= _restante)
        ? e - _restante
        : null;
    final sugeridos = <double>{
      _restante,
      for (final b in const [200.0, 500.0, 1000.0])
        if (b > _restante) b,
    }.take(4).toList();
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.page,
        right: AppSpacing.page,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Registrar cobro', style: theme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${widget.cita.clienteNombre}, ${widget.cita.servicioNombre}',
              style: theme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: Text('Por cobrar', style: theme.titleMedium)),
                Text(
                  moneyFormat.format(_restante),
                  style: AppText.cifra(size: 26, color: AppColors.gold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<String>(
              key: const Key('cobro_metodo'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'efectivo', label: Text('Efectivo')),
                ButtonSegment(value: 'tarjeta', label: Text('Tarjeta')),
                ButtonSegment(
                  value: 'transferencia',
                  label: Text('Transferencia'),
                ),
              ],
              selected: {_metodo},
              onSelectionChanged: (s) => setState(() => _metodo = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_metodo == 'efectivo' && _restante > 0) ...[
              TextField(
                key: const Key('cobro_recibido'),
                controller: _recibido,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppText.cifra(size: 18),
                decoration: const InputDecoration(
                  labelText: 'Efectivo recibido',
                  prefixText: '\$ ',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final s in sugeridos)
                    ActionChip(
                      label: Text(
                        s == _restante ? 'Exacto' : moneyFormat.format(s),
                      ),
                      onPressed: () => _monto(s),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.quick),
                child: cambio != null
                    ? Row(
                        key: const ValueKey('cambio'),
                        children: [
                          Expanded(
                            child: Text('Cambio', style: theme.titleMedium),
                          ),
                          Text(
                            moneyFormat.format(cambio),
                            key: const Key('cobro_cambio'),
                            style: AppText.cifra(size: 22, color: AppColors.ok),
                          ),
                        ],
                      )
                    : const SizedBox(key: ValueKey('sin-cambio')),
              ),
            ],
            if (_metodo == 'transferencia')
              TextField(
                key: const Key('cobro_comprobante'),
                controller: _comprobante,
                decoration: const InputDecoration(
                  labelText: 'Comprobante o referencia',
                ),
              ),
            if (_metodo == 'tarjeta')
              Text(
                'Cobra con la terminal y registra aquí el pago.',
                style: theme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            if (bloqueo != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                bloqueo,
                style: theme.bodyMedium?.copyWith(color: AppColors.crit),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    key: const Key('cobro_confirmar'),
                    onPressed: bloqueo != null ? null : _confirmar,
                    child: const Text('Cobrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

bool _fechaEditable(String fecha) {
  if (fecha.length < 10) return false;
  final parsed = DateTime.tryParse(fecha.substring(0, 10));
  if (parsed == null) return false;
  final hoy = DateTime.now();
  final inicio = DateTime(hoy.year, hoy.month, hoy.day);
  return !parsed.isBefore(inicio);
}

class SecretaryNav extends InheritedWidget {
  const SecretaryNav({super.key, required this.go, required super.child});

  final ValueChanged<int> go;

  static SecretaryNav? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<SecretaryNav>();
  }

  static void open(BuildContext context, int section, String route) {
    final nav = maybeOf(context);
    if (nav != null) {
      nav.go(section);
      return;
    }
    Navigator.pushNamed(context, route);
  }

  @override
  bool updateShouldNotify(SecretaryNav oldWidget) => go != oldWidget.go;
}
