import 'package:flutter/material.dart';
import 'theme_vars.dart';

/// Identifier for one of the app's selectable accent palettes. Each id maps
/// to a light and a dark [ThemeVars] via [resolveThemeVars].
enum PaletteId { blue, emerald, sunsetCoral, violet }

extension PaletteIdX on PaletteId {
  String get label => switch (this) {
    PaletteId.blue => 'Blue',
    PaletteId.emerald => 'Emerald',
    PaletteId.sunsetCoral => 'Sunset Coral',
    PaletteId.violet => 'Violet',
  };

  /// Representative swatch color for picker chips (always the light-mode
  /// accent, regardless of the app's current brightness).
  Color get swatch => switch (this) {
    PaletteId.blue => const Color(0xFF2F6FED),
    PaletteId.emerald => const Color(0xFF12B76A),
    PaletteId.sunsetCoral => const Color(0xFFFF6B4A),
    PaletteId.violet => const Color(0xFF7C4DFF),
  };
}

/// Resolves a [PaletteId] + [Brightness] pair to the concrete [ThemeVars]
/// instance carrying its colors.
ThemeVars resolveThemeVars(PaletteId id, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (id) {
    PaletteId.blue => dark ? const BlueDarkTheme() : const BlueLightTheme(),
    PaletteId.emerald => dark ? const EmeraldDarkTheme() : const EmeraldLightTheme(),
    PaletteId.sunsetCoral => dark ? const SunsetCoralDarkTheme() : const SunsetCoralLightTheme(),
    PaletteId.violet => dark ? const VioletDarkTheme() : const VioletLightTheme(),
  };
}

/// Shared neutrals for every light-mode palette — only the accent-related
/// fields (buttonColor/buttonText/containerColor/onContainer) differ between
/// palettes, so those four are the only overrides each concrete class needs.
abstract class _LightBase extends ThemeVars {
  const _LightBase();

  @override
  Brightness get brightness => Brightness.light;

  @override
  Color get background => const Color(0xFFFFFFFF);
  @override
  Color get surface => const Color(0xFFFFFFFF);
  @override
  Color get cardBackground => const Color(0xFFF4F6FA);
  @override
  Color get border => const Color(0xFFE1E6EF);

  @override
  Color get textPrimary => const Color(0xFF12151C);
  @override
  Color get textSecondary => const Color(0xFF5B6472);

  @override
  Color get success => const Color(0xFF1E8E3E);
  @override
  Color get danger => const Color(0xFFD93025);
  @override
  Color get warning => const Color(0xFFB26A00);
}

/// Shared neutrals for every dark-mode palette (see [_LightBase]).
abstract class _DarkBase extends ThemeVars {
  const _DarkBase();

  @override
  Brightness get brightness => Brightness.dark;

  @override
  Color get background => const Color(0xFF10131A);
  @override
  Color get surface => const Color(0xFF10131A);
  @override
  Color get cardBackground => const Color(0xFF1A1E27);
  @override
  Color get border => const Color(0xFF2B303C);

  @override
  Color get textPrimary => const Color(0xFFF2F4F8);
  @override
  Color get textSecondary => const Color(0xFF9AA3B2);

  @override
  Color get success => const Color(0xFF34C759);
  @override
  Color get danger => const Color(0xFFFF5B54);
  @override
  Color get warning => const Color(0xFFFFB020);
}

/// White background, blue accent. The original/default theme — values are
/// unchanged from before multi-palette support was added.
class BlueLightTheme extends _LightBase {
  const BlueLightTheme();

  @override
  Color get buttonColor => const Color(0xFF2F6FED);
  @override
  Color get buttonText => const Color(0xFFFFFFFF);

  @override
  Color get containerColor => const Color(0xFFDDE8FD);
  @override
  Color get onContainer => const Color(0xFF1D4ED8);
}

class BlueDarkTheme extends _DarkBase {
  const BlueDarkTheme();

  @override
  Color get buttonColor => const Color(0xFF5B8DEF);
  @override
  Color get buttonText => const Color(0xFF0B1220);

  @override
  Color get containerColor => const Color(0xFF1E3A78);
  @override
  Color get onContainer => const Color(0xFFBFD4FB);
}

class EmeraldLightTheme extends _LightBase {
  const EmeraldLightTheme();

  @override
  Color get buttonColor => const Color(0xFF12B76A);
  @override
  Color get buttonText => const Color(0xFFFFFFFF);

  @override
  Color get containerColor => const Color(0xFFD3F3E0);
  @override
  Color get onContainer => const Color(0xFF067647);
}

class EmeraldDarkTheme extends _DarkBase {
  const EmeraldDarkTheme();

  @override
  Color get buttonColor => const Color(0xFF22C980);
  @override
  Color get buttonText => const Color(0xFF04150C);

  @override
  Color get containerColor => const Color(0xFF12432C);
  @override
  Color get onContainer => const Color(0xFF8CEFBE);
}

class SunsetCoralLightTheme extends _LightBase {
  const SunsetCoralLightTheme();

  @override
  Color get buttonColor => const Color(0xFFFF6B4A);
  @override
  Color get buttonText => const Color(0xFFFFFFFF);

  @override
  Color get containerColor => const Color(0xFFFFE0D6);
  @override
  Color get onContainer => const Color(0xFFB23A1E);
}

class SunsetCoralDarkTheme extends _DarkBase {
  const SunsetCoralDarkTheme();

  @override
  Color get buttonColor => const Color(0xFFFF8A66);
  @override
  Color get buttonText => const Color(0xFF250D06);

  @override
  Color get containerColor => const Color(0xFF5A2A1D);
  @override
  Color get onContainer => const Color(0xFFFFC3AE);
}

class VioletLightTheme extends _LightBase {
  const VioletLightTheme();

  @override
  Color get buttonColor => const Color(0xFF7C4DFF);
  @override
  Color get buttonText => const Color(0xFFFFFFFF);

  @override
  Color get containerColor => const Color(0xFFE7DEFF);
  @override
  Color get onContainer => const Color(0xFF5B21B6);
}

class VioletDarkTheme extends _DarkBase {
  const VioletDarkTheme();

  @override
  Color get buttonColor => const Color(0xFFA78BFA);
  @override
  Color get buttonText => const Color(0xFF1B1130);

  @override
  Color get containerColor => const Color(0xFF3B2A66);
  @override
  Color get onContainer => const Color(0xFFDED0FF);
}
