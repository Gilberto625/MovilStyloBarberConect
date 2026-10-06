import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/catalog_list_viewmodel.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../widgets/common_widgets.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Servicios')),
      body: SafeArea(
        child: Consumer<CatalogListViewModel>(
          builder: (context, vm, _) {
            if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
              return const LoadingView();
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
              padding: const EdgeInsets.all(16),
              itemCount: vm.servicios.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final s = vm.servicios[i];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFF3D4F49)),
                  ),
                  title: Text(s.nombre),
                  subtitle: Text('${s.duracionMinutos} min · ${s.categoria}'),
                  trailing: Text(
                    moneyFormat.format(s.precio),
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            );
          },
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
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: SafeArea(
        child: Consumer<CatalogListViewModel>(
          builder: (context, vm, _) {
            if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
              return const LoadingView();
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
              padding: const EdgeInsets.all(16),
              itemCount: vm.productos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = vm.productos[i];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFF3D4F49)),
                  ),
                  title: Text(p.nombre),
                  subtitle: Text(
                    p.marca.isEmpty
                        ? p.categoria
                        : '${p.marca} · stock ${p.stock}',
                  ),
                  trailing: Text(
                    moneyFormat.format(p.precio),
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
