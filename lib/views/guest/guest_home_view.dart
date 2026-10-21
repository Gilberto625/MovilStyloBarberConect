import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/press_scale.dart';
import 'catalog_list_views.dart';
import 'guest_contacto_view.dart';
import 'guest_premium_widgets.dart';

/// Pestañas del invitado (Actividad 3): Inicio, Servicios, Productos y
/// Contacto. "Entrar" abre el inicio de sesión.
enum GuestTab { inicio, servicios, productos, contacto }

class GuestHomeView extends StatefulWidget {
  const GuestHomeView({
    super.key,
    this.initialTab = GuestTab.inicio,
    this.clock,
  });

  final GuestTab initialTab;

  /// Reloj inyectable para pruebas del estado "Abierto ahora".
  final DateTime Function()? clock;

  @override
  State<GuestHomeView> createState() => _GuestHomeViewState();
}

class _GuestHomeViewState extends State<GuestHomeView> {
  late GuestTab _tab = widget.initialTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HomeGuestViewModel>().load();
    });
  }

  void _select(int index) {
    if (index == GuestTab.values.length) {
      Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final tab = GuestTab.values[index];
    if (tab != _tab) setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: AppColors.guestBg,
        navigationBarTheme: theme.navigationBarTheme.copyWith(
          backgroundColor: AppColors.guestCard,
        ),
      ),
      child: PopScope(
        // Atrás en otra pestaña vuelve a Inicio antes de salir.
        canPop: _tab == GuestTab.inicio,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _tab = GuestTab.inicio);
        },
        child: Scaffold(
          backgroundColor: AppColors.guestBg,
          body: SafeArea(
            bottom: false,
            child: Consumer<HomeGuestViewModel>(
              builder: (context, vm, _) {
                if (vm.state == LoadState.loading ||
                    vm.state == LoadState.idle) {
                  return Semantics(
                    liveRegion: true,
                    child: const LoadingView(label: 'Cargando catálogo…'),
                  );
                }
                if (vm.state == LoadState.error) {
                  return Semantics(
                    liveRegion: true,
                    child: ErrorView(
                      title: 'No se pudo cargar el catálogo',
                      message:
                          vm.errorMessage ??
                          'No se pudo cargar la información.',
                      onRetry: vm.load,
                    ),
                  );
                }
                return QuietEntrance(
                  rise: 8,
                  child: AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.quick),
                    switchInCurve: AppMotion.ease,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(_tab),
                      child: RefreshIndicator(
                        color: AppColors.gold,
                        backgroundColor: AppColors.surface,
                        onRefresh: vm.load,
                        child: _body(vm),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: NavigationBar(
              selectedIndex: _tab.index,
              onDestinationSelected: _select,
              destinations: const [
                NavigationDestination(
                  key: ValueKey('guest-nav-inicio'),
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  key: ValueKey('guest-nav-servicios'),
                  icon: Icon(Icons.content_cut_outlined),
                  selectedIcon: Icon(Icons.content_cut_rounded),
                  label: 'Servicios',
                ),
                NavigationDestination(
                  key: ValueKey('guest-nav-productos'),
                  icon: Icon(Icons.shopping_bag_outlined),
                  selectedIcon: Icon(Icons.shopping_bag_rounded),
                  label: 'Productos',
                ),
                NavigationDestination(
                  key: ValueKey('guest-nav-contacto'),
                  icon: Icon(Icons.place_outlined),
                  selectedIcon: Icon(Icons.place_rounded),
                  label: 'Contacto',
                ),
                NavigationDestination(
                  key: ValueKey('guest-nav-entrar'),
                  icon: Icon(Icons.login_rounded),
                  label: 'Entrar',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(HomeGuestViewModel vm) {
    final now = widget.clock?.call() ?? DateTime.now();
    switch (_tab) {
      case GuestTab.inicio:
        return _InicioTab(
          vm: vm,
          now: now,
          onTab: (tab) => setState(() => _tab = tab),
        );
      case GuestTab.servicios:
        if (vm.servicios.isEmpty) {
          return _VacioTab(
            icon: Icons.content_cut_rounded,
            title: 'Aún no hay servicios publicados',
            onRetry: vm.load,
          );
        }
        return ServiciosCatalogo(
          key: const ValueKey('guest-servicios-tab'),
          servicios: vm.servicios,
          origen: 'lista',
          header: const CatalogHeader(
            title: 'Servicios',
            subtitle: 'Precio y duración de cada servicio.',
          ),
        );
      case GuestTab.productos:
        if (vm.productos.isEmpty) {
          return _VacioTab(
            icon: Icons.shopping_bag_outlined,
            title: 'Aún no hay productos publicados',
            onRetry: vm.load,
          );
        }
        return ProductosCatalogo(
          key: const ValueKey('guest-productos-tab'),
          productos: vm.productos,
          origen: 'lista',
          header: const CatalogHeader(
            title: 'Productos',
            subtitle: 'Cuidado para el cabello y la barba.',
          ),
        );
      case GuestTab.contacto:
        return GuestContactoTab(contacto: vm.contacto, now: now);
    }
  }
}

class _VacioTab extends StatelessWidget {
  const _VacioTab({
    required this.icon,
    required this.title,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    // ListView para que el gesto de actualizar siga funcionando.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: AppSpacing.huge),
        EmptyView(
          icon: icon,
          title: title,
          message: 'Cuando la barbería los publique aparecerán aquí.',
          actionLabel: 'Actualizar',
          onRetry: onRetry,
        ),
      ],
    );
  }
}

/// Invitado › Pantalla 1: Inicio (Actividad 3).
class _InicioTab extends StatelessWidget {
  const _InicioTab({required this.vm, required this.now, required this.onTab});

  final HomeGuestViewModel vm;
  final DateTime now;
  final ValueChanged<GuestTab> onTab;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = constraints.maxWidth >= 600 ? 28.0 : AppSpacing.page;
        final width = (constraints.maxWidth - gutter * 2).clamp(0.0, 1040.0);
        final inset = (constraints.maxWidth - width) / 2;
        final c = vm.contacto;
        final services = vm.serviciosDestacados;
        final products = vm.productosDestacados;
        final heroImage = services
            .where((service) => service.imagenUrl.trim().isNotEmpty)
            .firstOrNull;
        final hoy = c.horarioHoy(now);
        final hayContacto =
            c.direccion.isNotEmpty ||
            c.telefono.isNotEmpty ||
            c.horariosPorDia.isNotEmpty ||
            c.horario.isNotEmpty;
        return ListView(
          key: const PageStorageKey('guest-home-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(inset, AppSpacing.sm, inset, 36),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240, minHeight: 56),
                child: Semantics(
                  label: c.nombreNegocio,
                  child: BrandTitle(
                    part1: c.logoParte1,
                    part2: c.logoParte2,
                    logoHeight: 64,
                    logoUrl: c.logoUrl.isEmpty ? null : c.logoUrl,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (vm.state == LoadState.empty) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  'No hay servicios ni productos publicados todavía.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.muted),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
            _GuestHero(
              image: heroImage,
              wide: width >= 600,
              hoy: hoy,
              onReserve: () => Navigator.pushNamed(context, AppRoutes.login),
            ),
            if (vm.promociones.isNotEmpty) ...[
              const SectionHeader(title: 'Promociones'),
              for (final promo in vm.promociones)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: SurfaceCard(
                    padding: EdgeInsets.zero,
                    semanticLabel: 'Promoción. ${promo.nombre}',
                    onTap: () => abrirServicio(context, promo, origen: 'promo'),
                    child: AspectRatio(
                      aspectRatio: 16 / 7,
                      child: GuestPremiumImage(
                        url: promo.bannerUrl,
                        fit: BoxFit.cover,
                        label: promo.nombre,
                        fallbackIcon: Icons.local_offer_outlined,
                      ),
                    ),
                  ),
                ),
            ],
            SectionHeader(
              title: 'Servicios',
              action: 'Ver todos',
              actionKey: const ValueKey('guest-services-all'),
              onAction: () => onTab(GuestTab.servicios),
            ),
            if (services.isEmpty)
              Text(
                'Sin servicios disponibles.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.muted),
              )
            else
              _CatalogRail(
                cardWidth: width >= 600
                    ? 248
                    : (width * 0.72).clamp(196.0, 228.0),
                children: [
                  for (final service in services)
                    GuestServiceCard(
                      servicio: service,
                      heroTag: servicioHeroTag('inicio', service),
                      onTap: () =>
                          abrirServicio(context, service, origen: 'inicio'),
                    ),
                ],
              ),
            SectionHeader(
              title: 'Productos',
              action: 'Ver todos',
              actionKey: const ValueKey('guest-products-all'),
              onAction: () => onTab(GuestTab.productos),
            ),
            if (products.isEmpty)
              Text(
                'Sin productos disponibles.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.muted),
              )
            else
              _CatalogRail(
                cardWidth: width >= 600 ? 240 : 210,
                children: [
                  for (final product in products)
                    GuestProductCard(
                      producto: product,
                      heroTag: productoHeroTag('inicio', product),
                      onTap: () =>
                          abrirProducto(context, product, origen: 'inicio'),
                    ),
                ],
              ),
            if (hayContacto) ...[
              const SectionHeader(title: 'Visítanos'),
              SurfaceCard(
                key: const ValueKey('guest-visit-card'),
                semanticLabel: 'Ver contacto y horarios',
                onTap: () => onTab(GuestTab.contacto),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, color: AppColors.gold),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.direccion.isNotEmpty
                                ? c.direccion
                                : 'Horarios, teléfono y ubicación',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.ivory),
                          ),
                          if (hoy != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            HoyEstadoLine(hoy: hoy),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GuestHero extends StatelessWidget {
  const _GuestHero({
    required this.image,
    required this.wide,
    required this.hoy,
    required this.onReserve,
  });

  final ServicioDto? image;
  final bool wide;
  final HorarioHoy? hoy;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = MediaQuery.sizeOf(context).height;
        final floor = (constraints.maxWidth * (wide ? 0.46 : 0.78)).clamp(
          220.0,
          viewport < 420 ? 250.0 : 360.0,
        );
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.guestCard,
            borderRadius: BorderRadius.circular(AppRadii.sheet),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              if (image != null)
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: GuestPremiumImage(
                      url: image!.imagenUrl,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, 0.22),
                      label: image!.nombre,
                      fallbackIcon: Icons.content_cut_outlined,
                    ),
                  ),
                ),
              // Velo para que el texto se lea sobre cualquier foto.
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x330A100E),
                        Color(0x000A100E),
                        Color(0xB80A100E),
                        Color(0xF20A100E),
                      ],
                      stops: [0, 0.3, 0.6, 1],
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: floor),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 32 : AppSpacing.xl,
                    wide ? 28 : 18,
                    wide ? 32 : AppSpacing.xl,
                    wide ? AppSpacing.xxl : AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Semantics(
                          header: true,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Tu Estilo,\n'),
                                TextSpan(
                                  text: 'Nuestra Pasión',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.ivory.withValues(
                                      alpha: 0.92,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: AppColors.ivory,
                                  fontSize: wide ? 44 : 34,
                                  height: 1.06,
                                ),
                          ),
                        ),
                      ),
                      if (hoy != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        HoyEstadoLine(hoy: hoy, onPhoto: true),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: PressScale(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: wide ? 196 : double.infinity,
                            ),
                            child: ElevatedButton(
                              key: const ValueKey('guest-reservar'),
                              onPressed: onReserve,
                              child: const Text('Reservar cita'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogRail extends StatelessWidget {
  const _CatalogRail({required this.cardWidth, required this.children});

  final double cardWidth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Las listas destacadas son cortas: comparten un alto que sale del
    // contenido (nombres completos y texto escalado), no uno fijo.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(width: AppSpacing.md),
              SizedBox(width: cardWidth, child: children[index]),
            ],
          ],
        ),
      ),
    );
  }
}
