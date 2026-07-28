import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'auth/auth_repository.dart';
import 'auth/auth_state.dart';
import 'auth/demo_auth_repository.dart';
import 'auth/firebase_auth_repository.dart';
import 'core/theme_controller.dart';
import 'data/body_profile_store.dart';
import 'data/mock_store.dart';
import 'firebase_options.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/exercise_repository.dart';
import 'repositories/weight_goal_repository.dart';
import 'repositories/weight_repository.dart';
import 'repositories/walk_session_repository.dart';
import 'repositories/workout_repository.dart';
import 'repositories/workout_template_repository.dart';
import 'screens/workouts/active_workout_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MockStore.instance.loadExercises();

  // flutter_foreground_task is Android/iOS-only (no web platform
  // implementation) — IsolateNameServer coordination and the plugin's own
  // init aren't meaningful on web and have been observed to throw there.
  if (!kIsWeb) {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'walk_tracking',
        channelName: 'Walk/Run Tracking',
        channelDescription:
            'Shows live stats and controls while a walk/run session is active.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  AuthRepository authRepository;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    authRepository = FirebaseAuthRepository();
  } catch (e) {
    // No Firebase project configured yet for this platform. Falls back to an
    // in-memory auth flow so the UI stays fully usable; run
    // `flutterfire configure` and remove this fallback once real
    // credentials exist. This fallback never persists login across app
    // restarts, so surface it loudly rather than failing silently.
    debugPrint(
      'Firebase init failed, using non-persistent DemoAuthRepository: $e',
    );
    authRepository = DemoAuthRepository();
  }

  final authState = AuthState(authRepository);
  final themeController = ThemeController();
  final bodyProfileStore = BodyProfileStore();

  void syncProfileToAuth() {
    final uid = authState.user?.uid;
    if (uid != null) {
      bodyProfileStore.loadForUser(uid);
    } else {
      bodyProfileStore.signOut();
    }
  }

  authState.addListener(syncProfileToAuth);
  syncProfileToAuth();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authState),
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider.value(value: bodyProfileStore),
        Provider(create: (_) => WorkoutRepository()),
        Provider(create: (_) => WorkoutTemplateRepository()),
        Provider(create: (_) => WalkSessionRepository()),
        Provider(create: (_) => ExerciseRepository()),
        Provider(create: (_) => WeightRepository()),
        Provider(create: (_) => WeightGoalRepository()),
        ChangeNotifierProvider(create: (_) => ActiveWorkoutSession()),
        Provider(create: (_) => DashboardRepository()),
      ],
      child: const IronLogApp(),
    ),
  );
}
