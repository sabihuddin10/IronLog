import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'auth/auth_repository.dart';
import 'auth/auth_state.dart';
import 'auth/demo_auth_repository.dart';
import 'auth/firebase_auth_repository.dart';
import 'core/theme_controller.dart';
import 'data/body_profile_store.dart';
import 'data/mock_store.dart';
import 'data/workouts_store.dart';
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
  // Backs every repository's local (non-cloud) storage — see
  // `data/local_collection_store.dart`. Must be ready before any
  // repository's `list()`/`add()`/etc. can be called.
  await Hive.initFlutter();
  await MockStore.instance.loadExercises();

  // Premium.heading()/Premium.body() (core/premium_theme.dart) call
  // GoogleFonts.spaceGrotesk()/GoogleFonts.inter() directly, which fetch
  // the font file over the network the first time each weight is used and
  // render with the platform fallback font until it lands. Without this,
  // whichever screen happens to be first to request a given weight shows a
  // brief fallback-font flash while every other screen (which reused an
  // already-cached weight) doesn't — inconsistent fonts between screens on
  // a cold start. Awaiting every weight actually used before `runApp` means
  // every screen's first frame already has the real font.
  await GoogleFonts.pendingFonts([
    GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
    GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
    GoogleFonts.inter(fontWeight: FontWeight.w400),
    GoogleFonts.inter(fontWeight: FontWeight.w500),
    GoogleFonts.inter(fontWeight: FontWeight.w600),
    GoogleFonts.inter(fontWeight: FontWeight.w700),
  ]);

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
        // Drives `_WalkTaskHandler.onRepeatEvent`, which now owns the walk
        // tracker's live stats/notification ticker (moved off the main
        // isolate's Timer — see `walk_foreground_task.dart`). The workout
        // session's task handler (`workout_foreground_task.dart`) shares
        // this same global config but its `onRepeatEvent` is a no-op, so
        // the extra tick is harmless there.
        eventAction: ForegroundTaskEventAction.repeat(1000),
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
  final workoutsStore = WorkoutsStore(WorkoutRepository());

  String? previousUid = authState.user?.uid;
  void syncProfileToAuth() {
    final uid = authState.user?.uid;
    // Switching accounts without an app restart shouldn't leave the
    // previous user's workouts sitting in the shared store — reset it so
    // the next screen that reads it refetches for whoever's signed in now.
    if (uid != previousUid) workoutsStore.reset();
    previousUid = uid;
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
        ChangeNotifierProvider.value(value: workoutsStore),
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
