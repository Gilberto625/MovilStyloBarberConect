import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/auth_models.dart';
import '../../models/catalog_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/catalog_list_viewmodel.dart';
import '../../viewmodels/client_citas_viewmodel.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../widgets/common_widgets.dart';

class ClientHomeShell extends StatefulWidget {
  const ClientHomeShell({super.key});

  @override
  State<ClientHomeShell> createState() => _ClientHomeShellState();
}

class _ClientHomeShellState extends State<ClientHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _ClientHomeTab(),
      const _ClientCitasTab(),
      const _ClientAgendarTab(),
      const _ClientPerfilTab(),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            label: 'Citas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Agendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _ClientHomeTab extends StatelessWidget {
  const _ClientHomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Hola, ${auth.user?.username ?? 'cliente'}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Agenda, consulta tus citas y revisa el catálogo.'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.servicios),
            child: const Text('Ver servicios'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.productos),
            child: const Text('Ver productos'),
          ),
        ],
      ),
    );
  }
}

class _ClientCitasTab extends StatefulWidget {
  const _ClientCitasTab();

  @override
  State<_ClientCitasTab> createState() => _ClientCitasTabState();
}

class _ClientCitasTabState extends State<_ClientCitasTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientCitasViewModel>().loadMisCitas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ClientCitasViewModel>(
        builder: (context, vm, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mis citas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: vm.loadMisCitas,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: StatusBanner(message: vm.errorMessage!, isError: true),
                ),
              Expanded(
                child: switch (vm.state) {
                  LoadState.loading || LoadState.idle => const LoadingView(),
                  LoadState.error => ErrorView(
                    message: vm.errorMessage ?? 'Error',
                    onRetry: vm.loadMisCitas,
                  ),
                  LoadState.empty => EmptyView(
                    message: 'Aún no tienes citas.',
                    onRetry: vm.loadMisCitas,
                  ),
                  LoadState.ready => ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.citas.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = vm.citas[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.panelCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.servicioNombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                EstadoChip(estado: c.estado),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('${c.fecha} · ${c.hora}'),
                            Text(
                              c.barberoNombre,
                              style: const TextStyle(color: AppColors.museum),
                            ),
                            Text(
                              moneyFormat.format(c.precioTotal),
                              style: const TextStyle(color: AppColors.gold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClientAgendarTab extends StatefulWidget {
  const _ClientAgendarTab();

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
    if (ok) await vm.loadMisCitas();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogListViewModel>();
    final vm = context.watch<ClientCitasViewModel>();
    final servicios = catalog.servicios.where((s) => !s.isPromocion).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Agendar cita', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Disponibilidad y creación contra Django. Sin pagos simulados.',
          ),
          const SizedBox(height: 16),
          if (vm.errorMessage != null)
            StatusBanner(message: vm.errorMessage!, isError: true),
          Text('1. Servicio', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (catalog.state == LoadState.loading)
            const LoadingView()
          else
            ...servicios.map(
              (s) => ListTile(
                selected: _servicio?.id == s.id,
                selectedTileColor: AppColors.gold.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _servicio?.id == s.id
                        ? AppColors.gold
                        : AppColors.border,
                  ),
                ),
                title: Text(s.nombre),
                subtitle: Text(
                  '${moneyFormat.format(s.precio)} · ${s.duracionMinutos} min',
                ),
                trailing: _servicio?.id == s.id
                    ? const Icon(Icons.check_circle, color: AppColors.gold)
                    : null,
                onTap: () => _onServicio(s),
              ),
            ),
          if (_servicio != null) ...[
            const SizedBox(height: 12),
            Text('2. Barbero', style: Theme.of(context).textTheme.titleMedium),
            ...vm.barberos.map(
              (b) => ListTile(
                selected: _barberoId == b.id,
                selectedTileColor: AppColors.gold.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _barberoId == b.id
                        ? AppColors.gold
                        : AppColors.border,
                  ),
                ),
                title: Text(b.displayName),
                subtitle: Text(b.especialidades),
                trailing: _barberoId == b.id
                    ? const Icon(Icons.check_circle, color: AppColors.gold)
                    : null,
                onTap: () => _onBarbero(b.id),
              ),
            ),
            ListTile(
              title: Text(
                'Fecha: ${_fecha.toIso8601String().substring(0, 10)}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            if (_barberoId != null) ...[
              Text(
                '3. Horario',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
                  child: Text('No hay horarios disponibles para esa fecha.'),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_hora == null || vm.bookingBusy)
                      ? null
                      : _reservar,
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
            ],
          ],
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Perfil', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (_loading) const LoadingView(),
          if (_error != null) StatusBanner(message: _error!, isError: true),
          if (_perfil != null) ...[
            Text(
              _perfil!.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(_perfil!.email),
            if (_perfil!.telefono.isNotEmpty) Text(_perfil!.telefono),
            if (_perfil!.direccion.isNotEmpty) Text(_perfil!.direccion),
          ],
          const SizedBox(height: 24),
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
