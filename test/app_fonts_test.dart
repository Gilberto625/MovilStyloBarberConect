import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylo_barber_connect/core/config/app_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'las variantes que usa el tema están empaquetadas con su licencia',
    () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets().toSet();
      const variantes = [
        'Fraunces-Regular',
        'Fraunces-Medium',
        'Fraunces-SemiBold',
        'Fraunces-MediumItalic',
        'Fraunces-SemiBoldItalic',
        'Manrope-Regular',
        'Manrope-Medium',
        'Manrope-SemiBold',
        'Manrope-Bold',
        'Manrope-ExtraBold',
      ];
      for (final v in variantes) {
        expect(assets, contains('assets/google_fonts/$v.ttf'), reason: v);
      }
      for (final licencia in AppFonts.licencias.values) {
        final texto = utf8.decode(
          (await rootBundle.load(licencia)).buffer.asUint8List(),
        );
        expect(texto.toUpperCase(), contains('SIL OPEN FONT LICENSE'));
      }
    },
  );
}
