import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../core/premium_widgets.dart';
import '../../data/body_profile_store.dart';
import '../../models/exercise.dart';
import '../../models/workout.dart' as domain;
import '../../models/workout_template.dart';
import '../../repositories/exercise_repository.dart';
import '../../repositories/workout_repository.dart';
import '../../repositories/workout_template_repository.dart';
import '../../utils/health_formulas.dart';
import 'active_workout_models.dart';
import 'exercise_card_widgets.dart';
import 'log_workout_screen.dart' show ExercisePicker;
import 'workout_calorie_helpers.dart';

/// Builds (or, in the future, edits) a [WorkoutTemplate] preset — visually
/// and interactively the same screen as [LogWorkoutScreen] (add exercise,
/// add set, type weight/reps, check a set off, edit rest timer) reusing the
/// exact same [ExerciseCard]/[SetRow]/etc widgets, but backed by a local
/// exercise list instead of the app-wide [ActiveWorkoutSession] — nothing
/// here is actually being tracked live, so there's no stopwatch, no
/// foreground notification, and it can't collide with a real in-progress
/// workout. The stats strip shows an *estimated* duration/calories (the same
/// backfill-style formula used for a past/non-live workout) instead of a
/// live clock, computed from whatever sets you've checked off so far. Only
/// checked-off sets are saved into the preset, exactly like how only
/// completed sets get saved into a real logged workout.
class PresetBuilderScreen extends StatefulWidget {
  const PresetBuilderScreen({super.key});

  @override
  State<PresetBuilderScreen> createState() => _PresetBuilderScreenState();
}

class _PresetBuilderScreenState extends State<PresetBuilderScreen> {
  final _nameController = TextEditingController();
  final List<ActiveExercise> _exercises = [];
  List<domain.Workout> _history = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await context.read<WorkoutRepository>().list();
      if (mounted) setState(() => _history = history);
    } catch (_) {
      // "Previous" prefill is a nice-to-have; an empty history just means
      // newly added exercises show '-' instead.
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final e in _exercises) {
      for (final s in e.sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _pickExercise() async {
    final exercises = await context.read<ExerciseRepository>().list();
    if (!mounted) return;
    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExercisePicker(exercises: exercises),
    );
    if (selected == null) return;
    setState(() {
      _exercises.add(ActiveExercise.fromLibrary(
        exerciseId: selected.id,
        name: selected.name,
        isCardio: selected.muscleGroup == 'cardio',
        history: _history,
      ));
    });
  }

  void _removeExercise(ActiveExercise exercise) {
    for (final s in exercise.sets) {
      s.dispose();
    }
    setState(() => _exercises.remove(exercise));
  }

  Future<void> _confirmDiscard() async {
    if (_exercises.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this preset?'),
        content: const Text('The exercises and sets you\'ve added so far will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep going')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Discard')),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop(false);
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give this preset a name first.')));
      return;
    }

    final templateExercises = <TemplateExercise>[];
    for (final e in _exercises) {
      final sets = <TemplateSet>[];
      for (final s in e.sets) {
        if (!s.completed) continue;
        if (e.isCardio) {
          final minutes = double.tryParse(s.durationController.text);
          if (minutes == null || minutes <= 0) continue;
          final km = double.tryParse(s.distanceController.text);
          sets.add(TemplateSet(
            isWarmup: s.type == SetType.warmup,
            durationSeconds: (minutes * 60).round(),
            distanceMeters: km != null ? km * 1000 : null,
          ));
        } else {
          final weight = double.tryParse(s.weightController.text);
          final reps = int.tryParse(s.repsController.text);
          if (weight == null || reps == null) continue;
          sets.add(TemplateSet(isWarmup: s.type == SetType.warmup, weight: weight, reps: reps));
        }
      }
      if (sets.isEmpty) continue;
      templateExercises.add(TemplateExercise(
        exerciseId: e.exerciseId,
        exerciseName: e.name,
        isCardio: e.isCardio,
        sets: sets,
      ));
    }

    if (templateExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check off at least one completed set first.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<WorkoutTemplateRepository>().create(name: name, exercises: templateExercises);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BodyProfileStore>();
    final syntheticDuration = syntheticElapsedDurationOf(_exercises);
    final estimatedCalories = liveCalories(
      exercises: _exercises,
      profile: profile,
      isLiveSession: false,
      syntheticDuration: syntheticDuration,
    );
    var volume = 0.0;
    var completedSets = 0;
    for (final e in _exercises) {
      for (final s in e.sets) {
        if (!s.completed) continue;
        completedSets++;
        final w = double.tryParse(s.weightController.text) ?? 0;
        final r = int.tryParse(s.repsController.text) ?? 0;
        volume += w * r;
      }
    }
    final h = syntheticDuration.inHours;
    final m = syntheticDuration.inMinutes % 60;
    final durationLabel = h > 0 ? '${h}h ${m}m' : '${m}m ${syntheticDuration.inSeconds % 60}s';

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: _confirmDiscard,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: context.colors.cardBackground, borderRadius: BorderRadius.circular(9)),
                    alignment: Alignment.center,
                    child: Icon(Icons.keyboard_arrow_down, color: context.colors.textSecondary, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Preset name',
                    ),
                    style: Premium.heading(context, 19),
                  ),
                ),
                const SizedBox(width: 4),
                _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.accent),
                      )
                    : PremiumGradientButton(label: 'Save preset', onTap: _save),
              ],
            ),
            const SizedBox(height: 14),
            StatsRow(
              duration: durationLabel,
              durationLabel: 'Est. duration',
              volume: volume,
              sets: completedSets,
              calories: estimatedCalories,
              caloriesLabel: 'Est. calories',
            ),
            const SizedBox(height: 16),
            for (final exercise in _exercises) ...[
              ExerciseCard(
                exercise: exercise,
                onChanged: _refresh,
                onRemove: () => _removeExercise(exercise),
                kcalOf: (set) => setKcalOf(
                  exercise,
                  set,
                  profile,
                  HealthFormulas.bmr(profile.weightKg, profile.heightCm, profile.age, profile.gender),
                ),
              ),
              const SizedBox(height: 16),
            ],
            OutlinedButton.icon(
              onPressed: _pickExercise,
              icon: const Icon(Icons.add),
              label: const Text('Add exercise'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}
