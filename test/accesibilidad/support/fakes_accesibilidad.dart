// Repositorios falsos (sin red) para las pruebas de accesibilidad. Siguen el
// patrón de client_secretary_premium_test.dart. Los textos son deliberadamente
// largos para estresar el layout con texto ampliado y pantalla pequeña.
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/catalog_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';
import 'package:stylo_barber_connect/repositories/auth_repository.dart';
import 'package:stylo_barber_connect/repositories/catalog_repository.dart';
import 'package:stylo_barber_connect/repositories/citas_repository.dart';
import 'package:stylo_barber_connect/repositories/secretaria_repository.dart';

class FakeAuth implements AuthRepository {
  FakeAuth({required UserRole rol, this.conSesion = true})
    : user = AuthUser(
        id: 4,
        username: 'Gilberto',
        email: 'gilberto.hernandez@correo.example.test',
        rol: rol,
      );

  final AuthUser user;
  final bool conSesion;

  @override
  AuthUser? get currentUser => conSesion ? user : null;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async => LoginSuccess(access: 'a', refresh: 'r', user: user);

  @override
  Future<AuthUser> completeLogin(LoginSuccess success) async => success.user;

  @override
  Future<AuthUser> verify2fa({
    required String tempToken,
    required String codigo,
  }) async => user;

  @override
  Future<void> resend2fa(String tempToken) async {}

  @override
  Future<RegistroPendiente> registrar(RegistroRequest datos) async =>
      throw UnimplementedError('registro no se envía en estas pruebas');

  @override
  Future<AuthUser> verificarRegistro({
    required String tempToken,
    required String codigo,
  }) async => throw UnimplementedError('registro no se envía en estas pruebas');

  @override
  Future<String> reenviarCodigoRegistro(String correo) async => '';

  @override
  Future<AuthUser?> restoreSession() async => conSesion ? user : null;

  @override
  Future<PerfilDto> getPerfil() async => PerfilDto(
    email: user.email,
    username: user.username,
    nombre: 'Gilberto',
    apellido: 'Hernández Hernández',
    telefono: '7711234567',
    fechaNacimiento: '',
    avatarUrl: '',
    direccion: '',
  );

  @override
  Future<void> logoutLocal() async {}
}

/// Cita próxima del cliente (las pruebas fijan el reloj al 2026-11-11).
CitaDto citaCliente() => CitaDto(
  id: 3,
  servicioId: 1,
  servicioNombre: 'Corte clásico con acabado a navaja',
  servicioImagen: '',
  fecha: '2026-11-14',
  hora: '11:00',
  duracionMinutos: 45,
  estado: 'confirmada',
  precioTotal: 180,
  anticipoPagado: 0,
  saldoPendiente: 180,
  notas: '',
  barberoNombre: 'Luis Mora',
  requierePago: false,
  barberoId: 8,
  puedeModificar: true,
  limiteModificacion: DateTime(2026, 11, 13, 11),
);

class FakeCitas implements CitasRepository {
  int creadas = 0;

  @override
  Future<List<CitaDto>> getMisCitas() async => [citaCliente()];

  @override
  Future<List<BarberoDto>> getBarberos({int? servicioId}) async => const [
    BarberoDto(
      id: 8,
      nombre: 'Luis',
      apellido: 'Mora',
      especialidades: 'Corte y barba',
      avatarUrl: '',
      serviciosIds: [1],
    ),
  ];

  @override
  Future<List<SlotDisponibilidad>> getDisponibilidad({
    required int barberoId,
    required String fecha,
    required int duracion,
  }) async => const [
    SlotDisponibilidad(hora: '11:30', disponible: true),
    SlotDisponibilidad(hora: '12:00', disponible: false),
    SlotDisponibilidad(hora: '12:30', disponible: true),
  ];

  @override
  Future<PoliticaPagoDto> getPoliticaPago(int clienteId) async =>
      const PoliticaPagoDto(
        requiereAnticipo: false,
        porcentajeAnticipo: 0,
        penalizado: false,
        totalInasistencias: 0,
      );

  @override
  Future<Map<String, dynamic>> crearCita({
    required int clienteId,
    required int barberoId,
    required int servicioId,
    required int duracionMinutos,
    required String fecha,
    required String hora,
    required double precioTotal,
    double anticipoPagado = 0,
    String metodoAnticipo = '',
    String comprobantePago = '',
    String notas = '',
  }) async {
    creadas += 1;
    return {'ok': true, 'id': 9};
  }

  @override
  Future<Map<String, dynamic>> cancelarCita(int citaId, {String motivo = ''}) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> reprogramarCita(
    int citaId, {
    required String fecha,
    required String hora,
  }) => throw UnimplementedError();
}

