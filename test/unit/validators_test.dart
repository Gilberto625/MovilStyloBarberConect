import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/core/validation/validators.dart';

void main() {
  group('PM-U01 validador de correo o usuario', () {
    test('acepta correos válidos', () {
      expect(validarCuenta('cliente@example.test'), isNull);
      expect(
        validarCuenta('  nombre.apellido+citas@barberia.com.mx  '),
        isNull,
      );
    });

    test('acepta un nombre de usuario sin @', () {
      expect(validarCuenta('cliente.prueba'), isNull);
    });

    test('rechaza vacío o solo espacios', () {
      expect(validarCuenta(null), 'Obligatorio');
      expect(validarCuenta(''), 'Obligatorio');
      expect(validarCuenta('   '), 'Obligatorio');
    });

    test('rechaza correos sin @ válido, sin dominio o sin extensión', () {
      expect(validarCuenta('correo@'), 'Correo no válido');
      expect(validarCuenta('@example.test'), 'Correo no válido');
      expect(validarCuenta('correo@dominio'), 'Correo no válido');
      expect(
        validarCuenta('correo con espacio@example.test'),
        'Correo no válido',
      );
      expect(validarCuenta('a@@example.test'), 'Correo no válido');
    });
  });
}
