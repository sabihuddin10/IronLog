# Ironlog Mobile — Design System

Reference doc for how theming, color, and components work in the Flutter app
(`apps/mobile`). Read this before writing or reviewing any UI code so new
screens/widgets stay visually consistent with the rest of the app.

## Architecture

Five layers, each with one job:

```
ThemeVars              (core/theme_vars.dart)
  → abstract named color roles (the CSS-custom-property layer). No
    concrete themes live here anymore — see palettes.dart.

palettes.dart           (core/palettes.dart)
  → concrete ThemeVars implementations. `PaletteId` enum (blue, emerald,
    sunsetCoral, violet) × Brightness (light/dark) = 8 concrete classes,
    resolved via `resolveThemeVars(id, brightness)`. `_LightBase`/
    `_DarkBase` hold the neutrals shared by every palette in that
    brightness; each concrete class only overrides the 4 accent fields
    (buttonColor/buttonText/containerColor/onContainer).

AppColorTokens          (core/app_colors.dart)
  → ThemeExtension wrapper so any widget can read those roles via
    `context.colors.xxx`

AppTypography           (core/app_typography.dart)
  → builds the app's TextTheme (Manrope via google_fonts, Material's
    default size/weight scale, colored per ThemeVars).

AppTheme.build(vars)    (core/app_theme.dart)
  → maps ThemeVars + AppTypography onto Flutter's ThemeData / ColorScheme
    so built-in Material widgets (Button, Card, Chip, NavigationBar,
    Dialog, ...) pick up the same colors and fonts automatically

ThemeController          (core/theme_controller.dart)
  → the runtime theme provider. A ChangeNotifier holding the active
    ThemeMode + PaletteId, exposing `lightTheme`/`darkTheme` (each built
    via AppTheme.build), persisted via shared_preferences. Registered as
    a singleton in `main.dart` (`ChangeNotifierProvider.value`, constructed
    once — never `create:`, so nothing can accidentally reconstruct it
    and re-trigger its async prefs load). `app.dart`'s `MaterialApp` reads
    `theme`/`darkTheme`/`themeMode` from it via `context.watch`. Users
    switch mode/palette from Profile → Appearance
    (`screens/profile/theme_settings_screen.dart`).
```

Runtime multi-theme switching was built once before, then deliberately
removed after a hard-to-diagnose rebuild issue (see prior revision of this
doc). It has now been re-added; `ThemeController` calls out its specific
defensive choices (singleton registration, `notifyListeners()` only after
an `await`) in its doc comment — read those before changing how it's wired.

**Key rule (see the comment in `app_theme.dart`):** every Material color
*role* is pinned explicitly to a `ThemeVars` field. Material 3's
`ColorScheme.fromSeed` auto-generates tonal palettes for
primary/secondary/tertiary/container shades — that algorithm is **not**
used for anything visible. The seed call only satisfies a required
argument; every role Material actually renders with is overridden via
`.copyWith(...)` right after. This means there is exactly **one accent
color** (`buttonColor`) across the whole app — no auto-derived secondary or
tertiary hues. Never introduce a second accent color by pulling from
`Theme.of(context).colorScheme.secondary` etc. expecting it to differ from
primary — by design it doesn't.

## How to read colors in a widget

```dart
// Preferred: named app tokens
context.colors.textPrimary
context.colors.buttonColor
context.colors.cardBackground

// Also fine: Flutter's ColorScheme (mapped 1:1 to the same tokens, see table below)
Theme.of(context).colorScheme.primary   // == context.colors.buttonColor
Theme.of(context).colorScheme.surface   // == context.colors.surface
```

Never hardcode a `Color(0xFF...)` in a screen/widget — always go through
`context.colors` (or a themed Material widget that already picks it up
automatically, e.g. `FilledButton`, `Card`, `Chip`).

## Color roles

