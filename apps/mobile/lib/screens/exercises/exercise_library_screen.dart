import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_spacing.dart';
import '../../core/responsive.dart';
import '../../models/exercise.dart';
import '../../repositories/exercise_repository.dart';

String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Standalone exercise-library browser (Profile -> Dashboard -> Exercises).
/// Distinct from `_ExercisePicker` in `log_workout_screen.dart`, which is a
/// bottom sheet for picking an exercise to add to an in-progress workout —
/// this is a full-page reference browser with equipment/muscle filter chips,
/// not tied to a workout session.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  late Future<List<Exercise>> _future;
  String _query = '';
  String? _equipment;
  String? _muscle;

  @override
  void initState() {
    super.initState();
    _future = context.read<ExerciseRepository>().list();
  }

  Future<void> _pickFromList({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) async {
    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              title: const Text('All'),
              trailing: selected == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop<String?>(null),
            ),
            for (final o in options)
              ListTile(
                title: Text(_capitalize(o.replaceAll('_', ' '))),
                trailing: selected == o ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(o),
              ),
          ],
        ),
      ),
    );
    onSelected(choice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: Padding(
        padding: EdgeInsets.all(context.scale(AppSpacing.lg)),
        child: FutureBuilder<List<Exercise>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final exercises = snapshot.data ?? [];
            final equipmentOptions = exercises
                .map((e) => e.equipment)
                .whereType<String>()
                .toSet()
                .toList()
              ..sort();
            final muscleOptions = [...muscleGroups]..sort();

            final query = _query.toLowerCase().trim();
            final filtered = exercises.where((e) {
              if (_equipment != null && e.equipment != _equipment) return false;
              if (_muscle != null &&
                  e.muscleGroup != _muscle &&
                  !e.muscles.any((m) => m.muscle == _muscle)) {
                return false;
              }
              if (query.isEmpty) return true;
              return e.name.toLowerCase().contains(query) ||
                  e.muscleGroup.toLowerCase().contains(query) ||
                  e.muscles.any((m) => m.muscle.toLowerCase().contains(query));
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search exercise',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                SizedBox(height: context.scale(AppSpacing.md)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickFromList(
                          context: context,
                          title: 'Equipment',
                          options: equipmentOptions,
                          selected: _equipment,
                          onSelected: (v) => setState(() => _equipment = v),
                        ),
                        icon: const Icon(Icons.expand_more),
                        label: Text(
                          _equipment == null ? 'All Equipment' : _capitalize(_equipment!),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(width: context.scale(AppSpacing.md)),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickFromList(
                          context: context,
                          title: 'Muscle group',
                          options: muscleOptions,
                          selected: _muscle,
                          onSelected: (v) => setState(() => _muscle = v),
                        ),
                        icon: const Icon(Icons.expand_more),
                        label: Text(
                          _muscle == null ? 'All Muscles' : _capitalize(_muscle!.replaceAll('_', ' ')),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.scale(AppSpacing.md)),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      final breakdown = e.muscles
                          .map((m) => '${_capitalize(m.muscle)} ${m.percentage}%')
                          .join(' · ');
                      final scheme = Theme.of(context).colorScheme;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scheme.primary,
                          child: Icon(Icons.fitness_center, size: 18, color: scheme.onPrimary),
                        ),
                        title: Text(e.name),
                        subtitle: Text(
                          breakdown.isNotEmpty ? breakdown : e.muscleGroup.replaceAll('_', ' '),
                        ),
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.name, style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 4),
                                  Text(
                                    e.equipment != null
                                        ? '${_capitalize(e.muscleGroup.replaceAll('_', ' '))} · ${_capitalize(e.equipment!)}'
                                        : _capitalize(e.muscleGroup.replaceAll('_', ' ')),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  for (final m in e.muscles)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(_capitalize(m.muscle))),
                                          Text('${m.percentage}%'),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
