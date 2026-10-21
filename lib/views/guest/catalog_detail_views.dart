import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/media/variante_imagen.dart';
import '../../core/theme/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/press_scale.dart';
import 'guest_premium_widgets.dart';

/// Qué ofrece el pie del detalle.
enum DetalleAccion {
  /// Invitado: lleva a iniciar sesión.
  iniciarSesion,

  /// Sin acción (por ejemplo, consulta desde un panel con sesión).
  ninguna,
}

/// Argumentos de las rutas de detalle (`AppRoutes.servicioDetalle` y
/// `AppRoutes.productoDetalle`).
class CatalogDetailArgs<T> {
  const CatalogDetailArgs(
    this.item, {
    this.heroTag,
    this.accion = DetalleAccion.iniciarSesion,
  });

  final T item;
  final Object? heroTag;
  final DetalleAccion accion;
}

/// Invitado › Pantalla 3: detalle del servicio (Actividad 3).
class ServicioDetailView extends StatelessWidget {
  const ServicioDetailView({
    super.key,
    required this.servicio,
    this.heroTag,
    this.accion = DetalleAccion.iniciarSesion,
  });

  final ServicioDto servicio;
  final Object? heroTag;
  final DetalleAccion accion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final descripcion = servicio.descripcion.trim();
    return _DetailScaffold(
      title: servicio.nombre,
      heroTag: heroTag,
      image: GuestPremiumImage(
        url: servicio.imagenUrl,
        fit: BoxFit.cover,
        variante: VarianteImagen.detalle,
        label: servicio.nombre,
        fallbackIcon: Icons.content_cut_rounded,
      ),
      action: accion == DetalleAccion.iniciarSesion
          ? _DetailAction(
              buttonKey: const ValueKey('servicio-detalle-reservar'),
              label: 'Reservar este servicio',
              hint: 'Inicia sesión para elegir barbero, día y hora.',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            )
          : null,
      children: [
        Text(servicio.nombre, style: theme.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              moneyFormat.format(servicio.precio),
              style: AppText.cifra(size: 26, color: AppColors.gold),
            ),
            _Dato(
              icon: Icons.schedule_rounded,
              text: '${servicio.duracionMinutos} min',
            ),
          ],
        ),
        if (descripcion.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          Text('Qué incluye', style: theme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            descripcion,
            style: theme.bodyLarge?.copyWith(
              color: AppColors.text,
              height: 1.55,
            ),
          ),
        ],
      ],
    );
  }
}

/// Invitado › Pantalla 5: detalle del producto (Actividad 3).
class ProductoDetailView extends StatelessWidget {
  const ProductoDetailView({
    super.key,
    required this.producto,
    this.heroTag,
    this.accion = DetalleAccion.iniciarSesion,
  });

  final ProductoDto producto;
  final Object? heroTag;
  final DetalleAccion accion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final marca = producto.marca.trim();
    final descripcion = producto.descripcion.trim();
    final disponible = producto.stock > 0;
    return _DetailScaffold(
      title: producto.nombre,
      heroTag: heroTag,
      imagePadding: const EdgeInsets.fromLTRB(32, 72, 32, 24),
      image: GuestPremiumImage(
        url: producto.imagenUrl,
        fit: BoxFit.contain,
        variante: VarianteImagen.productoDetalle,
        label: producto.nombre,
        fallbackIcon: Icons.shopping_bag_outlined,
      ),
      action: accion == DetalleAccion.iniciarSesion
          ? _DetailAction(
              buttonKey: const ValueKey('producto-detalle-entrar'),
              label: 'Iniciar sesión para pedir',
              hint: disponible
                  ? 'Los pedidos se hacen desde tu cuenta.'
                  : 'Este producto está agotado por ahora.',
              onPressed: disponible
                  ? () => Navigator.pushNamed(context, AppRoutes.login)
                  : null,
            )
          : null,
      children: [
        if (marca.isNotEmpty) ...[
          Text(
            marca,
            style: theme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(producto.nombre, style: theme.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              moneyFormat.format(producto.precio),
              style: AppText.cifra(size: 26, color: AppColors.gold),
            ),
            _Disponibilidad(stock: producto.stock),
          ],
        ),
        if (descripcion.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          Text('Descripción', style: theme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            descripcion,
            style: theme.bodyLarge?.copyWith(
              color: AppColors.text,
              height: 1.55,
            ),
          ),
        ],
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: AppColors.text),
        ),
      ],
    );
  }
}

class _Disponibilidad extends StatelessWidget {
  const _Disponibilidad({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final disponible = stock > 0;
    final color = disponible ? AppColors.ok : AppColors.crit;
    final texto = !disponible
        ? 'Agotado'
        : stock == 1
        ? 'Queda 1 pieza'
        : 'Disponible, $stock piezas';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            texto,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.text),
          ),
        ),
      ],
    );
  }
}

class _DetailAction {
  const _DetailAction({
    required this.buttonKey,
    required this.label,
    required this.hint,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final String hint;
  final VoidCallback? onPressed;
}

/// Foto arriba (con Hero desde la tarjeta), contenido y una acción fija al
/// pie. Al plegar la foto, el título aparece en la barra.
class _DetailScaffold extends StatefulWidget {
  const _DetailScaffold({
    required this.title,
    required this.heroTag,
    required this.image,
    required this.children,
    this.action,
    this.imagePadding = EdgeInsets.zero,
  });

  final String title;
  final Object? heroTag;
  final Widget image;
  final List<Widget> children;
  final _DetailAction? action;
  final EdgeInsets imagePadding;

  @override
  State<_DetailScaffold> createState() => _DetailScaffoldState();
}

class _DetailScaffoldState extends State<_DetailScaffold> {
  final _scroll = ScrollController();
  var _collapsed = false;
  double _imageHeight = 300;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final collapsed =
          _scroll.hasClients &&
          _scroll.offset > _imageHeight - kToolbarHeight - 24;
      if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    _imageHeight = math.min(size.width * 0.8, size.height * 0.42);
    final action = widget.action;
    return Scaffold(
      backgroundColor: AppColors.guestBg,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _imageHeight,
            backgroundColor: AppColors.guestBg,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: IconButton(
                key: const ValueKey('detalle-volver'),
                tooltip: 'Volver',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.guestBg.withValues(alpha: 0.72),
                ),
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            title: AnimatedOpacity(
              opacity: _collapsed ? 1 : 0,
              duration: AppMotion.of(context, AppMotion.quick),
              curve: AppMotion.ease,
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: ColoredBox(
                color: AppColors.surface,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: widget.imagePadding,
                      child: CatalogHero(
                        tag: widget.heroTag,
                        child: widget.image,
                      ),
                    ),
                    // Velo arriba: la barra de estado y Volver se leen sobre
                    // cualquier foto.
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment(0, -0.4),
                            colors: [Color(0x990A100E), Color(0x000A100E)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContent,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.xxl,
                    AppSpacing.page,
                    AppSpacing.xxxl,
                  ),
                  child: QuietEntrance(
                    rise: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.children,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: action == null
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.guestCard,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        action.hint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ElevatedButton(
                        key: action.buttonKey,
                        onPressed: action.onPressed,
                        child: Text(action.label),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
