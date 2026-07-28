import '../../data/body_profile_store.dart';
import '../../utils/health_formulas.dart';
import 'active_workout_models.dart';

/// Calorie math for a list of [ActiveExercise]s, using the same
/// Compendium-of-Physical-Activities MET model everywhere in the app. Kept
/// at the UI layer (not on `ActiveWorkoutSession`) since it's the only place
/// with [BodyProfileStore] access; shared by [LogWorkoutScreen] (a real
/// in-progress session) and the preset builder (previewing a not-yet-
/// performed [WorkoutTemplate]) so both compute calories identically.
/// Net (activity-only) calorie cost of a single set — the same per-set
/// number shown on each row via [SetRow.kcal], summed by [liveCalories] to
/// build the running workout total. Keeping both call sites on this one
/// function is what makes the row-level numbers add up to the header total.
double setKcalOf(ActiveExercise e, ActiveSet s, BodyProfileStore profile, double bmrValue) {
  if (e.isCardio) {
    final minutes = double.tryParse(s.durationController.text) ?? 0;
    final km = double.tryParse(s.distanceController.text);
    return HealthFormulas.cardioSetKcal(
      bodyWeightKg: profile.weightKg,
      durationMinutes: minutes,
      distanceMeters: km != null ? km * 1000 : null,
    );
  }
  final reps = int.tryParse(s.repsController.text) ?? 0;
  final loadKg = double.tryParse(s.weightController.text) ?? 0;
  return HealthFormulas.setKcal(
    bodyWeightKg: profile.weightKg,
    bmrValue: bmrValue,
    reps: reps,
    isWarmup: s.type == SetType.warmup,
    loadKg: loadKg,
  );
}

/// Total workout calories (active sets + resting metabolism over
/// [isLiveSession] ? [liveDuration] : [syntheticDuration]) — see
/// [HealthFormulas.workoutKcal].
double liveCalories({
  required List<ActiveExercise> exercises,
  required BodyProfileStore profile,
  required bool isLiveSession,
  Duration liveDuration = Duration.zero,
  Duration syntheticDuration = Duration.zero,
}) {
  final bmrValue = HealthFormulas.bmr(profile.weightKg, profile.heightCm, profile.age, profile.gender);
  var activeKcal = 0.0;
  for (final e in exercises) {
    for (final s in e.sets) {
      if (!s.completed) continue;
      activeKcal += setKcalOf(e, s, profile, bmrValue);
    }
  }
  return HealthFormulas.workoutKcal(
    activeSetKcalSum: activeKcal,
    bmrValue: bmrValue,
    isLiveSession: isLiveSession,
    liveDuration: liveDuration,
    syntheticDuration: syntheticDuration,
  );
}
