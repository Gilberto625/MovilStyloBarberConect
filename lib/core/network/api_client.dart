import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../storage/secure_token_storage.dart';

typedef JsonMap = Map<String, dynamic>;

/// Central HTTP client for Django REST under `/api/`.
///
/// - Attaches Bearer access token when available.
/// - On 401, tries `POST /auth/token/refresh/` once, then retries.
/// - Never logs Authorization headers, tokens, or OTP codes.
class ApiClient {
  ApiClient({
    required SecureTokenStorage tokenStorage,
    http.Client? httpClient,
    String? baseUrl,
    Future<void> Function()? onSessionExpired,
  }) : _tokenStorage = tokenStorage,
       _http = httpClient ?? http.Client(),
       _baseUrl = AppConfig.normalizeBase(baseUrl ?? AppConfig.apiBaseUrl),
       _onSessionExpired = onSessionExpired;

  final SecureTokenStorage _tokenStorage;
  final http.Client _http;
  final String _baseUrl;
  final Future<void> Function()? _onSessionExpired;

  bool _refreshing = false;

  String get baseUrl => _baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$p').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({
    bool auth = true,
    bool json = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (auth) {
      final access = await _tokenStorage.readAccess();
      if (access != null && access.isNotEmpty) {
        headers['Authorization'] = 'Bearer $access';
      }
    }
    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) {
    return _send(
      () async =>
          _http.get(_uri(path, query), headers: await _headers(auth: auth)),
      auth: auth,
    );
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) {
    return _send(
      () async => _http.post(
        _uri(path),
        headers: await _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
      auth: auth,
    );
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) {
    return _send(
      () async => _http.put(
        _uri(path),
        headers: await _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
      auth: auth,
    );
  }

  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    required bool auth,
  }) async {
    var response = await request();
    if (auth && response.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        response = await request();
      } else {
        await _onSessionExpired?.call();
        throw ApiException.fromBody(401, _tryDecode(response));
      }
    }
    return _decodeOrThrow(response);
  }

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refresh = await _tokenStorage.readRefresh();
      if (refresh == null || refresh.isEmpty) return false;

      final response = await _http.post(
        _uri('/auth/token/refresh/'),
        headers: await _headers(auth: false),
        body: jsonEncode({'refresh': refresh}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await _tokenStorage.clear();
        return false;
      }
      final decoded = _tryDecode(response);
      if (decoded is! Map) {
        await _tokenStorage.clear();
        return false;
      }
      final map = Map<String, dynamic>.from(decoded);
      final access = map['access']?.toString();
      if (access == null || access.isEmpty) {
        await _tokenStorage.clear();
        return false;
      }
      final newRefresh = map['refresh']?.toString();
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _tokenStorage.saveTokens(access: access, refresh: newRefresh);
      } else {
        await _tokenStorage.saveAccess(access);
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  dynamic _decodeOrThrow(http.Response response) {
    final decoded = _tryDecode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw ApiException.fromBody(response.statusCode, decoded);
  }

  dynamic _tryDecode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  void close() => _http.close();
}
