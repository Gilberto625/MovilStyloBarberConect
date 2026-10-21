import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/core/media/variante_imagen.dart';
import 'package:stylo_barber_connect/models/catalog_models.dart';
import 'package:stylo_barber_connect/views/guest/guest_premium_widgets.dart';

const _cloudinary =
    'https://res.cloudinary.com/demo/image/upload/v1712000000/servicios/corte.jpg';

ServicioDto _servicio(String url) => ServicioDto(
  id: 1,
  nombre: 'Corte Fade',
  descripcion: '',
  precio: 200,
  duracionMinutos: 30,
  categoria: 'corte',
  popular: false,
  activo: true,
  imagenUrl: url,
  bannerUrl: '',
);

/// URL y ancho de decodificación que pidió el primer `Image` del árbol.
(String, int?) _pedida(WidgetTester tester) {
  final image = tester.widget<Image>(find.byType(Image).first);
  final provider = image.image;
  if (provider is ResizeImage) {
    return ((provider.imageProvider as NetworkImage).url, provider.width);
  }
  return ((provider as NetworkImage).url, null);
}

void main() {
  group('urlVariante', () {
    test('recorta en Cloudinary centrado en el contenido', () {
      expect(
        urlVariante(_cloudinary, VarianteImagen.tarjeta),
        'https://res.cloudinary.com/demo/image/upload/'
        'c_fill,g_auto,ar_1.6,w_720,q_auto/v1712000000/servicios/corte.jpg',
      );
    });

    test('proporciones en decimal corto', () {
      expect(VarianteImagen.miniatura.transformacion, contains('ar_1,'));
      expect(VarianteImagen.detalle.transformacion, contains('ar_1.25,'));
      expect(VarianteImagen.portada.transformacion, contains('ar_1.333,'));
    });

    test('banners y productos solo se reducen, sin recorte', () {
      for (final v in [
        VarianteImagen.banner,
        VarianteImagen.producto,
        VarianteImagen.productoDetalle,
        VarianteImagen.productoMiniatura,
      ]) {
        expect(v.transformacion, startsWith('c_limit,w_'));
        expect(v.transformacion, isNot(contains('g_auto')));
      }
    });

    test('otras URLs no se tocan', () {
      for (final url in [
        'https://backend.example.test/media/corte.jpg',
        'http://res.cloudinary.com/demo/image/upload/v1/a.jpg',
        'https://res.cloudinary.com/demo/video/upload/v1/a.mp4',
        'no es una url',
      ]) {
        expect(urlVariante(url, VarianteImagen.tarjeta), url);
      }
    });
  });

  group('Fotos del catálogo', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: SizedBox(width: 280, child: child)),
          ),
        ),
      );
    }

    testWidgets('la tarjeta de servicio pide el recorte 16:10 de 720 px', (
      tester,
    ) async {
      await pump(
        tester,
        GuestServiceCard(servicio: _servicio(_cloudinary), onTap: () {}),
      );

      final (url, ancho) = _pedida(tester);
      expect(url, contains('/image/upload/c_fill,g_auto,ar_1.6,w_720,q_auto/'));
      expect(ancho, 720, reason: 'Se decodifica al ancho de la variante');
    });

    testWidgets('la miniatura de la lista pide el recorte cuadrado', (
      tester,
    ) async {
      await pump(
        tester,
        ServiceListTile(servicio: _servicio(_cloudinary), onTap: () {}),
      );

      expect(_pedida(tester).$1, contains('c_fill,g_auto,ar_1,w_240'));
    });

    testWidgets('fuera de Cloudinary baja la foto original, pero la '
        'decodifica reducida', (tester) async {
      const otra = 'https://backend.example.test/media/corte.jpg';
      await pump(
        tester,
        GuestServiceCard(servicio: _servicio(otra), onTap: () {}),
      );

      final (url, ancho) = _pedida(tester);
      expect(url, otra);
      expect(ancho, 720);
    });
  });
}