class FakeCatalog implements CatalogRepository {
  static const servicio = ServicioDto(
    id: 1,
    nombre: 'Corte clásico con acabado a navaja',
    descripcion: 'Corte de máquina y tijera con lavado.',
    precio: 180,
    duracionMinutos: 45,
    categoria: 'corte',
    popular: true,
    activo: true,
    imagenUrl: '',
    bannerUrl: '',
  );

  static const producto = ProductoDto(
    id: 23,
    nombre: 'Pomada de fijación media',
    marca: 'Stylo',
    descripcion: 'Producto de prueba.',
    precio: 189.90,
    categoria: 'cabello',
    stock: 4,
    imagenUrl: '',
    destacado: true,
  );

  @override
  Future<List<ServicioDto>> getServicios() async => const [servicio];

  @override
  Future<List<ProductoDto>> getProductos() async => const [producto];

  @override
  Future<ContactoDto> getContacto() async => ContactoDto.fromJson({
    'telefono': '5550001234',
    'correo': 'contacto@example.invalid',
    'direccion': 'Avenida del Estilo 123, Centro',
    'horario': '',
    'nombre_negocio': 'Tony Stylo Barbería',
    'logo_tipo': 'texto',
    'logo_texto_parte1': 'Tony Stylo',
    'logo_texto_parte2': 'Barbería',
    'logo_url': '',
    'whatsapp_url': '',
    'google_maps_url': '',
    'horarios_por_dia': [
      for (var d = 0; d < 6; d++)
        {
          'dia_semana': d,
          'abierto': true,
          'apertura': '09:00',
          'cierre': '19:00',
        },
      {'dia_semana': 6, 'abierto': false},
    ],
  });

  @override
  Future<
    ({
      ContactoDto contacto,
      List<ServicioDto> servicios,
      List<ProductoDto> productos,
    })
  >
  loadHomeGuest() async => (
    contacto: await getContacto(),
    servicios: await getServicios(),
    productos: await getProductos(),
  );
}

/// Cita del día con todas las acciones que el backend puede autorizar.
const citaSecretaria = SecretariaCitaDto(
  id: 15,
  clienteId: 4,
  clienteNombre: 'Ana López Martínez',
  clienteTelefono: '7711234567',
  servicioNombre: 'Corte clásico con acabado a navaja',
  barberoNombre: 'Luis Mora',
  fecha: '2026-11-11',
  hora: '10:00',
  duracionMinutos: 45,
  estado: 'confirmada',
  precioTotal: 180,
  anticipoPagado: 0,
  anticipoPendiente: 0,
  restante: 180,
  puedeCobrar: true,
  puedeMarcarAsistencia: true,
  clientePenalizado: true,
  penalizacionPorcentaje: 50,
  penalizacionInasistencias: 2,
  penalizacionCitasRestantes: 1,
);

class FakeSecretaria implements SecretariaRepository {
  @override
  Future<SecretariaDiaDto> getCitasDia({String? fecha}) async =>
      const SecretariaDiaDto(
        fecha: '2026-11-11',
        esHoy: true,
        citas: [citaSecretaria],
        total: 1,
        pendientesAccion: 1,
        enCurso: 0,
        completadas: 0,
        noAsistio: 0,
      );

  @override
  Future<Map<String, dynamic>> marcarLlego(int citaId) async => {'ok': true};

  @override
  Future<Map<String, dynamic>> marcarNoAsistio(int citaId) async => {
    'ok': true,
  };

  @override
  Future<Map<String, dynamic>> cobrar({
    required int citaId,
    required String metodoPago,
    String? comprobante,
    String? referencia,
    double? efectivoRecibido,
  }) async => {'ok': true};

  @override
  Future<List<SecretariaClienteDto>> buscarClientes(String q) async => const [];

  @override
  Future<SecretariaClienteDto> crearClientePaso({
    required String nombres,
    String apellido = '',
    required String telefono,
  }) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> crearCita({
    required int clienteId,
    required int barberoId,
    required int servicioId,
    required int duracionMinutos,
    required String fecha,
    required String hora,
    required double precioTotal,
    double anticipoPagado = 0,
    String metodoAnticipo = '',
    String comprobantePago = '',
    String notas = '',
  }) async => {'ok': true, 'id': 1};

  @override
  Future<List<SecretariaCitaResumenDto>> citasDeCliente(int clienteId) async =>
      const [];

  @override
  Future<SecretariaCitaEditableDto> citaEditable(int citaId) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> actualizarCita({
    required int citaId,
    required int barberoId,
    required int servicioId,
    required String fecha,
    required String hora,
    required double precioTotal,
    required double anticipoPagado,
    required String metodoAnticipo,
    required String notas,
    bool cancelar = false,
  }) async => {'ok': true};
}
