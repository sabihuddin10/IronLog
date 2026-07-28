import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_vars.dart';

/// App-wide type scale. Reuses Material 3's default size/weight scale and
/// only swaps the font family, so there's no custom scale to invent or
/// maintain — just a family swap applied consistently everywhere.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(ThemeVars vars) {
    final base = GoogleFonts.manropeTextTheme(
      ThemeData(brightness: vars.brightness).textTheme,
    );
    return base.apply(bodyColor: vars.textPrimary, displayColor: vars.textPrimary);
  }
}
