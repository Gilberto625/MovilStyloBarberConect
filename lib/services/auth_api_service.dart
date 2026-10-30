import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';
import '../models/auth_models.dart';
import '../models/privacidad_models.dart';

class AuthApiService {
  AuthApiService(this._api);

  final ApiClient _api;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final raw = await _api.post(
      '/login/',
      auth: false,
      body: {'email': email.trim(), 'password': password},
    );
    if (raw is! Map) {
      throw ApiException('Respuesta de login inválida.');
    }
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudo iniciar sesión.').toString(),
      );
    }
    if (map['requires2fa'] == true) {
      return LoginRequires2FA(
        tempToken: (map['tempToken'] ?? '').toString(),
        destino: (map['destino'] ?? '').toString(),
        mensaje: (map['mensaje'] ?? 'Te enviamos un código de verificación.')
            .toString(),
      );
    }
    final access = (map['access'] ?? '').toString();
    final refresh = (map['refresh'] ?? '').toString();
    final userRaw = map['usuario'];
    if (access.isEmpty || refresh.isEmpty || userRaw is! Map) {
      throw ApiException('Login incompleto: faltan tokens o usuario.');
    }
    return LoginSuccess(
      access: access,
      refresh: refresh,
      user: AuthUser.fromJson(Map<String, dynamic>.from(userRaw)),
    );
  }

  Future<LoginSuccess> verify2fa({
    required String tempToken,
    required String codigo,
  }) async {
    final raw = await _api.post(
      '/login/2fa/verificar/',
      auth: false,
      body: {'tempToken': tempToken, 'codigo': codigo.trim()},
    );
    if (raw is! Map) {
      throw ApiException('Respuesta 2FA inválida.');
    }
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException((map['error'] ?? 'Código inválido.').toString());
    }
    final access = (map['access'] ?? '').toString();
    final refresh = (map['refresh'] ?? '').toString();
    final userRaw = map['usuario'];
    if (access.isEmpty || refresh.isEmpty || userRaw is! Map) {
      throw ApiException('Verificación 2FA incompleta.');
    }
    return LoginSuccess(
      access: access,
      refresh: refresh,
      user: AuthUser.fromJson(Map<String, dynamic>.from(userRaw)),
    );
  }

  Future<void> solicitarCodigo2fa({required String tempToken}) async {
    final raw = await _api.post(
      '/login/2fa/solicitar-codigo/',
      auth: false,
      body: {'tempToken': tempToken},
    );
    if (raw is Map && raw['ok'] == false) {
      throw ApiException(
        (raw['error'] ?? 'No se pudo reenviar el código.').toString(),
      );
    }
  }

  /// Alta de cliente. Con `sinVerificacion`, Django crea la cuenta verificada
  /// y responde con la sesión ([RegistroCompletado]). Si responde con
  /// `tempToken` (servidor anterior), la cuenta espera el código del correo
  /// ([RegistroPendiente]). Los 400/409 llegan como [ApiException].
  Future<RegistroResultado> registrar(RegistroRequest datos) async {
    final raw = await _api.post(
      '/register/',
      auth: false,
      body: datos.toJson(),
    );
    if (raw is! Map) {
      throw ApiException('Respuesta de registro inválida.');
    }
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudo completar el registro.').toString(),
      );
    }
    final tempToken = (map['tempToken'] ?? '').toString();
    final access = (map['access'] ?? '').toString();
    if (map['requiereVerificacion'] != true &&
        tempToken.isEmpty &&
        access.isNotEmpty) {
      final refresh = (map['refresh'] ?? '').toString();
      final userRaw = map['usuario'];
      if (refresh.isEmpty || userRaw is! Map) {
        throw ApiException('Registro incompleto: faltan tokens o usuario.');
      }
      return RegistroCompletado(
        sesion: LoginSuccess(
          access: access,
          refresh: refresh,
          user: AuthUser.fromJson(Map<String, dynamic>.from(userRaw)),
        ),
        mensaje: (map['mensaje'] ?? 'Cuenta creada correctamente.').toString(),
      );
    }
    if (tempToken.isEmpty) {
      throw ApiException('Registro incompleto: falta el token temporal.');
    }
    return RegistroPendiente(
      tempToken: tempToken,
      destino: (map['destino'] ?? '').toString(),
      mensaje: (map['mensaje'] ?? 'Te enviamos un código a tu correo.')
          .toString(),
      emailEnviado: map['email_enviado'] != false,
    );
  }

  /// Paso 2 del alta: confirma el código y devuelve la sesión del cliente.
  Future<LoginSuccess> verificarRegistro({
    required String tempToken,
    required String codigo,
  }) async {
    final raw = await _api.post(
      '/register/2fa/verificar/',
      auth: false,
      body: {'tempToken': tempToken, 'codigo': codigo.trim()},
    );
    if (raw is! Map) {
      throw ApiException('Respuesta de verificación inválida.');
    }
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      // Django puede responder 200 con ok:false si la cuenta quedó verificada
      // pero no pudo abrir sesión: el mensaje lo explica.
      throw ApiException((map['error'] ?? 'Código inválido.').toString());
    }
    final access = (map['access'] ?? '').toString();
    final refresh = (map['refresh'] ?? '').toString();
    final userRaw = map['usuario'];
    if (access.isEmpty || refresh.isEmpty || userRaw is! Map) {
      throw ApiException('Verificación incompleta: faltan tokens o usuario.');
    }
    return LoginSuccess(
      access: access,
      refresh: refresh,
      user: AuthUser.fromJson(Map<String, dynamic>.from(userRaw)),
    );
  }

  /// Reenvía el código del alta. Django no revela si el correo existe.
  Future<String> reenviarCodigoRegistro(String correo) async {
    final raw = await _api.post(
      '/reenviar-otp/',
      auth: false,
      body: {'correo': correo.trim().toLowerCase()},
    );
    if (raw is Map && raw['ok'] == false) {
      throw ApiException(
        (raw['error'] ?? 'No se pudo reenviar el código.').toString(),
      );
    }
    final mensaje = raw is Map ? raw['mensaje']?.toString() : null;
    return (mensaje == null || mensaje.isEmpty) ? 'Código reenviado.' : mensaje;
  }

  Future<AuthUser> me() async {
    final raw = await _api.get('/auth/me/');
    if (raw is! Map) throw ApiException('Respuesta /auth/me inválida.');
    return AuthUser.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<PerfilDto> perfil() async {
    final raw = await _api.get('/perfil/');
    return _perfilDesde(raw);
  }

  /// `PUT /perfil/` (rectificación ARCO). Django responde con el perfil ya
  /// actualizado, en el mismo sobre que `GET /perfil/`.
  Future<PerfilDto> actualizarPerfil(PerfilUpdate cambios) async {
    final raw = await _api.put('/perfil/', body: cambios.toJson());
    return _perfilDesde(raw);
  }

  /// `GET /perfil/2fa/`: si al iniciar sesión se pide código por correo.
  Future<Preferencia2fa> preferencia2fa() async {
    return _preferencia2faDesde(await _api.get('/perfil/2fa/'));
  }

  /// `PUT /perfil/2fa/` con `{email_2fa}`. Devuelve lo que quedó guardado.
  Future<Preferencia2fa> guardarPreferencia2fa({required bool email2fa}) async {
    return _preferencia2faDesde(
      await _api.put('/perfil/2fa/', body: {'email_2fa': email2fa}),
    );
  }

  Preferencia2fa _preferencia2faDesde(Object? raw) {
    if (raw is! Map) throw ApiException('Respuesta de seguridad inválida.');
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false || map['email_2fa'] is! bool) {
      throw ApiException(
        (map['error'] ?? 'No se pudo leer la verificación por correo.')
            .toString(),
      );
    }
    return Preferencia2fa.fromJson(map);
  }

  PerfilDto _perfilDesde(Object? raw) {
    if (raw is! Map) throw ApiException('Respuesta de perfil inválida.');
    final map = Map<String, dynamic>.from(raw);
    if (map['ok'] == false) {
      throw ApiException(
        (map['error'] ?? 'No se pudo cargar el perfil.').toString(),
      );
    }
    final perfil = map['perfil'];
    if (perfil is Map) {
      return PerfilDto.fromJson(Map<String, dynamic>.from(perfil));
    }
    // Compat: some payloads may be flat.
    return PerfilDto.fromJson(map);
  }
}
