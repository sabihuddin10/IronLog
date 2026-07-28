import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'theme_vars.dart';

class AppTheme {
  AppTheme._();

  static ThemeData build(ThemeVars vars) {
    final tokens = AppColorTokens.fromVars(vars);
    final textTheme = AppTypography.textTheme(vars);

    // Material widgets (buttons, chips, FAB, nav bar, dialogs, ...) read
    // from ColorScheme, and Material's own tonal-palette algorithm invents
    // its own container/secondary/tertiary shades from the seed — that
    // mismatch is exactly what caused inconsistent colors before. Pin every
    // role Material renders with to our named vars so nothing falls back to
    // an auto-generated shade; the seed below only satisfies fromSeed's
    // required argument, every rendered role is overridden after it.
    final scheme = ColorScheme.fromSeed(
      seedColor: vars.buttonColor,
      brightness: vars.brightness,
    ).copyWith(
      surface: vars.surface,
      onSurface: vars.textPrimary,
      onSurfaceVariant: vars.textSecondary,
      primary: vars.buttonColor,
      onPrimary: vars.buttonText,
      secondary: vars.buttonColor,
      onSecondary: vars.buttonText,
      tertiary: vars.buttonColor,
      onTertiary: vars.buttonText,
      primaryContainer: vars.containerColor,
      onPrimaryContainer: vars.onContainer,
      secondaryContainer: vars.containerColor,
      onSecondaryContainer: vars.onContainer,
      tertiaryContainer: vars.containerColor,
      onTertiaryContainer: vars.onContainer,
      error: vars.danger,
      onError: vars.buttonText,
      outline: vars.textSecondary,
      outlineVariant: vars.border,
      surfaceContainerLowest: vars.background,
      surfaceContainerLow: vars.cardBackground,
      surfaceContainer: vars.cardBackground,
      surfaceContainerHigh: vars.cardBackground,
      surfaceContainerHighest: vars.cardBackground,
      inverseSurface: vars.textPrimary,
      onInverseSurface: vars.background,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: vars.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      dividerColor: tokens.border,
      splashColor: tokens.buttonColor.withValues(alpha: 0.12),
      highlightColor: tokens.buttonColor.withValues(alpha: 0.08),
      extensions: [tokens],
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
      ),

      iconTheme: IconThemeData(color: tokens.textPrimary),

      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        focusColor: tokens.buttonColor,
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: tokens.buttonColor),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.cardBackground,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.cardBackground,
        indicatorColor: tokens.containerColor,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? tokens.onContainer : tokens.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? tokens.textPrimary : tokens.textSecondary,
          ),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.cardBackground,
        indicatorColor: tokens.containerColor,
        selectedIconTheme: IconThemeData(color: tokens.onContainer),
        unselectedIconTheme: IconThemeData(color: tokens.textSecondary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: tokens.textSecondary),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.buttonColor,
          foregroundColor: tokens.buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.buttonColor,
          foregroundColor: tokens.buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.buttonColor,
          side: BorderSide(color: tokens.border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: tokens.buttonColor),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: tokens.textPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.buttonColor,
        foregroundColor: tokens.buttonText,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: tokens.cardBackground,
        selectedColor: tokens.containerColor,
        labelStyle: textTheme.labelLarge?.copyWith(color: tokens.textPrimary),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: tokens.onContainer),
        side: BorderSide(color: tokens.border),
      ),

      dialogTheme: DialogThemeData(backgroundColor: tokens.surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: tokens.surface),
      popupMenuTheme: PopupMenuThemeData(color: tokens.surface),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: tokens.buttonColor),
    );
  }
}
