import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/media/variante_imagen.dart';
import '../../core/theme/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../models/cita_models.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/catalog_list_viewmodel.dart';
import '../../viewmodels/client_citas_viewmodel.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/press_scale.dart';
import '../guest/guest_premium_widgets.dart';
import 'client_widgets.dart';

const _pasos = ['Servicio', 'Barbero', 'Fecha y hora', 'Resumen'];

/// Cliente › Pantallas 2 a 5: agendar en cuatro pasos. Servicios, barberos,
/// horarios, política y la cita misma salen de Django.
class ClientAgendarTab extends StatefulWidget {
  const ClientAgendarTab({
    super.key,
    required this.onBooked,
    this.onPaso,
    this.hoy,
  });

  final VoidCallback onBooked;

  /// Avisa el paso actual al panel (para el botón Atrás del sistema).
  final ValueChanged<int>? onPaso;

  /// Fecha de referencia inyectable para pruebas.
  final DateTime? hoy;

  @override
  State<ClientAgendarTab> createState() => _ClientAgendarTabState();
}

class _ClientAgendarTabState extends State<ClientAgendarTab> {
  var _paso = 0;
  var _avanza = true;
  ServicioDto? _servicio;
  BarberoDto? _barbero;
  late DateTime _fecha;
  String? _hora;

  DateTime get _hoy {
    final h = widget.hoy ?? DateTime.now();
    return DateTime(h.year, h.month, h.day);
  }

  @override
  void initState() {
    super.initState();
    _fecha = _hoy.add(const Duration(days: 1));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final catalog = context.read<CatalogListViewModel>();
      if (catalog.servicios.isEmpty) catalog.loadServicios();
    });
  }

  void _ir(int paso) {
    setState(() {
      _avanza = paso > _paso;
      _paso = paso;
    });
    widget.onPaso?.call(paso);
  }

  Future<void> _elegirServicio(ServicioDto s) async {
    setState(() {
      _servicio = s;
      _barbero = null;
      _hora = null;
    });
    _ir(1);
    await context.read<ClientCitasViewModel>().loadBarberos(servicioId: s.id);
  }

  Future<void> _elegirBarbero(BarberoDto b) async {
    setState(() {
      _barbero = b;
      _hora = null;
    });
    _ir(2);
    await _cargarHorarios();
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
      helpText: 'Elige el día',
    );
    if (!mounted || picked == null) return;
    await _elegirFecha(picked);
  }

  Future<void> _cargarHorarios() async {
    final s = _servicio;
    final b = _barbero;
    if (s == null || b == null) return;
    await context.read<ClientCitasViewModel>().loadDisponibilidad(
      barberoId: b.id,
      fecha: isoFecha(_fecha),
      duracion: s.duracionMinutos,
    );
  }

  Future<void> _resumen() async {
    _ir(3);
    final user = context.read<AuthViewModel>().user;
    if (user != null) {
      await context.read<ClientCitasViewModel>().loadPolitica(user.id);
    }
  }

  Future<void> _confirmar() async {
    final user = context.read<AuthViewModel>().user;
    final s = _servicio;
    final b = _barbero;
    final h = _hora;
    if (user == null || s == null || b == null || h == null) return;
    final vm = context.read<ClientCitasViewModel>();
    await vm.loadPolitica(user.id);
    if (vm.politica?.requiereAnticipo == true) return;

    final ok = await vm.reservar(
      user: user,
      barberoId: b.id,
      servicioId: s.id,
      duracionMinutos: s.duracionMinutos,
      fecha: isoFecha(_fecha),
      hora: h,
      precioTotal: s.precio,
    );
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(vm.bookingMessage ?? 'Cita creada.')),
    );
    setState(() {
      _servicio = null;
      _barbero = null;
      _hora = null;
      _paso = 0;
    });
    widget.onPaso?.call(0);
    await vm.loadMisCitas();
    if (mounted) widget.onBooked();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClientCitasViewModel>();
    final dur = AppMotion.of(context, AppMotion.entrance);
    return PopScope(
      canPop: _paso == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _paso > 0) _ir(_paso - 1);
      },
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClientHeader(
              title: 'Agendar cita',
              subtitle: 'Paso ${_paso + 1} de 4: ${_pasos[_paso]}',
              trailing: _paso > 0
                  ? IconButton(
                      key: const Key('agendar_atras'),
                      tooltip: 'Paso anterior',
                      onPressed: vm.bookingBusy ? null : () => _ir(_paso - 1),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: _Progreso(paso: _paso),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AnimatedSwitcher(
                duration: dur,
                switchInCurve: AppMotion.ease,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, a) {
                  final entra = child.key == ValueKey(_paso);
                  final desde = (_avanza == entra) ? 0.06 : -0.06;
                  return FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: Offset(desde, 0),
                        end: Offset.zero,
                      ).animate(a),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_paso),
                  child: switch (_paso) {
                    0 => _PasoServicio(
                      seleccionado: _servicio,
                      onElegir: _elegirServicio,
                    ),
                    1 => _PasoBarbero(
                      seleccionado: _barbero,
                      onElegir: _elegirBarbero,
                    ),
                    2 => _PasoHorario(
                      hoy: _hoy,
                      fecha: _fecha,
                      hora: _hora,
                      onFecha: _elegirFecha,
                      onOtraFecha: _otraFecha,
                      onHora: (h) => setState(() => _hora = h),
                    ),
                    _ => _PasoResumen(
                      servicio: _servicio!,
                      barbero: _barbero!,
                      fecha: _fecha,
                      hora: _hora!,
                    ),
                  },
                ),
              ),
            ),
            if (_paso == 2 && _hora != null)
              _BarraAccion(
                key: const Key('agendar_continuar'),
                label: 'Revisar y confirmar',
                onPressed: _resumen,
              ),
            if (_paso == 3)
              _BarraAccion(
                key: const Key('agendar_confirmar'),
                label: 'Confirmar reserva',
                busy: vm.bookingBusy,
                onPressed: vm.politica?.requiereAnticipo == true
                    ? null
                    : _confirmar,
              ),
          ],
        ),
      ),
    );
  }
}

