import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../widgets/common_widgets.dart';

const _ivory = Color(0xFFF4F0E8);
const _surface = Color(0xFF14211B);
const _muted = Color(0xFFA6BAB0);

class GuestPremiumImage extends StatelessWidget {
  const GuestPremiumImage({
    super.key,
    required this.url,
    required this.fit,
    required this.label,
    required this.fallbackIcon,
    this.alignment = Alignment.center,
  });

  final String url;
  final BoxFit fit;
  final String label;
  final IconData fallbackIcon;
  final Alignment alignment;

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

    return Image.network(
      source,
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
        child: DecoratedBox(
          decoration: const BoxDecoration(color: _surface),
          child: Center(
            child: SizedBox.square(
              dimension: 28,
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
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_surface, Color(0xFF0E1813)],
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.museum.withValues(alpha: 0.10),
                        border: Border.all(
                          color: AppColors.museum.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Icon(fallbackIcon, color: _muted, size: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 12, color: _muted),
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

class GuestServiceCard extends StatelessWidget {
  const GuestServiceCard({
    super.key,
    required this.servicio,
    required this.onTap,
  });

  final ServicioDto servicio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = moneyFormat.format(servicio.precio);
    return _GuestCatalogSurface(
      label:
          'Ver servicios. ${servicio.nombre}. $price. '
          '${servicio.duracionMinutos} minutos.',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRect(
              child: SizedBox.expand(
                child: GuestPremiumImage(
                  url: servicio.imagenUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  label: servicio.nombre,
                  fallbackIcon: Icons.content_cut_rounded,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    height: 1.28,
                    fontWeight: FontWeight.w600,
                    color: _ivory,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  price,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 16, color: _muted),
                    Text(
                      '${servicio.duracionMinutos} min',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontSize: 14, color: _muted),
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

class GuestProductCard extends StatelessWidget {
  const GuestProductCard({
    super.key,
    required this.producto,
    required this.onTap,
  });

  final ProductoDto producto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = moneyFormat.format(producto.precio);
    final brand = producto.marca.trim();
    return _GuestCatalogSurface(
      label:
          'Ver productos. ${producto.nombre}. '
          '${brand.isEmpty ? '' : '$brand. '}$price.',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: GuestPremiumImage(
                url: producto.imagenUrl,
                fit: BoxFit.contain,
                label: producto.nombre,
                fallbackIcon: Icons.shopping_bag_outlined,
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
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 12, height: 1.35, color: _muted),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  producto.nombre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: _ivory,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  price,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
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
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
    );
    return GuestPressable(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: _surface,
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
                    hoverColor: AppColors.gold.withValues(alpha: 0.08),
                    splashColor: AppColors.gold.withValues(alpha: 0.16),
                    highlightColor: AppColors.gold.withValues(alpha: 0.08),
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

/// Press feedback on transform only. Skipped when the system asks for less motion.
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
        scale: _pressed ? 0.98 : 1,
        duration: reduced ? Duration.zero : const Duration(milliseconds: 120),
        curve: const Cubic(0.23, 1, 0.32, 1),
        child: widget.child,
      ),
    );
  }
}
