import 'package:flutter/widgets.dart';

/// Lightweight width-based scaling so spacing/icon/font sizes adapt across
/// phone sizes (small Android phones through large iPhones/tablets) without
/// pulling in a full responsive-layout package.
extension Responsive on BuildContext {
  /// Scale factor relative to a 390px-wide reference device (iPhone 13/14),
  /// clamped so very small or very large screens don't distort the UI.
  double get widthScale => (MediaQuery.sizeOf(this).width / 390).clamp(0.82, 1.35);

  /// Scales a design-reference pixel value (spacing, icon size, custom font
  /// size) by [widthScale].
  double scale(double base) => base * widthScale;

  bool get isCompactWidth => MediaQuery.sizeOf(this).width < 360;
  bool get isTablet => MediaQuery.sizeOf(this).width >= 600;

  /// Material 3 window-size-class breakpoints for the nav shell
  /// (`root_screen.dart`): phone (<600, bottom bar) → medium (600–839,
  /// collapsed rail) → expanded (≥840, extended rail acting as a permanent
  /// desktop sidebar). Distinct from [isTablet], which only gates
  /// spacing/content decisions inside individual screens.
  bool get isMediumWindow => MediaQuery.sizeOf(this).width >= 600;
  bool get isExpandedWindow => MediaQuery.sizeOf(this).width >= 840;
}
