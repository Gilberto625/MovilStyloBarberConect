import '../core/storage/secure_token_storage.dart';
import '../models/auth_models.dart';
import '../services/auth_api_service.dart';

class AuthRepository {
  AuthRepository({
    required AuthApiService api,
    required SecureTokenStorage storage,
  }) : _api = api,
       _storage = storage;

  final AuthApiService _api;
  final SecureTokenStorage _storage;

  AuthUser? _cachedUser;

  AuthUser? get currentUser => _cachedUser;

  Future<LoginResult> login({required String email, required String password}) {
    return _api.login(email: email, password: password);
  }

  Future<AuthUser> completeLogin(LoginSuccess success) async {
    await _storage.saveTokens(access: success.access, refresh: success.refresh);
    await _storage.saveSessionMeta(
      role: success.user.rol.apiValue,
      userJson: success.user.encode(),
    );
    _cachedUser = success.user;
    return success.user;
  }

  Future<AuthUser> verify2fa({
    required String tempToken,
    required String codigo,
  }) async {
    final success = await _api.verify2fa(tempToken: tempToken, codigo: codigo);
    return completeLogin(success);
  }

  Future<void> resend2fa(String tempToken) =>
      _api.solicitarCodigo2fa(tempToken: tempToken);

  Future<RegistroPendiente> registrar(RegistroRequest datos) =>
      _api.registrar(datos);

  /// Confirma el alta y abre la sesión igual que un login.
  Future<AuthUser> verificarRegistro({
    required String tempToken,
    required String codigo,
  }) async {
    final success = await _api.verificarRegistro(
      tempToken: tempToken,
      codigo: codigo,
    );
    return completeLogin(success);
  }

  Future<String> reenviarCodigoRegistro(String correo) =>
      _api.reenviarCodigoRegistro(correo);

  Future<AuthUser?> restoreSession() async {
    final access = await _storage.readAccess();
    if (access == null || access.isEmpty) {
      _cachedUser = null;
      return null;
    }
    final cached = AuthUser.tryDecode(await _storage.readUserJson());
    try {
      final me = await _api.me();
      _cachedUser = me;
      await _storage.saveSessionMeta(
        role: me.rol.apiValue,
        userJson: me.encode(),
      );
      return me;
    } catch (_) {
      if (cached != null) {
        _cachedUser = cached;
        return cached;
      }
      await logoutLocal();
      return null;
    }
  }

  Future<PerfilDto> getPerfil() => _api.perfil();

  /// Local logout only — backend has no logout endpoint.
  Future<void> logoutLocal() async {
    _cachedUser = null;
    await _storage.clear();
  }
}
