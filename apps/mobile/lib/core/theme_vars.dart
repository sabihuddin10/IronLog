import 'package:flutter/material.dart';

/// Named color variables for one theme — the Flutter equivalent of a CSS
/// custom-property set (`--bg`, `--text`, `--button-color`, ...).
/// Each concrete theme below is just a class with these fields filled in;
/// use the object directly: `BlueLightTheme().textPrimary`.
abstract class ThemeVars {
  const ThemeVars();

  Brightness get brightness;

  Color get background;
  Color get surface;
  Color get cardBackground;
  Color get border;

  Color get textPrimary;
  Color get textSecondary;

  /// The single accent color for the whole theme — every button, icon
  /// highlight, link, and selected state uses exactly this. Nothing else
  /// (no auto-generated Material tonal palette) supplies accent color.
  Color get buttonColor;
  Color get buttonText;

  /// Soft tinted background for icon chips/avatars (e.g. exercise icons),
  /// paired with [onContainer] for the icon itself.
  Color get containerColor;
  Color get onContainer;

  Color get success;
  Color get danger;
  Color get warning;
}

