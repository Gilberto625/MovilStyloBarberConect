import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';

final moneyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

/// Tono de un aviso en línea.
enum BannerTone { info, ok, aviso, error }

/// Aviso en línea con icono, en una capa tonal (DESIGN.md › Sin Sombra).
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.isError = false,
    this.tone,
  });

  final String message;
  final bool isError;

  /// Si se omite, `isError` decide entre error y aviso (compatibilidad).
  final BannerTone? tone;

  @override
  Widget build(BuildContext context) {
    final t = tone ?? (isError ? BannerTone.error : BannerTone.aviso);
    final (color, icon) = switch (t) {
      BannerTone.info => (AppColors.museum, Icons.info_outline),
      BannerTone.ok => (AppColors.ok, Icons.check_circle_outline),
      BannerTone.aviso => (AppColors.warn, Icons.schedule),
      BannerTone.error => (AppColors.crit, Icons.error_outline),
    };
    // La región "live" la pone quien muestra el aviso (p. ej. el login), para
    // no anunciarlo dos veces.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.12),
          AppColors.surface,
        ),
        borderRadius: AppRadii.controlBorder,
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.ivory),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Cargando…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío: dice qué falta y, si aplica, qué hacer.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
    this.icon = Icons.inbox_outlined,
    this.actionLabel = 'Reintentar',
  });

  final String message;
  final VoidCallback? onRetry;
  final String? title;
  final IconData icon;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: AppColors.museum),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (title != null) ...[
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: theme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton(onPressed: onRetry, child: Text(actionLabel)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error recuperable: mismo esqueleto que el vacío, con icono de error.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry, this.title});

  final String message;
  final VoidCallback? onRetry;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      message: message,
      onRetry: onRetry,
      title: title,
      icon: Icons.cloud_off_outlined,
    );
  }
}

class BrandTitle extends StatelessWidget {
  const BrandTitle({
    super.key,
    required this.part1,
    required this.part2,
    this.logoUrl,
    this.logoHeight = 48,
  });

  final String part1;
  final String part2;
  final String? logoUrl;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return Image.network(
        logoUrl!,
        height: logoHeight,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        filterQuality: FilterQuality.medium,
        semanticLabel:
            '${part1.isEmpty ? 'Stylo' : part1} '
            '${part2.isEmpty ? 'Barber' : part2}',
        errorBuilder: (context, error, stackTrace) => _textBrand(context),
      );
    }
    return _textBrand(context);
  }

  Widget _textBrand(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.headlineMedium,
        children: [
          TextSpan(text: part1.isEmpty ? 'Stylo' : part1),
          TextSpan(
            text: ' ${part2.isEmpty ? 'Barber' : part2}',
            style: const TextStyle(color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}

/// Estado de una cita con su palabra y su color (DESIGN.md › Estado Con Palabra).
class EstadoChip extends StatelessWidget {
  const EstadoChip({super.key, required this.estado});

  final String estado;

  /// Palabra que ve la persona para cada estado del backend.
  static String etiqueta(String estado) => switch (estado) {
    'pendiente' => 'Pendiente',
    'confirmada' => 'Confirmada',
    'en_curso' => 'En sala',
    'completada' => 'Completada',
    'cancelada' => 'Cancelada',
    'no_asistio' => 'No asistió',
    'reprogramada' => 'Reprogramada',
    '' => 'Sin estado',
    _ => estado[0].toUpperCase() + estado.substring(1).replaceAll('_', ' '),
  };

  static Color color(String estado) => switch (estado) {
    'confirmada' || 'completada' => AppColors.ok,
    'pendiente' || 'reprogramada' => AppColors.warn,
    'en_curso' => AppColors.museum,
    'cancelada' || 'no_asistio' => AppColors.crit,
    _ => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final c = color(estado);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          c.withValues(alpha: 0.12),
          AppColors.surfaceHigh,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              etiqueta(estado),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: c),
            ),
          ),
        ],
      ),
    );
  }
}

/// Par etiqueta–valor (DESIGN.md › Dato Estructurado). Reemplaza las cadenas
/// "a · b · c".
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final IconData? icon;

  /// Valor en cifra marfil (horas, montos).
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 18, color: AppColors.museum),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
          ],
          SizedBox(width: 108, child: Text(label, style: theme.bodySmall)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: emphasis
                  ? AppText.cifra(size: 15)
                  : theme.bodyMedium?.copyWith(color: AppColors.ivory),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de sección con acción opcional a la derecha.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.actionKey,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxl,
        bottom: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (action != null && onAction != null)
            TextButton(
              key: actionKey,
              onPressed: onAction,
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// Superficie tonal con borde filo (tarjeta sin sombra). Si recibe `onTap`,
/// pinta su efecto de toque dentro de la forma.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color = AppColors.surface,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadii.cardBorder,
      side: const BorderSide(color: AppColors.border),
    );
    final body = Padding(padding: padding, child: child);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? body : InkWell(onTap: onTap, child: body),
      ),
    );
  }
}
