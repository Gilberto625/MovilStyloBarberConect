import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token store. Never logs token values.
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const _kAccess = 'sbc_access_token';
  static const _kRefresh = 'sbc_refresh_token';
  static const _kRole = 'sbc_user_role';
  static const _kUserJson = 'sbc_user_json';

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> saveAccess(String access) async {
    await _storage.write(key: _kAccess, value: access);
  }

  Future<String?> readAccess() => _storage.read(key: _kAccess);

  Future<String?> readRefresh() => _storage.read(key: _kRefresh);

  Future<void> saveSessionMeta({
    required String role,
    required String userJson,
  }) async {
    await _storage.write(key: _kRole, value: role);
    await _storage.write(key: _kUserJson, value: userJson);
  }

  Future<String?> readRole() => _storage.read(key: _kRole);

  Future<String?> readUserJson() => _storage.read(key: _kUserJson);

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kRole);
    await _storage.delete(key: _kUserJson);
  }
}
