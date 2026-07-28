import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ironlog/app.dart';
import 'package:ironlog/auth/auth_state.dart';
import 'package:ironlog/auth/demo_auth_repository.dart';
import 'package:ironlog/core/theme_controller.dart';

void main() {
  testWidgets('shows the login screen when signed out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthState(DemoAuthRepository())),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: const IronLogApp(),
      ),
    );

    expect(find.text('IronLog'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
