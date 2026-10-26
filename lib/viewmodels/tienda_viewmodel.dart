import 'package:flutter/foundation.dart';

import '../models/catalog_models.dart';
import '../models/pedido_models.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/pedidos_repository.dart';
import 'home_guest_viewmodel.dart';

/// Tienda del cliente: catálogo, carrito en memoria, pedido y "Mis pedidos".
/// El carrito no se guarda en el teléfono: el pedido se crea en Django.
class TiendaViewModel extends ChangeNotifier {
  TiendaViewModel({
    required CatalogRepository catalogo,
    required PedidosRepository pedidos,
  }) : _catalogo = catalogo,
       _pedidos = pedidos;

  final CatalogRepository _catalogo;
  final PedidosRepository _pedidos;

  LoadState productosState = LoadState.idle;
  List<ProductoDto> productos = const [];
  String? productosError;

  final Map<int, CarritoLinea> _carrito = {};
  bool enviando = false;
  String? pedidoError;
  PedidoCreado? ultimoPedido;

  LoadState pedidosState = LoadState.idle;
  List<PedidoDto> misPedidos = const [];
  String? pedidosError;

  List<CarritoLinea> get lineas => _carrito.values.toList(growable: false);
  int get piezas => _carrito.values.fold(0, (s, l) => s + l.cantidad);
  double get totalEstimado => _carrito.values.fold(0, (s, l) => s + l.subtotal);
  bool get carritoVacio => _carrito.isEmpty;

  int cantidadDe(int productoId) => _carrito[productoId]?.cantidad ?? 0;

  Future<void> cargarProductos() async {
    productosState = LoadState.loading;
    productosError = null;
    notifyListeners();
    try {
      productos = await _catalogo.getProductos();
      productosState = productos.isEmpty ? LoadState.empty : LoadState.ready;
    } catch (e) {
      productosError = e.toString();
      productosState = LoadState.error;
    }
    notifyListeners();
  }

  /// Agrega una pieza sin pasar de las existencias publicadas. Devuelve
  /// `false` si ya no hay más.
  bool agregar(ProductoDto producto) {
    final actual = cantidadDe(producto.id);
    if (producto.stock <= 0 || actual >= producto.stock) return false;
    _carrito[producto.id] = CarritoLinea(
      producto: producto,
      cantidad: actual + 1,
    );
    pedidoError = null;
    notifyListeners();
    return true;
  }

  void quitarUno(int productoId) {
    final linea = _carrito[productoId];
    if (linea == null) return;
    if (linea.cantidad <= 1) {
      _carrito.remove(productoId);
    } else {
      _carrito[productoId] = linea.conCantidad(linea.cantidad - 1);
    }
    notifyListeners();
  }

  void eliminar(int productoId) {
    if (_carrito.remove(productoId) != null) notifyListeners();
  }

  Future<bool> hacerPedido({String notas = ''}) async {
    if (_carrito.isEmpty || enviando) return false;
    enviando = true;
    pedidoError = null;
    notifyListeners();
    try {
      ultimoPedido = await _pedidos.crearPedido(lineas: lineas, notas: notas);
      _carrito.clear();
      enviando = false;
      notifyListeners();
      // Las existencias cambiaron en el servidor: se vuelven a leer.
      await Future.wait([cargarProductos(), cargarMisPedidos()]);
      return true;
    } catch (e) {
      pedidoError = e.toString();
      enviando = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> cargarMisPedidos() async {
    pedidosState = LoadState.loading;
    pedidosError = null;
    notifyListeners();
    try {
      misPedidos = await _pedidos.misPedidos();
      pedidosState = misPedidos.isEmpty ? LoadState.empty : LoadState.ready;
    } catch (e) {
      pedidosError = e.toString();
      pedidosState = LoadState.error;
    }
    notifyListeners();
  }

  /// Al cerrar sesión no debe quedar nada del usuario anterior (PM09).
  void limpiar() {
    _carrito.clear();
    misPedidos = const [];
    ultimoPedido = null;
    pedidoError = null;
    pedidosError = null;
    pedidosState = LoadState.idle;
    notifyListeners();
  }
}
