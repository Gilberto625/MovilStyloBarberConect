import 'package:stylo_barber_connect/core/storage/secure_token_storage.dart';

/// Tokens en memoria para probar ApiClient sin el almacenamiento seguro real.
class MemoryTokenStorage extends SecureTokenStorage {
  MemoryTokenStorage({this.access, this.refresh});

  String? access;
  String? refresh;
  String? role;
  String? userJson;
  int clears = 0;

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    this.access = access;
    this.refresh = refresh;
  }

  @override
  Future<void> saveAccess(String access) async => this.access = access;

  @override
  Future<String?> readAccess() async => access;

  @override
  Future<String?> readRefresh() async => refresh;

  @override
  Future<void> saveSessionMeta({
    required String role,
    required String userJson,
  }) async {
    this.role = role;
    this.userJson = userJson;
  }

  @override
  Future<String?> readRole() async => role;

  @override
  Future<String?> readUserJson() async => userJson;

  @override
  Future<void> clear() async {
    clears++;
    access = null;
    refresh = null;
    role = null;
    userJson = null;
  }
}
