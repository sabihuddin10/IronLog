import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/workouts_store.dart';
import '../../models/workout.dart' as domain;
import '../../models/workout_template.dart';
import '../../utils/health_formulas.dart';
import 'active_workout_models.dart';
import 'workout_foreground_task.dart';

/// Owns the state of an in-progress workout at the app level (via Provider,
/// registered once in `main.dart`) rather than inside `LogWorkoutScreen`'s
/// `State` — so leaving that screen (back button, switching tabs) doesn't
/// tear down the timer, sets, or foreground notification. The workout only
/// actually ends via [finish] or [discard]; `LogWorkoutScreen` just
/// re-attaches to whatever's already running when reopened.
class ActiveWorkoutSession extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController(
    text: 'Push Day',
  );
  final TextEditingController noteController = TextEditingController();
  final List<ActiveExercise> exercises = [];
  final Stopwatch stopwatch = Stopwatch();

  DateTime? _startedAt;
  Timer? _ticker;
  WorkoutsStore? _store;
  List<domain.Workout> history = [];
  bool isSaving = false;

  /// True for a real-time tracked workout (the stopwatch is ground truth
  /// for rest time); false when backfilling a workout that already
  /// happened, where there's no real elapsed time to trust and rest time
  /// has to be estimated instead — see [HealthFormulas.workoutKcal].
  bool isLiveSession = true;

  bool get isActive => _startedAt != null;

  /// Starts a new session, or does nothing if one is already running (so
  /// re-opening `LogWorkoutScreen` on an active session just resumes it).
  /// [template], when given, pre-populates [exercises] with that preset's
  /// boilerplate (exercise list + target sets, pre-filled from what was
  /// typed while building it) instead of the default starter pair — see
  /// [WorkoutTemplate].
  Future<void> start(WorkoutsStore store, {bool isLiveSession = true, WorkoutTemplate? template}) async {
    if (isActive) return;
    _startedAt = DateTime.now();
    _store = store;
    this.isLiveSession = isLiveSession;

    List<domain.Workout> loadedHistory = [];
    try {
      await store.ensureLoaded();
      loadedHistory = store.workouts;
    } catch (_) {
      // Previous-performance prefill is a nice-to-have; an empty history
      // just means the starter exercises below show '-' instead.
    }
    if (!isActive) return; // discarded while history was loading

    history = loadedHistory;
    noteController.clear();
    if (template != null) {
      nameController.text = template.name;
      exercises.addAll([
        for (final te in template.exercises) ActiveExercise.fromTemplate(te, history: history),
      ]);
    } else {
      nameController.text = 'Push Day';
      exercises.addAll([
        ActiveExercise.fromLibrary(
          // Must match the real library entry in assets/data/exercises.json
          // exactly (id AND name) — the muscle-distribution chart resolves
          // a logged set's category by looking up this id in the library,
          // and "previous" prefill matches by name; a mismatched starter
          // silently drops out of both instead of erroring.
          exerciseId: 'ex-barbell-bench-press',
          name: 'Barbell Bench Press',
          tip: 'Increase the weight next time.',
          history: history,
        ),
        ActiveExercise.fromLibrary(
          exerciseId: 'ex-arnold-press',
          name: 'Arnold Press (Dumbbell)',
          history: history,
        ),
      ]);
    }
    // A past/backfilled workout has no real time to track — no live clock,
    // no per-second ticker, no "in progress" foreground notification.
    // [trackedDuration] falls back to [syntheticElapsedDuration] instead,
    // which only moves when sets are actually checked off.
    if (isLiveSession) {
      stopwatch
        ..reset()
        ..start();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        notifyListeners();
        if (!kIsWeb) {
          FlutterForegroundTask.updateService(notificationText: notificationText);
        }
      });
      FlutterForegroundTask.addTaskDataCallback(_handleTaskData);
      _startForegroundNotification();
    }
    notifyListeners();
  }

  void addExercise(ActiveExercise exercise) {
    exercises.add(exercise);
    notifyListeners();
  }

  void removeExercise(ActiveExercise exercise) {
    for (final s in exercise.sets) {
      s.dispose();
    }
    exercises.remove(exercise);
    notifyListeners();
  }

  /// Passthrough for set-level edits (weight/reps/completed/type changes)
  /// that don't change the exercise list itself, so the UI rebuilds.
  void refresh() => notifyListeners();

  /// Backfill/preview estimate of total workout time — mirrors what
  /// [stopwatch] would have measured live. Used in place of [stopwatch]
  /// whenever [isLiveSession] is false, since there's no real elapsed time
  /// to trust for a workout entered after the fact. See
  /// [syntheticElapsedDurationOf] for the formula, shared with the preset
  /// builder's time estimate.
  Duration get syntheticElapsedDuration => syntheticElapsedDurationOf(exercises);

  /// The duration this session's UI/calorie math should treat as "how long
  /// has this workout taken" — real stopwatch time when live, the
  /// accumulated [syntheticElapsedDuration] otherwise.
  Duration get trackedDuration => isLiveSession ? stopwatch.elapsed : syntheticElapsedDuration;

  String get durationLabel {
    final d = trackedDuration;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${d.inSeconds % 60}s';
  }

  double get volume {
    var total = 0.0;
    for (final e in exercises) {
      for (final s in e.sets) {
        if (!s.completed) continue;
        final w = double.tryParse(s.weightController.text) ?? 0;
        final r = int.tryParse(s.repsController.text) ?? 0;
        total += w * r;
      }
    }
    return total;
  }

  int get completedSetCount => exercises.fold(
    0,
    (sum, e) => sum + e.sets.where((s) => s.completed).length,
  );

  String get notificationText =>
      '$durationLabel · $completedSetCount sets · ${volume.toStringAsFixed(0)} kg volume';

  Future<void> _startForegroundNotification() async {
    // Android-only feature (no web platform implementation); the in-app
    // timer still works fine on web, just without the notification.
    if (kIsWeb) return;

    var permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      permission = await FlutterForegroundTask.requestNotificationPermission();
    }
    if (permission != NotificationPermission.granted) return;

    // Android requires ACTIVITY_RECOGNITION (or BODY_SENSORS /
    // HIGH_SAMPLING_RATE_SENSORS) to start a "health"-typed foreground
    // service — without it, startForeground() throws a SecurityException
    // and the service is silently killed with no notification ever shown.
    var activityRecognition = await Permission.activityRecognition.status;
    if (!activityRecognition.isGranted) {
      activityRecognition = await Permission.activityRecognition.request();
    }
    if (!activityRecognition.isGranted) return;

    await FlutterForegroundTask.startService(
      serviceTypes: const [ForegroundServiceTypes.health],
      notificationTitle: 'Workout in progress',
      notificationText: notificationText,
      notificationButtons: const [
        NotificationButton(
          id: WorkoutNotificationActions.finish,
          text: 'Finish',
        ),
      ],
      callback: startWorkoutForegroundTask,
    );
  }

  void _handleTaskData(Object data) {
    if (data == WorkoutNotificationActions.finish) finish();
  }

  /// Saves the workout and ends the session. Returns `false` (without
  /// ending the session) if there are no completed sets to save, so the
  /// caller can show a message and let the user keep going. [restKcal] is
  /// the already-resolved resting-calorie contribution (live stopwatch or
  /// synthetic backfill estimate — see [HealthFormulas.workoutKcal]),
  /// computed by the caller since that's where [BodyProfileStore] access
  /// lives; stored as-is rather than recomputed on every future view.
  /// Defaults to 0 for the one caller that can't supply it —
  /// [_handleTaskData]'s notification "Finish" button, a background
  /// callback with no [BuildContext] to read the profile from.
  Future<bool> finish({double restKcal = 0}) async {
    final store = _store;
    if (store == null || !isActive) return false;

    final workoutExercises = <domain.WorkoutExercise>[];
    for (var i = 0; i < exercises.length; i++) {
      final domainExercise = exercises[i].toDomain(i);
      if (domainExercise != null) workoutExercises.add(domainExercise);
    }
    if (workoutExercises.isEmpty) return false;

    isSaving = true;
    notifyListeners();
    try {
      await store.create(
        name: nameController.text.trim().isEmpty
            ? 'Workout'
            : nameController.text.trim(),
        exercises: workoutExercises,
        startedAt: _startedAt!,
        restKcal: restKcal,
      );
      await _end();
      return true;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Ends the session without saving.
  Future<void> discard() => _end();

  Future<void> _end() async {
    FlutterForegroundTask.removeTaskDataCallback(_handleTaskData);
    if (!kIsWeb) await FlutterForegroundTask.stopService();
    _ticker?.cancel();
    _ticker = null;
    stopwatch
      ..stop()
      ..reset();
    for (final e in exercises) {
      for (final s in e.sets) {
        s.dispose();
      }
    }
    exercises.clear();
    history = [];
    _startedAt = null;
    _store = null;
    notifyListeners();
  }
}
