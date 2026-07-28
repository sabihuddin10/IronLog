import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_spacing.dart';
import '../../core/responsive.dart';
import '../../models/exercise.dart';
import '../../models/workout.dart';
import '../../repositories/exercise_repository.dart';

const List<String> _radarCategories = ['Back', 'Chest', 'Shoulders', 'Arms', 'Core', 'Legs'];

/// Buckets a library `muscleGroup` (chest/back/shoulders/biceps/triceps/
/// legs/glutes/core/cardio/full_body — see `models/exercise.dart`) into one
/// of the six broad categories the radar chart plots. Cardio/full_body
/// don't map to a single muscle group, so they're excluded from this chart.
String? _categoryOf(String muscleGroup) => switch (muscleGroup) {
      'back' => 'Back',
      'chest' => 'Chest',
      'shoulders' => 'Shoulders',
      'biceps' || 'triceps' => 'Arms',
      'core' => 'Core',
      'legs' || 'glutes' => 'Legs',
      _ => null,
    };

/// Set counts per broad muscle category for a set of workouts, looking up
/// each logged exercise's `muscleGroup` from the library.
Map<String, int> _setCountsByCategory(List<Workout> workouts, Map<String, Exercise> exercisesById) {
  final counts = {for (final c in _radarCategories) c: 0};
  for (final w in workouts) {
    for (final e in w.exercises) {
      final category = _categoryOf(exercisesById[e.exerciseId]?.muscleGroup ?? '');
      if (category != null) counts[category] = counts[category]! + e.sets.length;
    }
  }
  return counts;
}

class MuscleDistributionScreen extends StatelessWidget {
  final List<Workout> workouts;

  const MuscleDistributionScreen({super.key, required this.workouts});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month);
    final lastMonthStart = DateTime(now.year, now.month - 1);

    bool inMonth(Workout w, DateTime monthStart) {
      final d = w.startedAt.toLocal();
      return d.year == monthStart.year && d.month == monthStart.month;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Muscle Distribution')),
      body: FutureBuilder<List<Exercise>>(
        future: context.read<ExerciseRepository>().list(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final exercisesById = {for (final e in snapshot.data ?? <Exercise>[]) e.id: e};

          final thisMonth = _setCountsByCategory(
            workouts.where((w) => inMonth(w, thisMonthStart)).toList(),
            exercisesById,
          );
          final lastMonth = _setCountsByCategory(
            workouts.where((w) => inMonth(w, lastMonthStart)).toList(),
            exercisesById,
          );
          final maxCount = [
            ...thisMonth.values,
            ...lastMonth.values,
          ].fold(0, (a, b) => a > b ? a : b);
          final ranked = thisMonth.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: EdgeInsets.all(context.scale(AppSpacing.lg)),
            children: [
              Text('Muscle Distribution', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: context.scale(AppSpacing.lg)),
              AspectRatio(
                aspectRatio: 1.1,
                child: RadarChart(
                  RadarChartData(
                    radarShape: RadarShape.polygon,
                    tickCount: 3,
                    ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
                    radarBorderData: BorderSide(color: Theme.of(context).dividerColor),
                    gridBorderData: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                    titleTextStyle: Theme.of(context).textTheme.bodySmall,
                    getTitle: (index, angle) => RadarChartTitle(text: _radarCategories[index]),
                    dataSets: [
                      RadarDataSet(
                        fillColor: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                        borderColor: Theme.of(context).disabledColor,
                        entryRadius: 2,
                        borderWidth: 2,
                        dataEntries: [
                          for (final c in _radarCategories)
                            RadarEntry(value: (lastMonth[c] ?? 0).toDouble()),
                        ],
                      ),
                      RadarDataSet(
                        fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                        borderColor: Theme.of(context).colorScheme.primary,
                        entryRadius: 2,
                        borderWidth: 2,
                        dataEntries: [
                          for (final c in _radarCategories)
                            RadarEntry(value: (thisMonth[c] ?? 0).toDouble()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.scale(AppSpacing.md)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(color: Theme.of(context).disabledColor, label: _monthLabel(lastMonthStart)),
                  SizedBox(width: context.scale(AppSpacing.lg)),
                  _LegendDot(
                    color: Theme.of(context).colorScheme.primary,
                    label: _monthLabel(thisMonthStart),
                  ),
                ],
              ),
              SizedBox(height: context.scale(AppSpacing.xxl)),
              Text('Main Muscle Groups', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: context.scale(AppSpacing.md)),
              Row(
                children: [
                  Expanded(child: Text('Muscle', style: Theme.of(context).textTheme.bodySmall)),
                  Text('Sets', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              SizedBox(height: context.scale(AppSpacing.sm)),
              for (final entry in ranked)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: context.scale(AppSpacing.xs)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: context.scale(80),
                        child: Text(entry.key, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: context.scale(AppSpacing.sm)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: maxCount <= 0 ? 0 : entry.value / maxCount,
                              minHeight: context.scale(10),
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: context.scale(28),
                        child: Text(
                          '${entry.value}',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _monthLabel(DateTime d) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[d.month - 1]} ${d.year}';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.scale(10),
          height: context.scale(10),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: context.scale(AppSpacing.xs)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
