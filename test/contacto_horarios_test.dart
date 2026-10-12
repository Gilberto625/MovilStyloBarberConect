import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/models/catalog_models.dart';

void main() {
  group('ContactoDto horarios reales', () {
    test('ordena los días suministrados sin completar los ausentes', () {
      final contacto = ContactoDto.fromJson({
        'horarios_por_dia': [
          {
            'dia_semana': 5,
            'abierto': true,
            'apertura': '10:30',
            'cierre': '18:15',
          },
          {
            'dia_semana': 0,
            'abierto': true,
            'apertura': '09:45',
            'cierre': '19:00',
          },
        ],
      });

      expect(contacto.horariosPorDia.map((h) => h.diaSemana), [0, 5]);
      expect(contacto.horariosPorDia.first.apertura, '09:45');
      expect(contacto.horariosPorDia.first.cierre, '19:00');
      expect(contacto.horariosPorDia.last.apertura, '10:30');
      expect(contacto.horariosPorDia.last.cierre, '18:15');
      expect(contacto.horario, isEmpty);
    });

    test('el contacto legado conserva su horario y no inventa filas', () {
      const horario = 'Lun 11:00:00-16:30:00';
      final contacto = ContactoDto.fromJson({'horario': horario});

      expect(contacto.horario, horario);
      expect(contacto.horariosPorDia, isEmpty);
      expect(ContactoDto.empty().horariosPorDia, isEmpty);
    });

    test('cerrado requiere un false explícito', () {
      final contacto = ContactoDto.fromJson({
        'horarios_por_dia': [
          {'dia_semana': 0, 'abierto': false},
          {'dia_semana': 1, 'abierto': true},
          {'dia_semana': 2},
          {'dia_semana': 3, 'abierto': 'false'},
          {'dia_semana': 4, 'abierto': 0},
        ],
      });

      expect(contacto.horariosPorDia.map((h) => h.abierto), [
        false,
        true,
        null,
        null,
        null,
      ]);
      expect(contacto.horariosPorDia.map((h) => h.cerrado), [
        true,
        false,
        false,
        false,
        false,
      ]);
      expect(contacto.horariosPorDia.every((h) => h.apertura == null), isTrue);
      expect(contacto.horariosPorDia.every((h) => h.cierre == null), isTrue);
    });

    test('ignora filas malformadas y días fuera del contrato sin fallar', () {
      final contacto = ContactoDto.fromJson({
        'horarios_por_dia': [
          null,
          'lunes',
          4,
          {},
          {'dia_semana': -1},
          {'dia_semana': 7},
          {'dia_semana': 'desconocido'},
          {'dia_semana': 1.5},
          {'dia_semana': true},
          {'dia_semana': ' 2 ', 'abierto': true},
        ],
      });

      expect(contacto.horariosPorDia, hasLength(1));
      expect(contacto.horariosPorDia.single.diaSemana, 2);
      expect(contacto.horariosPorDia.single.apertura, isNull);
      expect(contacto.horariosPorDia.single.cierre, isNull);
    });

    test('horarios_por_dia con tipo incorrecto conserva lista vacía', () {
      for (final raw in [
        null,
        'Lunes',
        42,
        {'dia_semana': 0},
      ]) {
        final contacto = ContactoDto.fromJson({'horarios_por_dia': raw});
        expect(contacto.horariosPorDia, isEmpty);
      }
    });

    test('horas vacías o de tipo incorrecto permanecen desconocidas', () {
      final contacto = ContactoDto.fromJson({
        'horarios_por_dia': [
          {'dia_semana': 0, 'apertura': ' ', 'cierre': null},
          {'dia_semana': 1, 'apertura': 900, 'cierre': false},
          {'dia_semana': 2, 'apertura': ' 12:15 ', 'cierre': 'Por confirmar'},
        ],
      });

      expect(contacto.horariosPorDia[0].apertura, isNull);
      expect(contacto.horariosPorDia[0].cierre, isNull);
      expect(contacto.horariosPorDia[1].apertura, isNull);
      expect(contacto.horariosPorDia[1].cierre, isNull);
      expect(contacto.horariosPorDia[2].apertura, '12:15');
      expect(contacto.horariosPorDia[2].cierre, 'Por confirmar');
      expect(contacto.horariosPorDia.every((h) => !h.cerrado), isTrue);
    });

    test('la lista parseada no permite modificar los horarios del DTO', () {
      final contacto = ContactoDto.fromJson({
        'horarios_por_dia': [
          {'dia_semana': 0, 'abierto': true},
        ],
      });

      expect(contacto.horariosPorDia.clear, throwsUnsupportedError);
    });
  });
}
