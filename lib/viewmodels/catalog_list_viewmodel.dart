import 'package:flutter/foundation.dart';

import '../models/catalog_models.dart';
import '../repositories/catalog_repository.dart';
import 'home_guest_viewmodel.dart';

class CatalogListViewModel extends ChangeNotifier {
  CatalogListViewModel(this._repository);

  final CatalogRepository _repository;

  LoadState state = LoadState.idle;
  String? errorMessage;
  List<ServicioDto> servicios = const [];
  List<ProductoDto> productos = const [];

  Future<void> loadServicios() async {
    state = LoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      servicios = await _repository.getServicios();
      state = servicios.isEmpty ? LoadState.empty : LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadProductos() async {
    state = LoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      productos = await _repository.getProductos();
      state = productos.isEmpty ? LoadState.empty : LoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
    notifyListeners();
  }
}