| Role | Purpose |
|---|---|
| `background` | Scaffold/page background |
| `surface` | Dialogs, bottom sheets, popup menus |
| `cardBackground` | Cards, nav bar, chip background |
| `border` | Dividers, outlined borders, chip/outline button borders |
| `textPrimary` | Headings, body text, icons |
| `textSecondary` | Captions, unselected nav labels, hints |
| `buttonColor` | **The one accent color** — buttons, FAB, links, selected states, splash/highlight tint, focus outline, exercise/workout icon badges (tinted at 15% alpha) |
| `buttonText` | Text/icon color drawn on top of `buttonColor` |
| `containerColor` | Soft tinted background for the selected nav indicator |
| `onContainer` | Icon/text color drawn on top of `containerColor` |
| `success` / `danger` / `warning` | Status colors (danger doubles as Material's `error`) |

### Palettes

Shared neutrals (identical across all 4 palettes, only differ by brightness):

| Role | Light | Dark |
|---|---|---|
| background / surface | `#FFFFFF` | `#10131A` |
| cardBackground | `#F4F6FA` | `#1A1E27` |
| border | `#E1E6EF` | `#2B303C` |
| textPrimary | `#12151C` | `#F2F4F8` |
| textSecondary | `#5B6472` | `#9AA3B2` |
| success | `#1E8E3E` | `#34C759` |
| danger | `#D93025` | `#FF5B54` |
| warning | `#B26A00` | `#FFB020` |

Per-palette accent fields (the only fields that differ between palettes):

| Palette | buttonColor (L/D) | buttonText (L/D) | containerColor (L/D) | onContainer (L/D) |
|---|---|---|---|---|
| Blue (default) | `#2F6FED` / `#5B8DEF` | `#FFFFFF` / `#0B1220` | `#DDE8FD` / `#1E3A78` | `#1D4ED8` / `#BFD4FB` |
| Emerald | `#12B76A` / `#22C980` | `#FFFFFF` / `#04150C` | `#D3F3E0` / `#12432C` | `#067647` / `#8CEFBE` |
| Sunset Coral | `#FF6B4A` / `#FF8A66` | `#FFFFFF` / `#250D06` | `#FFE0D6` / `#5A2A1D` | `#B23A1E` / `#FFC3AE` |
| Violet | `#7C4DFF` / `#A78BFA` | `#FFFFFF` / `#1B1130` | `#E7DEFF` / `#3B2A66` | `#5B21B6` / `#DED0FF` |

Dark-mode accents are brighter/lighter tints of the same hue (better
legibility on a near-black background) paired with near-black `buttonText`
rather than white, since white-on-mid-brightness-accent reads poorly.

To add a NEW palette: add a `PaletteId` case in `core/palettes.dart`, a
light+dark concrete `ThemeVars` pair extending `_LightBase`/`_DarkBase`
(only override the 4 accent fields), wire it into `resolveThemeVars()` and
`PaletteIdX.label`/`.swatch`, and it's automatically available in the
Appearance picker — no other file needs to change.

## Buttons

All button variants are themed globally in `AppTheme.build` — never set
per-button colors inline unless intentionally deviating from the design
system.

| Widget | Background | Foreground | Border |
|---|---|---|---|
| `FilledButton` | `buttonColor` | `buttonText` | — |
| `ElevatedButton` | `buttonColor` | `buttonText` | — |
| `OutlinedButton` | transparent | `buttonColor` | `border` |
| `TextButton` | transparent | `buttonColor` | — |
| `IconButton` | transparent | `textPrimary` | — |
| `FloatingActionButton` | `buttonColor` | `buttonText` | — |

### Exercise/workout icon badges

The small circular icon badges on workout/exercise cards (`workouts_screen.dart`,
`log_workout_screen.dart`'s `_ExerciseCard`) use solid `scheme.primary` for the
background and `scheme.onPrimary` for the icon — the same colors as the FAB,
just at avatar size. **Not** `containerColor`/`onContainer` (hand-picked per
theme independently of `buttonColor`; on `GreenDarkTheme` that pairing read as
a muddy, disconnected-from-the-accent dark-olive badge), and **not** a low-alpha
tint of `buttonColor` either (tried first — at 15% alpha over a dark card
background it read as a barely-visible dark smudge instead of a clear accent
color, unlike the Tools grid's fully opaque icon chips). Full-opacity
`scheme.primary`/`scheme.onPrimary` is the pattern to reach for on any new
badge that should unmistakably read as "the accent color" regardless of card
background or theme.

`FilledButton` and `ElevatedButton` are visually identical in this app
(both map to the same colors) — prefer `FilledButton` for primary actions
per Material 3 convention. Use `OutlinedButton`/`TextButton` for secondary
actions, `IconButton` for icon-only taps. Ripple/splash uses `buttonColor`
at 12% (splash) / 8% (highlight) opacity app-wide.

## Other themed components

- **Cards**: flat (`elevation: 0`), `cardBackground` fill, `16px` corner radius.
- **AppBar**: transparent-to-background, `elevation: 0`, `textPrimary` foreground.
- **NavigationBar**: `cardBackground` fill; selected item icon/indicator uses
  `containerColor`/`onContainer`, selected label `textPrimary`, unselected
  label/icon `textSecondary`, label size `12`.
- **Chips**: `cardBackground` fill, `containerColor` when selected, `border`
  outline, label in `textPrimary` (`onContainer` for secondary label).
- **Inputs**: `OutlineInputBorder`, focus color and floating label in
  `buttonColor`.
- **Dialog / BottomSheet / PopupMenu**: `surface` background.
- **ProgressIndicator**: `buttonColor`.
- **Divider**: `border`.

## Layout conventions

- Card corner radius: `16px` (theme default). One-off rounded containers in
  screens (buttons, chips, tiles) commonly use `12px`; check the nearest
  existing widget in the same screen before picking a new radius.
- `core/app_spacing.dart` defines `AppSpacing` (xxs=4 … xxxl=32) and
  `AppRadius` (xs=6 … xl=20) — design-reference tokens. Spacing/icon sizes
  compose with the device-width scale below (`context.scale(AppSpacing.lg)`);
  `BorderRadius` values are used directly, never wrapped in `context.scale`
  (shape/identity, not a device-adaptive value).
- Spacing/icon/font sizes additionally scale per-device via
  `core/responsive.dart`:
  ```dart
  context.scale(16)      // scales a design-reference px value by widthScale
  context.isCompactWidth // width < 360
  context.isTablet       // width >= 600
  ```
  `widthScale` is width/390 (iPhone 13/14 reference), clamped to
  `[0.82, 1.35]`.
- Typography: `AppTypography.textTheme(vars)` (`core/app_typography.dart`)
  builds a Manrope-based `TextTheme` (via `google_fonts`), reusing
  Material's default size/weight scale. Always pull text style from
  `Theme.of(context).textTheme.<role>` (optionally `.copyWith(...)` for a
  real per-widget color/weight deviation) — never write a raw
  `TextStyle(fontSize: N, ...)` literal.

## Do / Don't

- Do: use `context.colors.*` or themed Material widgets for every color.
- Do: use `buttonColor` as the only accent — don't introduce a second brand
  color anywhere (including via `colorScheme.secondary`/`tertiary`, which
  are intentionally aliased to the same value as primary).
- Do: pair `containerColor` with `onContainer` (never mix with
  `textPrimary`/`textSecondary`) — same for `buttonColor`/`buttonText`.
- Don't: hardcode hex colors in screens/widgets.
- Don't: rely on Material's auto-generated tonal palette (`fromSeed`) for
  anything visible — it's deliberately overridden everywhere.
- Don't: write a raw `TextStyle(fontSize: N, ...)` literal — use
  `Theme.of(context).textTheme.<role>` (+ `.copyWith` for a real deviation).
- Don't: register `ThemeController` with `ChangeNotifierProvider(create: ...)`
  — it must stay a singleton via `.value` (see Architecture above).
