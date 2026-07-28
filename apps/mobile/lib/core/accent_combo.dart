import 'package:flutter/material.dart';

/// A single gradient's two colors — either one half of an [AccentCombo]
/// (light or dark) or a fully custom user-picked pair.
class AccentColors {
  final Color accent;
  final Color accent2;

  const AccentColors(this.accent, this.accent2);
}

/// One selectable built-in accent — a light-tuned and a dark-tuned color
/// pair, since a neon pair that reads well on a near-black background can
/// wash out (or vice versa) on white. See [kAccentPresets] for the actual
/// set shown in the theme picker.
class AccentCombo {
  final String id;
  final String label;
  final AccentColors light;
  final AccentColors dark;

  const AccentCombo({
    required this.id,
    required this.label,
    required this.light,
    required this.dark,
  });
}

/// Sentinel id [ThemeController] uses for a user-picked custom pair rather
/// than one of these presets.
const kCustomAccentId = 'custom';

/// Built-in accent combos shown in the theme picker, `mintSky` first as the
/// default (matches the app's original fixed accent).
const kAccentPresets = <AccentCombo>[
  AccentCombo(
    id: 'mintSky',
    label: 'Mint & Sky',
    dark: AccentColors(Color(0xFF4FFFAE), Color(0xFF39D9FF)),
    light: AccentColors(Color(0xFF1B8F5A), Color(0xFF25B8DB)),
  ),
  AccentCombo(
    id: 'bluePurple',
    label: 'Blue & Purple',
    dark: AccentColors(Color(0xFF5B8DEF), Color(0xFFA78BFA)),
    light: AccentColors(Color(0xFF2F6FED), Color(0xFF7C4DFF)),
  ),
  AccentCombo(
    id: 'pinkPurple',
    label: 'Pink & Purple',
    dark: AccentColors(Color(0xFFFF6FB5), Color(0xFFB07CFF)),
    light: AccentColors(Color(0xFFDB2E80), Color(0xFF7C4DFF)),
  ),
  AccentCombo(
    id: 'autumn',
    label: 'Autumn',
    dark: AccentColors(Color(0xFF9BE05B), Color(0xFFFFC145)),
    light: AccentColors(Color(0xFF4C8C2B), Color(0xFFD98F00)),
  ),
  AccentCombo(
    id: 'sunset',
    label: 'Sunset',
    dark: AccentColors(Color(0xFFFF8A66), Color(0xFFFF6FA5)),
    light: AccentColors(Color(0xFFE8532E), Color(0xFFD6336C)),
  ),
  AccentCombo(
    id: 'teal',
    label: 'Teal & Cyan',
    dark: AccentColors(Color(0xFF2DD4BF), Color(0xFF39D9FF)),
    light: AccentColors(Color(0xFF0F9488), Color(0xFF0EA5B7)),
  ),
];

AccentCombo? findAccentCombo(String id) {
  for (final combo in kAccentPresets) {
    if (combo.id == id) return combo;
  }
  return null;
}
