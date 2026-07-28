import 'package:flutter/material.dart';
import '../../core/premium_theme.dart';
import '../../core/premium_widgets.dart';
import '../../core/responsive.dart';
import 'active_workout_models.dart';

/// Pure-presentation widgets for editing a list of [ActiveExercise] —
/// exercise cards, set rows, and the duration/volume/sets/calories stats
/// strip. Shared by [LogWorkoutScreen] (a real in-progress session) and the
/// preset builder (editing a not-yet-performed [WorkoutTemplate]'s target
/// sets) — neither of these widgets know or care which one they're in,
/// since they only take [ActiveExercise]/[ActiveSet] and callbacks, never
/// `ActiveWorkoutSession` itself.
Future<void> editRestTimer(BuildContext context, ActiveExercise exercise, VoidCallback onChanged) async {
  final minutesController = TextEditingController(text: '${exercise.restTimer.inMinutes}');
  final secondsController = TextEditingController(text: '${exercise.restTimer.inSeconds % 60}');

  final result = await showDialog<Duration>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rest between each set'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'min'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: secondsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'sec'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final min = int.tryParse(minutesController.text) ?? 0;
            final sec = int.tryParse(secondsController.text) ?? 0;
            Navigator.of(context).pop(Duration(minutes: min, seconds: sec));
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  minutesController.dispose();
  secondsController.dispose();

  if (result != null) {
    exercise.restTimer = result;
    onChanged();
  }
}

class StatsRow extends StatelessWidget {
  final String duration;
  final double volume;
  final int sets;
  final double calories;
  final String durationLabel;
  final String caloriesLabel;

