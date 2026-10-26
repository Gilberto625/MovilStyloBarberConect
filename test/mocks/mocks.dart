// Mocks de Mockito para las pruebas unitarias (Actividad 3, GH#14).
// Regenera mocks.mocks.dart con:
//   dart run build_runner build --delete-conflicting-outputs
import 'package:mockito/annotations.dart';
import 'package:stylo_barber_connect/repositories/auth_repository.dart';
import 'package:stylo_barber_connect/repositories/barbero_repository.dart';
import 'package:stylo_barber_connect/repositories/catalog_repository.dart';
import 'package:stylo_barber_connect/repositories/citas_repository.dart';
import 'package:stylo_barber_connect/repositories/pedidos_repository.dart';
import 'package:stylo_barber_connect/repositories/privacidad_repository.dart';
import 'package:stylo_barber_connect/repositories/secretaria_repository.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<BarberoRepository>(),
  MockSpec<CatalogRepository>(),
  MockSpec<CitasRepository>(),
  MockSpec<PedidosRepository>(),
  MockSpec<PrivacidadRepository>(),
  MockSpec<SecretariaRepository>(),
])
void main() {}
