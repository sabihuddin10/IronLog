import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_state.dart';
import '../../core/app_spacing.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../core/premium_widgets.dart';
import '../../core/responsive.dart';
import '../../models/workout.dart';
import '../../repositories/workout_repository.dart';
import '../exercises/exercise_library_screen.dart';
import '../tools/weight_tracker_screen.dart';
import '../workouts/active_workout_session.dart';
import '../workouts/workout_detail_screen.dart';
import 'statistics_screen.dart';
import 'theme_settings_screen.dart';
import 'workout_calendar_screen.dart';

enum _Metric { volume, reps, duration }

enum _Period { threeMonths, sixMonths, oneYear }

extension on _Period {
  String get label => switch (this) {
    _Period.threeMonths => 'Last 3 months',
    _Period.sixMonths => 'Last 6 months',
    _Period.oneYear => 'Last year',
  };

  int get weeks => switch (this) {
    _Period.threeMonths => 12,
    _Period.sixMonths => 26,
    _Period.oneYear => 52,
  };
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Workout>> _future;
  late final ActiveWorkoutSession _session;
  bool _sessionWasActive = false;
  _Metric _metric = _Metric.volume;
  _Period _period = _Period.threeMonths;

  @override
  void initState() {
    super.initState();
    _future = context.read<WorkoutRepository>().list();
    _session = context.read<ActiveWorkoutSession>();
    _sessionWasActive = _session.isActive;
    _session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  // This tab stays alive (never disposed) in RootScreen's IndexedStack, so
  // finishing a workout from another tab wouldn't otherwise refetch it.
  void _onSessionChanged() {
    if (_sessionWasActive && !_session.isActive) _refresh();
    _sessionWasActive = _session.isActive;
  }

  Future<void> _refresh() async {
    final future = context.read<WorkoutRepository>().list();
    setState(() => _future = future);
    await future;
  }

  DateTime _weekStart(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: date.weekday - 1));
  }

  int _totalReps(Workout w) => w.exercises.fold(
    0,
    (sum, e) => sum + e.sets.fold(0, (s, set) => s + (set.reps ?? 0)),
  );

  /// Consecutive days (walking back from today, tolerating today itself not
  /// having a workout logged yet) with at least one workout.
  int _streakDays(List<Workout> workouts) {
    final days = workouts.map((w) {
      final d = w.startedAt.toLocal();
      return DateTime(d.year, d.month, d.day);
    }).toSet();
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Appearance'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ThemeSettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () {
                Navigator.of(context).pop();
                context.read<AuthState>().signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final email = auth.user?.email ?? '';

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: context.colors.accent,
          backgroundColor: context.colors.cardBackground,
          child: FutureBuilder<List<Workout>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: context.colors.accent));
              }
              final workouts = <Workout>[...snapshot.data ?? []]
                ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  context.scale(AppSpacing.lg),
                  context.scale(AppSpacing.sm),
                  context.scale(AppSpacing.lg),
                  108,
                ),
                children: [
                  _Header(email: email, onMenu: () => _openMenu(context)),
                  SizedBox(height: context.scale(AppSpacing.xl)),
                  _StatsRow(
                    workouts: workouts.length,
                    thisWeek: workouts
                        .where(
                          (w) =>
                              _weekStart(w.startedAt.toLocal()) ==
                              _weekStart(DateTime.now()),
                        )
                        .length,
                    streakDays: _streakDays(workouts),
                  ),
                  SizedBox(height: context.scale(AppSpacing.xxl)),
                  _VolumeChartCard(
                    workouts: workouts,
                    metric: _metric,
                    period: _period,
                    weekStartOf: _weekStart,
                    totalRepsOf: _totalReps,
                    onMetricChanged: (m) => setState(() => _metric = m),
                    onPeriodChanged: (p) => setState(() => _period = p),
                  ),
                  SizedBox(height: context.scale(AppSpacing.xxl)),
                  Text('Dashboard', style: Premium.heading(context, 16)),
                  SizedBox(height: context.scale(AppSpacing.md)),
                  _DashboardGrid(workouts: workouts),
                  SizedBox(height: context.scale(AppSpacing.xxl)),
                  Text('Workouts', style: Premium.heading(context, 16)),
                  SizedBox(height: context.scale(AppSpacing.md)),
                  if (workouts.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: context.scale(AppSpacing.xxl),
                      ),
                      child: Center(
                        child: Text(
                          'No workouts logged yet.',
                          style: Premium.body(context, 13, color: context.colors.textSecondary),
                        ),
                      ),
                    )
                  else
                    for (final w in workouts.take(5)) ...[
                      _WorkoutHistoryCard(workout: w),
                      SizedBox(height: context.scale(AppSpacing.md)),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String email;
  final VoidCallback onMenu;

  const _Header({required this.email, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final name = email.isEmpty ? '?' : email.split('@').first;
    return Row(
      children: [
        Container(
          width: context.scale(56),
          height: context.scale(56),
          decoration: BoxDecoration(gradient: context.colors.accentGradient, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: Premium.heading(context, 22, color: context.colors.onAccent),
          ),
        ),
        SizedBox(width: context.scale(AppSpacing.md)),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: Premium.heading(context, 20),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onMenu,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: context.colors.cardBackground, borderRadius: BorderRadius.circular(9)),
            child: Icon(Icons.settings_outlined, size: 17, color: context.colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int workouts;
  final int thisWeek;
  final int streakDays;

  const _StatsRow({
    required this.workouts,
    required this.thisWeek,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Stat(label: 'Workouts', value: '$workouts')),
        Expanded(child: _Stat(label: 'This Week', value: '$thisWeek')),
        Expanded(child: _Stat(label: 'Streak', value: '$streakDays d')),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Premium.heading(context, 19)),
        const SizedBox(height: 2),
        Text(label, style: Premium.body(context, 12, color: context.colors.textSecondary)),
      ],
    );
  }
}

class _VolumeChartCard extends StatelessWidget {
  final List<Workout> workouts;
  final _Metric metric;
  final _Period period;
  final DateTime Function(DateTime) weekStartOf;
  final int Function(Workout) totalRepsOf;
  final ValueChanged<_Metric> onMetricChanged;
  final ValueChanged<_Period> onPeriodChanged;

  const _VolumeChartCard({
    required this.workouts,
    required this.metric,
    required this.period,
    required this.weekStartOf,
    required this.totalRepsOf,
    required this.onMetricChanged,
    required this.onPeriodChanged,
  });

  double _metricOf(Workout w) => switch (metric) {
    _Metric.volume => w.totalVolume,
    _Metric.reps => totalRepsOf(w).toDouble(),
    _Metric.duration => w.duration.inMinutes.toDouble(),
  };

  String get _unit => switch (metric) {
    _Metric.volume => 'kg',
    _Metric.reps => 'reps',
    _Metric.duration => 'min',
  };

  Future<void> _pickPeriod(BuildContext context) async {
    final choice = await showModalBottomSheet<_Period>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in _Period.values)
              ListTile(
                title: Text(p.label),
                trailing: p == period ? Icon(Icons.check, color: context.colors.accent) : null,
                onTap: () => Navigator.of(context).pop(p),
              ),
          ],
        ),
      ),
    );
    if (choice != null) onPeriodChanged(choice);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentWeekStart = weekStartOf(now);
    final weekStarts = List.generate(
      period.weeks,
      (i) =>
          currentWeekStart.subtract(Duration(days: 7 * (period.weeks - 1 - i))),
    );

    final totals = <DateTime, double>{for (final ws in weekStarts) ws: 0};
    for (final w in workouts) {
      final ws = weekStartOf(w.startedAt.toLocal());
      if (totals.containsKey(ws)) totals[ws] = totals[ws]! + _metricOf(w);
    }

    final thisWeekTotal = totals[currentWeekStart] ?? 0;
    final maxY = totals.values.fold(0.0, (a, b) => a > b ? a : b);
    final barWidth = context.scale(18.0);
    final chartWidth = (period.weeks * context.scale(36.0)).clamp(
      context.scale(280.0),
      double.infinity,
    );

    return PremiumCard(
      padding: EdgeInsets.all(context.scale(AppSpacing.lg)),
      radius: Premium.radiusXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: Premium.heading(context, 22),
                    children: [
                      TextSpan(text: '${thisWeekTotal.toStringAsFixed(0)} $_unit '),
                      TextSpan(text: 'this week', style: Premium.body(context, 12.5, color: context.colors.textSecondary)),
                    ],
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => _pickPeriod(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceHigh,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(period.label, style: Premium.body(context, 12, color: context.colors.textSecondary)),
                      Icon(Icons.expand_more, size: 15, color: context.colors.textFaint),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.scale(AppSpacing.lg)),
          SizedBox(
            height: context.scale(160),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: SizedBox(
                width: chartWidth,
                child: BarChart(
                  BarChartData(
                    maxY: maxY <= 0 ? 1 : maxY * 1.2,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= weekStarts.length) {
                              return const SizedBox.shrink();
                            }
                            final showEvery = (weekStarts.length / 6).ceil().clamp(1, 100);
                            if (i % showEvery != 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                DateFormat.Md().format(weekStarts[i]),
                                style: Premium.body(context, 10.5, color: context.colors.textFaint),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < weekStarts.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: totals[weekStarts[i]] ?? 0,
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: i == weekStarts.length - 1
                                    ? [context.colors.accent, context.colors.accent2]
                                    : [
                                        context.colors.accent.withValues(alpha: 0.28),
                                        context.colors.accent2.withValues(alpha: 0.28),
                                      ],
                              ),
                              width: barWidth,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: context.scale(AppSpacing.md)),
          _PremiumTabs<_Metric>(
            value: metric,
            onChanged: onMetricChanged,
            labels: const {
              _Metric.volume: 'Volume',
              _Metric.reps: 'Reps',
              _Metric.duration: 'Duration',
            },
          ),
        ],
      ),
    );
  }
}

