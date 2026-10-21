import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../models/pedido_models.dart';
import '../../routes/app_routes.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../viewmodels/tienda_viewmodel.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/press_scale.dart';
import '../guest/guest_premium_widgets.dart';
import 'client_widgets.dart';

/// Abre el carrito con el mismo ViewModel de la tienda.
void abrirCarrito(BuildContext context) {
  final vm = context.read<TiendaViewModel>();
  Navigator.push(
    context,
    AppRoutes.page<void>(
      ChangeNotifierProvider<TiendaViewModel>.value(
        value: vm,
        child: const CarritoView(),
      ),
    ),
  );
}

void abrirMisPedidos(BuildContext context) {
  final vm = context.read<TiendaViewModel>();
  Navigator.push(
    context,
    AppRoutes.page<void>(
      ChangeNotifierProvider<TiendaViewModel>.value(
        value: vm,
        child: const MisPedidosView(),
      ),
    ),
  );
}

/// Cliente › Pantalla 8: Tienda.
class ClientTiendaTab extends StatefulWidget {
  const ClientTiendaTab({super.key});

  @override
  State<ClientTiendaTab> createState() => _ClientTiendaTabState();
}

class _ClientTiendaTabState extends State<ClientTiendaTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<TiendaViewModel>();
      if (vm.productosState == LoadState.idle) vm.cargarProductos();
    });
  }

  void _agregar(TiendaViewModel vm, ProductoDto p) {
    if (!vm.agregar(p)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Solo hay ${p.stock} de ${p.nombre} disponibles.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TiendaViewModel>();
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClientHeader(
            title: 'Tienda',
            subtitle: 'Pide en la app y recoge en la barbería.',
            trailing: _BotonCarrito(piezas: vm.piezas),
          ),
          Expanded(child: _cuerpo(vm)),
          _BarraCarrito(vm: vm),
        ],
      ),
    );
  }

  Widget _cuerpo(TiendaViewModel vm) {
    if (vm.productosState == LoadState.loading ||
        vm.productosState == LoadState.idle) {
      return const LoadingView(label: 'Cargando productos…');
    }
    if (vm.productosState == LoadState.error) {
      return ErrorView(
        title: 'No se pudo cargar la tienda',
        message: vm.productosError ?? 'Revisa tu conexión y reintenta.',
        onRetry: vm.cargarProductos,
      );
    }
    if (vm.productos.isEmpty) {
      return EmptyView(
        icon: Icons.shopping_bag_outlined,
        message: 'No hay productos publicados por ahora.',
        onRetry: vm.cargarProductos,
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final columnas = c.maxWidth >= 600 ? 3 : 2;
        final filas = (vm.productos.length / columnas).ceil();
        return RefreshIndicator(
          onRefresh: vm.cargarProductos,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.xs,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            itemCount: filas,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, fila) => IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var col = 0; col < columnas; col++) ...[
                    if (col > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: fila * columnas + col < vm.productos.length
                          ? _ProductoTienda(
                              producto: vm.productos[fila * columnas + col],
                              cantidad: vm.cantidadDe(
                                vm.productos[fila * columnas + col].id,
                              ),
                              onAgregar: () => _agregar(
                                vm,
                                vm.productos[fila * columnas + col],
                              ),
                              onQuitar: () => vm.quitarUno(
                                vm.productos[fila * columnas + col].id,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BotonCarrito extends StatelessWidget {
  const _BotonCarrito({required this.piezas});

  final int piezas;

  @override
  Widget build(BuildContext context) {
    final dur = AppMotion.of(context, AppMotion.quick);
    return IconButton(
      key: const Key('tienda_carrito'),
      tooltip: piezas == 0 ? 'Carrito vacío' : 'Carrito, $piezas piezas',
      onPressed: () => abrirCarrito(context),
      icon: Badge(
        isLabelVisible: piezas > 0,
        backgroundColor: AppColors.gold,
        textColor: AppColors.onGold,
        label: AnimatedSwitcher(
          duration: dur,
          transitionBuilder: (child, a) => ScaleTransition(
            scale: Tween(begin: 0.6, end: 1.0).animate(a),
            child: child,
          ),
          child: Text('$piezas', key: ValueKey(piezas)),
        ),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}

class _ProductoTienda extends StatelessWidget {
  const _ProductoTienda({
    required this.producto,
    required this.cantidad,
    required this.onAgregar,
    required this.onQuitar,
  });

  final ProductoDto producto;
  final int cantidad;
  final VoidCallback onAgregar;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final agotado = producto.stock <= 0;
    final marca = producto.marca.trim();
    return Container(
      key: ValueKey('tienda-producto-${producto.id}'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: GuestPremiumImage(
                url: producto.imagenUrl,
                fit: BoxFit.contain,
                label: producto.nombre,
                fallbackIcon: Icons.shopping_bag_outlined,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (marca.isNotEmpty)
                    Text(
                      marca,
                      style: theme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  Text(
                    producto.nombre,
                    style: theme.titleSmall?.copyWith(color: AppColors.ivory),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    moneyFormat.format(producto.precio),
                    style: AppText.cifra(size: 17, color: AppColors.gold),
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.sm),
                  if (agotado)
                    Text(
                      'Agotado',
                      style: theme.labelLarge?.copyWith(color: AppColors.crit),
                    )
                  else if (cantidad == 0)
                    SizedBox(
                      width: double.infinity,
                      child: PressScale(
                        child: OutlinedButton.icon(
                          key: ValueKey('tienda-agregar-${producto.id}'),
                          onPressed: onAgregar,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Agregar'),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: QuantityStepper(
                        cantidad: cantidad,
                        nombre: producto.nombre,
                        onMenos: onQuitar,
                        onMas: cantidad >= producto.stock ? null : onAgregar,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra inferior que aparece al haber algo en el carrito.
class _BarraCarrito extends StatelessWidget {
  const _BarraCarrito({required this.vm});

  final TiendaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final dur = AppMotion.of(context, AppMotion.entrance);
    final visible = !vm.carritoVacio;
    return AnimatedSize(
      duration: dur,
      curve: AppMotion.ease,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: PressScale(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('tienda_ver_carrito'),
                    onPressed: () => abrirCarrito(context),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ver carrito (${vm.piezas})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          moneyFormat.format(vm.totalEstimado),
                          style: AppText.cifra(
                            size: 16,
                            color: AppColors.onGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Cliente › Pantalla 9: Carrito.
class CarritoView extends StatefulWidget {
  const CarritoView({super.key});

  @override
  State<CarritoView> createState() => _CarritoViewState();
}

class _CarritoViewState extends State<CarritoView> {
  final _notas = TextEditingController();

  @override
  void dispose() {
    _notas.dispose();
    super.dispose();
  }

  Future<void> _pedir(TiendaViewModel vm) async {
    final ok = await vm.hacerPedido(notas: _notas.text);
    if (ok && mounted) _notas.clear();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TiendaViewModel>();
    final theme = Theme.of(context).textTheme;
    final creado = vm.ultimoPedido;
    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      body: SafeArea(
        top: false,
        child: vm.carritoVacio
            ? (creado != null
                  ? _Confirmacion(pedido: creado)
                  : EmptyView(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Tu carrito está vacío',
                      message: 'Agrega productos desde la tienda.',
                      actionLabel: 'Volver a la tienda',
                      onRetry: () => Navigator.maybePop(context),
                    ))
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.sm,
                  AppSpacing.page,
                  AppSpacing.xxl,
                ),
                children: [
                  for (final l in vm.lineas) ...[
                    _LineaCarrito(
                      linea: l,
                      onMenos: () => vm.quitarUno(l.producto.id),
                      onMas: l.cantidad >= l.producto.stock
                          ? null
                          : () => vm.agregar(l.producto),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoRow(
                          label: 'Entrega',
                          value: 'Recoger en la barbería',
                        ),
                        const InfoRow(
                          label: 'Pago',
                          value: 'En efectivo al recoger',
                        ),
                        const Divider(height: AppSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Total estimado',
                                style: theme.titleMedium,
                              ),
                            ),
                            Text(
                              moneyFormat.format(vm.totalEstimado),
                              style: AppText.cifra(
                                size: 22,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'La barbería confirma el total y las existencias al '
                          'recibir el pedido.',
                          style: theme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('carrito_notas'),
                    controller: _notas,
                    maxLength: 200,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Nota para la barbería (opcional)',
                    ),
                  ),
                  if (vm.pedidoError != null)
                    Semantics(
                      liveRegion: true,
                      child: StatusBanner(
                        message: vm.pedidoError!,
                        isError: true,
                      ),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: vm.carritoVacio
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.sm,
                  AppSpacing.page,
                  AppSpacing.md,
                ),
                child: PressScale(
                  enabled: !vm.enviando,
                  child: ElevatedButton(
                    key: const Key('carrito_pedir'),
                    onPressed: vm.enviando ? null : () => _pedir(vm),
                    child: vm.enviando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onGold,
                            ),
                          )
                        : const Text('Hacer pedido'),
                  ),
                ),
              ),
            ),
    );
  }
}

class _LineaCarrito extends StatelessWidget {
  const _LineaCarrito({
    required this.linea,
    required this.onMenos,
    required this.onMas,
  });

  final CarritoLinea linea;
  final VoidCallback onMenos;
  final VoidCallback? onMas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final p = linea.producto;
    return SurfaceCard(
      key: ValueKey('carrito-linea-${p.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 64,
            child: ClipRRect(
              borderRadius: AppRadii.controlBorder,
              child: GuestPremiumImage(
                url: p.imagenUrl,
                fit: BoxFit.contain,
                label: p.nombre,
                fallbackIcon: Icons.shopping_bag_outlined,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nombre,
                  style: theme.titleSmall?.copyWith(color: AppColors.ivory),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  moneyFormat.format(linea.subtotal),
                  style: AppText.cifra(size: 15, color: AppColors.gold),
                ),
                const SizedBox(height: AppSpacing.sm),
                QuantityStepper(
                  cantidad: linea.cantidad,
                  nombre: p.nombre,
                  onMenos: onMenos,
                  onMas: onMas,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Confirmacion extends StatelessWidget {
  const _Confirmacion({required this.pedido});

  final PedidoCreado pedido;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: QuietEntrance(
          rise: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.alphaBlend(
                    AppColors.ok.withValues(alpha: 0.14),
                    AppColors.surface,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.ok,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Pedido #${pedido.pedidoId} recibido',
                key: const Key('carrito_confirmado'),
                textAlign: TextAlign.center,
                style: theme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Total ${moneyFormat.format(pedido.total)}. Puedes seguir su '
                'estado en Mis pedidos.',
                textAlign: TextAlign.center,
                style: theme.bodyLarge?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: () => abrirMisPedidos(context),
                child: const Text('Ver mis pedidos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mis pedidos (desde Perfil y tras pedir).
class MisPedidosView extends StatefulWidget {
  const MisPedidosView({super.key});

  @override
  State<MisPedidosView> createState() => _MisPedidosViewState();
}

class _MisPedidosViewState extends State<MisPedidosView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TiendaViewModel>().cargarMisPedidos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TiendaViewModel>();
    final theme = Theme.of(context).textTheme;
    Widget cuerpo;
    if (vm.pedidosState == LoadState.loading ||
        vm.pedidosState == LoadState.idle) {
      cuerpo = const LoadingView(label: 'Cargando tus pedidos…');
    } else if (vm.pedidosState == LoadState.error) {
      cuerpo = ErrorView(
        message: vm.pedidosError ?? 'No se pudieron cargar tus pedidos.',
        onRetry: vm.cargarMisPedidos,
      );
    } else if (vm.misPedidos.isEmpty) {
      cuerpo = const EmptyView(
        icon: Icons.receipt_long_outlined,
        title: 'Aún no tienes pedidos',
        message: 'Los pedidos que hagas en la tienda aparecerán aquí.',
      );
    } else {
      cuerpo = RefreshIndicator(
        onRefresh: vm.cargarMisPedidos,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xxl,
          ),
          itemCount: vm.misPedidos.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) {
            final p = vm.misPedidos[i];
            final fecha = p.fechaCreacion.length >= 10
                ? fechaLarga(p.fechaCreacion.substring(0, 10))
                : p.fechaCreacion;
            return SurfaceCard(
              key: ValueKey('pedido-${p.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pedido #${p.id}',
                          style: theme.titleMedium,
                        ),
                      ),
                      EstadoChip(estado: p.estado),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(fecha, style: theme.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  for (final item in p.items)
                    InfoRow(label: '${item.cantidad} ×', value: item.nombre),
                  const Divider(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${p.piezas} ${p.piezas == 1 ? 'pieza' : 'piezas'}',
                          style: theme.bodyMedium,
                        ),
                      ),
                      Text(
                        moneyFormat.format(p.total),
                        style: AppText.cifra(size: 17, color: AppColors.gold),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: SafeArea(top: false, child: cuerpo),
    );
  }
}
