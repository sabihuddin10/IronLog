import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/premium_theme.dart';
import '../../models/workout.dart';
import '../workouts/workout_detail_screen.dart';

class WorkoutCalendarScreen extends StatefulWidget {
  final List<Workout> workouts;

  const WorkoutCalendarScreen({super.key, required this.workouts});

  @override
  State<WorkoutCalendarScreen> createState() => _WorkoutCalendarScreenState();
}

class _WorkoutCalendarScreenState extends State<WorkoutCalendarScreen> {
  late DateTime _month;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  Map<DateTime, List<Workout>> get _byDay {
    final map = <DateTime, List<Workout>>{};
    for (final w in widget.workouts) {
      final d = w.startedAt.toLocal();
      final key = DateTime(d.year, d.month, d.day);
      (map[key] ??= []).add(w);
    }
    return map;
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final byDay = _byDay;
    final firstOfMonth = DateTime(_month.year, _month.month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1;
    final selectedWorkouts = _selectedDay != null ? byDay[_selectedDay] ?? [] : <Workout>[];

    return Scaffold(
      backgroundColor: Premium.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _ScreenHeader(title: 'Calendar'),
            const SizedBox(height: 6),
            _CalNav(
              label: DateFormat.yMMMM().format(_month),
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Center(
                      child: Text(
                        label,
                        style: Premium.body(10, color: Premium.textFaint, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
                for (var day = 1; day <= daysInMonth; day++)
                  Builder(
                    builder: (context) {
                      final date = DateTime(_month.year, _month.month, day);
                      final hasWorkout = byDay.containsKey(date);
                      final isSelected = _selectedDay == date;
                      return _CalDay(
                        day: day,
                        hasWorkout: hasWorkout,
                        isSelected: isSelected,
                        onTap: hasWorkout ? () => setState(() => _selectedDay = date) : null,
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 22),
            if (_selectedDay != null) ...[
              Text(DateFormat.yMMMd().format(_selectedDay!), style: Premium.heading(14)),
              const SizedBox(height: 12),
              for (final w in selectedWorkouts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LastWorkoutRow(
                    workout: w,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: w)),
                    ),
                  ),
                ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Tap a highlighted day to see that workout.',
                    style: Premium.body(12.5, color: Premium.textDim),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// `.sc-header` — back chevron chip + page title.
class _ScreenHeader extends StatelessWidget {
  final String title;

  const _ScreenHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Premium.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Premium.border),
                ),
                child: const Icon(Icons.arrow_back, size: 16, color: Premium.textDim),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(title, style: Premium.heading(19)),
        ],
      ),
    );
  }
}

/// `.cal-nav` — chevron buttons either side of the month label.
class _CalNav extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _CalNav({required this.label, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavButton(icon: Icons.chevron_left, onTap: onPrev),
        Text(label, style: Premium.heading(15)),
        _NavButton(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

/// `.cal-nav .cnav-btn`.
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Premium.surface2,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Premium.border),
          ),
          child: Icon(icon, size: 16, color: Premium.textDim),
        ),
      ),
    );
  }
}

/// `.cal-day` — circular day cell; gradient fill when selected, a soft
/// accent tint when it has a logged workout (and is tappable).
class _CalDay extends StatelessWidget {
  final int day;
  final bool hasWorkout;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CalDay({
    required this.day,
    required this.hasWorkout,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected ? Premium.accentGradient : null,
              color: isSelected ? null : (hasWorkout ? Premium.accent.withValues(alpha: 0.12) : null),
              boxShadow: isSelected ? Premium.accentGlowShadow(blur: 12, spread: -4) : null,
            ),
            child: Text(
              '$day',
              style: Premium.body(
                12.5,
                color: isSelected ? Premium.ink : (hasWorkout ? Premium.text : Premium.textDim),
                weight: isSelected ? FontWeight.w700 : (hasWorkout ? FontWeight.w600 : FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.last-workout` — gradient icon chip, title/subtitle, trailing chevron.
class _LastWorkoutRow extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const _LastWorkoutRow({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: Premium.cardGradient,
            border: Border.all(color: Premium.border),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: Premium.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: Premium.accentGlowShadow(),
                ),
                child: Icon(Icons.fitness_center, size: 19, color: Premium.ink),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name, style: Premium.heading(14.5, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${workout.totalSets} sets · ${workout.totalVolume.toStringAsFixed(0)} kg',
                      style: Premium.body(12, color: Premium.textDim),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Premium.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
