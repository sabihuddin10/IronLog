import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'accent_combo.dart';
import 'app_colors.dart';

/// One brightness's full neutral set (everything except the accent, which
/// comes from an [AccentColors] passed into [Premium.themeData] separately).
/// Dark values are the original, unchanged `app-redesign-premium.html`
/// tokens; light values are a new counterpart tuned for a white background.
class _Neutrals {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textDim;
  final Color textFaint;
  final Color good;
  final Color pageBg;

  const _Neutrals({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textDim,
    required this.textFaint,
    required this.good,
    required this.pageBg,
  });
}

const _darkNeutrals = _Neutrals(
  bg: Color(0xFF0A0B0D),
  surface: Color(0xFF141519),
  surface2: Color(0xFF1A1C21),
  surface3: Color(0xFF212329),
  border: Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
  borderStrong: Color(0x24FFFFFF), // rgba(255,255,255,0.14)
  text: Color(0xFFF5F3F0),
  textDim: Color(0xFF93959C),
  textFaint: Color(0xFF55575E),
  good: Color(0xFF7CD9A5),
  pageBg: Color(0xFF050506),
);

const _lightNeutrals = _Neutrals(
  bg: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFF4F6FA),
  surface3: Color(0xFFEAEEF5),
  border: Color(0xFFE1E6EF),
  borderStrong: Color(0xFFC7CFDC),
  text: Color(0xFF12151C),
  textDim: Color(0xFF5B6472),
  textFaint: Color(0xFF8A93A3),
  good: Color(0xFF1E8E3E),
  pageBg: Color(0xFFF7F8FA),
);

/// Design tokens transcribed from `app-redesign-premium.html` (repo root),
/// now parameterized by [Brightness] and an [AccentColors] pair instead of
/// being fixed to one dark accent — see [ThemeController] for how the active
/// combo is chosen and persisted.
class Premium {
  Premium._();

  // Radii (from the spec's border-radius values) — brightness/accent
  // independent, unchanged.
  static const double radiusSm = 9;
  static const double radiusMd = 14;
  static const double radiusLg = 17;
  static const double radiusXl = 19;
  static const double radiusXxl = 20;

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x80000000), blurRadius: 20, offset: Offset(0, 8), spreadRadius: -12),
  ];

  /// Heading text style. Defaults to the active theme's primary text color
  /// via [context]; pass [color] to override (e.g. text sitting on a solid
  /// accent fill).
  static TextStyle heading(BuildContext context, double size, {FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color ?? context.colors.textPrimary,
        letterSpacing: -0.3,
      );

  /// Body text style. Defaults to the active theme's secondary text color
  /// via [context]; pass [color] to override.
  static TextStyle body(BuildContext context, double size, {FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color ?? context.colors.textSecondary);

  /// The [ThemeData] for one brightness with the given accent combo plugged
  /// in — see `theme_controller.dart`, which calls this once per brightness
  /// with the user's selected/custom [AccentColors].
  static ThemeData themeData({required Brightness brightness, required AccentColors accentColors}) {
    final neutrals = brightness == Brightness.dark ? _darkNeutrals : _lightNeutrals;
    final accent = accentColors.accent;
    final accent2 = accentColors.accent2;
    final onAccent = ThemeData.estimateBrightnessForColor(accent) == Brightness.dark ? Colors.white : Colors.black;
    final accentDim = accent.withValues(alpha: 0.13);
    final danger = brightness == Brightness.dark ? const Color(0xFFFF6B5C) : const Color(0xFFD93025);
    final warning = brightness == Brightness.dark ? const Color(0xFFFFB020) : const Color(0xFFB26A00);

    final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness).copyWith(
      surface: neutrals.surface,
      onSurface: neutrals.text,
      onSurfaceVariant: neutrals.textDim,
      primary: accent,
      onPrimary: onAccent,
      secondary: accent2,
      onSecondary: onAccent,
      primaryContainer: accentDim,
      onPrimaryContainer: accent,
      error: danger,
      onError: onAccent,
      outline: neutrals.textFaint,
      outlineVariant: neutrals.border,
      surfaceContainerLowest: neutrals.bg,
      surfaceContainerLow: neutrals.surface,
      surfaceContainer: neutrals.surface2,
      surfaceContainerHigh: neutrals.surface3,
      surfaceContainerHighest: neutrals.surface3,
    );

    final base = GoogleFonts.interTextTheme(ThemeData(brightness: brightness).textTheme);
    final textTheme = base.apply(bodyColor: neutrals.text, displayColor: neutrals.text);

    // Screens/widgets across the app read named tokens via
    // `context.colors.xxx` (see app_colors.dart), which resolves
    // `Theme.of(context).extension<AppColorTokens>()!` — that's a
    // null-check, so this extension MUST be registered below or every one
    // of those call sites throws at runtime.
    final tokens = AppColorTokens(
      background: neutrals.bg,
      surface: neutrals.surface,
      textPrimary: neutrals.text,
      textSecondary: neutrals.textDim,
      buttonColor: accent,
      buttonText: onAccent,
      cardBackground: neutrals.surface2,
      border: neutrals.border,
      containerColor: accentDim,
      onContainer: accent,
      success: neutrals.good,
      danger: danger,
      warning: warning,
      accent: accent,
      accent2: accent2,
      surfaceHigh: neutrals.surface3,
      borderStrong: neutrals.borderStrong,
      textFaint: neutrals.textFaint,
      pageBackground: neutrals.pageBg,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: neutrals.bg,
      canvasColor: neutrals.bg,
      dividerColor: neutrals.border,
      textTheme: textTheme,
      splashColor: accent.withValues(alpha: 0.12),
      highlightColor: accent.withValues(alpha: 0.08),
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: neutrals.bg,
        foregroundColor: neutrals.text,
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutrals.text,
          letterSpacing: -0.3,
        ),
      ),
      iconTheme: IconThemeData(color: neutrals.text),
      cardTheme: CardThemeData(
        elevation: 0,
        color: neutrals.surface2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutrals.surface3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neutrals.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: neutrals.textFaint),
      ),
      dialogTheme: DialogThemeData(backgroundColor: neutrals.surface2, surfaceTintColor: Colors.transparent),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: neutrals.surface2),
      popupMenuTheme: PopupMenuThemeData(color: neutrals.surface2),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      dividerTheme: DividerThemeData(color: neutrals.border, space: 1),
    );
  }
}
