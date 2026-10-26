import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cita_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/client_citas_viewmodel.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../viewmodels/tienda_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/press_scale.dart';
import 'client_agendar_view.dart';
import 'client_citas_view.dart';
import 'client_perfil_view.dart';
import 'client_tienda_view.dart';
import 'client_widgets.dart';

/// Pestañas del cliente (Actividad 3): Inicio, Agendar, Citas, Tienda y
/// Perfil.
enum ClientTab { inicio, agendar, citas, tienda, perfil }

class ClientHomeShell extends StatefulWidget {
  const ClientHomeShell({super.key, this.crearTienda});

  /// Fábrica del ViewModel de la tienda. Por defecto usa los repositorios de
  /// [AppScope]; las pruebas pasan la suya.
  final TiendaViewModel Function(BuildContext context)? crearTienda;

  @override
  State<ClientHomeShell> createState() => _ClientHomeShellState();
}

class _ClientHomeShellState extends State<ClientHomeShell> {
  var _tab = ClientTab.inicio;

  /// Paso actual de Agendar: Atrás retrocede pasos antes de salir.
  var _pasoAgendar = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ClientCitasViewModel>().loadMisCitas();
      context.read<AuthViewModel>().loadPerfil();
    });
  }

  void _open(ClientTab tab) {
    if (tab != _tab) setState(() => _tab = tab);
  }

  TiendaViewModel _tienda(BuildContext context) {
    final fabrica = widget.crearTienda;
    if (fabrica != null) return fabrica(context);
    final scope = context.read<AppScope>();
    return TiendaViewModel(
      catalogo: scope.catalogRepository,
      pedidos: scope.pedidosRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dur = AppMotion.of(context, AppMotion.quick);
    return ChangeNotifierProvider<TiendaViewModel>(
      // Se crea al abrir la tienda y muere con la sesión (PM09).
      create: _tienda,
      child: PopScope(
        canPop: _tab == ClientTab.inicio,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_tab == ClientTab.agendar && _pasoAgendar > 0) return;
          _open(ClientTab.inicio);
        },
        child: Scaffold(
          backgroundColor: AppColors.panelBg,
          body: AnimatedSwitcher(
            duration: dur,
            switchInCurve: AppMotion.ease,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(
              key: ValueKey(_tab),
              child: switch (_tab) {
                ClientTab.inicio => _ClientInicioTab(onOpen: _open),
                ClientTab.agendar => ClientAgendarTab(
                  onBooked: () => _open(ClientTab.citas),
                  onPaso: (p) => _pasoAgendar = p,
                ),
                ClientTab.citas => ClientCitasTab(
                  onAgendar: () => _open(ClientTab.agendar),
                ),
                ClientTab.tienda => const ClientTiendaTab(),
                ClientTab.perfil => const ClientPerfilTab(),
              },
            ),
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: NavigationBar(
              selectedIndex: _tab.index,
              onDestinationSelected: (i) => _open(ClientTab.values[i]),
              destinations: const [
                NavigationDestination(
                  key: ValueKey('cliente-nav-inicio'),
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  key: ValueKey('cliente-nav-agendar'),
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Agendar',
                ),
                NavigationDestination(
                  key: ValueKey('cliente-nav-citas'),
                  icon: Icon(Icons.event_note_outlined),
                  selectedIcon: Icon(Icons.event_note_rounded),
                  label: 'Citas',
                ),
                NavigationDestination(
                  key: ValueKey('cliente-nav-tienda'),
                  icon: Icon(Icons.shopping_bag_outlined),
                  selectedIcon: Icon(Icons.shopping_bag_rounded),
                  label: 'Tienda',
                ),
                NavigationDestination(
                  key: ValueKey('cliente-nav-perfil'),
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cliente › Pantalla 1: inicio con la próxima cita y accesos rápidos.
class _ClientInicioTab extends StatelessWidget {
  const _ClientInicioTab({required this.onOpen});

  final ValueChanged<ClientTab> onOpen;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final citas = context.watch<ClientCitasViewModel>();
    final theme = Theme.of(context).textTheme;
    final name = auth.nombreCorto;
    final sinConexion =
        citas.state == LoadState.error && citas.citas.isNotEmpty;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: citas.loadMisCitas,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.lg,
            AppSpacing.page,
            AppSpacing.xxxl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text('Hola, $name', style: theme.headlineMedium),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tu silla, tus citas y la tienda de la barbería.',
              style: theme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            if (sinConexion) ...[
              const SizedBox(height: AppSpacing.lg),
              const StatusBanner(
                key: Key('cliente_sin_conexion'),
                tone: BannerTone.aviso,
                message:
                    'Sin conexión con la barbería. Ves lo último que se '
                    'cargó; agendar y pedir necesitan internet.',
              ),
            ],
            const SectionHeader(title: 'Próxima cita'),
            QuietEntrance(
              rise: 10,
              child: _ProximaCita(
                vm: citas,
                onAgendar: () => onOpen(ClientTab.agendar),
              ),
            ),
            const SectionHeader(title: 'Accesos'),
            Row(
              children: [
                Expanded(
                  child: _Acceso(
                    key: const Key('inicio_reservar'),
                    icon: Icons.content_cut_rounded,
                    label: 'Reservar cita',
                    onTap: () => onOpen(ClientTab.agendar),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Acceso(
                    key: const Key('inicio_mis_citas'),
                    icon: Icons.event_note_outlined,
                    label: 'Mis citas',
                    onTap: () => onOpen(ClientTab.citas),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Acceso(
                    key: const Key('inicio_tienda'),
                    icon: Icons.shopping_bag_outlined,
                    label: 'Ver tienda',
                    onTap: () => onOpen(ClientTab.tienda),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SurfaceCard(
              key: const Key('inicio_servicios'),
              semanticLabel: 'Servicios y precios',
              onTap: () => Navigator.pushNamed(context, AppRoutes.servicios),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    const Icon(Icons.sell_outlined, color: AppColors.goldSoft),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        'Servicios y precios',
                        style: theme.titleMedium?.copyWith(
                          color: AppColors.ivory,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProximaCita extends StatelessWidget {
  const _ProximaCita({required this.vm, required this.onAgendar});

  final ClientCitasViewModel vm;
  final VoidCallback onAgendar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final next = _proxima(vm.citas);
    if (next != null) {
      return CitaTicket(
        key: const Key('inicio_proxima_cita'),
        cita: next,
        actions: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              AppRoutes.page<void>(CitaDetalleView(cita: next)),
            ),
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Ver detalle'),
          ),
        ),
      );
    }
    if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
      return const SurfaceCard(
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Text('Consultando tus citas…')),
          ],
        ),
      );
    }
    if (vm.state == LoadState.error) {
      return SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vm.errorMessage ?? 'No se pudieron cargar las citas.',
              style: theme.bodyMedium,
            ),
            TextButton(
              onPressed: vm.loadMisCitas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sin cita próxima', style: theme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Cuando reserves, tu próxima cita aparecerá aquí.',
            style: theme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          PressScale(
            child: ElevatedButton(
              key: const Key('inicio_agendar'),
              onPressed: onAgendar,
              child: const Text('Agendar cita'),
            ),
          ),
        ],
      ),
    );
  }

  CitaDto? _proxima(List<CitaDto> citas) {
    final abiertas = citas.where(esCitaProxima).toList();
    if (abiertas.isEmpty) return null;
    abiertas.sort(
      (a, b) => '${a.fecha} ${a.hora}'.compareTo('${b.fecha} ${b.hora}'),
    );
    return abiertas.first;
  }
}

class _Acceso extends StatelessWidget {
  const _Acceso({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.lg,
        ),
        onTap: onTap,
        semanticLabel: label,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: AppColors.ivory),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
