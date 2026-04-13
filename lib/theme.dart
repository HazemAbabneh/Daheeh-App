import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand palette ─────────────────────────────────────────────────────────────
const Color kSeedViolet  = Color(0xFF7C3AED);  // fallback seed
const Color kAccentCyan  = Color(0xFF22D3EE);
const Color kBgDark      = Color(0xFF080815);
const Color kGlassFill   = Color(0x18FFFFFF);
const Color kGlassBorder = Color(0x2AFFFFFF);
const Color kGold        = Color(0xFFFFD700); // milestone gold

// ─── Glassmorphism decoration ──────────────────────────────────────────────────
BoxDecoration glassDecoration({
  double radius = 32,
  Color? fill,
  Color? border,
  List<BoxShadow>? shadows,
}) =>
    BoxDecoration(
      color: fill ?? kGlassFill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? kGlassBorder, width: 1.4),
      boxShadow: shadows ??
          const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 32,
              spreadRadius: -6,
            ),
          ],
    );

// ─── Theme factory ─────────────────────────────────────────────────────────────
class DahihTheme {
  DahihTheme._();

  /// Pass the Monet [dynamicScheme] from DynamicColorBuilder.
  /// Falls back to our violet seed on older Android / iOS.
  static ThemeData fromDynamic(ColorScheme? dynamicScheme) {
    final cs = (dynamicScheme ??
            ColorScheme.fromSeed(
              seedColor: kSeedViolet,
              brightness: Brightness.dark,
            ))
        .copyWith(
      brightness:  Brightness.dark,
      secondary:   kAccentCyan,
      surface:     const Color(0xFF10102A),
      onSurface:   Colors.white,
    );

    final base = ThemeData(
      colorScheme:             cs,
      useMaterial3:            true,
      scaffoldBackgroundColor: kBgDark,
      splashColor:             cs.primary.withValues(alpha: .14),
      highlightColor:          Colors.transparent,
    );

    // Tajawal for large display text; Cairo for body/UI
    final textTheme = _buildTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      cardTheme: CardTheme(
        color:     kGlassFill,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: kGlassBorder, width: 1.4),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:     true,
        fillColor:  kGlassFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:   const BorderSide(color: kGlassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:   const BorderSide(color: kGlassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:   BorderSide(color: cs.primary, width: 2),
        ),
        labelStyle: GoogleFonts.cairo(color: Colors.white70),
        hintStyle:  GoogleFonts.cairo(color: Colors.white38),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          elevation:       0,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:     Color(0xFF10102A),
        selectedItemColor:   kSeedViolet,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation:       0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor:                    Colors.transparent,
          statusBarIconBrightness:           Brightness.light,
          systemNavigationBarColor:          Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.tajawal(
          fontSize:   20,
          fontWeight: FontWeight.w800,
          color:      Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor:   kSeedViolet,
        thumbColor:         kSeedViolet,
        inactiveTrackColor: Colors.white24,
        overlayColor:       Color(0x227C3AED),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white70,
        textColor: Colors.white,
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    // Display / headline → Tajawal (bolder Arabic personality)
    // Body / labels → Cairo (cleaner at small sizes)
    return base.copyWith(
      displayLarge:  GoogleFonts.tajawal(
          textStyle: base.displayLarge,  color: Colors.white, fontWeight: FontWeight.w900),
      displayMedium: GoogleFonts.tajawal(
          textStyle: base.displayMedium, color: Colors.white, fontWeight: FontWeight.w800),
      displaySmall:  GoogleFonts.tajawal(
          textStyle: base.displaySmall,  color: Colors.white, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.tajawal(
          textStyle: base.headlineLarge, color: Colors.white, fontWeight: FontWeight.w800),
      headlineMedium:GoogleFonts.tajawal(
          textStyle: base.headlineMedium,color: Colors.white, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.tajawal(
          textStyle: base.headlineSmall, color: Colors.white, fontWeight: FontWeight.w600),
      titleLarge:    GoogleFonts.cairo(
          textStyle: base.titleLarge,    color: Colors.white, fontWeight: FontWeight.w700),
      titleMedium:   GoogleFonts.cairo(
          textStyle: base.titleMedium,   color: Colors.white, fontWeight: FontWeight.w600),
      titleSmall:    GoogleFonts.cairo(
          textStyle: base.titleSmall,    color: Colors.white70),
      bodyLarge:     GoogleFonts.cairo(
          textStyle: base.bodyLarge,     color: Colors.white),
      bodyMedium:    GoogleFonts.cairo(
          textStyle: base.bodyMedium,    color: Colors.white70),
      bodySmall:     GoogleFonts.cairo(
          textStyle: base.bodySmall,     color: Colors.white54),
      labelLarge:    GoogleFonts.cairo(
          textStyle: base.labelLarge,    color: Colors.white, fontWeight: FontWeight.w600),
      labelSmall:    GoogleFonts.cairo(
          textStyle: base.labelSmall,    color: Colors.white54),
    );
  }

  /// Light fallback (rarely used but kept for completeness)
  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: kSeedViolet,
      brightness: Brightness.light,
    ).copyWith(secondary: kAccentCyan);
    final base = ThemeData(colorScheme: cs, useMaterial3: true);
    return base.copyWith(textTheme: _buildTextTheme(base.textTheme));
  }
}
