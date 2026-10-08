import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';

final moneyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? AppColors.crit : AppColors.warn).withValues(
          alpha: 0.15,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isError ? AppColors.crit : AppColors.warn),
      ),
      child: Text(message),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Cargando…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.gold),
          const SizedBox(height: 16),
          Text(label),
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyView(message: message, onRetry: onRetry);
  }
}

class BrandTitle extends StatelessWidget {
  const BrandTitle({
    super.key,
    required this.part1,
    required this.part2,
    this.logoUrl,
  });

  final String part1;
  final String part2;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return Image.network(
        logoUrl!,
        height: 48,
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

class ServicioCard extends StatelessWidget {
  const ServicioCard({
    super.key,
    required this.nombre,
    required this.precio,
    required this.duracion,
    this.imagenUrl,
    this.onTap,
  });

  final String nombre;
  final double precio;
  final int duracion;
  final String? imagenUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.guestCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: imagenUrl != null && imagenUrl!.isNotEmpty
                  ? Image.network(
                      imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    moneyFormat.format(precio),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$duracion min',
                    style: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.panelCard,
    child: const Icon(Icons.content_cut, color: AppColors.museum),
  );
}

class ProductoCard extends StatelessWidget {
  const ProductoCard({
    super.key,
    required this.nombre,
    required this.marca,
    required this.precio,
    this.imagenUrl,
  });

  final String nombre;
  final String marca;
  final double precio;
  final String? imagenUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.guestCardProduct,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: imagenUrl != null && imagenUrl!.isNotEmpty
                ? Image.network(
                    imagenUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => _ph(),
                  )
                : _ph(),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (marca.isNotEmpty)
                  Text(
                    marca,
                    style: TextStyle(color: AppColors.museum, fontSize: 11),
                  ),
                Text(nombre, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  moneyFormat.format(precio),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ph() => Container(
    color: AppColors.panelCard,
    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.museum),
  );
}

class EstadoChip extends StatelessWidget {
  const EstadoChip({super.key, required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    Color c = AppColors.museum;
    switch (estado) {
      case 'confirmada':
      case 'completada':
        c = AppColors.ok;
        break;
      case 'pendiente':
      case 'en_curso':
        c = AppColors.warn;
        break;
      case 'cancelada':
      case 'no_asistio':
        c = AppColors.crit;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c),
      ),
      child: Text(
        estado,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
