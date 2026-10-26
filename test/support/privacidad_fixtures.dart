import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/privacidad_models.dart';

// Datos ficticios compartidos por las pruebas ARCO.
const perfilPrueba = PerfilDto(
  email: 'cliente.prueba@example.test',
  username: 'cliente.prueba',
  nombre: 'Cliente',
  apellido: 'Prueba',
  telefono: '7710000000',
  fechaNacimiento: '1999-05-04',
  avatarUrl: 'https://cdn.example.test/avatar.png',
  direccion: 'Calle Falsa #123',
);

const avisoPrueba = ContenidoLegalDto(
  tipo: 'privacidad',
  tipoDisplay: 'Política de privacidad',
  titulo: 'Aviso de privacidad',
  contenido: 'Tony Stylo Barbería trata tus datos para agendar citas.',
);
