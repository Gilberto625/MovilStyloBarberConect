import 'package:flutter/material.dart';

import '../../core/media/variante_imagen.dart';
import '../../core/theme/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../widgets/common_widgets.dart';

/// Foto real del backend (Cloudinary). Sin URL, o si falla, muestra un
/// placeholder honesto con el icono del rubro (DESIGN.md › fotos reales).
class GuestPremiumImage extends StatelessWidget {
  const GuestPremiumImage({
    super.key,
    required this.url,
    required this.fit,
    required this.label,
    required this.fallbackIcon,
    this.alignment = Alignment.center,
    this.variante,
  });

  final String url;
  final BoxFit fit;
  final String label;
  final IconData fallbackIcon;
  final Alignment alignment;

  /// Tamaño y encuadre que se pide a Cloudinary. Sin variante se baja la
  /// foto original.
  final VarianteImagen? variante;

  @override
  Widget build(BuildContext context) {
    final source = url.trim();
    if (source.isEmpty) return _fallback(context, 'Sin imagen');
    final uri = Uri.tryParse(source);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return _fallback(context, 'Imagen no disponible');
    }

    final variante = this.variante;
    return Image.network(
      variante == null ? source : urlVariante(source, variante),
      // Fuera de Cloudinary la foto llega completa: se decodifica al ancho de
      // la variante para no ocupar la memoria de una foto de 12 MP.
      cacheWidth: variante?.ancho,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      alignment: alignment,
      excludeFromSemantics: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return Semantics(
            image: true,
            label: label,
            child: ExcludeSemantics(child: child),
          );
        }
        return _loading();
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final total = progress.expectedTotalBytes;
        return _loading(
          progress: total != null && total > 0
              ? progress.cumulativeBytesLoaded / total
              : null,
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _fallback(context, 'Imagen no disponible'),
    );
  }

  Widget _loading({double? progress}) {
    return Semantics(
      image: true,
      label: '$label. Cargando imagen.',
      child: ExcludeSemantics(
        child: ColoredBox(
          color: AppColors.surface,
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                color: AppColors.gold,
                backgroundColor: AppColors.border,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context, String message) {
    return Semantics(
      image: true,
      label: '$label. $message.',
      child: ExcludeSemantics(
        child: ColoredBox(
          color: AppColors.surface,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceHigh,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        fallbackIcon,
                        color: AppColors.muted,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero de la foto hacia el detalle. Con "reducir movimiento" no vuela.
class CatalogHero extends StatelessWidget {
  const CatalogHero({super.key, required this.tag, required this.child});

  final Object? tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (tag == null) return child;
    return HeroMode(
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: Hero(tag: tag!, child: child),
    );
  }
}

/// Tarjeta de servicio para carruseles: foto, nombre, precio y duración.
class GuestServiceCard extends StatelessWidget {
  const GuestServiceCard({
    super.key,
    required this.servicio,
    required this.onTap,
    this.heroTag,
  });

  final ServicioDto servicio;
  final VoidCallback onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final price = moneyFormat.format(servicio.precio);
    final theme = Theme.of(context).textTheme;
    return _GuestCatalogSurface(
      label:
          'Ver detalle. ${servicio.nombre}. $price. '
          '${servicio.duracionMinutos} minutos.',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: CatalogHero(
              tag: heroTag,
              child: ColoredBox(
                color: AppColors.surface,
                child: SizedBox.expand(
                  child: GuestPremiumImage(
                    url: servicio.imagenUrl,
                    fit: BoxFit.cover,
                    variante: VarianteImagen.tarjeta,
                    label: servicio.nombre,
                    fallbackIcon: Icons.content_cut_rounded,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servicio.nombre,
                  style: theme.titleMedium?.copyWith(
                    fontSize: 17,
                    height: 1.28,
                    color: AppColors.ivory,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        price,
                        style: AppText.cifra(size: 18, color: AppColors.gold),
                      ),
                    ),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${servicio.duracionMinutos} min',
                      style: theme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de servicio para la lista completa: miniatura, nombre, precio y
/// duración. Más fácil de comparar que una tarjeta grande por servicio.
class ServiceListTile extends StatelessWidget {
  const ServiceListTile({
    super.key,
    required this.servicio,
    required this.onTap,
    this.heroTag,
  });

  final ServicioDto servicio;
  final VoidCallback onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final price = moneyFormat.format(servicio.precio);
    final theme = Theme.of(context).textTheme;
    return _GuestCatalogSurface(
      label:
          'Ver detalle. ${servicio.nombre}. $price. '
          '${servicio.duracionMinutos} minutos.',
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox.square(
              dimension: 84,
              child: CatalogHero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: AppRadii.controlBorder,
                  child: GuestPremiumImage(
                    url: servicio.imagenUrl,
                    fit: BoxFit.cover,
                    variante: VarianteImagen.miniatura,
                    label: servicio.nombre,
                    fallbackIcon: Icons.content_cut_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    servicio.nombre,
                    style: theme.titleMedium?.copyWith(
                      height: 1.3,
                      color: AppColors.ivory,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        price,
                        style: AppText.cifra(size: 16, color: AppColors.gold),
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
                            '${servicio.duracionMinutos} min',
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
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de producto: foto, marca, nombre y precio.
class GuestProductCard extends StatelessWidget {
  const GuestProductCard({
    super.key,
    required this.producto,
    required this.onTap,
    this.heroTag,
  });

  final ProductoDto producto;
  final VoidCallback onTap;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final price = moneyFormat.format(producto.precio);
    final brand = producto.marca.trim();
    final theme = Theme.of(context).textTheme;
    return _GuestCatalogSurface(
      label:
          'Ver detalle. ${producto.nombre}. '
          '${brand.isEmpty ? '' : '$brand. '}$price.',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: CatalogHero(
                tag: heroTag,
                child: GuestPremiumImage(
                  url: producto.imagenUrl,
                  fit: BoxFit.contain,
                  variante: VarianteImagen.producto,
                  label: producto.nombre,
                  fallbackIcon: Icons.shopping_bag_outlined,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (brand.isNotEmpty) ...[
                  Text(
                    brand,
                    style: theme.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                ],
                Text(
                  producto.nombre,
                  style: theme.titleMedium?.copyWith(
                    fontSize: 16,
                    height: 1.35,
                    color: AppColors.ivory,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  price,
                  style: AppText.cifra(size: 18, color: AppColors.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestCatalogSurface extends StatelessWidget {
  const _GuestCatalogSurface({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadii.cardBorder,
      side: const BorderSide(color: AppColors.border),
    );
    return GuestPressable(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: AppColors.surface,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              ExcludeSemantics(child: child),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onTap,
                    customBorder: shape,
                    focusColor: AppColors.gold.withValues(alpha: 0.14),
                    splashColor: AppColors.gold.withValues(alpha: 0.12),
                    highlightColor: AppColors.gold.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Respuesta al presionar: escala 0.97 en 120 ms. Sin animación si el
/// sistema pide reducir movimiento.
class GuestPressable extends StatefulWidget {
  const GuestPressable({super.key, required this.child});

  final Widget child;

  @override
  State<GuestPressable> createState() => _GuestPressableState();
}

class _GuestPressableState extends State<GuestPressable> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (MediaQuery.disableAnimationsOf(context) || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: reduced ? Duration.zero : AppMotion.press,
        curve: AppMotion.ease,
        child: widget.child,
      ),
    );
  }
}
