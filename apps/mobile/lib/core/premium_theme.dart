import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Exact design tokens from `app-redesign-premium.html` (repo root) — the
/// authoritative visual spec for the app's redesign. Values are transcribed
/// 1:1 from that file's `:root` CSS custom properties; keep this in sync if
/// the spec changes rather than eyeballing new colors.
class Premium {
  Premium._();

  static const Color bg = Color(0xFF0A0B0D);
  static const Color surface = Color(0xFF141519);
  static const Color surface2 = Color(0xFF1A1C21);
  static const Color surface3 = Color(0xFF212329);
  static const Color border = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color borderStrong = Color(0x24FFFFFF); // rgba(255,255,255,0.14)
  static const Color accent = Color(0xFF4FFFAE);
  static const Color accent2 = Color(0xFF39D9FF);
  static const Color accentDim = Color(0x214FFFAE); // rgba(79,255,174,0.13)
  static const Color accentGlow = Color(0x614FFFAE); // rgba(79,255,174,0.38)
  static const Color blueDim = Color(0x2139D9FF); // rgba(57,217,255,0.13)
  static const Color ink = Color(0xFF06140F);
  static const Color text = Color(0xFFF5F3F0);
  static const Color textDim = Color(0xFF93959C);
  static const Color textFaint = Color(0xFF55575E);
  static const Color good = Color(0xFF7CD9A5);
  static const Color liveRed = Color(0xFFFF5B4D);
  static const Color pageBg = Color(0xFF050506);

  /// `linear-gradient(150deg, var(--accent), var(--accent-2))` — the
  /// signature two-tone gradient used on every primary action, badge,
  /// active-tab, and highlight in the spec.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent2],
  );

  /// `linear-gradient(165deg, var(--surface-2), var(--surface))` — the base
  /// card background used by nearly every card/tile in the spec.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface2, surface],
  );

  /// `linear-gradient(160deg, var(--surface-3), var(--surface-2))` — used by
  /// the ring-card (weekly goal) and other slightly-more-elevated cards.
  static const LinearGradient elevatedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface3, surface2],
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x80000000), blurRadius: 20, offset: Offset(0, 8), spreadRadius: -12),
  ];

  static List<BoxShadow> accentGlowShadow({double blur = 16, double spread = -4}) => [
        BoxShadow(color: accentGlow, blurRadius: blur, spreadRadius: spread, offset: const Offset(0, 6)),
      ];

  // Radii (from the spec's border-radius values).
  static const double radiusSm = 9;
  static const double radiusMd = 14;
  static const double radiusLg = 17;
  static const double radiusXl = 19;
  static const double radiusXxl = 20;

  static TextStyle heading(double size, {FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: weight, color: color ?? text, letterSpacing: -0.3);

  static TextStyle body(double size, {FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color ?? textDim);

  /// The dark [ThemeData] used app-wide — see `theme_controller.dart`.
  static ThemeData themeData() {
    final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark).copyWith(
      surface: surface,
      onSurface: text,
      onSurfaceVariant: textDim,
      primary: accent,
      onPrimary: ink,
      secondary: accent2,
      onSecondary: ink,
      primaryContainer: accentDim,
      onPrimaryContainer: accent,
      error: const Color(0xFFFF6B5C),
      onError: text,
      outline: textFaint,
      outlineVariant: border,
      surfaceContainerLowest: bg,
      surfaceContainerLow: surface,
      surfaceContainer: surface2,
      surfaceContainerHigh: surface3,
      surfaceContainerHighest: surface3,
    );

    final base = GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme);
    final textTheme = base.apply(bodyColor: text, displayColor: text);

    // Screens/widgets across the app read named tokens via
    // `context.colors.xxx` (see app_colors.dart), which resolves
    // `Theme.of(context).extension<AppColorTokens>()!` — that's a
    // null-check, so this extension MUST be registered below or every one
    // of those call sites throws at runtime.
    const tokens = AppColorTokens(
      background: bg,
      surface: surface,
      textPrimary: text,
      textSecondary: textDim,
      buttonColor: accent,
      buttonText: ink,
      cardBackground: surface2,
      border: border,
      containerColor: accentDim,
      onContainer: accent,
      success: good,
      danger: Color(0xFFFF6B5C),
      warning: Color(0xFFFFB020),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      dividerColor: border,
      textTheme: textTheme,
      splashColor: accent.withValues(alpha: 0.12),
      highlightColor: accent.withValues(alpha: 0.08),
      extensions: const [tokens],
      appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: text, elevation: 0),
      iconTheme: const IconThemeData(color: text),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent),
        ),
        hintStyle: body(14, color: textFaint),
      ),
      dialogTheme: DialogThemeData(backgroundColor: surface2, surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: surface2),
      popupMenuTheme: const PopupMenuThemeData(color: surface2),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
      dividerTheme: const DividerThemeData(color: border, space: 1),
    );
  }
}
