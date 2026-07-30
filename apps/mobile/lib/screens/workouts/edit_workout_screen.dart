import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../core/premium_widgets.dart';
import '../../data/body_profile_store.dart';
import '../../data/workouts_store.dart';
import '../../models/exercise.dart';
import '../../models/workout.dart' as domain;
import '../../repositories/exercise_repository.dart';
import '../../utils/health_formulas.dart';
import 'active_workout_models.dart';
import 'exercise_card_widgets.dart';
import 'log_workout_screen.dart' show ExercisePicker;
import 'workout_calorie_helpers.dart';

/// Edits a saved workout using the exact same exercise-card UI as
/// [LogWorkoutScreen] ([ExerciseCard]/[StatsRow] — pure-presentation
/// widgets over [ActiveExercise]/[ActiveSet] that don't care whether
/// they're driven by a live [ActiveWorkoutSession] or, as here, a local
/// list built from an already-saved [domain.Workout]). This whole screen
/// *is* edit mode (reached via a pencil on the workout card/detail view),
/// so name and duration are plain always-editable fields — no in-screen
/// pencil-to-confirm-you-want-to-edit gating on top of that. Deliberately
/// mirrors [LogWorkoutScreen]'s layout piece for piece (header shape, stats
/// card, exercise cards) so the two only differ in header actions and in
/// being pre-filled with historical data — see that screen for the pieces
/// this one intentionally doesn't reinvent.
class EditWorkoutScreen extends StatefulWidget {
  final domain.Workout workout;

  const EditWorkoutScreen({super.key, required this.workout});

  @override
  State<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends State<EditWorkoutScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _durationMinutesController;
  late final TextEditingController _durationSecondsController;
  late DateTime _startedAt;
  late List<ActiveExercise> _exercises;
  List<domain.Workout> _history = [];
  bool _saving = false;

