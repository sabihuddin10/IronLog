import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../data/body_profile_store.dart';
import '../../models/workout.dart';
import '../../utils/health_formulas.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final exercises = [...workout.exercises]..sort((a, b) => a.order.compareTo(b.order));
    final profile = context.watch<BodyProfileStore>();
    final bmrValue = HealthFormulas.bmr(profile.weightKg, profile.heightCm, profile.age, profile.gender);

    double setKcalOf(WorkoutSet set) => set.kind == SetKind.cardio
        ? HealthFormulas.cardioSetKcal(
            bodyWeightKg: profile.weightKg,
            durationMinutes: (set.durationSeconds ?? 0) / 60,
            distanceMeters: set.distanceMeters,
          )
        : HealthFormulas.setKcal(
            bodyWeightKg: profile.weightKg,
            bmrValue: bmrValue,
            reps: set.reps ?? 0,
            isWarmup: set.isWarmup,
            loadKg: set.weight ?? 0,
          );

    double exerciseKcalOf(WorkoutExercise exercise) =>
        exercise.sets.fold(0.0, (sum, s) => sum + setKcalOf(s));

    // Rest-time calorie contribution was already resolved once at save time
    // (real stopwatch time for a live session, or a synthetic backfill
    // estimate — see HealthFormulas.workoutKcal) and persisted as
    // [Workout.restKcal], rather than recomputed here from [workout.duration]
    // — which for a backfilled workout wouldn't reflect any real elapsed time.
    final activeKcalSum = exercises.fold(0.0, (sum, e) => sum + exerciseKcalOf(e));
    final totalKcal = activeKcalSum + workout.restKcal;

    return Scaffold(
      appBar: AppBar(title: Text(workout.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            DateFormat.yMMMd().add_jm().format(workout.startedAt.toLocal()),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                label: 'Duration',
                value: workout.duration.inMinutes > 0 ? '${workout.duration.inMinutes}m' : '-',
              ),
              _Stat(label: 'Volume', value: '${workout.totalVolume.toStringAsFixed(0)}kg'),
              _Stat(label: 'Sets', value: '${workout.totalSets}'),
              _Stat(label: 'Calories', value: '${totalKcal.toStringAsFixed(0)} kcal'),
            ],
          ),
          const SizedBox(height: 24),
          for (final exercise in exercises)
            _ExerciseSection(
              exercise: exercise,
              exerciseKcal: exerciseKcalOf(exercise),
              setKcalOf: setKcalOf,
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ExerciseSection extends StatelessWidget {
  final WorkoutExercise exercise;
  final double exerciseKcal;
  final double Function(WorkoutSet set) setKcalOf;

  const _ExerciseSection({
    required this.exercise,
    required this.exerciseKcal,
    required this.setKcalOf,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(exercise.exerciseName, style: Theme.of(context).textTheme.titleMedium),
                ),
                Text(
                  '${exerciseKcal.toStringAsFixed(0)} kcal',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final set in exercise.sets) _SetLine(set: set, kcal: setKcalOf(set)),
          ],
        ),
      ),
    );
  }
}

class _SetLine extends StatelessWidget {
  final WorkoutSet set;
  final double kcal;

  const _SetLine({required this.set, required this.kcal});

  String get _label {
    if (set.kind == SetKind.cardio) {
      final totalSeconds = set.durationSeconds ?? 0;
      final time = '${totalSeconds ~/ 60}:${(totalSeconds % 60).toString().padLeft(2, '0')}';
      final km = set.distanceMeters;
      return km != null ? '$time · ${(km / 1000).toStringAsFixed(2)} km' : time;
    }
    return '${(set.weight ?? 0).toStringAsFixed(1)} kg × ${set.reps ?? 0}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badgeColor = set.isWarmup ? context.colors.warning : scheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Text(
              set.isWarmup ? 'W' : '${set.setNumber}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: badgeColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            '${kcal.toStringAsFixed(1)} kcal',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}
