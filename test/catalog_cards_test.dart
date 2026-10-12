import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/widgets/common_widgets.dart';

void main() {
  testWidgets('product and service cards fit the home rows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 250,
                child: ServicioCard(
                  nombre: 'Corte clásico con barba',
                  precio: 180,
                  duracion: 45,
                ),
              ),
              SizedBox(
                height: 280,
                child: ProductoCard(
                  nombre: 'Minoxidil Solución',
                  marca: 'FARMAPIEL',
                  precio: 199,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('BOTTOM OVERFLOWED'), findsNothing);
  });
}