  bool _editingDuration = false;
  final FocusNode _durationMinutesFocus = FocusNode();
  final FocusNode _durationSecondsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout.name);
    _startedAt = widget.workout.startedAt;
    final duration = widget.workout.duration;
    _durationMinutesController = TextEditingController(text: '${duration.inMinutes}');
    _durationSecondsController = TextEditingController(text: '${duration.inSeconds % 60}');
    // Built synchronously first (so the screen isn't blank while history
    // loads), with '-' placeholders for "previous" — [_loadHistory] fills
    // those in with the real prior-session values once it resolves.
    _exercises = [for (final e in widget.workout.exercises) _fromDomain(e, null)];
    _loadHistory();
  }

  /// Loads this workout's siblings (everything *but* itself — otherwise it'd
  /// show up as its own "previous") so the PREVIOUS column reflects the
  /// actual session before this one, exactly like [LogWorkoutScreen] does
  /// via `ActiveWorkoutSession.history`.
  Future<void> _loadHistory() async {
    List<domain.Workout> history = [];
    try {
      final store = context.read<WorkoutsStore>();
      await store.ensureLoaded();
      history = store.workouts;
    } catch (_) {
      // "Previous" prefill is a nice-to-have; an empty history just leaves
      // the '-' placeholders in place.
    }
    history = history.where((w) => w.id != widget.workout.id).toList();
    if (!mounted) return;
    setState(() {
      _history = history;
      for (final exercise in _exercises) {
        final previousSets = previousSetsFor(exercise.name, history);
        for (var i = 0; i < exercise.sets.length; i++) {
          exercise.sets[i].previous = previousLabelAt(i, exercise.isCardio, previousSets);
        }
      }
    });
  }

  Duration get _duration => Duration(
        minutes: int.tryParse(_durationMinutesController.text) ?? 0,
        seconds: int.tryParse(_durationSecondsController.text) ?? 0,
      );

  static ActiveExercise _fromDomain(domain.WorkoutExercise e, List<domain.Workout>? history) {
    final isCardio = e.sets.isNotEmpty && e.sets.first.kind == domain.SetKind.cardio;
    final previousSets = history == null ? null : previousSetsFor(e.exerciseName, history);
    return ActiveExercise(
      exerciseId: e.exerciseId,
      name: e.exerciseName,
      isCardio: isCardio,
      sets: [
        for (var i = 0; i < e.sets.length; i++)
          ActiveSet(
            type: e.sets[i].isWarmup ? SetType.warmup : SetType.normal,
            previous: previousLabelAt(i, isCardio, previousSets),
            completed: true,
            initialWeight: e.sets[i].weight,
            initialReps: e.sets[i].reps,
            initialDurationSeconds: e.sets[i].durationSeconds,
            initialDistanceMeters: e.sets[i].distanceMeters,
          ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationMinutesController.dispose();
    _durationSecondsController.dispose();
    _durationMinutesFocus.dispose();
    _durationSecondsFocus.dispose();
    for (final e in _exercises) {
      for (final s in e.sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  static String _durationLabel(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${d.inSeconds % 60}s';
  }

  /// Tapping the date pill opens one dialog with the same calendar grid
  /// `showDatePicker` would've shown (via [CalendarDatePicker] directly, so
  /// it inherits the app's theme identically) plus an HH:MM AM/PM time row
  /// underneath — date and time set together, one OK, instead of two
  /// separate sequential dialogs.
  Future<void> _pickDateTime() async {
    final result = await showDialog<DateTime>(
      context: context,
      builder: (_) => _DateTimeDialog(initial: _startedAt),
    );
    if (result != null && mounted) {
      setState(() => _startedAt = result);
    }
  }

  void _startEditingDuration() => setState(() => _editingDuration = true);

  /// Called from each duration field's `onTapOutside`/`onSubmitted` — only
  /// actually collapses once neither field has focus (checked next frame,
  /// so tapping from the minutes field straight into the seconds field
  /// doesn't collapse it out from under you mid-edit).
  void _maybeCollapseDuration() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_durationMinutesFocus.hasFocus && !_durationSecondsFocus.hasFocus) {
        setState(() => _editingDuration = false);
      }
    });
  }

  Future<void> _addExercise() async {
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

  double get _volume {
    var total = 0.0;
    for (final e in _exercises) {
      for (final s in e.sets) {
        if (!s.completed) continue;
        final w = double.tryParse(s.weightController.text) ?? 0;
        final r = int.tryParse(s.repsController.text) ?? 0;
        total += w * r;
      }
    }
    return total;
  }

  int get _completedSetCount =>
      _exercises.fold(0, (sum, e) => sum + e.sets.where((s) => s.completed).length);

  Future<void> _save() async {
    final workoutExercises = <domain.WorkoutExercise>[];
    for (var i = 0; i < _exercises.length; i++) {
      final domainExercise = _exercises[i].toDomain(i);
      if (domainExercise != null) workoutExercises.add(domainExercise);
    }
    if (workoutExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check off at least one completed set first.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final profile = context.read<BodyProfileStore>();
      final bmrValue = HealthFormulas.bmr(profile.weightKg, profile.heightCm, profile.age, profile.gender);
      final restKcal = HealthFormulas.restingKcalPerMinute(bmrValue) * (_duration.inMilliseconds / 60000);

      final name = _nameController.text.trim();
      final updated = domain.Workout(
        id: widget.workout.id,
        name: name.isEmpty ? 'Workout' : name,
        exercises: workoutExercises,
        startedAt: _startedAt,
        completedAt: _startedAt.add(_duration),
        restKcal: restKcal,
      );
      await context.read<WorkoutsStore>().update(updated);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${widget.workout.name}"?'),
        content: const Text('This workout will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF6B5C))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<WorkoutsStore>().delete(widget.workout.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BodyProfileStore>();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            // Mirrors LogWorkoutScreen's header exactly, minus the
            // LivePulseDot (this isn't a live session) and with Save
            // instead of Finish.
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: context.colors.cardBackground,
                      borderRadius: BorderRadius.circular(9),
                    ),
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
                    ),
                    style: Premium.heading(context, 19),
                  ),
                ),
                PopupMenuButton<void>(
                  icon: Icon(Icons.more_vert, color: context.colors.textSecondary),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: _deleteWorkout,
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF6B5C)),
                          const SizedBox(width: 8),
                          Text('Delete workout', style: Premium.body(context, 14, color: const Color(0xFFFF6B5C))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.accent),
                      )
                    : PremiumGradientButton(label: 'Save', onTap: _save),
              ],
            ),
            const SizedBox(height: 14),
            // A single tappable pill — same surface/border/radius/shadow as
            // the stat card and exercise cards below it, instead of looking
            // like a bolted-on separate widget. Tapping it opens the native
            // date picker then the native time picker directly; there's no
            // in-screen expanding editor of our own to keep in sync.
            PremiumCard(
              padding: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(Premium.radiusLg),
                onTap: _pickDateTime,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.event, size: 15, color: context.colors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${DateFormat.yMMMd().format(_startedAt)} · ${DateFormat.jm().format(_startedAt)}',
                          overflow: TextOverflow.ellipsis,
                          style: Premium.body(context, 12.5, weight: FontWeight.w600, color: context.colors.textPrimary),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: context.colors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            StatsRow(
              duration: _durationLabel(_duration),
              volume: _volume,
              sets: _completedSetCount,
              calories: liveCalories(
                exercises: _exercises,
                profile: profile,
                isLiveSession: true,
                liveDuration: _duration,
              ),
              durationValue: _buildDurationStat(context),
            ),
            const SizedBox(height: 16),
            for (final exercise in _exercises) ...[
              ExerciseCard(
                exercise: exercise,
                onChanged: _refresh,
                onRemove: () => setState(() {
                  for (final s in exercise.sets) {
                    s.dispose();
                  }
                  _exercises.remove(exercise);
                }),
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
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Add exercise'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }

  /// The Duration stat cell's value widget — collapsed it's plain pink
  /// accent text with a dotted underline signaling it's tappable (no pencil
  /// icon; that clutters a 4-up stat row this tight). Tapping it swaps the
  /// text in place for two small inline number inputs, right inside the
  /// same stat card — no modal, no separate component.
  Widget _buildDurationStat(BuildContext context) {
    if (!_editingDuration) {
      return InkWell(
        onTap: _startEditingDuration,
        borderRadius: BorderRadius.circular(6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _durationLabel(_duration),
            maxLines: 1,
            softWrap: false,
            style: Premium.heading(context, 16, color: context.colors.accent).copyWith(
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationColor: context.colors.accent.withValues(alpha: 0.55),
                ),
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          child: _InlineDurationField(
            controller: _durationMinutesController,
            focusNode: _durationMinutesFocus,
            autofocus: true,
            onChanged: _refresh,
            onBlurCollapse: _maybeCollapseDuration,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('m', style: Premium.body(context, 11, color: context.colors.textSecondary)),
        ),
        SizedBox(
          width: 26,
          child: _InlineDurationField(
            controller: _durationSecondsController,
            focusNode: _durationSecondsFocus,
            onChanged: _refresh,
            onBlurCollapse: _maybeCollapseDuration,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text('s', style: Premium.body(context, 11, color: context.colors.textSecondary)),
        ),
      ],
    );
  }
}

/// A minimal number field for the Duration stat's inline editor — same
/// filled/outlined styling tokens as [SetField] (KG/REPS), just narrower to
/// fit inside a quarter-width stat cell.
class _InlineDurationField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final VoidCallback onChanged;
  final VoidCallback onBlurCollapse;

  const _InlineDurationField({
    required this.controller,
    required this.focusNode,
    this.autofocus = false,
    required this.onChanged,
    required this.onBlurCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: Premium.body(context, 12, weight: FontWeight.w600, color: context.colors.textPrimary),
      onChanged: (_) => onChanged(),
      onSubmitted: (_) => onBlurCollapse(),
      onTapOutside: (_) => onBlurCollapse(),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        filled: true,
        fillColor: context.colors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: context.colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: Border.all(color: context.colors.accent.withValues(alpha: 0.5)).top,
        ),
      ),
    );
  }
}

/// One dialog for both date and time — [CalendarDatePicker] is the same
/// grid widget `showDatePicker` builds its dialog around (so it inherits
/// the app's theme/accent identically to the stock date picker), with an
/// HH:MM AM/PM row added underneath instead of needing a second, separate
/// time dialog.
class _DateTimeDialog extends StatefulWidget {
  final DateTime initial;

  const _DateTimeDialog({required this.initial});

  @override
  State<_DateTimeDialog> createState() => _DateTimeDialogState();
}

class _DateTimeDialogState extends State<_DateTimeDialog> {
  late DateTime _date;
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late bool _isPm;

  @override
  void initState() {
    super.initState();
    _date = widget.initial;
    final tod = TimeOfDay.fromDateTime(widget.initial);
    final hour12 = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    _hourController = TextEditingController(text: hour12.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: tod.minute.toString().padLeft(2, '0'));
    _isPm = tod.period == DayPeriod.pm;
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  DateTime get _result {
    final hour12 = (int.tryParse(_hourController.text) ?? 12).clamp(1, 12);
    final minute = (int.tryParse(_minuteController.text) ?? 0).clamp(0, 59);
    var hour24 = hour12 % 12;
    if (_isPm) hour24 += 12;
    return DateTime(_date.year, _date.month, _date.day, hour24, minute);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Premium.radiusXl)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CalendarDatePicker(
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              onDateChanged: (d) => setState(() => _date = d),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 48, child: _TimeField(controller: _hourController)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(':', style: Premium.heading(context, 20)),
                  ),
                  SizedBox(width: 48, child: _TimeField(controller: _minuteController)),
                  const SizedBox(width: 14),
                  _AmPmToggle(isPm: _isPm, onChanged: (pm) => setState(() => _isPm = pm)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: Premium.body(context, 14, weight: FontWeight.w700, color: context.colors.accent)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_result),
                    child: Text('OK', style: Premium.body(context, 14, weight: FontWeight.w700, color: context.colors.accent)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final TextEditingController controller;

  const _TimeField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 2,
      style: Premium.heading(context, 20),
      decoration: const InputDecoration(counterText: '', border: InputBorder.none, isDense: true),
    );
  }
}

class _AmPmToggle extends StatelessWidget {
  final bool isPm;
  final ValueChanged<bool> onChanged;

  const _AmPmToggle({required this.isPm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: context.colors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AmPmButton(label: 'AM', selected: !isPm, onTap: () => onChanged(false)),
          _AmPmButton(label: 'PM', selected: isPm, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _AmPmButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AmPmButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected ? context.colors.accentGradient : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: Premium.body(context, 12, weight: FontWeight.w700, color: selected ? context.colors.onAccent : context.colors.textSecondary),
        ),
      ),
    );
  }
}
