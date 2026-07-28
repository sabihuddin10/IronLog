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

  /// The two-tone accent gradient's colors — every button, icon highlight,
  /// link, and selected state draws from these two (see [AccentFx] below for
  /// the gradient/glow/dim variants derived from them).
  final Color accent;
  final Color accent2;

  /// Third surface elevation tier (above [surface]/[cardBackground]), used by
  /// the most-elevated cards (e.g. the weekly-goal ring card).
  final Color surfaceHigh;

  /// Stronger-contrast border than [border], for emphasized dividers/outlines.
  final Color borderStrong;

  /// Third text tier, dimmer than [textSecondary] — placeholders, disabled
  /// labels, faint captions.
  final Color textFaint;

  /// Background for the outermost app shell, one shade off [background]
  /// (e.g. behind a scrollable page that itself uses [background]).
  final Color pageBackground;

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
    required this.accent,
    required this.accent2,
    required this.surfaceHigh,
    required this.borderStrong,
    required this.textFaint,
    required this.pageBackground,
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
      accent: vars.buttonColor,
      accent2: vars.buttonColor,
      surfaceHigh: vars.cardBackground,
      borderStrong: vars.border,
      textFaint: vars.textSecondary,
      pageBackground: vars.background,
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
    Color? accent,
    Color? accent2,
    Color? surfaceHigh,
    Color? borderStrong,
    Color? textFaint,
    Color? pageBackground,
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
      accent: accent ?? this.accent,
      accent2: accent2 ?? this.accent2,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      borderStrong: borderStrong ?? this.borderStrong,
      textFaint: textFaint ?? this.textFaint,
      pageBackground: pageBackground ?? this.pageBackground,
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
      accent: Color.lerp(accent, other.accent, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  /// Named color tokens for the active theme, e.g. `context.colors.textPrimary`.
  AppColorTokens get colors => Theme.of(this).extension<AppColorTokens>()!;
}

/// Values derived from [AppColorTokens.accent]/[AppColorTokens.accent2]
/// rather than stored directly — computed on demand so there's a single
/// source of truth for the two accent colors themselves.
extension AccentFx on AppColorTokens {
  /// Readable text/icon color for content placed on a solid [accent] fill
  /// (e.g. a filled button's label) — works for any accent, including
  /// user-picked custom colors.
  Color get onAccent =>
      ThemeData.estimateBrightnessForColor(accent) == Brightness.dark ? Colors.white : Colors.black;

  LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent, accent2],
      );

  Color get accentDim => accent.withValues(alpha: 0.13);
  Color get accentGlow => accent.withValues(alpha: 0.38);

  List<BoxShadow> accentGlowShadow({double blur = 16, double spread = -4}) => [
        BoxShadow(color: accentGlow, blurRadius: blur, spreadRadius: spread, offset: const Offset(0, 6)),
      ];

  LinearGradient get cardGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cardBackground, surface],
      );

  LinearGradient get elevatedGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [surfaceHigh, cardBackground],
      );
}
