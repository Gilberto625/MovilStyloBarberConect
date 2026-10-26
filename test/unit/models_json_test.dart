import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/models/auth_models.dart';
import 'package:stylo_barber_connect/models/cita_models.dart';

Map<String, dynamic> _fixture(String name) => Map<String, dynamic>.from(
  jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map,
);

void main() {
  group('U-JSON fromJson con fixtures del contrato Django', () {
    test('CitaDto acepta números como texto y campos ausentes', () {
      final citas = (_fixture('mis_citas.json')['citas'] as List)
          .map((e) => CitaDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      expect(citas, hasLength(2));
      final a = citas.first;
      expect(a.id, 41);
      expect(a.precioTotal, 180);
      expect(a.anticipoPagado, 90);
      expect(a.saldoPendiente, 90);
      expect(a.requierePago, isTrue);

      final b = citas.last;
      expect(b.id, 42);
      expect(b.servicioId, 5);
      expect(b.duracionMinutos, 30);
      expect(b.barberoNombre, 'Barbero');
      expect(b.saldoPendiente, 0);
      // Solo un booleano true real cuenta: "true" como texto no exige pago.
      expect(b.requierePago, isFalse);
    });

    test('BarberoDto ignora ids no numéricos y da un nombre por defecto', () {
      final barberos = (_fixture('barberos.json')['barberos'] as List)
          .map((e) => BarberoDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      expect(barberos.first.serviciosIds, [3, 5]);
      expect(barberos.first.displayName, 'Ana Prueba');
      expect(barberos.last.serviciosIds, isEmpty);
      expect(barberos.last.displayName, 'Barbero');
    });

    test('PoliticaPagoDto lee anticipo y penalización', () {
      final p = PoliticaPagoDto.fromJson(_fixture('politica_pago.json'));
      expect(p.requiereAnticipo, isTrue);
      expect(p.porcentajeAnticipo, 50);
      expect(p.penalizado, isTrue);
      expect(p.totalInasistencias, 2);
    });

    test('SecretariaCitaDto lee permisos y penalización anidada', () {
      final c = SecretariaCitaDto.fromJson(_fixture('secretaria_cita.json'));
      expect(c.puedeMarcarAsistencia, isTrue);
      expect(c.puedeCobrar, isFalse);
      expect(c.clientePenalizado, isTrue);
      expect(c.anticipoPendiente, 90);
      expect(c.penalizacionPorcentaje, 50);
      expect(c.penalizacionInasistencias, 2);
      expect(c.penalizacionCitasRestantes, 3);
    });

    test(
      'SecretariaCitaDto sin penalización ni permisos los deja en falso',
      () {
        final c = SecretariaCitaDto.fromJson({'id': 1});
        expect(c.puedeMarcarAsistencia, isFalse);
        expect(c.puedeCobrar, isFalse);
        expect(c.clientePenalizado, isFalse);
        expect(c.penalizacionCitasRestantes, 0);
        expect(c.clienteNombre, 'Cliente');
      },
    );

    test('AuthUser normaliza el rol y sobrevive a encode/tryDecode', () {
      final u = AuthUser.fromJson(_fixture('auth_me.json'));
      expect(u.id, 15);
      expect(u.rol, UserRole.cliente);
      final back = AuthUser.tryDecode(u.encode());
      expect(back?.email, u.email);
      expect(back?.rol, UserRole.cliente);
      expect(AuthUser.tryDecode('{no es json'), isNull);
      expect(AuthUser.tryDecode(null), isNull);
    });

    test('parseUserRole reconoce administrador y desconocidos', () {
      expect(parseUserRole('Administrador'), UserRole.admin);
      expect(parseUserRole(' SECRETARIA '), UserRole.secretaria);
      expect(parseUserRole('barbero'), UserRole.barbero);
      expect(parseUserRole('otro'), UserRole.unknown);
      expect(parseUserRole(null), UserRole.unknown);
    });

    test('PerfilDto lee el sobre {ok, perfil} y arma el nombre visible', () {
      final p = PerfilDto.fromJson(
        Map<String, dynamic>.from(_fixture('perfil.json')['perfil'] as Map),
      );
      expect(p.displayName, 'Cliente Prueba');
      expect(p.fechaNacimiento, '1999-05-04');
      expect(
        PerfilDto.fromJson({'username': 'solo.usuario'}).displayName,
        'solo.usuario',
      );
    });
  });
}
