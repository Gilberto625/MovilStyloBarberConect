import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/auth_models.dart';
import '../../models/catalog_models.dart';
import '../../models/cita_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/catalog_list_viewmodel.dart';
import '../../viewmodels/client_citas_viewmodel.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/press_scale.dart';

const _ivory = AppColors.ivory;
const _muted = AppColors.muted;
const _surface = AppColors.surface;

class ClientHomeShell extends StatefulWidget {
  const ClientHomeShell({super.key});

  @override
  State<ClientHomeShell> createState() => _ClientHomeShellState();
}

class _ClientHomeShellState extends State<ClientHomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientCitasViewModel>().loadMisCitas();
    });
  }

  void _open(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ClientHomeTab(onAgendar: () => _open(2), onCitas: () => _open(1)),
      const _ClientCitasTab(),
      _ClientAgendarTab(onBooked: () => _open(1)),
      const _ClientPerfilTab(),
    ];
    return Theme(
      data: AppTheme.guest(),
      child: Scaffold(
        backgroundColor: AppColors.guestBg,
        body: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          switchInCurve: const Cubic(0.23, 1, 0.32, 1),
          switchOutCurve: const Cubic(0.23, 1, 0.32, 1),
          child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
        ),
        bottomNavigationBar: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1,
          child: NavigationBar(
            backgroundColor: _surface,
            indicatorColor: AppColors.gold.withValues(alpha: 0.18),
            selectedIndex: _index,
            onDestinationSelected: _open,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.gold),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note, color: AppColors.gold),
                label: 'Citas',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month, color: AppColors.gold),
                label: 'Agendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppColors.gold),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientHomeTab extends StatelessWidget {
  const _ClientHomeTab({required this.onAgendar, required this.onCitas});

  final VoidCallback onAgendar;
  final VoidCallback onCitas;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final citas = context.watch<ClientCitasViewModel>();
    final name = auth.user?.username ?? 'cliente';
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const _BrandLockup(),
          const SizedBox(height: 28),
          Text(
            'Hola, $name',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: _ivory, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu silla, tus citas y el catálogo de la barbería.',
            style: TextStyle(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 24),
          _NextCitaCard(vm: citas, onCitas: onCitas, onAgendar: onAgendar),
          const SizedBox(height: 22),
          Text(
            'Accesos',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: _ivory),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.content_cut,
            title: 'Reservar cita',
            subtitle: 'Servicio, barbero y horario reales',
            onTap: onAgendar,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.event_note_outlined,
            title: 'Mis citas',
            subtitle: 'Lo que el sistema tiene registrado',
            onTap: onCitas,
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.design_services_outlined,
            title: 'Servicios',
            subtitle: 'Duración y precio publicados',
            onTap: () => Navigator.pushNamed(context, AppRoutes.servicios),
          ),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.shopping_bag_outlined,
            title: 'Productos',
            subtitle: 'Catálogo de la barbería',
            onTap: () => Navigator.pushNamed(context, AppRoutes.productos),
          ),
        ],
      ),
    );
  }
}

class _NextCitaCard extends StatelessWidget {
  const _NextCitaCard({
    required this.vm,
    required this.onCitas,
    required this.onAgendar,
  });

  final ClientCitasViewModel vm;
  final VoidCallback onCitas;
  final VoidCallback onAgendar;

  @override
  Widget build(BuildContext context) {
    final next = _proxima(vm.citas);
    if (next != null) {
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Próxima cita',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: _ivory),
            ),
            const SizedBox(height: 10),
            Text(
              next.servicioNombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: _ivory),
            ),
            const SizedBox(height: 6),
            Text(
              '${next.fecha} · ${next.hora}',
              style: const TextStyle(color: _ivory),
            ),
            Text(next.barberoNombre, style: const TextStyle(color: _muted)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: EstadoChip(estado: next.estado),
                  ),
                ),
                TextButton(onPressed: onCitas, child: const Text('Ver citas')),
              ],
            ),
          ],
        ),
      );
    }
    if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
      return const _Panel(
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Consultando tus citas…')),
          ],
        ),
      );
    }
    if (vm.state == LoadState.error && vm.citas.isEmpty) {
      return _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vm.errorMessage ?? 'No se pudieron cargar las citas.'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: vm.loadMisCitas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sin cita próxima',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: _ivory),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cuando reserves, la próxima cita aparecerá aquí.',
            style: TextStyle(color: _muted),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onAgendar, child: const Text('Agendar')),
        ],
      ),
    );
  }

  CitaDto? _proxima(List<CitaDto> citas) {
    final abiertas = citas.where((c) {
      final estado = c.estado.toLowerCase();
      return estado != 'cancelada' &&
          estado != 'completada' &&
          estado != 'no_asistio';
    }).toList();
    if (abiertas.isEmpty) return null;
    abiertas.sort(
      (a, b) => '${a.fecha} ${a.hora}'.compareTo('${b.fecha} ${b.hora}'),
    );
    return abiertas.first;
  }
}

