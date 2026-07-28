import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/premium_theme.dart';
import '../../core/premium_widgets.dart';
import '../../data/body_profile_store.dart';
import '../../models/exercise.dart';
import '../../models/workout_template.dart';
import '../../repositories/exercise_repository.dart';
import '../../repositories/workout_repository.dart';
import '../../utils/health_formulas.dart';
import 'active_workout_models.dart';
import 'active_workout_session.dart';
import 'exercise_card_widgets.dart';
import 'workout_calorie_helpers.dart';

double _restKcalOf(ActiveWorkoutSession session, BodyProfileStore profile) {
  final bmrValue = HealthFormulas.bmr(profile.weightKg, profile.heightCm, profile.age, profile.gender);
  return HealthFormulas.restingKcalPerMinute(bmrValue) * (session.trackedDuration.inMilliseconds / 60000);
}

class LogWorkoutScreen extends StatefulWidget {
  /// True (default) for a real-time tracked workout. False when logging a
  /// workout that already happened — see [ActiveWorkoutSession.isLiveSession].
  /// Only takes effect when starting a new session; re-opening an
  /// already-active one just resumes it as-is.
  final bool isLiveSession;

  /// Preset to load the session's starter exercises from — see
  /// [ActiveWorkoutSession.start]. Only takes effect when starting a new
  /// session; ignored (and safe to omit) when resuming one already active.
  final WorkoutTemplate? template;

  const LogWorkoutScreen({super.key, this.isLiveSession = true, this.template});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  @override
  void initState() {
    super.initState();
    final session = context.read<ActiveWorkoutSession>();
    if (!session.isActive) {
      session.start(
        context.read<WorkoutRepository>(),
        isLiveSession: widget.isLiveSession,
        template: widget.template,
      );
    }
  }

  Future<void> _pickExercise(ActiveWorkoutSession session) async {
    final exercises = await context.read<ExerciseRepository>().list();
    if (!mounted) return;
    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExercisePicker(exercises: exercises),
    );
    if (selected == null) return;
    session.addExercise(
      ActiveExercise.fromLibrary(
        exerciseId: selected.id,
        name: selected.name,
        isCardio: selected.muscleGroup == 'cardio',
        history: session.history,
      ),
    );
  }

  Future<void> _finish(ActiveWorkoutSession session) async {
    final profile = context.read<BodyProfileStore>();
    final saved = await session.finish(restKcal: _restKcalOf(session, profile));
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check off at least one completed set first.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _confirmDiscard(ActiveWorkoutSession session) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this workout?'),
        content: const Text('Your sets and progress so far will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      await session.discard();
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ActiveWorkoutSession>();
    final profile = context.watch<BodyProfileStore>();

    return Scaffold(
      backgroundColor: Premium.bg,
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 108),
        children: [
          // Custom header replacing the AppBar — leaving this screen (down
          // chevron) doesn't end the session; it keeps running (timer, sets,
          // notification) in the background until Finish or Discard.
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => Navigator.of(context).pop(false),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Premium.surface2,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.keyboard_arrow_down, color: Premium.textDim, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              const LivePulseDot(),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: session.nameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: Premium.heading(19),
                ),
              ),
              PopupMenuButton<void>(
                icon: const Icon(Icons.more_vert, color: Premium.textDim),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => _confirmDiscard(session),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF6B5C)),
                        const SizedBox(width: 8),
                        Text('Discard workout', style: Premium.body(14, color: const Color(0xFFFF6B5C))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              session.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Premium.accent),
                    )
                  : PremiumGradientButton(
                      label: 'Finish',
                      onTap: () => _finish(session),
                    ),
            ],
          ),
          const SizedBox(height: 14),
          StatsRow(
            duration: session.durationLabel,
            volume: session.volume,
            sets: session.completedSetCount,
            calories: liveCalories(
              exercises: session.exercises,
              profile: profile,
              isLiveSession: session.isLiveSession,
              liveDuration: session.stopwatch.elapsed,
              syntheticDuration: session.syntheticElapsedDuration,
            ),
          ),
          const SizedBox(height: 16),
          for (final exercise in session.exercises) ...[
            ExerciseCard(
              exercise: exercise,
              onChanged: session.refresh,
              onRemove: () => session.removeExercise(exercise),
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
            onPressed: () => _pickExercise(session),
            icon: const Icon(Icons.add),
            label: const Text('Add exercise'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: session.noteController,
            decoration: const InputDecoration(
              hintText: 'Add a note...',
              prefixIcon: Icon(Icons.edit_note),
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 3,
          ),
        ],
        ),
      ),
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Search-and-pick bottom sheet for adding an exercise — shared by
/// [LogWorkoutScreen] (adding to an in-progress session) and the preset
/// builder (adding to a [WorkoutTemplate]).
class ExercisePicker extends StatefulWidget {
  final List<Exercise> exercises;
  const ExercisePicker({super.key, required this.exercises});

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase().trim();
    final filtered = widget.exercises
        .where((e) =>
            query.isEmpty ||
            e.name.toLowerCase().contains(query) ||
            e.muscleGroup.toLowerCase().contains(query) ||
            e.muscles.any((m) => m.muscle.toLowerCase().contains(query)))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add exercise', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search exercises',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
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
                      child: Icon(
                        Icons.fitness_center,
                        size: 18,
                        color: scheme.onPrimary,
                      ),
                    ),
                    title: Text(e.name),
                    subtitle: Text(
                      breakdown.isNotEmpty
                          ? breakdown
                          : e.muscleGroup.replaceAll('_', ' '),
                    ),
                    isThreeLine: false,
                    onTap: () => Navigator.of(context).pop(e),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
