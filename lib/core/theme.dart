import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Set to false in tests so no font is fetched over the network.
class KharchuFonts {
  static bool enabled = true;
}

/// Every color the screens use, in a light and a teal-tinted dark palette.
/// Read with `context.kc`.
@immutable
class KharchuColors extends ThemeExtension<KharchuColors> {
  const KharchuColors({
    required this.bg,
    required this.surface,
    required this.field,
    required this.ink,
    required this.muted,
    required this.line,
    required this.hair,
    required this.accent,
    required this.onAccent,
    required this.soft,
    required this.softInk,
    required this.warn,
    required this.warnBg,
    required this.warnInk,
    required this.danger,
    required this.dangerBg,
    required this.dangerInk,
    required this.track,
    required this.lentBg,
    required this.lentInk,
    required this.borrowedBg,
    required this.borrowedInk,
    required this.bar,
    required this.chart,
  });

  final Color bg, surface, field, ink, muted, line, hair;
  final Color accent, onAccent, soft, softInk;
  final Color warn, warnBg, warnInk;
  final Color danger, dangerBg, dangerInk;
  final Color track, bar;
  final Color lentBg, lentInk, borrowedBg, borrowedInk;
  final List<Color> chart;

  static const light = KharchuColors(
    bg: Color(0xFFF2F4F3),
    surface: Color(0xFFFFFFFF),
    field: Color(0xFFF7F9F8),
    ink: Color(0xFF15201B),
    muted: Color(0xFF56635C),
    line: Color(0xFFDDE3E0),
    hair: Color(0xFFEEF1EF),
    accent: Color(0xFF0F6B5C),
    onAccent: Color(0xFFFFFFFF),
    soft: Color(0xFFE3F1EC),
    softInk: Color(0xFF0A4F44),
    warn: Color(0xFFC2620F),
    warnBg: Color(0xFFFFF4E8),
    warnInk: Color(0xFF6E3A0A),
    danger: Color(0xFFB42318),
    dangerBg: Color(0xFFFCEDEC),
    dangerInk: Color(0xFF8A1C12),
    track: Color(0xFFE3E8E5),
    lentBg: Color(0xFFEAF0FA),
    lentInk: Color(0xFF24477F),
    borrowedBg: Color(0xFFF3ECF8),
    borrowedInk: Color(0xFF5B3480),
    bar: Color(0xFF94C7B8),
    chart: [
      Color(0xFF0F6B5C),
      Color(0xFFD9822B),
      Color(0xFF3A66C4),
      Color(0xFF7FB8A6),
      Color(0xFF8A5BB0),
      Color(0xFFA9B3AE),
    ],
  );

  static const dark = KharchuColors(
    bg: Color(0xFF0E1513),
    surface: Color(0xFF16201D),
    field: Color(0xFF1C2925),
    ink: Color(0xFFE4ECE8),
    muted: Color(0xFF9AABA3),
    line: Color(0xFF26342F),
    hair: Color(0xFF1F2B27),
    accent: Color(0xFF3FAE95),
    onAccent: Color(0xFF06231C),
    soft: Color(0xFF183A32),
    softInk: Color(0xFF8FDCC8),
    warn: Color(0xFFE08A3C),
    warnBg: Color(0xFF33240F),
    warnInk: Color(0xFFF2C08A),
    danger: Color(0xFFE5604F),
    dangerBg: Color(0xFF3A1A17),
    dangerInk: Color(0xFFF4A49A),
    track: Color(0xFF26342F),
    lentBg: Color(0xFF1B2840),
    lentInk: Color(0xFFA8C2EE),
    borrowedBg: Color(0xFF2A1F38),
    borrowedInk: Color(0xFFCDB2E8),
    bar: Color(0xFF2E5E52),
    chart: [
      Color(0xFF3FAE95),
      Color(0xFFE08A3C),
      Color(0xFF6E95E6),
      Color(0xFF8CC9B6),
      Color(0xFFA983CC),
      Color(0xFF5F6E68),
    ],
  );

  @override
  KharchuColors copyWith() => this;

  @override
  KharchuColors lerp(ThemeExtension<KharchuColors>? other, double t) {
    if (other is! KharchuColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension KharchuContext on BuildContext {
  KharchuColors get kc => Theme.of(this).extension<KharchuColors>()!;
}

/// Sora for headings and big amounts; falls back to the default font when
/// fonts are disabled (tests) or offline and not yet cached.
TextStyle headingStyle({
  double size = 20,
  FontWeight weight = FontWeight.w700,
  Color? color,
}) {
  final base = TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  return KharchuFonts.enabled ? GoogleFonts.sora(textStyle: base) : base;
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? KharchuColors.dark : KharchuColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: c.accent,
    brightness: brightness,
  ).copyWith(
    primary: c.accent,
    onPrimary: c.onAccent,
    surface: c.surface,
    onSurface: c.ink,
    error: c.danger,
    outline: c.line,
  );

  var base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    extensions: [c],
  );
  if (KharchuFonts.enabled) {
    base = base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
    );
  }

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: c.hair, space: 1, thickness: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      height: 64,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? c.accent : c.muted,
            size: 24,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 11,
            fontWeight:
                s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
            color: s.contains(WidgetState.selected) ? c.accent : c.muted,
          )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.accent, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: c.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: TextStyle(color: c.bg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
