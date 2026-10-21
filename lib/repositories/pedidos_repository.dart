import '../models/pedido_models.dart';
import '../services/pedidos_api_service.dart';

class PedidosRepository {
  PedidosRepository(this._api);

  final PedidosApiService _api;

  Future<List<PedidoDto>> misPedidos() => _api.misPedidos();

  Future<PedidoCreado> crearPedido({
    required List<CarritoLinea> lineas,
    String notas = '',
  }) => _api.crearPedido(lineas: lineas, notas: notas);
}
