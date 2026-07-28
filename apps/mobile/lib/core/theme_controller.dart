import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'palettes.dart';
import 'premium_theme.dart';

/// Central theme provider — the single source of truth for which theme
/// mode (light/dark/system) and accent palette the app renders with.
///
/// Constructs synchronously with valid defaults, then refines itself once
/// the persisted choice loads from [SharedPreferences]. `notifyListeners()`
/// is only ever called after an `await`, never synchronously during
/// construction, so it can't fire mid-build of some other widget.
class ThemeController extends ChangeNotifier {
  static const _prefsKeyMode = 'theme_mode';
  static const _prefsKeyPalette = 'theme_palette';

  ThemeMode _themeMode = ThemeMode.system;
  PaletteId _paletteId = PaletteId.blue;

  ThemeController() {
    _load();
  }

  ThemeMode get themeMode => _themeMode;
  PaletteId get paletteId => _paletteId;

  // The app now renders a single fixed dark theme matching
  // `app-redesign-premium.html` (repo root) exactly, regardless of
  // mode/palette selection — see [Premium.themeData]. [AppTheme.build] and
  // the palette system below are kept intact (not deleted) since
  // [ThemeSettingsScreen] and [_paletteId]/[_themeMode] still read them, but
  // neither currently affects what's rendered.
  ThemeData get lightTheme => Premium.themeData();
  ThemeData get darkTheme => Premium.themeData();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeName = prefs.getString(_prefsKeyMode);
    final paletteName = prefs.getString(_prefsKeyPalette);
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => ThemeMode.system,
    );
    _paletteId = PaletteId.values.firstWhere(
      (p) => p.name == paletteName,
      orElse: () => PaletteId.blue,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyMode, mode.name);
  }

  Future<void> setPalette(PaletteId id) async {
    if (_paletteId == id) return;
    _paletteId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyPalette, id.name);
  }
}
