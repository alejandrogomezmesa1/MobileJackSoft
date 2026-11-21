import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de color de FrontedJackSoft/jacksoft/DESIGN.md.
/// La app usa el lenguaje de la "Cuenta del cliente" (superficie para celular):
/// fondo cálido #faf8f5, líneas #e7e1d9, esquinas de 2 px y naranja solo en la
/// acción principal de cada pantalla (One Orange Rule).
abstract final class JkColors {
  static const orange = Color(
    0xFFF2641A,
  ); // coca-orange: solo la acción principal
  static const orangeHover = Color(0xFFFF7330);
  static const orangeDeep = Color(0xFFB93F0C);
  static const orangeWash = Color(0xFFFFF3EA);
  static const orangeLine = Color(0xFFF7C9A8);

  static const ink = Color(0xFF2B2118); // carbon-ink
  static const inkSoft = Color(0xFF5C4E41);
  static const inkMuted = Color(0xFF6B5D50);

  static const cream = Color(0xFFFFF6EA);
  static const beige = Color(0xFFFBF8F3);
  static const paper = Color(0xFFFFFDF9);
  static const white = Color(0xFFFFFFFF);

  static const hairline = Color(0xFFEEE6DA);
  static const hairlineStrong = Color(0xFFDDD1BF);
  static const dash = Color(0xFFCBBDA9);

  static const green = Color(0xFF5E8D62);
  static const greenWash = Color(0xFFE7F3E8);
  static const greenInk = Color(0xFF2F5A33);
  static const amberWash = Color(0xFFFFF1D0);
  static const amberInk = Color(0xFF7A5100);
  static const red = Color(0xFFB42318);
  static const redWash = Color(0xFFFDECEB);
  static const night = Color(0xFF17130F);

  // Superficie de la cuenta (DESIGN.md · Cuenta del cliente)
  static const bg = Color(0xFFFAF8F5);
  static const line = Color(0xFFE7E1D9);
}

abstract final class JkRadius {
  /// "Esquinas de 2 px en todo" (Cuenta del cliente). Cambiar aquí si el
  /// equipo decide volver a las esquinas redondas del prototipo HTML.
  static const double r = 2;
  static const BorderRadius br = BorderRadius.all(Radius.circular(r));
}

abstract final class JkSpace {
  static const double gutter = 16; // márgenes de 16 px
  static const double touch = 44; // objetivos táctiles de 44 px o más
  static const double field = 48;
}

/// Baloo 2 para titulares, Work Sans para leer, monoespaciada solo para la comanda.
abstract final class JkText {
  /// En las pruebas se apaga para no descargar fuentes.
  static bool googleFonts = true;

  static TextStyle _f(
    String family,
    TextStyle Function({TextStyle? textStyle}) g,
    TextStyle base,
  ) => googleFonts ? g(textStyle: base) : base.copyWith(fontFamily: family);

  static TextStyle display(
    double size, {
    FontWeight w = FontWeight.w700,
    Color c = JkColors.ink,
  }) => _f(
    'Baloo 2',
    GoogleFonts.baloo2,
    TextStyle(fontSize: size, fontWeight: w, color: c, height: 1.15),
  );

  static TextStyle body(
    double size, {
    FontWeight w = FontWeight.w400,
    Color c = JkColors.ink,
    double h = 1.4,
  }) => _f(
    'Work Sans',
    GoogleFonts.workSans,
    TextStyle(fontSize: size, fontWeight: w, color: c, height: h),
  );

  static TextStyle mono(
    double size, {
    FontWeight w = FontWeight.w600,
    Color c = JkColors.inkSoft,
  }) => _f(
    'JetBrains Mono',
    GoogleFonts.jetBrainsMono,
    TextStyle(fontSize: size, fontWeight: w, color: c),
  );
}

ThemeData buildJkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: JkColors.orange,
      primary: JkColors.ink,
      onPrimary: JkColors.white,
      secondary: JkColors.orange,
      surface: JkColors.white,
      error: JkColors.red,
    ),
    scaffoldBackgroundColor: JkColors.bg,
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    textTheme: GoogleFonts.workSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: JkColors.ink, displayColor: JkColors.ink),
    dividerColor: JkColors.line,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: JkColors.ink,
      selectionColor: JkColors.orangeLine,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: JkColors.ink,
      contentTextStyle: JkText.body(14, c: JkColors.white, w: FontWeight.w500),
      shape: const RoundedRectangleBorder(borderRadius: JkRadius.br),
      elevation: 6,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: JkColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(JkRadius.r)),
      ),
      showDragHandle: true,
      dragHandleColor: JkColors.hairlineStrong,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JkColors.white,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      hintStyle: JkText.body(16, c: JkColors.inkMuted.withValues(alpha: .7)),
      border: _border(JkColors.hairlineStrong),
      enabledBorder: _border(JkColors.hairlineStrong),
      focusedBorder: _border(JkColors.ink, 1.5),
      errorBorder: _border(JkColors.red),
      focusedErrorBorder: _border(JkColors.red, 1.5),
      errorStyle: JkText.body(12.5, c: JkColors.red),
    ),
  );
}

OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
  borderRadius: JkRadius.br,
  borderSide: BorderSide(color: c, width: w),
);
