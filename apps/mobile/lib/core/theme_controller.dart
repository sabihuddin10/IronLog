import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'accent_combo.dart';
import 'palettes.dart';
import 'premium_theme.dart';

/// Central theme provider — the single source of truth for which theme
/// mode (light/dark/system) and accent combo the app renders with.
///
/// Constructs synchronously with valid defaults, then refines itself once
/// the persisted choice loads from [SharedPreferences]. `notifyListeners()`
/// is only ever called after an `await`, never synchronously during
/// construction, so it can't fire mid-build of some other widget.
class ThemeController extends ChangeNotifier {
  static const _prefsKeyMode = 'theme_mode';
  static const _prefsKeyPalette = 'theme_palette';
  static const _prefsKeyAccentCombo = 'accent_combo_id';
  static const _prefsKeyCustomAccent = 'custom_accent';
  static const _prefsKeyCustomAccent2 = 'custom_accent2';

  ThemeMode _themeMode = ThemeMode.system;
  PaletteId _paletteId = PaletteId.blue;
  String _accentComboId = kAccentPresets.first.id;
  AccentColors? _customAccent;

  ThemeController() {
    _load();
  }

  ThemeMode get themeMode => _themeMode;
  PaletteId get paletteId => _paletteId;
  String get accentComboId => _accentComboId;
  AccentColors? get customAccent => _customAccent;

  /// Resolves the active accent for one brightness: the user's custom pair
  /// (used as-is for both brightnesses — no auto-adjustment) if selected,
  /// otherwise the chosen preset's light/dark-tuned pair.
  AccentColors activeAccent(Brightness brightness) {
    if (_accentComboId == kCustomAccentId && _customAccent != null) {
      return _customAccent!;
    }
    final combo = findAccentCombo(_accentComboId) ?? kAccentPresets.first;
    return brightness == Brightness.dark ? combo.dark : combo.light;
  }

  ThemeData get lightTheme =>
      Premium.themeData(brightness: Brightness.light, accentColors: activeAccent(Brightness.light));
  ThemeData get darkTheme =>
      Premium.themeData(brightness: Brightness.dark, accentColors: activeAccent(Brightness.dark));

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
    _accentComboId = prefs.getString(_prefsKeyAccentCombo) ?? kAccentPresets.first.id;
    final customArgb = prefs.getInt(_prefsKeyCustomAccent);
    final customArgb2 = prefs.getInt(_prefsKeyCustomAccent2);
    if (customArgb != null && customArgb2 != null) {
      _customAccent = AccentColors(Color(customArgb), Color(customArgb2));
    }
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

  Future<void> setAccentCombo(String id) async {
    if (_accentComboId == id) return;
    _accentComboId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyAccentCombo, id);
  }

  Future<void> setCustomAccent(Color accent, Color accent2) async {
    _customAccent = AccentColors(accent, accent2);
    _accentComboId = kCustomAccentId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyAccentCombo, kCustomAccentId);
    await prefs.setInt(_prefsKeyCustomAccent, accent.toARGB32());
    await prefs.setInt(_prefsKeyCustomAccent2, accent2.toARGB32());
  }
}