/// `.tabs` — a segmented row of equal-width tabs inside a `surface-3` track,
/// gradient-filled on the active tab.
class _PremiumTabs<T> extends StatelessWidget {
  final T value;
  final ValueChanged<T> onChanged;
  final Map<T, String> labels;

  const _PremiumTabs({required this.value, required this.onChanged, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: context.colors.surfaceHigh, borderRadius: BorderRadius.circular(11)),
      child: Row(
        children: [
          for (final entry in labels.entries)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => onChanged(entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: entry.key == value ? context.colors.accentGradient : null,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.value,
                    style: Premium.body(context, 
                      12.5,
                      weight: entry.key == value ? FontWeight.w700 : FontWeight.w500,
                      color: entry.key == value ? context.colors.onAccent : context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  final List<Workout> workouts;

  const _DashboardGrid({required this.workouts});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: context.scale(AppSpacing.md),
      mainAxisSpacing: context.scale(AppSpacing.md),
      childAspectRatio: 2.4,
      children: [
        _DashboardTile(
          icon: Icons.show_chart,
          label: 'Statistics',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StatisticsScreen(workouts: workouts),
            ),
          ),
        ),
        _DashboardTile(
          icon: Icons.fitness_center,
          label: 'Exercises',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
          ),
        ),
        _DashboardTile(
          icon: Icons.monitor_weight_outlined,
          label: 'Measures',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WeightTrackerScreen()),
          ),
        ),
        _DashboardTile(
          icon: Icons.calendar_month_outlined,
          label: 'Calendar',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkoutCalendarScreen(workouts: workouts),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.symmetric(horizontal: context.scale(AppSpacing.lg)),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: context.colors.accent, size: 20),
          SizedBox(width: context.scale(AppSpacing.md)),
          Expanded(
            child: Text(label, style: Premium.body(context, 14, color: context.colors.textPrimary, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _WorkoutHistoryCard extends StatelessWidget {
  final Workout workout;

  const _WorkoutHistoryCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.all(context.scale(AppSpacing.lg)),
      radius: Premium.radiusLg,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(workout: workout),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(workout.name, style: Premium.heading(context, 14.5)),
          const SizedBox(height: 2),
          Text(
            DateFormat.yMMMd().add_jm().format(workout.startedAt.toLocal()),
            style: Premium.body(context, 12, color: context.colors.textSecondary),
          ),
          SizedBox(height: context.scale(AppSpacing.md)),
          Row(
            children: [
              _MiniStat(
                label: 'Time',
                value: workout.duration.inMinutes > 0 ? '${workout.duration.inMinutes}min' : '-',
              ),
              _MiniStat(label: 'Volume', value: '${workout.totalVolume.toStringAsFixed(0)} kg'),
              _MiniStat(label: 'Sets', value: '${workout.totalSets}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Premium.body(context, 13, weight: FontWeight.w700, color: context.colors.textPrimary)),
          Text(label, style: Premium.body(context, 11, color: context.colors.textSecondary)),
        ],
      ),
    );
  }
}
