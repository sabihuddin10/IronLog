import 'package:flutter/material.dart';
import 'theme_vars.dart';

/// Bridges a [ThemeVars] object into Flutter's [ThemeExtension] system so
/// `Theme.of(context).extension<AppColorTokens>()` (or the `context.colors`
/// shortcut below) works from any widget. The actual named values live on
/// the [ThemeVars] classes in theme_vars.dart — this class only carries them
/// and knows how to animate between two themes ([lerp]).
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color buttonColor;
  final Color buttonText;
  final Color cardBackground;
  final Color border;
  final Color containerColor;
  final Color onContainer;
  final Color success;
  final Color danger;
  final Color warning;

  const AppColorTokens({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.buttonColor,
    required this.buttonText,
    required this.cardBackground,
    required this.border,
    required this.containerColor,
    required this.onContainer,
    required this.success,
    required this.danger,
    required this.warning,
  });

  factory AppColorTokens.fromVars(ThemeVars vars) {
    return AppColorTokens(
      background: vars.background,
      surface: vars.surface,
      textPrimary: vars.textPrimary,
      textSecondary: vars.textSecondary,
      buttonColor: vars.buttonColor,
      buttonText: vars.buttonText,
      cardBackground: vars.cardBackground,
      border: vars.border,
      containerColor: vars.containerColor,
      onContainer: vars.onContainer,
      success: vars.success,
      danger: vars.danger,
      warning: vars.warning,
    );
  }

  @override
  AppColorTokens copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? buttonColor,
    Color? buttonText,
    Color? cardBackground,
    Color? border,
    Color? containerColor,
    Color? onContainer,
    Color? success,
    Color? danger,
    Color? warning,
  }) {
    return AppColorTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonText: buttonText ?? this.buttonText,
      cardBackground: cardBackground ?? this.cardBackground,
      border: border ?? this.border,
      containerColor: containerColor ?? this.containerColor,
      onContainer: onContainer ?? this.onContainer,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      buttonColor: Color.lerp(buttonColor, other.buttonColor, t)!,
      buttonText: Color.lerp(buttonText, other.buttonText, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      border: Color.lerp(border, other.border, t)!,
      containerColor: Color.lerp(containerColor, other.containerColor, t)!,
      onContainer: Color.lerp(onContainer, other.onContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  /// Named color tokens for the active theme, e.g. `context.colors.textPrimary`.
  AppColorTokens get colors => Theme.of(this).extension<AppColorTokens>()!;
}
