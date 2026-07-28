import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth/auth_state.dart';
import 'core/theme_controller.dart';
import 'screens/auth/login_screen.dart';
import 'screens/root_screen.dart';

/// Consistent bouncy overscroll on every platform (rather than Android's
/// default clamp-and-glow) plus mouse/trackpad drag-to-scroll, since the
/// desktop-width sidebar layout in [RootScreen] is otherwise touch-only.
class _SmoothScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}

class IronLogApp extends StatelessWidget {
  const IronLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return MaterialApp(
      title: 'IronLog',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _SmoothScrollBehavior(),
      theme: themeController.lightTheme,
      darkTheme: themeController.darkTheme,
      themeMode: themeController.themeMode,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthState>().status;

    return switch (status) {
      AuthStatus.unknown => const Scaffold(body: Center(child: CircularProgressIndicator())),
      AuthStatus.signedOut => const LoginScreen(),
      AuthStatus.signedIn => const RootScreen(),
    };
  }
}