class _ClientCitasTab extends StatelessWidget {
  const _ClientCitasTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ClientCitasViewModel>(
        builder: (context, vm, _) {
          final body = _body(context, vm);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mis citas',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: _ivory),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Actualizar citas',
                      onPressed: vm.loadMisCitas,
                      icon: const Icon(Icons.refresh, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, ClientCitasViewModel vm) {
    if (vm.citas.isEmpty &&
        (vm.state == LoadState.loading || vm.state == LoadState.idle)) {
      return const LoadingView(label: 'Cargando citas…');
    }
    if (vm.citas.isEmpty && vm.state == LoadState.error) {
      return ErrorView(
        message: vm.errorMessage ?? 'Error',
        onRetry: vm.loadMisCitas,
      );
    }
    if (vm.citas.isEmpty) {
      return EmptyView(
        message: 'Aún no tienes citas.',
        onRetry: vm.loadMisCitas,
      );
    }
    const cerradas = {'cancelada', 'completada', 'no_asistio'};
    final proximas = vm.citas
        .where((c) => !cerradas.contains(c.estado))
        .toList();
    final historial = vm.citas
        .where((c) => cerradas.contains(c.estado))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (vm.errorMessage != null) ...[
          StatusBanner(message: vm.errorMessage!, isError: true),
          const SizedBox(height: 12),
        ],
        if (proximas.isNotEmpty) ...[
          const _CitasHeading('Próximas'),
          ..._citasPorFecha(proximas),
        ],
        if (historial.isNotEmpty) ...[
          const _CitasHeading('Historial'),
          ..._citasPorFecha(historial),
        ],
      ],
    );
  }

  List<Widget> _citasPorFecha(List<CitaDto> citas) {
    final groups = <String, List<CitaDto>>{};
    for (final cita in citas) {
      groups.putIfAbsent(cita.fecha, () => []).add(cita);
    }
    final fechas = groups.keys.toList()..sort();
    return [
      for (final fecha in fechas) ...[
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            fecha,
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        for (final c in groups[fecha]!) ...[
          _CitaCard(cita: c),
          const SizedBox(height: 10),
        ],
      ],
    ];
  }
}

class _CitasHeading extends StatelessWidget {
  const _CitasHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _ivory),
      ),
    );
  }
}

class _CitaCard extends StatelessWidget {
  const _CitaCard({required this.cita});

