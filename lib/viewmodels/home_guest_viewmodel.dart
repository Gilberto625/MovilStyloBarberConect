import 'package:flutter/foundation.dart';

import '../models/catalog_models.dart';
import '../repositories/catalog_repository.dart';

enum LoadState { idle, loading, ready, empty, error }

class HomeGuestViewModel extends ChangeNotifier {
  HomeGuestViewModel(this._repository);

  final CatalogRepository _repository;

  LoadState state = LoadState.idle;
  String? errorMessage;
  ContactoDto contacto = ContactoDto.empty();
  List<ServicioDto> servicios = const [];
  List<ProductoDto> productos = const [];

  List<ServicioDto> get promociones =>
      servicios.where((s) => s.isPromocion && s.bannerUrl.isNotEmpty).toList();

  List<ServicioDto> get serviciosDestacados {
    final popular = servicios
        .where((s) => !s.isPromocion && s.popular)
        .take(4)
        .toList();
    if (popular.isNotEmpty) return popular;
    return servicios.where((s) => !s.isPromocion).take(4).toList();
  }

  List<ProductoDto> get productosDestacados {
    final dest = productos.where((p) => p.destacado).take(3).toList();
    if (dest.isNotEmpty) return dest;
    return productos.take(3).toList();
  }

  Future<void> load() async {
    state = LoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await _repository.loadHomeGuest();
      contacto = data.contacto;
      servicios = data.servicios;
      productos = data.productos;
      if (servicios.isEmpty && productos.isEmpty) {
        state = LoadState.empty;
      } else {
        state = LoadState.ready;
      }
    } catch (e) {
      errorMessage = e.toString();
      state = LoadState.error;
    }
    notifyListeners();
  }
}