class _Progreso extends StatelessWidget {
  const _Progreso({required this.paso});

  final int paso;

  @override
  Widget build(BuildContext context) {
    final dur = AppMotion.of(context, AppMotion.entrance);
    return Semantics(
      label: 'Paso ${paso + 1} de 4',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: dur,
                  curve: AppMotion.ease,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= paso ? AppColors.gold : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < 3) const SizedBox(width: AppSpacing.xs + 2),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarraAccion extends StatelessWidget {
  const _BarraAccion({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.md,
      ),
      child: PressScale(
        enabled: !busy && onPressed != null,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: busy ? null : onPressed,
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onGold,
                    ),
                  )
                : Text(label),
          ),
        ),
      ),
    );
  }
}

EdgeInsets get _lista => const EdgeInsets.fromLTRB(
  AppSpacing.page,
  AppSpacing.xs,
  AppSpacing.page,
  AppSpacing.xxl,
);

class _PasoServicio extends StatelessWidget {
  const _PasoServicio({required this.seleccionado, required this.onElegir});

  final ServicioDto? seleccionado;
  final ValueChanged<ServicioDto> onElegir;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogListViewModel>();
    final servicios = catalog.servicios.where((s) => !s.isPromocion).toList();
    if (catalog.state == LoadState.loading || catalog.state == LoadState.idle) {
      return const LoadingView(label: 'Cargando servicios…');
    }
    if (catalog.state == LoadState.error) {
      return ErrorView(
        message: catalog.errorMessage ?? 'No se pudieron cargar los servicios.',
        onRetry: catalog.loadServicios,
      );
    }
    if (servicios.isEmpty) {
      return EmptyView(
        icon: Icons.content_cut_rounded,
        message: 'No hay servicios activos para reservar.',
        onRetry: catalog.loadServicios,
      );
    }
    final theme = Theme.of(context).textTheme;
    return ListView.separated(
      padding: _lista,
      itemCount: servicios.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final s = servicios[i];
        return SelectableRow(
          key: ValueKey('agendar-servicio-${s.id}'),
          selected: seleccionado?.id == s.id,
          onTap: () => onElegir(s),
          semanticLabel:
              '${s.nombre}, ${moneyFormat.format(s.precio)}, '
              '${s.duracionMinutos} minutos',
          child: ExcludeSemantics(
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 64,
                  child: ClipRRect(
                    borderRadius: AppRadii.controlBorder,
                    child: GuestPremiumImage(
                      url: s.imagenUrl,
                      fit: BoxFit.cover,
                      variante: VarianteImagen.miniatura,
                      label: s.nombre,
                      fallbackIcon: Icons.content_cut_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.nombre,
                        style: theme.titleMedium?.copyWith(
                          color: AppColors.ivory,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.lg,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            moneyFormat.format(s.precio),
                            style: AppText.cifra(
                              size: 15,
                              color: AppColors.gold,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${s.duracionMinutos} min',
                                style: theme.bodyMedium?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PasoBarbero extends StatelessWidget {
  const _PasoBarbero({required this.seleccionado, required this.onElegir});

  final BarberoDto? seleccionado;
  final ValueChanged<BarberoDto> onElegir;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClientCitasViewModel>();
    if (vm.barberosLoading) {
      return const LoadingView(label: 'Buscando barberos para ese servicio…');
    }
    if (vm.barberos.isEmpty) {
      return EmptyView(
        icon: Icons.person_search_outlined,
        message:
            vm.errorMessage ?? 'Ningún barbero ofrece este servicio por ahora.',
      );
    }
    final theme = Theme.of(context).textTheme;
    return ListView.separated(
      padding: _lista,
      itemCount: vm.barberos.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final b = vm.barberos[i];
        return SelectableRow(
          key: ValueKey('agendar-barbero-${b.id}'),
          selected: seleccionado?.id == b.id,
          onTap: () => onElegir(b),
          semanticLabel: '${b.displayName}. ${b.especialidades}',
          child: ExcludeSemantics(
            child: Row(
              children: [
                Iniciales(nombre: b.displayName, size: 48),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.displayName,
                        style: theme.titleMedium?.copyWith(
                          color: AppColors.ivory,
                        ),
                      ),
                      if (b.especialidades.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          b.especialidades,
                          style: theme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PasoHorario extends StatelessWidget {
  const _PasoHorario({
    required this.hoy,
    required this.fecha,
    required this.hora,
    required this.onFecha,
    required this.onOtraFecha,
    required this.onHora,
  });

  final DateTime hoy;
  final DateTime fecha;
  final String? hora;
  final ValueChanged<DateTime> onFecha;
  final VoidCallback onOtraFecha;
  final ValueChanged<String> onHora;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClientCitasViewModel>();
    final theme = Theme.of(context).textTheme;
    final dias = [for (var i = 0; i < 14; i++) hoy.add(Duration(days: i))];
    final libres = vm.slots.where((s) => s.disponible).toList();
    return ListView(
      padding: _lista,
      children: [
        Text(fechaLarga(isoFecha(fecha)), style: theme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dias.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              if (i == dias.length) {
                return _DiaChip(
                  key: const Key('agendar_otra_fecha'),
                  arriba: 'Otra',
                  abajo: 'fecha',
                  selected: false,
                  onTap: onOtraFecha,
                  icon: Icons.calendar_month_outlined,
                );
              }
              final d = dias[i];
              return _DiaChip(
                key: ValueKey('agendar-dia-${isoFecha(d)}'),
                arriba: i == 0 ? 'Hoy' : diaSemanaCorto(d),
                abajo: '${d.day}',
                selected: isoFecha(d) == isoFecha(fecha),
                onTap: () => onFecha(d),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Horarios libres', style: theme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        if (vm.slotsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: LoadingView(label: 'Consultando horarios…'),
          )
        else if (vm.errorMessage != null && libres.isEmpty)
          StatusBanner(message: vm.errorMessage!, isError: true)
        else if (libres.isEmpty)
          Text(
            'No hay horarios libres ese día. Prueba con otra fecha.',
            style: theme.bodyMedium?.copyWith(color: AppColors.muted),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in libres)
                ChoiceChip(
                  key: ValueKey('agendar-hora-${s.hora}'),
                  label: Text(
                    horaCorta(s.hora),
                    style: AppText.cifra(
                      size: 15,
                      weight: FontWeight.w600,
                      color: hora == s.hora
                          ? AppColors.onGold
                          : AppColors.ivory,
                    ),
                  ),
                  selected: hora == s.hora,
                  showCheckmark: false,
                  selectedColor: AppColors.gold,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: hora == s.hora ? AppColors.gold : AppColors.border,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => onHora(s.hora),
                ),
            ],
          ),
      ],
    );
  }
}

class _DiaChip extends StatelessWidget {
  const _DiaChip({
    super.key,
    required this.arriba,
    required this.abajo,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String arriba;
  final String abajo;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dur = AppMotion.of(context, AppMotion.quick);
    final color = selected ? AppColors.onGold : AppColors.ivory;
    return Semantics(
      button: true,
      selected: selected,
      label: '$arriba $abajo',
      child: AnimatedContainer(
        duration: dur,
        curve: AppMotion.ease,
        width: 60,
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.surface,
          borderRadius: AppRadii.controlBorder,
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.border,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadii.controlBorder,
            onTap: onTap,
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    arriba,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? AppColors.onGold : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (icon != null)
                    Icon(icon, size: 20, color: color)
                  else
                    Text(
                      abajo,
                      style: AppText.cifra(
                        size: 20,
                        color: color,
                        weight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasoResumen extends StatelessWidget {
  const _PasoResumen({
    required this.servicio,
    required this.barbero,
    required this.fecha,
    required this.hora,
  });

  final ServicioDto servicio;
  final BarberoDto barbero;
  final DateTime fecha;
  final String hora;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClientCitasViewModel>();
    final theme = Theme.of(context).textTheme;
    final politica = vm.politica;
    return ListView(
      padding: _lista,
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
              Text(
                fechaLarga(isoFecha(fecha)),
                style: theme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              Text(
                horaCorta(hora),
                style: AppText.cifra(size: 40, weight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              InfoRow(label: 'Servicio', value: servicio.nombre),
              InfoRow(label: 'Barbero', value: barbero.displayName),
              InfoRow(
                label: 'Duración',
                value: '${servicio.duracionMinutos} min',
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: Text('Total', style: theme.titleMedium)),
                  Text(
                    moneyFormat.format(servicio.precio),
                    style: AppText.cifra(size: 22, color: AppColors.gold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (vm.errorMessage != null)
          Semantics(
            liveRegion: true,
            child: StatusBanner(message: vm.errorMessage!, isError: true),
          ),
        if (politica?.requiereAnticipo == true)
          StatusBanner(
            tone: BannerTone.aviso,
            message:
                'Tu cuenta requiere un anticipo del '
                '${politica!.porcentajeAnticipo.toStringAsFixed(0)} % para '
                'reservar. Por ahora se paga en la web o con la secretaría.',
          )
        else
          Text(
            'Pagas en la barbería. Si faltas sin avisar, tus siguientes '
            'citas pueden pedir un anticipo.',
            style: theme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
      ],
    );
  }
}
