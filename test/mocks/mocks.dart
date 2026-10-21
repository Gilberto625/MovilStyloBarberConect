// Mocks de Mockito para las pruebas unitarias (Actividad 3, GH#14).
// Regenera mocks.mocks.dart con:
//   dart run build_runner build --delete-conflicting-outputs
import 'package:mockito/annotations.dart';
import 'package:stylo_barber_connect/repositories/auth_repository.dart';
import 'package:stylo_barber_connect/repositories/catalog_repository.dart';
import 'package:stylo_barber_connect/repositories/citas_repository.dart';
import 'package:stylo_barber_connect/repositories/secretaria_repository.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<CatalogRepository>(),
  MockSpec<CitasRepository>(),
  MockSpec<SecretariaRepository>(),
])
void main() {}
