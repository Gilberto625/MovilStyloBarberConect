import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografías de la marca empaquetadas en `assets/google_fonts/`.
///
/// La app no descarga fuentes en tiempo de ejecución: se ven igual sin
/// internet y desde el primer arranque, y no hay peticiones a Google.
/// La licencia OFL de cada familia aparece en la pantalla de licencias.
class AppFonts {
  AppFonts._();

  static const licencias = {
    'Fraunces': 'assets/google_fonts/OFL-Fraunces.txt',
    'Manrope': 'assets/google_fonts/OFL-Manrope.txt',
  };

  static void configurar() {
    GoogleFonts.config.allowRuntimeFetching = false;
    LicenseRegistry.addLicense(() async* {
      for (final entrada in licencias.entries) {
        final texto = await rootBundle.loadString(entrada.value);
        yield LicenseEntryWithLineBreaks([entrada.key], texto);
      }
    });
  }
}
