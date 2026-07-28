import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_spacing.dart';
import '../../core/responsive.dart';
import '../../models/exercise.dart';
import '../../models/workout.dart';
import '../../repositories/exercise_repository.dart';
import 'muscle_distribution_screen.dart';

class StatisticsScreen extends StatelessWidget {
  final List<Workout> workouts;

  const StatisticsScreen({super.key, required this.workouts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        children: [
          _StatRow(
            icon: Icons.pentagon_outlined,
            title: 'Muscle distribution',
            subtitle: 'Compare your current and previous muscle distributions.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MuscleDistributionScreen(workouts: workouts)),
            ),
          ),
          const Divider(height: 1),
          _StatRow(
            icon: Icons.list_alt_outlined,
            title: 'Main exercises',
            subtitle: 'List of exercises you do most often.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => _MainExercisesScreen(workouts: workouts)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _StatRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _MainExercisesScreen extends StatelessWidget {
  final List<Workout> workouts;

  const _MainExercisesScreen({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final setCounts = <String, int>{};
    final exerciseIds = <String, String>{};
    for (final w in workouts) {
      for (final e in w.exercises) {
        setCounts[e.exerciseName] = (setCounts[e.exerciseName] ?? 0) + e.sets.length;
        exerciseIds[e.exerciseName] = e.exerciseId;
      }
    }
    final ranked = setCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Main Exercises')),
      body: FutureBuilder<List<Exercise>>(
        future: context.read<ExerciseRepository>().list(),
        builder: (context, snapshot) {
          final byId = {for (final e in snapshot.data ?? <Exercise>[]) e.id: e};
          if (ranked.isEmpty) {
            return const Center(child: Text('No workouts logged yet.'));
          }
          return ListView.separated(
            padding: EdgeInsets.all(context.scale(AppSpacing.lg)),
            itemCount: ranked.length,
            separatorBuilder: (_, _) => Divider(height: context.scale(AppSpacing.lg)),
            itemBuilder: (context, index) {
              final entry = ranked[index];
              final exercise = byId[exerciseIds[entry.key]];
              return Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.fitness_center,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(width: context.scale(AppSpacing.md)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: Theme.of(context).textTheme.bodyMedium),
                        if (exercise != null)
                          Text(
                            exercise.muscleGroup.replaceAll('_', ' '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Text('${entry.value} sets', style: Theme.of(context).textTheme.bodyMedium),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
