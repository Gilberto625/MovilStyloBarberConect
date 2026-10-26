import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/pedido_models.dart';

/// Pedidos del cliente (`PedidosView` en Django). Requiere sesión.
class PedidosApiService {
  PedidosApiService(this._api);

  final ApiClient _api;

  Future<List<PedidoDto>> misPedidos() async {
    final raw = await _api.get('/pedidos/');
    if (raw is! Map || raw['ok'] == false) {
      throw ApiException(
        raw is Map
            ? (raw['error'] ?? 'No se pudieron consultar tus pedidos.')
                  .toString()
            : 'Respuesta de pedidos inválida.',
      );
    }
    final lista = raw['pedidos'];
    if (lista is! List) return const [];
    return [
      for (final p in lista)
        if (p is Map) PedidoDto.fromJson(Map<String, dynamic>.from(p)),
    ];
  }

  /// Crea el pedido para recoger en la barbería y pagar en efectivo. Django
  /// valida existencias y calcula el total.
  Future<PedidoCreado> crearPedido({
    required List<CarritoLinea> lineas,
    String notas = '',
  }) async {
    final raw = await _api.post(
      '/pedidos/crear/',
      body: {
        'items': [
          for (final l in lineas)
            {'producto_id': l.producto.id, 'cantidad': l.cantidad},
        ],
        'metodo_entrega': 'recoger_local',
        'metodo_pago': 'efectivo',
        if (notas.trim().isNotEmpty) 'notas': notas.trim(),
      },
    );
    if (raw is! Map) throw ApiException('Respuesta de pedido inválida.');
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudo crear el pedido.').toString(),
      );
    }
    final creado = PedidoCreado.fromJson(map);
    if (creado.pedidoId <= 0) {
      throw ApiException('El servidor no devolvió el número de pedido.');
    }
    return creado;
  }
}
