import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../viewmodels/catalog_list_viewmodel.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import 'guest_premium_widgets.dart';

class ServiciosListView extends StatefulWidget {
  const ServiciosListView({super.key});

  @override
  State<ServiciosListView> createState() => _ServiciosListViewState();
}

class _ServiciosListViewState extends State<ServiciosListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogListViewModel>().loadServicios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.guest(),
      child: Scaffold(
        backgroundColor: AppColors.guestBg,
        appBar: AppBar(title: const Text('Servicios')),
        body: SafeArea(
          child: Consumer<CatalogListViewModel>(
            builder: (context, vm, _) {
              if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
                return const LoadingView(label: 'Cargando servicios…');
              }
              if (vm.state == LoadState.error) {
                return ErrorView(
                  message: vm.errorMessage ?? 'Error',
                  onRetry: vm.loadServicios,
                );
              }
              if (vm.state == LoadState.empty) {
                return EmptyView(
                  message: 'No hay servicios activos.',
                  onRetry: vm.loadServicios,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                itemCount: vm.servicios.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final s = vm.servicios[i];
                  return Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: GuestServiceCard(
                        servicio: s,
                        onTap: () => _detalleServicio(context, s),
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

class ProductosListView extends StatefulWidget {
  const ProductosListView({super.key});

  @override
  State<ProductosListView> createState() => _ProductosListViewState();
}

class _ProductosListViewState extends State<ProductosListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogListViewModel>().loadProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.guest(),
      child: Scaffold(
        backgroundColor: AppColors.guestBg,
        appBar: AppBar(title: const Text('Productos')),
        body: SafeArea(
          child: Consumer<CatalogListViewModel>(
            builder: (context, vm, _) {
              if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
                return const LoadingView(label: 'Cargando productos…');
              }
              if (vm.state == LoadState.error) {
                return ErrorView(
                  message: vm.errorMessage ?? 'Error',
                  onRetry: vm.loadProductos,
                );
              }
              if (vm.state == LoadState.empty) {
                return EmptyView(
                  message: 'No hay productos disponibles.',
                  onRetry: vm.loadProductos,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                itemCount: vm.productos.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final p = vm.productos[i];
                  return Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: GuestProductCard(
                        producto: p,
                        onTap: () => _detalleProducto(context, p),
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

void _detalleServicio(BuildContext context, ServicioDto servicio) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF14211B),
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              servicio.nombre,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${moneyFormat.format(servicio.precio)} · ${servicio.duracionMinutos} min',
              style: const TextStyle(color: AppColors.gold),
            ),
            if (servicio.descripcion.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(servicio.descripcion, softWrap: true),
            ],
          ],
        ),
      );
    },
  );
}

void _detalleProducto(BuildContext context, ProductoDto producto) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF14211B),
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (producto.marca.trim().isNotEmpty)
              Text(
                producto.marca,
                style: const TextStyle(color: Color(0xFFA6BAB0)),
              ),
            Text(
              producto.nombre,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              moneyFormat.format(producto.precio),
              style: const TextStyle(color: AppColors.gold),
            ),
            if (producto.descripcion.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(producto.descripcion, softWrap: true),
            ],
            const SizedBox(height: 8),
            Text('Stock publicado: ${producto.stock}'),
          ],
        ),
      );
    },
  );
}
