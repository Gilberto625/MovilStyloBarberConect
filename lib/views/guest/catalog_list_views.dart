import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/catalog_list_viewmodel.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import 'catalog_detail_views.dart';
import 'guest_premium_widgets.dart';

/// Abre el detalle de un servicio con su foto como Hero.
void abrirServicio(
  BuildContext context,
  ServicioDto servicio, {
  required String origen,
  DetalleAccion accion = DetalleAccion.iniciarSesion,
}) {
  Navigator.pushNamed(
    context,
    AppRoutes.servicioDetalle,
    arguments: CatalogDetailArgs<ServicioDto>(
      servicio,
      heroTag: servicioHeroTag(origen, servicio),
      accion: accion,
    ),
  );
}

/// Abre el detalle de un producto con su foto como Hero.
void abrirProducto(
  BuildContext context,
  ProductoDto producto, {
  required String origen,
  DetalleAccion accion = DetalleAccion.iniciarSesion,
}) {
  Navigator.pushNamed(
    context,
    AppRoutes.productoDetalle,
    arguments: CatalogDetailArgs<ProductoDto>(
      producto,
      heroTag: productoHeroTag(origen, producto),
      accion: accion,
    ),
  );
}

/// Un tag por pantalla de origen: la misma foto puede estar en Inicio y en la
/// lista sin chocar.
String servicioHeroTag(String origen, ServicioDto s) =>
    'servicio-$origen-${s.id}';
String productoHeroTag(String origen, ProductoDto p) =>
    'producto-$origen-${p.id}';

/// Título y subtítulo de una sección de catálogo.
class CatalogHeader extends StatelessWidget {
  const CatalogHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.headlineMedium),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs + 2),
            Text(
              subtitle!,
              style: theme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lista de servicios (Invitado › Pantalla 2). Filas comparables: foto,
/// nombre, precio y duración.
class ServiciosCatalogo extends StatelessWidget {
  const ServiciosCatalogo({
    super.key,
    required this.servicios,
    required this.origen,
    this.accion = DetalleAccion.iniciarSesion,
    this.header,
  });

  final List<ServicioDto> servicios;
  final String origen;
  final DetalleAccion accion;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: PageStorageKey('servicios-$origen'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xxxl,
      ),
      itemCount: servicios.length + (header == null ? 0 : 1),
      separatorBuilder: (context, index) =>
          SizedBox(height: header != null && index == 0 ? 0 : AppSpacing.md),
      itemBuilder: (context, i) {
        if (header != null && i == 0) return _Centered(child: header!);
        final s = servicios[i - (header == null ? 0 : 1)];
        return _Centered(
          child: ServiceListTile(
            key: ValueKey('servicio-fila-${s.id}'),
            servicio: s,
            heroTag: servicioHeroTag(origen, s),
            onTap: () =>
                abrirServicio(context, s, origen: origen, accion: accion),
          ),
        );
      },
    );
  }
}

/// Cuadrícula de productos (Invitado › Pantalla 4). Cada fila toma el alto de
/// su tarjeta más alta, así los nombres largos no se cortan.
class ProductosCatalogo extends StatelessWidget {
  const ProductosCatalogo({
    super.key,
    required this.productos,
    required this.origen,
    this.accion = DetalleAccion.iniciarSesion,
    this.header,
  });

  final List<ProductoDto> productos;
  final String origen;
  final DetalleAccion accion;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 600 ? 3 : 2;
        final filas = (productos.length / columnas).ceil();
        return ListView.separated(
          key: PageStorageKey('productos-$origen'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xxxl,
          ),
          itemCount: filas + (header == null ? 0 : 1),
          separatorBuilder: (context, index) => SizedBox(
            height: header != null && index == 0 ? 0 : AppSpacing.md,
          ),
          itemBuilder: (context, i) {
            if (header != null && i == 0) {
              return _Centered(wide: true, child: header!);
            }
            final fila = i - (header == null ? 0 : 1);
            final inicio = fila * columnas;
            return _Centered(
              wide: true,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < columnas; c++) ...[
                      if (c > 0) const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: inicio + c < productos.length
                            ? GuestProductCard(
                                key: ValueKey(
                                  'producto-celda-${productos[inicio + c].id}',
                                ),
                                producto: productos[inicio + c],
                                heroTag: productoHeroTag(
                                  origen,
                                  productos[inicio + c],
                                ),
                                onTap: () => abrirProducto(
                                  context,
                                  productos[inicio + c],
                                  origen: origen,
                                  accion: accion,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child, this.wide = false});

  final Widget child;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: wide ? 1040 : AppSpacing.maxContent,
        ),
        child: child,
      ),
    );
  }
}

/// Catálogo completo de servicios desde un panel con sesión (`/servicios`).
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
      if (mounted) context.read<CatalogListViewModel>().loadServicios();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.guestBg,
      appBar: AppBar(title: const Text('Servicios')),
      body: SafeArea(
        top: false,
        child: Consumer<CatalogListViewModel>(
          builder: (context, vm, _) {
            if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
              return const LoadingView(label: 'Cargando servicios…');
            }
            if (vm.state == LoadState.error) {
              return ErrorView(
                title: 'No se pudieron cargar los servicios',
                message: vm.errorMessage ?? 'Revisa tu conexión y reintenta.',
                onRetry: vm.loadServicios,
              );
            }
            if (vm.state == LoadState.empty || vm.servicios.isEmpty) {
              return EmptyView(
                icon: Icons.content_cut_rounded,
                message: 'No hay servicios activos.',
                onRetry: vm.loadServicios,
              );
            }
            return RefreshIndicator(
              onRefresh: vm.loadServicios,
              child: ServiciosCatalogo(
                servicios: vm.servicios,
                origen: 'panel',
                accion: DetalleAccion.ninguna,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Catálogo completo de productos desde un panel con sesión (`/productos`).
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
      if (mounted) context.read<CatalogListViewModel>().loadProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.guestBg,
      appBar: AppBar(title: const Text('Productos')),
      body: SafeArea(
        top: false,
        child: Consumer<CatalogListViewModel>(
          builder: (context, vm, _) {
            if (vm.state == LoadState.loading || vm.state == LoadState.idle) {
              return const LoadingView(label: 'Cargando productos…');
            }
            if (vm.state == LoadState.error) {
              return ErrorView(
                title: 'No se pudieron cargar los productos',
                message: vm.errorMessage ?? 'Revisa tu conexión y reintenta.',
                onRetry: vm.loadProductos,
              );
            }
            if (vm.state == LoadState.empty || vm.productos.isEmpty) {
              return EmptyView(
                icon: Icons.shopping_bag_outlined,
                message: 'No hay productos disponibles.',
                onRetry: vm.loadProductos,
              );
            }
            return RefreshIndicator(
              onRefresh: vm.loadProductos,
              child: ProductosCatalogo(
                productos: vm.productos,
                origen: 'panel',
                accion: DetalleAccion.ninguna,
              ),
            );
          },
        ),
      ),
    );
  }
}
