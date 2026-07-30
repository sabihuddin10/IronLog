import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/workout.dart' as domain;
import '../../models/workout_template.dart';
import '../../utils/health_formulas.dart';

enum SetType { warmup, normal, failure }

String trimNum(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

class ActiveSet {
  SetType type;

  /// Not [final] — [EditWorkoutScreen] builds sets synchronously from the
  /// saved workout first (so the screen isn't blank while history loads),
  /// then fills in the real previous-session label once
  /// [WorkoutRepository.list] resolves, matching [previousLabelAt]'s
  /// set-for-set order.
  String previous;

  /// Strength fields (kg lifted, reps).
  final TextEditingController weightController;
  final TextEditingController repsController;

  /// Cardio fields (minutes elapsed, km covered) — only used/shown when the
  /// parent [ActiveExercise.isCardio] is true.
  final TextEditingController durationController;
  final TextEditingController distanceController;

  bool completed;

  /// [initialWeight]/[initialReps]/[initialDurationSeconds]/[initialDistanceMeters]
  /// pre-fill the relevant controller's text — used by
  /// [ActiveExercise.fromTemplate] to load a preset's saved target values
  /// (weight/reps typed in while building it) as this set's starting point,
  /// still fully editable before you check it off.
  ActiveSet({
    required this.type,
    required this.previous,
    this.completed = false,
    double? initialWeight,
    int? initialReps,
    int? initialDurationSeconds,
    double? initialDistanceMeters,
  })  : weightController = TextEditingController(text: initialWeight == null ? '' : trimNum(initialWeight)),
        repsController = TextEditingController(text: initialReps == null ? '' : '$initialReps'),
        durationController = TextEditingController(
          text: initialDurationSeconds == null ? '' : trimNum(initialDurationSeconds / 60),
        ),
        distanceController = TextEditingController(
          text: initialDistanceMeters == null ? '' : trimNum(initialDistanceMeters / 1000),
        );

  void dispose() {
    weightController.dispose();
    repsController.dispose();
    durationController.dispose();
    distanceController.dispose();
  }
}

class ActiveExercise {
  final String exerciseId;
  final String name;
  final String? tip;

  /// Rest-between-sets reminder for this exercise. Editable per exercise
  /// from the workout logger — not [final] on purpose.
  Duration restTimer;
  final List<ActiveSet> sets;

  /// True for cardio-category exercises (treadmill, bike, rower, jump
  /// rope...) — these log duration + distance, not weight + reps.
  final bool isCardio;

  ActiveExercise({
    required this.exerciseId,
    required this.name,
    required this.sets,
    this.tip,
    this.isCardio = false,
    this.restTimer = const Duration(minutes: 1, seconds: 30),
  });

  factory ActiveExercise.fromLibrary({
    required String exerciseId,
    required String name,
    String? tip,
    bool isCardio = false,
    List<domain.Workout> history = const [],
  }) {
    final previousSets = previousSetsFor(name, history);
    final sets = <ActiveSet>[];

    if (previousSets != null && previousSets.isNotEmpty) {
      for (var i = 0; i < previousSets.length; i++) {
        sets.add(ActiveSet(
          type: previousSets[i].isWarmup ? SetType.warmup : SetType.normal,
          previous: previousLabelAt(i, isCardio, previousSets),
        ));
      }
    } else {
      sets.add(ActiveSet(type: SetType.normal, previous: '-'));
    }

    return ActiveExercise(exerciseId: exerciseId, name: name, sets: sets, tip: tip, isCardio: isCardio);
  }

  /// Builds an exercise's starter sets from a saved [WorkoutTemplate] preset
  /// — each set's weight/reps (or cardio duration/distance) is pre-filled
  /// from what was typed in while building the preset (see
  /// `PresetBuilderScreen`), still fully editable and still requiring a
  /// checkmark to count toward this session's volume/calories, exactly like
  /// any other set. "Previous" labels still come from [history], same as
  /// [fromLibrary], so a preset-started session shows what you actually
  /// lifted last time alongside the preset's target.
  factory ActiveExercise.fromTemplate(TemplateExercise template, {List<domain.Workout> history = const []}) {
    final previousSets = previousSetsFor(template.exerciseName, history);
    final sets = <ActiveSet>[];

    for (var i = 0; i < template.sets.length; i++) {
      final ts = template.sets[i];
      sets.add(ActiveSet(
        type: ts.isWarmup ? SetType.warmup : SetType.normal,
        previous: previousLabelAt(i, template.isCardio, previousSets),
        initialWeight: ts.weight,
        initialReps: ts.reps,
        initialDurationSeconds: ts.durationSeconds,
        initialDistanceMeters: ts.distanceMeters,
      ));
    }

    return ActiveExercise(
      exerciseId: template.exerciseId,
      name: template.exerciseName,
      sets: sets,
      isCardio: template.isCardio,
    );
  }

  domain.WorkoutExercise? toDomain(int order) {
    final completedSets = <domain.WorkoutSet>[];
    var n = 1;
    for (final s in sets) {
      if (!s.completed) continue;
      if (isCardio) {
        final minutes = double.tryParse(s.durationController.text);
        if (minutes == null || minutes <= 0) continue;
        final km = double.tryParse(s.distanceController.text);
        completedSets.add(domain.WorkoutSet(
          setNumber: n++,
          kind: domain.SetKind.cardio,
          durationSeconds: (minutes * 60).round(),
          distanceMeters: km != null ? km * 1000 : null,
          isWarmup: s.type == SetType.warmup,
        ));
      } else {
        final weight = double.tryParse(s.weightController.text);
        final reps = int.tryParse(s.repsController.text);
        if (weight == null || reps == null) continue;
        completedSets.add(domain.WorkoutSet(
          setNumber: n++,
          kind: domain.SetKind.strength,
          weight: weight,
          reps: reps,
          isWarmup: s.type == SetType.warmup,
        ));
      }
    }
    if (completedSets.isEmpty) return null;
    return domain.WorkoutExercise(
      exerciseId: exerciseId,
      exerciseName: name,
      order: order,
      sets: completedSets,
    );
  }
}

/// Most recent completed set-by-set performance for an exercise, used to
/// show "previous" values while logging a new workout — and, via
/// [previousLabelAt], while editing an already-saved one. [history] should
/// already be sorted most-recent-first (as `WorkoutRepository.list()`
/// returns it) and should exclude the workout currently being edited/logged,
/// or it'd show itself as its own "previous".
List<domain.WorkoutSet>? previousSetsFor(String exerciseName, List<domain.Workout> history) {
  for (final workout in history) {
    for (final exercise in workout.exercises) {
      if (exercise.exerciseName == exerciseName) return exercise.sets;
    }
  }
  return null;
}

String formatPreviousCardio(int? durationSeconds, double? distanceMeters) {
  if (durationSeconds == null) return '-';
  final m = durationSeconds ~/ 60;
  final s = durationSeconds % 60;
  final time = '$m:${s.toString().padLeft(2, '0')}';
  if (distanceMeters == null) return time;
  return '$time · ${trimNum(distanceMeters / 1000)}km';
}

/// Formats the "previous" label for set [index], matching it set-for-set
/// against [previousSets] (as returned by [previousSetsFor]) — shared by
/// [ActiveExercise.fromTemplate] (a preset's target sets vs. last time's
/// actuals) and `EditWorkoutScreen` (a saved workout's own sets vs. the
/// session before it).
String previousLabelAt(int index, bool isCardio, List<domain.WorkoutSet>? previousSets) {
  final prev = previousSets != null && index < previousSets.length ? previousSets[index] : null;
  if (prev == null) return '-';
  return isCardio
      ? formatPreviousCardio(prev.durationSeconds, prev.distanceMeters)
      : '${trimNum(prev.weight ?? 0)}kg × ${prev.reps ?? 0}';
}

/// Backfill/preview estimate of elapsed time for a list of active exercises
/// — every completed set's own active time (reps × [HealthFormulas.secondsPerRep],
/// or the logged duration for a cardio set) *plus* each exercise's configured
/// [ActiveExercise.restTimer] across its between-set gaps (n completed sets ->
/// n-1 rest intervals; there's no rest after the last set). Shared by
/// [ActiveWorkoutSession.syntheticElapsedDuration] (backfilling a past
/// workout) and the preset builder (previewing a not-yet-performed preset) —
/// same formula, same estimate, different caller.
Duration syntheticElapsedDurationOf(List<ActiveExercise> exercises) {
  var totalMs = 0;
  for (final e in exercises) {
    final completedSets = e.sets.where((s) => s.completed).toList();
    for (final s in completedSets) {
      if (e.isCardio) {
        final minutes = double.tryParse(s.durationController.text) ?? 0;
        totalMs += (minutes * 60000).round();
      } else {
        final reps = int.tryParse(s.repsController.text) ?? 0;
        totalMs += (reps * HealthFormulas.secondsPerRep * 1000).round();
      }
    }
    final restIntervals = completedSets.length > 1 ? completedSets.length - 1 : 0;
    totalMs += e.restTimer.inMilliseconds * restIntervals;
  }
  return Duration(milliseconds: totalMs);
}

String setLabel(SetType type, int normalIndex) {
  switch (type) {
    case SetType.warmup:
      return 'W';
    case SetType.failure:
      return 'F';
    case SetType.normal:
      return '$normalIndex';
  }
}

Color setLabelColor(BuildContext context, SetType type) {
  switch (type) {
    case SetType.warmup:
      return context.colors.warning;
    case SetType.failure:
      return Theme.of(context).colorScheme.error;
    case SetType.normal:
      return Theme.of(context).colorScheme.primary;
  }
}