  final CitaDto cita;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cita.servicioNombre,
                  style: const TextStyle(
                    color: _ivory,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              EstadoChip(estado: cita.estado),
            ],
          ),
          const SizedBox(height: 8),
          Text('${cita.hora} · ${cita.duracionMinutos} min'),
          Text(cita.barberoNombre, style: const TextStyle(color: _muted)),
          const SizedBox(height: 6),
          Text(
            moneyFormat.format(cita.precioTotal),
            style: const TextStyle(color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}

class _ClientAgendarTab extends StatefulWidget {
  const _ClientAgendarTab({required this.onBooked});

  final VoidCallback onBooked;

  @override
  State<_ClientAgendarTab> createState() => _ClientAgendarTabState();
}

class _ClientAgendarTabState extends State<_ClientAgendarTab> {
  ServicioDto? _servicio;
  int? _barberoId;
  DateTime _fecha = DateTime.now().add(const Duration(days: 1));
  String? _hora;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CatalogListViewModel>().loadServicios();
    });
  }

  Future<void> _onServicio(ServicioDto s) async {
    setState(() {
      _servicio = s;
      _barberoId = null;
      _hora = null;
    });
    final vm = context.read<ClientCitasViewModel>();
    await vm.loadBarberos(servicioId: s.id);
  }

  Future<void> _onBarbero(int id) async {
    final s = _servicio;
    if (s == null) return;
    setState(() {
      _barberoId = id;
      _hora = null;
    });
    final fecha = _fecha.toIso8601String().substring(0, 10);
    await context.read<ClientCitasViewModel>().loadDisponibilidad(
      barberoId: id,
      fecha: fecha,
      duracion: s.duracionMinutos,
    );
  }

  Future<void> _pickDate() async {
    final citasVm = context.read<ClientCitasViewModel>();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _fecha = picked;
      _hora = null;
    });
    final barberoId = _barberoId;
    final servicio = _servicio;
    if (barberoId != null && servicio != null) {
      await citasVm.loadDisponibilidad(
        barberoId: barberoId,
        fecha: picked.toIso8601String().substring(0, 10),
        duracion: servicio.duracionMinutos,
      );
    }
  }

  Future<void> _reservar() async {
    final auth = context.read<AuthViewModel>();
    final user = auth.user;
    final s = _servicio;
    final b = _barberoId;
    final h = _hora;
    if (user == null || s == null || b == null || h == null) return;

    final vm = context.read<ClientCitasViewModel>();
    await vm.loadPolitica(user.id);
    if (vm.politica?.requiereAnticipo == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Esta cuenta requiere anticipo (${vm.politica!.porcentajeAnticipo}%). '
            'Completa el anticipo desde la web o con secretaría; la reserva sin anticipo no aplica.',
          ),
        ),
      );
      return;
    }

    final ok = await vm.reservar(
      user: user,
      barberoId: b,
      servicioId: s.id,
      duracionMinutos: s.duracionMinutos,
      fecha: _fecha.toIso8601String().substring(0, 10),
      hora: h,
      precioTotal: s.precio,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (vm.bookingMessage ?? 'Cita creada')
              : (vm.errorMessage ?? 'Error'),
        ),
      ),
    );
    if (!ok) return;
    setState(() {
      _servicio = null;
      _barberoId = null;
      _hora = null;
    });
    await vm.loadMisCitas();
    if (!mounted) return;
    widget.onBooked();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogListViewModel>();
    final vm = context.watch<ClientCitasViewModel>();
    final servicios = catalog.servicios.where((s) => !s.isPromocion).toList();
    final fecha = _fecha.toIso8601String().substring(0, 10);
    final barbero = vm.barberos.where((b) => b.id == _barberoId).firstOrNull;
    final paso = _hora != null
        ? 4
        : _barberoId != null
        ? 3
        : _servicio != null
        ? 2
        : 1;

    final listo = _servicio != null && _barberoId != null && _hora != null;
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text(
                  'Reservar',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: _ivory),
                ),
                const SizedBox(height: 6),
                const Text(
                  'La disponibilidad y la confirmación salen de Django.',
                  style: TextStyle(color: _muted),
                ),
                const SizedBox(height: 16),
                _StepRail(step: paso),
                const SizedBox(height: 16),
                if (vm.errorMessage != null) ...[
                  StatusBanner(message: vm.errorMessage!, isError: true),
                  const SizedBox(height: 12),
                ],
                const _StepLabel(index: '01', title: 'Servicio'),
                if (catalog.state == LoadState.loading ||
                    catalog.state == LoadState.idle)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: LoadingView(label: 'Cargando servicios…'),
                  )
                else if (catalog.state == LoadState.error)
                  ErrorView(
                    message: catalog.errorMessage ?? 'Error',
                    onRetry: catalog.loadServicios,
                  )
                else if (servicios.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No hay servicios activos para reservar.'),
                  )
                else
                  ...servicios.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SelectTile(
                        selected: _servicio?.id == s.id,
                        title: s.nombre,
                        subtitle:
                            '${moneyFormat.format(s.precio)} · ${s.duracionMinutos} min',
                        onTap: () => _onServicio(s),
                      ),
                    ),
                  ),
                if (_servicio != null) ...[
                  if (_servicio!.descripcion.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _servicio!.descripcion,
                      style: const TextStyle(color: _muted, height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const _StepLabel(index: '02', title: 'Barbero'),
                  if (vm.barberosLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LoadingView(label: 'Cargando barberos…'),
                    )
                  else if (vm.barberos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No hay barberos para este servicio.'),
                    )
                  else
                    ...vm.barberos.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SelectTile(
                          selected: _barberoId == b.id,
                          title: b.displayName,
                          subtitle: b.especialidades,
                          onTap: () => _onBarbero(b.id),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const _StepLabel(index: '03', title: 'Fecha y horario'),
                  _SelectTile(
                    selected: false,
                    title: fecha,
                    subtitle: 'Cambiar fecha',
                    onTap: _pickDate,
                  ),
                  if (_barberoId == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Elige un barbero para consultar los horarios de esa fecha.',
                        style: TextStyle(color: _muted),
                      ),
                    )
                  else if (vm.slotsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LoadingView(label: 'Consultando horarios…'),
                    )
                  else ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: vm.slots
                          .where((s) => s.disponible)
                          .map(
                            (s) => ChoiceChip(
                              label: Text(s.hora),
                              selected: _hora == s.hora,
                              onSelected: (_) => setState(() => _hora = s.hora),
                            ),
                          )
                          .toList(),
                    ),
                    if (vm.slots.where((s) => s.disponible).isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No hay horarios disponibles para esa fecha.',
                        ),
                      ),
                  ],
                ],
                if (_servicio != null &&
                    _barberoId != null &&
                    _hora != null) ...[
                  const SizedBox(height: 18),
                  const _StepLabel(index: '04', title: 'Resumen'),
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _servicio!.nombre,
                          style: const TextStyle(
                            color: _ivory,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(barbero?.displayName ?? 'Barbero'),
                        Text(
                          '$fecha · $_hora · ${_servicio!.duracionMinutos} min',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          moneyFormat.format(_servicio!.precio),
                          style: const TextStyle(color: AppColors.gold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (listo)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: vm.bookingBusy ? null : _reservar,
                  child: vm.bookingBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onGold,
                          ),
                        )
                      : const Text('Confirmar reserva'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClientPerfilTab extends StatefulWidget {
  const _ClientPerfilTab();

  @override
  State<_ClientPerfilTab> createState() => _ClientPerfilTabState();
}

class _ClientPerfilTabState extends State<_ClientPerfilTab> {
  PerfilDto? _perfil;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final p = await context.read<AuthViewModel>().loadPerfil();
    if (!mounted) return;
    setState(() {
      _perfil = p;
      _loading = false;
      if (p == null) _error = context.read<AuthViewModel>().errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final perfil = _perfil;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            'Perfil',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: _ivory),
          ),
          const SizedBox(height: 16),
          if (_loading) const LoadingView(label: 'Cargando perfil…'),
          if (_error != null) ...[
            StatusBanner(message: _error!, isError: true),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
          if (perfil != null)
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    perfil.displayName,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(color: _ivory),
                  ),
                  const SizedBox(height: 12),
                  _ProfileRow(label: 'Correo', value: perfil.email),
                  if (perfil.username.isNotEmpty)
                    _ProfileRow(label: 'Usuario', value: perfil.username),
                  if (perfil.telefono.isNotEmpty)
                    _ProfileRow(label: 'Teléfono', value: perfil.telefono),
                  if (perfil.fechaNacimiento.isNotEmpty)
                    _ProfileRow(
                      label: 'Nacimiento',
                      value: perfil.fechaNacimiento,
                    ),
                  if (perfil.direccion.isNotEmpty)
                    _ProfileRow(label: 'Dirección', value: perfil.direccion),
                ],
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('perfil_privacidad'),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.privacidad);
              // Al volver, refleja lo que se haya corregido.
              if (mounted) await _load();
            },
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Privacidad y mis datos'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.guestHome,
                (_) => false,
              );
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold),
          ),
          child: const Icon(Icons.content_cut, color: AppColors.gold, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stylo Barber',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ivory,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'BARBERÍA',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.museum,
                  fontSize: 11,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.gold),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _ivory,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(subtitle, style: const TextStyle(color: _muted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Material(
        color: selected ? AppColors.gold.withValues(alpha: 0.12) : _surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.gold : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _ivory),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: const TextStyle(color: _muted)),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: AppColors.gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRail extends StatelessWidget {
  const _StepRail({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 4; i++) ...[
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: i <= step ? AppColors.gold : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 4) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.index, required this.title});

  final String index;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        '$index  $title',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _ivory),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          Text(
            _breakLongTokens(value),
            softWrap: true,
            style: const TextStyle(color: _ivory, height: 1.35),
          ),
        ],
      ),
    );
  }
}

String _breakLongTokens(String value) {
  if (!value.contains('@') && !value.contains('/')) return value;
  return value.replaceAll('@', '@\u200b').replaceAll('.', '.\u200b');
}
