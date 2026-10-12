import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/models/catalog_models.dart';
import 'package:stylo_barber_connect/views/guest/guest_premium_widgets.dart';
import 'package:stylo_barber_connect/widgets/common_widgets.dart';

const _imageUrl = 'https://assets.example.invalid/catalog.png';
const _imageLabel = 'Imagen del catálogo de prueba';
const _transparentPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAABmJLR0QA/wD/AP+gvaeT'
    'AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5gMQFwcdLl4wmwAAAAtJREFU'
    'CNdjYAACAAAFAAHiJgWbAAAAAElFTkSuQmCC';

const _service = ServicioDto(
  id: 7,
  nombre: 'Corte profesional con lavado, barba y peinado personalizado',
  descripcion: 'Descripción local de prueba.',
  precio: 275.50,
  duracionMinutos: 45,
  categoria: 'corte',
  popular: true,
  activo: true,
  imagenUrl: '',
  bannerUrl: '',
);

const _product = ProductoDto(
  id: 11,
  nombre: 'Pomada de fijación profesional con acabado mate y aroma suave',
  marca: 'Una marca de productos profesionales con nombre muy largo',
  descripcion: 'Descripción local de prueba.',
  precio: 189.90,
  categoria: 'cabello',
  stock: 2,
  imagenUrl: '',
  destacado: true,
);

class _ImageHttpClient implements HttpClient {
  _ImageHttpClient(this._response);

  final Future<HttpClientResponse> Function() _response;
  final List<Uri> requests = [];

  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    if (url.scheme != 'https' || url.host != 'assets.example.invalid') {
      throw StateError('Unexpected image request: $url');
    }
    requests.add(url);
    return _ImageHttpRequest(_response);
  }

  @override
  void close({bool force = false}) {}

  @override
  Never noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected HTTP operation: ${invocation.memberName}',
  );
}

class _ImageHttpRequest implements HttpClientRequest {
  _ImageHttpRequest(this._response);

  final Future<HttpClientResponse> Function() _response;

  @override
  final HttpHeaders headers = _ImageHttpHeaders();

  @override
  Future<HttpClientResponse> close() => _response();

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  Never noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected request operation: ${invocation.memberName}',
  );
}

class _ImageHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  Never noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected header operation: ${invocation.memberName}',
  );
}

class _ImageHttpResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _ImageHttpResponse({
    this.statusCode = HttpStatus.notFound,
    this.bytes = const [],
  });

  final List<int> bytes;

  @override
  final int statusCode;

  @override
  int get contentLength => bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.fromIterable([if (bytes.isNotEmpty) bytes]).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  Never noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected response operation: ${invocation.memberName}',
  );
}

Future<void> _withImageHttpClient(
  WidgetTester tester,
  _ImageHttpClient client,
  Future<void> Function() body,
) async {
  final previousProvider = debugNetworkImageHttpClientProvider;
  final semantics = tester.ensureSemantics();
  final cache = PaintingBinding.instance.imageCache;
  cache.clear();
  cache.clearLiveImages();
  try {
    await HttpOverrides.runZoned<Future<void>>(() async {
      // NetworkImage caches its default HttpClient. Supply this fake directly
      // so test order and runAsync cannot escape the no-network guarantee.
      debugNetworkImageHttpClientProvider = () => client;
      await body();
    }, createHttpClient: (_) => client);
  } finally {
    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    debugNetworkImageHttpClientProvider = previousProvider;
    cache.clear();
    cache.clearLiveImages();
  }
}

