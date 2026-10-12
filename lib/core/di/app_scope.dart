import '../network/api_client.dart';
import '../storage/secure_token_storage.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/catalog_repository.dart';
import '../../repositories/citas_repository.dart';
import '../../repositories/secretaria_repository.dart';
import '../../services/auth_api_service.dart';
import '../../services/catalog_api_service.dart';
import '../../services/citas_api_service.dart';
import '../../services/secretaria_api_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/catalog_list_viewmodel.dart';
import '../../viewmodels/client_citas_viewmodel.dart';
import '../../viewmodels/home_guest_viewmodel.dart';
import '../../viewmodels/secretaria_gestion_viewmodel.dart';
import '../../viewmodels/secretaria_hoy_viewmodel.dart';

/// Manual constructor DI graph (no service-locator package).
class AppScope {
  AppScope._({
    required this.storage,
    required this.api,
    required this.catalogRepository,
    required this.authRepository,
    required this.citasRepository,
    required this.secretariaRepository,
    required this.authViewModel,
    required this.homeGuestViewModel,
    required this.catalogListViewModel,
    required this.clientCitasViewModel,
    required this.secretariaHoyViewModel,
    required this.secretariaGestionViewModel,
  });

  factory AppScope.create() {
    final storage = SecureTokenStorage();
    late final AuthRepository authRepository;
    late final AuthViewModel authViewModel;

    final api = ApiClient(
      tokenStorage: storage,
      onSessionExpired: () async {
        await authRepository.logoutLocal();
        await authViewModel.logout();
      },
    );

    final catalogApi = CatalogApiService(api);
    final authApi = AuthApiService(api);
    final citasApi = CitasApiService(api);
    final secretariaApi = SecretariaApiService(api);

    final CatalogRepository catalogRepository = CatalogRepositoryImpl(
      catalogApi,
    );
    authRepository = AuthRepository(api: authApi, storage: storage);
    final citasRepository = CitasRepository(citasApi);
    final secretariaRepository = SecretariaRepository(secretariaApi);
    authViewModel = AuthViewModel(authRepository);

    return AppScope._(
      storage: storage,
      api: api,
      catalogRepository: catalogRepository,
      authRepository: authRepository,
      citasRepository: citasRepository,
      secretariaRepository: secretariaRepository,
      authViewModel: authViewModel,
      homeGuestViewModel: HomeGuestViewModel(catalogRepository),
      catalogListViewModel: CatalogListViewModel(catalogRepository),
      clientCitasViewModel: ClientCitasViewModel(citasRepository),
      secretariaHoyViewModel: SecretariaHoyViewModel(secretariaRepository),
      secretariaGestionViewModel: SecretariaGestionViewModel(
        secretaria: secretariaRepository,
        citas: citasRepository,
        catalog: catalogRepository,
      ),
    );
  }

  final SecureTokenStorage storage;
  final ApiClient api;
  final CatalogRepository catalogRepository;
  final AuthRepository authRepository;
  final CitasRepository citasRepository;
  final SecretariaRepository secretariaRepository;
  final AuthViewModel authViewModel;
  final HomeGuestViewModel homeGuestViewModel;
  final CatalogListViewModel catalogListViewModel;
  final ClientCitasViewModel clientCitasViewModel;
  final SecretariaHoyViewModel secretariaHoyViewModel;
  final SecretariaGestionViewModel secretariaGestionViewModel;

  void dispose() {
    homeGuestViewModel.dispose();
    catalogListViewModel.dispose();
    authViewModel.dispose();
    clientCitasViewModel.dispose();
    secretariaHoyViewModel.dispose();
    secretariaGestionViewModel.dispose();
    api.close();
  }
}
