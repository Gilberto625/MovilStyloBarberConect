import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import 'guest_premium_widgets.dart';

const _ivory = Color(0xFFF4F0E8);
const _muted = Color(0xFFA6BAB0);
const _weekdays = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

class GuestHomeView extends StatefulWidget {
  const GuestHomeView({super.key});

  @override
  State<GuestHomeView> createState() => _GuestHomeViewState();
}

class _GuestHomeViewState extends State<GuestHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HomeGuestViewModel>().load();
    });
  }

  void _navigate(String route) => Navigator.pushNamed(context, route);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Keep the application's Fraunces/Manrope fonts without another font
    // request or changing the authenticated screens' theme.
    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: AppColors.guestBg,
        colorScheme: theme.colorScheme.copyWith(
          primary: AppColors.gold,
          onPrimary: AppColors.onGold,
          surface: AppColors.guestCard,
          onSurface: _ivory,
        ),
        textTheme: theme.textTheme.apply(
          bodyColor: _ivory,
          displayColor: _ivory,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.guestBg,
        body: SafeArea(
          child: Consumer<HomeGuestViewModel>(
            builder: (context, vm, _) {
              if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
                return Semantics(
                  liveRegion: true,
                  child: const LoadingView(label: 'Cargando catálogo…'),
                );
              }
              if (vm.state == LoadState.error) {
                return Semantics(
                  liveRegion: true,
                  child: ErrorView(
                    message:
                        vm.errorMessage ?? 'No se pudo cargar la información.',
                    onRetry: vm.load,
                  ),
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final gutter = constraints.maxWidth >= 600 ? 28.0 : 20.0;
                  final width = (constraints.maxWidth - gutter * 2).clamp(
                    0.0,
                    1040.0,
                  );
                  final inset = (constraints.maxWidth - width) / 2;
                  final c = vm.contacto;
                  final services = vm.serviciosDestacados;
                  final products = vm.productosDestacados;
                  final heroImage = services
                      .where((service) => service.imagenUrl.trim().isNotEmpty)
                      .firstOrNull;
                  return RefreshIndicator(
                    color: AppColors.gold,
                    backgroundColor: AppColors.guestCard,
                    onRefresh: vm.load,
                    child: _GuestEntrance(
                      child: ListView(
                        key: const PageStorageKey('guest-home-scroll'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(inset, 8, inset, 36),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 240,
                                      minHeight: 56,
                                    ),
                                    child: Semantics(
                                      label: c.nombreNegocio,
                                      child: BrandTitle(
                                        part1: c.logoParte1,
                                        part2: c.logoParte2,
                                        logoHeight: 68,
                                        logoUrl: c.logoUrl.isEmpty
                                            ? null
                                            : c.logoUrl,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(88, 48),
                                  foregroundColor: AppColors.gold,
                                  side: const BorderSide(color: AppColors.gold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => _navigate(AppRoutes.login),
                                child: const Text('Entrar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (vm.state == LoadState.empty) ...[
                            Semantics(
                              liveRegion: true,
                              child: const Text(
                                'No hay servicios ni productos publicados todavía.',
                                style: TextStyle(color: _muted),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          _GuestHero(
                            contacto: c,
                            image: heroImage,
                            wide: width >= 600,
                            onReserve: () => _navigate(AppRoutes.login),
                          ),
                          if (vm.promociones.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            const _SectionTitle(title: 'Promociones'),
                            const SizedBox(height: 16),
                            ...vm.promociones.map(
                              (service) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 7,
                                    child: GuestPremiumImage(
                                      url: service.bannerUrl,
                                      fit: BoxFit.cover,
                                      label: service.nombre,
                                      fallbackIcon: Icons.local_offer_outlined,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          _SectionTitle(
                            title: 'Servicios',
                            actionKey: const ValueKey('guest-services-all'),
                            onAll: () => _navigate(AppRoutes.servicios),
                          ),
                          const SizedBox(height: 16),
                          if (services.isEmpty)
                            const Text(
                              'Sin servicios disponibles.',
                              style: TextStyle(color: _muted),
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
                                    onTap: () => _navigate(AppRoutes.servicios),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 32),
                          _SectionTitle(
                            title: 'Productos',
                            actionKey: const ValueKey('guest-products-all'),
                            onAll: () => _navigate(AppRoutes.productos),
                          ),
                          const SizedBox(height: 16),
                          if (products.isEmpty)
                            const Text(
                              'Sin productos disponibles.',
                              style: TextStyle(color: _muted),
                            )
                          else
                            _CatalogRail(
                              cardWidth: width >= 600 ? 240 : 210,
                              children: [
                                for (final product in products)
                                  GuestProductCard(
                                    producto: product,
                                    onTap: () => _navigate(AppRoutes.productos),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 32),
                          const _SectionTitle(title: 'Encuéntranos'),
                          const SizedBox(height: 16),
                          _GuestContact(contacto: c, wide: width >= 720),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GuestEntrance extends StatefulWidget {
  const _GuestEntrance({required this.child});

  final Widget child;

  @override
  State<_GuestEntrance> createState() => _GuestEntranceState();
}

class _GuestEntranceState extends State<_GuestEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      _controller.value = 0;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}

class _GuestHero extends StatelessWidget {
  const _GuestHero({
    required this.contacto,
    required this.image,
    required this.wide,
    required this.onReserve,
  });
  final ContactoDto contacto;
  final ServicioDto? image;
  final bool wide;
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
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
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
                      stops: [0, 0.34, 0.62, 1],
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: floor),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 32 : 20,
                    wide ? 28 : 18,
                    wide ? 32 : 20,
                    wide ? 24 : 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Text(
                          contacto.nombreNegocio,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Tu Estilo,\n'),
                              TextSpan(
                                text: 'Nuestra Pasión',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: _ivory.withValues(alpha: 0.92),
                                ),
                              ),
                            ],
                          ),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: _ivory,
                                fontSize: wide ? 44 : 32,
                                height: 1.08,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GuestPressable(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: wide ? 196 : double.infinity,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.onGold,
                                minimumSize: const Size(48, 48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.onAll, this.actionKey});
  final String title;
  final VoidCallback? onAll;
  final Key? actionKey;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: _ivory,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 28, height: 1, color: AppColors.gold),
          ],
        ),
      ),
      if (onAll != null)
        TextButton(
          key: actionKey,
          onPressed: onAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gold,
            minimumSize: const Size(48, 48),
          ),
          child: const Text('Ver todos'),
        ),
    ],
  );
}

class _CatalogRail extends StatelessWidget {
  const _CatalogRail({required this.cardWidth, required this.children});
  final double cardWidth;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    // The small featured lists share a content-driven height, including
    // complete names and scaled text, instead of a fixed carousel height.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              SizedBox(width: cardWidth, child: children[index]),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuestContact extends StatelessWidget {
  const _GuestContact({required this.contacto, required this.wide});
  final ContactoDto contacto;
  final bool wide;
  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$label copiado')));
    }
  }

  Widget _line(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 12),
            child: Icon(icon, color: AppColors.gold, size: 22),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  value,
                  style: const TextStyle(
                    color: _ivory,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar ${label.toLowerCase()}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => _copy(context, value, label),
            icon: const Icon(Icons.copy_outlined, color: _muted, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.guestCard,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final info = _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contacto.direccion.isNotEmpty)
            _line(
              context,
              Icons.location_on_outlined,
              'Ubicación',
              contacto.direccion,
            ),
          if (contacto.telefono.isNotEmpty)
            _line(context, Icons.phone_outlined, 'Teléfono', contacto.telefono),
          if (contacto.correo.isNotEmpty)
            _line(context, Icons.mail_outline, 'Correo', contacto.correo),
          if (contacto.googleMapsUrl.isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  _copy(context, contacto.googleMapsUrl, 'Enlace de ubicación'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Copiar enlace de ubicación'),
            ),
          if (contacto.telefono.isEmpty &&
              contacto.correo.isEmpty &&
              contacto.direccion.isEmpty &&
              contacto.googleMapsUrl.isEmpty)
            const Text(
              'Información de contacto no publicada.',
              style: TextStyle(color: _muted),
            ),
        ],
      ),
    );
    final hours = _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_outlined, color: AppColors.gold, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Horarios de atención',
                  style: TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (contacto.horariosPorDia.isNotEmpty)
            ...contacto.horariosPorDia.map(
              (day) => Padding(
                key: ValueKey('guest-schedule-row-${day.diaSemana}'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      Text(
                        _weekdays[day.diaSemana],
                        style: const TextStyle(color: _muted, fontSize: 14),
                      ),
                      Text(
                        day.cerrado
                            ? 'Cerrado'
                            : day.apertura == null && day.cierre == null
                            ? 'Horario no publicado'
                            : '${day.apertura ?? '—'} – ${day.cierre ?? '—'}',
                        style: const TextStyle(color: _ivory, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (contacto.horario.isNotEmpty)
            Text(
              contacto.horario,
              style: const TextStyle(color: _ivory, fontSize: 14, height: 1.6),
            )
          else
            const Text('Horario no publicado', style: TextStyle(color: _muted)),
        ],
      ),
    );
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: info),
          const SizedBox(width: 20),
          Expanded(child: hours),
        ],
      );
    }
    return Column(children: [info, const SizedBox(height: 16), hours]);
  }
}
