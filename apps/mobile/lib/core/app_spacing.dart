/// Design-reference spacing scale. Compose with `context.scale(...)`
/// (see `core/responsive.dart`) for device-width-adaptive spacing/icon
/// sizes, e.g. `context.scale(AppSpacing.lg)`.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Design-reference corner-radius scale. Unlike [AppSpacing], these values
/// are shape/identity properties and are used directly, never wrapped in
/// `context.scale(...)`.
class AppRadius {
  AppRadius._();

  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}