Future<void> _pumpSubject(
  WidgetTester tester,
  Widget subject, {
  double width = 240,
  double? height,
  double textScale = 1,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(width: width, height: height, child: subject),
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

GuestPremiumImage _image({String url = _imageUrl, BoxFit fit = BoxFit.cover}) =>
    GuestPremiumImage(
      url: url,
      fit: fit,
      label: _imageLabel,
      fallbackIcon: Icons.content_cut,
    );

Finder _cardButtonSemantics(Finder card) => find
    .descendant(
      of: card,
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.button == true,
      ),
    )
    .first;

void _expectUntruncatedText(WidgetTester tester, String value) {
  final text = tester.widget<Text>(find.text(value));
  expect(text.maxLines, isNull);
  expect(text.overflow, isNot(TextOverflow.ellipsis));
}

void main() {
  group('GuestPremiumImage', () {
    testWidgets('empty URL uses its fallback without requesting a resource', (
      tester,
    ) async {
      final client = _ImageHttpClient(() async => _ImageHttpResponse());
      await _withImageHttpClient(tester, client, () async {
        await _pumpSubject(tester, _image(url: ''), height: 220);

        expect(client.requests, isEmpty);
        expect(find.byIcon(Icons.content_cut), findsOneWidget);
        expect(find.text('Sin imagen'), findsOneWidget);
        expect(
          tester.getSemantics(
            find.bySemanticsLabel('$_imageLabel. Sin imagen.'),
          ),
          isSemantics(isImage: true),
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('HTTP failure shows an accessible fallback without throwing', (
      tester,
    ) async {
      final client = _ImageHttpClient(() async => _ImageHttpResponse());
      await _withImageHttpClient(tester, client, () async {
        await _pumpSubject(tester, _image(), height: 220);

        expect(client.requests, [Uri.parse(_imageUrl)]);
        expect(find.byIcon(Icons.content_cut), findsOneWidget);
        expect(find.text('Imagen no disponible'), findsOneWidget);
        expect(
          tester.getSemantics(
            find.bySemanticsLabel('$_imageLabel. Imagen no disponible.'),
          ),
          isSemantics(isImage: true),
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('connection error uses the same fallback', (tester) async {
      final client = _ImageHttpClient(
        () async => throw const SocketException('Simulated offline image'),
      );
      await _withImageHttpClient(tester, client, () async {
        await _pumpSubject(tester, _image(), height: 220);

        expect(client.requests, hasLength(1));
        expect(find.byIcon(Icons.content_cut), findsOneWidget);
        expect(find.text('Imagen no disponible'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('pending download exposes loading then recovers to fallback', (
      tester,
    ) async {
      final response = Completer<HttpClientResponse>();
      final client = _ImageHttpClient(() => response.future);
      await _withImageHttpClient(tester, client, () async {
        await _pumpSubject(tester, _image(), height: 220, settle: false);

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          tester.getSemantics(
            find.bySemanticsLabel('$_imageLabel. Cargando imagen.'),
          ),
          isSemantics(isImage: true),
        );
        expect(tester.takeException(), isNull);

        response.complete(_ImageHttpResponse());
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Imagen no disponible'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('supplied contain fit is preserved by the network image', (
      tester,
    ) async {
      final response = Completer<HttpClientResponse>();
      final client = _ImageHttpClient(() => response.future);
      await _withImageHttpClient(tester, client, () async {
        await _pumpSubject(
          tester,
          _image(fit: BoxFit.contain),
          height: 220,
          settle: false,
        );

        final image = tester.widget<Image>(find.byType(Image));
        expect(image.fit, BoxFit.contain);
        response.complete(_ImageHttpResponse());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('successful local response keeps the exact image label', (
      tester,
    ) async {
      final client = _ImageHttpClient(
        () async => _ImageHttpResponse(
          statusCode: HttpStatus.ok,
          bytes: base64Decode(_transparentPng),
        ),
      );
      await _withImageHttpClient(tester, client, () async {
        await tester.runAsync(() async {
          await _pumpSubject(tester, _image(), height: 220, settle: false);
          final image = tester.widget<Image>(find.byType(Image));
          final stream = image.image.resolve(ImageConfiguration.empty);
          final decoded = Completer<void>();
          final listener = ImageStreamListener(
            (image, synchronousCall) {
              if (!decoded.isCompleted) decoded.complete();
            },
            onError: (Object error, StackTrace? stackTrace) {
              if (!decoded.isCompleted) {
                decoded.completeError(error, stackTrace);
              }
            },
          );
          stream.addListener(listener);
          try {
            await decoded.future;
          } finally {
            stream.removeListener(listener);
          }
        });
        await tester.pumpAndSettle();

        expect(client.requests, hasLength(1));
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Imagen no disponible'), findsNothing);
        expect(
          tester.getSemantics(find.bySemanticsLabel(_imageLabel)),
          isSemantics(isImage: true),
        );
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('Guest premium catalog cards', () {
    testWidgets('service card can be activated with Tab and Enter', (
      tester,
    ) async {
      var taps = 0;
      await _pumpSubject(
        tester,
        GuestServiceCard(servicio: _service, onTap: () => taps += 1),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('service card invokes its callback once and preserves values', (
      tester,
    ) async {
      var taps = 0;
      await _pumpSubject(
        tester,
        GuestServiceCard(servicio: _service, onTap: () => taps += 1),
      );

      expect(find.text(_service.nombre), findsOneWidget);
      expect(find.text(moneyFormat.format(_service.precio)), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      await tester.tap(find.byType(GuestServiceCard));
      await tester.pump();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'product card invokes its callback once and contains its image',
      (tester) async {
        var taps = 0;
        await _pumpSubject(
          tester,
          GuestProductCard(producto: _product, onTap: () => taps += 1),
        );

        expect(find.text(_product.nombre), findsOneWidget);
        expect(find.text(_product.marca), findsOneWidget);
        expect(find.text(moneyFormat.format(_product.precio)), findsOneWidget);
        final image = tester.widget<GuestPremiumImage>(
          find.descendant(
            of: find.byType(GuestProductCard),
            matching: find.byType(GuestPremiumImage),
          ),
        );
        expect(image.fit, BoxFit.contain);
        await tester.tap(find.byType(GuestProductCard));
        await tester.pump();
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'service card exposes an accessible action with its full name',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _pumpSubject(
            tester,
            GuestServiceCard(servicio: _service, onTap: () {}),
          );

          final card = find.byType(GuestServiceCard);
          final node = tester.getSemantics(_cardButtonSemantics(card));
          expect(node, isSemantics(isButton: true, hasTapAction: true));
          expect(node.getSemanticsData().label, contains(_service.nombre));
          expect(tester.getSize(card).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'product card exposes an accessible action with its full name',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _pumpSubject(
            tester,
            GuestProductCard(producto: _product, onTap: () {}),
          );

          final card = find.byType(GuestProductCard);
          final node = tester.getSemantics(_cardButtonSemantics(card));
          expect(node, isSemantics(isButton: true, hasTapAction: true));
          expect(node.getSemanticsData().label, contains(_product.nombre));
          expect(tester.getSize(card).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'narrow service card wraps its full name at enlarged text scale',
      (tester) async {
        await _pumpSubject(
          tester,
          GuestServiceCard(servicio: _service, onTap: () {}),
          width: 164,
          textScale: 1.3,
        );

        _expectUntruncatedText(tester, _service.nombre);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('narrow product card wraps its full name and brand', (
      tester,
    ) async {
      await _pumpSubject(
        tester,
        GuestProductCard(producto: _product, onTap: () {}),
        width: 164,
        textScale: 1.3,
      );

      _expectUntruncatedText(tester, _product.nombre);
      _expectUntruncatedText(tester, _product.marca);
      expect(tester.takeException(), isNull);
    });
  });
}
