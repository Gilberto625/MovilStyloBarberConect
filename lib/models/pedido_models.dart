import 'catalog_models.dart';

double _asDouble(Object? v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

int _asInt(Object? v) {
  if (v is int) return v;
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

/// Renglón de un pedido ya creado (`GET /pedidos/` › items).
class PedidoItemDto {
  const PedidoItemDto({
    required this.productoId,
    required this.nombre,
    required this.imagen,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  final int productoId;
  final String nombre;
  final String imagen;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  factory PedidoItemDto.fromJson(Map<String, dynamic> json) => PedidoItemDto(
    productoId: _asInt(json['producto_id']),
    nombre: (json['producto_nombre'] ?? '').toString(),
    imagen: (json['producto_imagen'] ?? '').toString(),
    cantidad: _asInt(json['cantidad']),
    precioUnitario: _asDouble(json['precio_unitario']),
    subtotal: _asDouble(json['subtotal']),
  );
}

/// Pedido del cliente (`GET /pedidos/`).
class PedidoDto {
  const PedidoDto({
    required this.id,
    required this.estado,
    required this.metodoEntrega,
    required this.metodoPago,
    required this.subtotal,
    required this.descuento,
    required this.costoEnvio,
    required this.total,
    required this.notas,
    required this.fechaCreacion,
    required this.items,
  });

  final int id;
  final String estado;
  final String metodoEntrega;
  final String metodoPago;
  final double subtotal;
  final double descuento;
  final double costoEnvio;
  final double total;
  final String notas;

  /// ISO 8601 tal como lo manda Django.
  final String fechaCreacion;
  final List<PedidoItemDto> items;

  int get piezas => items.fold(0, (s, i) => s + i.cantidad);

  factory PedidoDto.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return PedidoDto(
      id: _asInt(json['id']),
      estado: (json['estado'] ?? 'pendiente').toString(),
      metodoEntrega: (json['metodo_entrega'] ?? '').toString(),
      metodoPago: (json['metodo_pago'] ?? '').toString(),
      subtotal: _asDouble(json['subtotal']),
      descuento: _asDouble(json['descuento']),
      costoEnvio: _asDouble(json['costo_envio']),
      total: _asDouble(json['total']),
      notas: (json['notas'] ?? '').toString(),
      fechaCreacion: (json['fecha_creacion'] ?? '').toString(),
      items: raw is List
          ? [
              for (final i in raw)
                if (i is Map)
                  PedidoItemDto.fromJson(Map<String, dynamic>.from(i)),
            ]
          : const [],
    );
  }
}

/// Respuesta de `POST /pedidos/crear/`. Los montos los calcula Django.
class PedidoCreado {
  const PedidoCreado({
    required this.pedidoId,
    required this.estado,
    required this.total,
  });

  final int pedidoId;
  final String estado;
  final double total;

  factory PedidoCreado.fromJson(Map<String, dynamic> json) => PedidoCreado(
    pedidoId: _asInt(json['pedido_id']),
    estado: (json['estado'] ?? 'pendiente').toString(),
    total: _asDouble(json['total']),
  );
}

/// Producto en el carrito, antes de pedirlo. El precio es el publicado; el
/// total definitivo lo devuelve el servidor.
class CarritoLinea {
  const CarritoLinea({required this.producto, required this.cantidad});

  final ProductoDto producto;
  final int cantidad;

  double get subtotal => producto.precio * cantidad;

  CarritoLinea conCantidad(int n) =>
      CarritoLinea(producto: producto, cantidad: n);
}