  const StatsRow({
    super.key,
    required this.duration,
    required this.volume,
    required this.sets,
    required this.calories,
    this.durationLabel = 'Duration',
    this.caloriesLabel = 'Calories',
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      child: Row(
        children: [
          Expanded(child: Stat(label: durationLabel, value: duration)),
          _divider(),
          Expanded(child: Stat(label: 'Volume', value: '${volume.toStringAsFixed(0)} kg')),
          _divider(),
          Expanded(child: Stat(label: 'Sets', value: '$sets')),
          _divider(),
          Expanded(child: Stat(label: caloriesLabel, value: calories.toStringAsFixed(0))),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 22, color: Premium.border);
}

class Stat extends StatelessWidget {
  final String label;
  final String value;

  const Stat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Premium.heading(16),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: Premium.body(9, weight: FontWeight.w600, color: Premium.textFaint).copyWith(letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class ExerciseCard extends StatelessWidget {
  final ActiveExercise exercise;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final double Function(ActiveSet set) kcalOf;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onChanged,
    required this.onRemove,
    required this.kcalOf,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      radius: Premium.radiusXl,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const PremiumIconChip(icon: Icons.fitness_center, size: 34),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    exercise.name,
                    overflow: TextOverflow.ellipsis,
                    style: Premium.heading(14.5),
                  ),
                ),
                PopupMenuButton<void>(
                  icon: const Icon(Icons.more_vert, color: Premium.textDim),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onRemove,
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF6B5C)),
                          const SizedBox(width: 8),
                          Text('Remove exercise', style: Premium.body(14, color: const Color(0xFFFF6B5C))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (exercise.tip != null) ...[
              const SizedBox(height: 6),
              Text(exercise.tip!, style: Premium.body(12, color: Premium.textDim)),
            ],
            const SizedBox(height: 6),
            InkWell(
              onTap: () => editRestTimer(context, exercise, onChanged),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Premium.surface3,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Premium.textDim),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Rest btw each set: ${exercise.restTimer.inMinutes}min ${exercise.restTimer.inSeconds % 60}s',
                        overflow: TextOverflow.ellipsis,
                        style: Premium.body(11, weight: FontWeight.w500, color: Premium.textDim),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 12, color: Premium.textDim),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SetTableHeader(isCardio: exercise.isCardio),
            for (var i = 0; i < exercise.sets.length; i++)
              SetRow(
                set: exercise.sets[i],
                isCardio: exercise.isCardio,
                normalIndex: exercise.sets
                    .sublist(0, i + 1)
                    .where((s) => s.type == SetType.normal)
                    .length,
                kcal: kcalOf(exercise.sets[i]),
                onChanged: onChanged,
                onRemove: () {
                  exercise.sets[i].dispose();
                  exercise.sets.removeAt(i);
                  onChanged();
                },
              ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                exercise.sets.add(
                  ActiveSet(type: SetType.normal, previous: '-'),
                );
                onChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Premium.accent.withValues(alpha: 0.3), style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 16, color: Premium.accent),
                    const SizedBox(width: 6),
                    Text('Add set', style: Premium.body(13, weight: FontWeight.w600, color: Premium.accent)),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

class SetTableHeader extends StatelessWidget {
  final bool isCardio;

  const SetTableHeader({super.key, required this.isCardio});

  @override
  Widget build(BuildContext context) {
    final style = Premium.body(9.5, weight: FontWeight.w600, color: Premium.textFaint).copyWith(letterSpacing: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: context.scale(28),
            child: Text('SET', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 3,
            child: Text('PREVIOUS', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text(isCardio ? 'MIN' : 'KG', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text(isCardio ? 'KM' : 'REPS', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(width: context.scale(28)),
          SizedBox(width: context.scale(24)),
        ],
      ),
    );
  }
}

class SetRow extends StatelessWidget {
  final ActiveSet set;
  final bool isCardio;
  final int normalIndex;
  final double kcal;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const SetRow({
    super.key,
    required this.set,
    required this.isCardio,
    required this.normalIndex,
    required this.kcal,
    required this.onChanged,
    required this.onRemove,
  });

  void _cycleType() {
    set.type = switch (set.type) {
      SetType.normal => SetType.warmup,
      SetType.warmup => SetType.failure,
      SetType.failure => SetType.normal,
    };
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: set.completed ? Premium.good.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: context.scale(28),
            child: InkWell(
              onTap: _cycleType,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Container(
                  width: context.scale(24),
                  height: context.scale(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Premium.surface3,
                    border: Border.all(color: Premium.borderStrong),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    setLabel(set.type, normalIndex),
                    style: Premium.body(11, weight: FontWeight.w600, color: setLabelColor(context, set.type)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  set.previous,
                  textAlign: TextAlign.center,
                  style: Premium.body(12.5, color: Premium.textDim),
                ),
                if (set.completed)
                  Text(
                    '${kcal.toStringAsFixed(1)} kcal',
                    textAlign: TextAlign.center,
                    style: Premium.body(10, color: Premium.textFaint),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: SetField(controller: isCardio ? set.durationController : set.weightController),
          ),
          Expanded(
            flex: 2,
            child: SetField(controller: isCardio ? set.distanceController : set.repsController),
          ),
          SizedBox(
            width: context.scale(28),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                set.completed = !set.completed;
                onChanged();
              },
              icon: set.completed
                  ? Container(
                      width: context.scale(22),
                      height: context.scale(22),
                      decoration: const BoxDecoration(gradient: Premium.accentGradient, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Icon(Icons.check, size: context.scale(14), color: Premium.ink),
                    )
                  : Icon(
                      Icons.circle_outlined,
                      size: context.scale(20),
                      color: Premium.textFaint,
                    ),
            ),
          ),
          SizedBox(
            width: context.scale(24),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onRemove,
              icon: Icon(
                Icons.close,
                size: context.scale(16),
                color: Premium.textFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SetField extends StatelessWidget {
  final TextEditingController controller;

  const SetField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: Premium.body(12.5, weight: FontWeight.w600, color: Premium.text),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 7),
          filled: true,
          fillColor: Premium.surface3,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Premium.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: Border.all(color: Premium.accent.withValues(alpha: 0.5)).top,
          ),
        ),
      ),
    );
  }
}
