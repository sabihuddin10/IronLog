import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../core/premium_widgets.dart';
import '../../models/weight_goal.dart';
import '../../models/weight_log.dart';
import '../../repositories/weight_goal_repository.dart';
import '../../repositories/weight_repository.dart';

enum _Range { twoW, oneM, threeM, sixM, oneY, all }

extension on _Range {
  String get longLabel => switch (this) {
        _Range.twoW => 'Last 2 weeks',
        _Range.oneM => 'Last month',
        _Range.threeM => 'Last 3 months',
        _Range.sixM => 'Last 6 months',
        _Range.oneY => 'Last year',
        _Range.all => 'All time',
      };

  int? get days => switch (this) {
        _Range.twoW => 14,
        _Range.oneM => 30,
        _Range.threeM => 90,
        _Range.sixM => 180,
        _Range.oneY => 365,
        _Range.all => null,
      };
}

/// `.ldelta.up` — literal spec color for a weight-gain arrow (not part of
/// the shared [Premium] palette, only used for this one glyph).
const _deltaUpColor = Color(0xFFFF9A7A);

typedef _TrackerData = ({List<WeightLog> logs, List<WeightGoal> goals, List<WeightGoal> newlyAchieved});

class WeightTrackerScreen extends StatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  State<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends State<WeightTrackerScreen> {
  _Range _range = _Range.all;
  late Future<_TrackerData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = _loadData();

  Future<_TrackerData> _loadData() async {
    final goalRepo = context.read<WeightGoalRepository>();
    final results = await Future.wait([
      context.read<WeightRepository>().list(),
      goalRepo.list(),
    ]);
    final logs = results[0] as List<WeightLog>;
    var goals = results[1] as List<WeightGoal>;

    if (logs.isEmpty) return (logs: logs, goals: goals, newlyAchieved: const <WeightGoal>[]);

    final current = ([...logs]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt))).last.weight;
    final newlyAchieved = <WeightGoal>[];
    final updated = <WeightGoal>[];
    for (final goal in goals) {
      if (!goal.achieved && goal.isMetBy(current)) {
        final achieved = await goalRepo.markAchieved(goal.id, DateTime.now());
        newlyAchieved.add(achieved);
        updated.add(achieved);
      } else {
        updated.add(goal);
      }
    }
    goals = updated;

    return (logs: logs, goals: goals, newlyAchieved: newlyAchieved);
  }

  Future<void> _addRecord() async {
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    DateTime date = DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add a Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setDialogState(() => date = picked);
                },
                child: Text(DateFormat.yMMMd().format(date)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text);
                if (weight == null) return;
                await context.read<WeightRepository>().create(
                      weight: weight,
                      unit: 'kg',
                      loggedAt: date,
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    );
                if (context.mounted) Navigator.of(context).pop(true);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) setState(_load);
  }

  Future<void> _openGoalDialog({WeightGoal? existing, required double currentWeight}) async {
    final targetController = TextEditingController(
      text: existing != null ? existing.targetWeightKg.toString() : '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Goal' : 'Edit Goal'),
        content: TextField(
          controller: targetController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Target weight (kg)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final target = double.tryParse(targetController.text);
              if (target == null) return;
              final repo = context.read<WeightGoalRepository>();
              if (existing == null) {
                await repo.create(targetWeightKg: target, startWeightKg: currentWeight);
              } else {
                await repo.update(existing.id, targetWeightKg: target);
              }
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) setState(_load);
  }

  Future<void> _deleteGoal(WeightGoal goal) async {
    await context.read<WeightGoalRepository>().delete(goal.id);
    if (mounted) setState(_load);
  }

  Future<void> _celebrate(List<WeightGoal> newlyAchieved) async {
    for (final goal in newlyAchieved) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: context.colors.accentGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: context.colors.accentGlowShadow(),
            ),
            child: Icon(Icons.emoji_events, size: 24, color: context.colors.onAccent),
          ),
          title: const Text('Goal Achieved!'),
          content: Text('You reached your target of ${goal.targetWeightKg.toStringAsFixed(1)} kg.'),
          actions: [
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Nice!')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: _GradientFab(onTap: _addRecord),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_TrackerData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: context.colors.accent));
            }
            final data = snapshot.data;
            final allLogs = <WeightLog>[...data?.logs ?? const []]
              ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
            final goals = data?.goals ?? const <WeightGoal>[];

            if (data != null && data.newlyAchieved.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate(data.newlyAchieved));
            }

            if (allLogs.isEmpty) {
              return Column(
                children: [
                  _ScreenHeader(title: 'Weight Tracker'),
                  Expanded(
                    child: Center(
                      child: Text('No weight entries yet.', style: TextStyle(color: context.colors.textSecondary)),
                    ),
                  ),
                ],
              );
            }

            final days = _range.days;
            final logs = days == null
                ? allLogs
                : allLogs.where((l) => DateTime.now().difference(l.loggedAt).inDays <= days).toList();
            final effective = logs.isEmpty ? allLogs : logs;

            final current = effective.last.weight;
            final average = effective.map((l) => l.weight).reduce((a, b) => a + b) / effective.length;
            final change = effective.length > 1 ? effective.last.weight - effective.first.weight : 0.0;

            WeightGoal? activeGoal;
            for (final goal in goals) {
              if (!goal.achieved) {
                activeGoal = goal;
                break;
              }
            }
            activeGoal ??= goals.isNotEmpty ? goals.first : null;
            final remaining = activeGoal != null ? current - activeGoal.targetWeightKg : null;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              children: [
                _ScreenHeader(title: 'Weight Tracker'),
                const SizedBox(height: 6),
                _ChartCard(
                  current: current,
                  average: average,
                  goal: activeGoal?.targetWeightKg,
                  logs: effective,
                  range: _range,
                  onRangeChanged: (r) => setState(() => _range = r),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBlock(label: 'Average', value: '${average.toStringAsFixed(1)} kg'),
                    _StatBlock(label: 'Current', value: '${current.toStringAsFixed(1)} kg', emphasize: true),
                    if (activeGoal != null)
                      _StatBlock(label: 'Goal', value: '${activeGoal.targetWeightKg.toStringAsFixed(1)} kg'),
                  ],
                ),
                if (remaining != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatBlock(
                        label: 'Change',
                        value: '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
                      ),
                      _StatBlock(label: 'Remaining', value: '${remaining.abs().toStringAsFixed(1)} kg'),
                    ],
                  ),
                ],
                if (activeGoal != null && activeGoal.achieved) ...[
                  const SizedBox(height: 20),
                  _CelebrateCard(goal: activeGoal, current: current),
                ],
                if (activeGoal != null) ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('Goal progress'),
                  _GoalProgress(goal: activeGoal, current: current),
                ],
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Goals', style: Premium.heading(context, 16)),
                    _IconChipButton(
                      icon: Icons.add,
                      onTap: () => _openGoalDialog(currentWeight: current),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (goals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'No goals yet. Add one to track your progress.',
                      style: Premium.body(context, 12.5, color: context.colors.textSecondary),
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final goal in goals)
                        _GoalTile(
                          goal: goal,
                          currentWeight: current,
                          onEdit: () => _openGoalDialog(existing: goal, currentWeight: current),
                          onDelete: () => _deleteGoal(goal),
                        ),
                    ],
                  ),
                const SizedBox(height: 22),
                const _SectionTitle('Weight log'),
                _LogList(logs: allLogs),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// `.sc-header` — back chevron in a rounded surface chip + page title.
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
                  color: context.colors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.colors.border),
                ),
                child: Icon(Icons.arrow_back, size: 16, color: context.colors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(title, style: Premium.heading(context, 19)),
        ],
      ),
    );
  }
}

/// `.section-title h2`.
class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label, style: Premium.heading(context, 16)),
    );
  }
}

/// Small circular gradient FAB — accent gradient with glow, matching the
/// spec's primary-action styling.
class _GradientFab extends StatelessWidget {
  final VoidCallback onTap;

  const _GradientFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Ink(
          decoration: BoxDecoration(
            gradient: context.colors.accentGradient,
            shape: BoxShape.circle,
            boxShadow: context.colors.accentGlowShadow(blur: 18, spread: -2),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Icon(Icons.add, color: context.colors.onAccent),
          ),
        ),
      ),
    );
  }
}

/// A small square icon button chip, e.g. `.cal-nav .cnav-btn`.
class _IconChipButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconChipButton({required this.icon, required this.onTap});

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
            color: context.colors.cardBackground,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: context.colors.border),
          ),
          child: Icon(icon, size: 16, color: context.colors.textSecondary),
        ),
      ),
    );
  }
}

/// Mirrors the "days to next birthday"-style stat: a big bold value with a
/// small caption underneath.
class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _StatBlock({required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Premium.heading(context, 18, color: emphasize ? context.colors.accent : context.colors.textPrimary),
        ),
        const SizedBox(height: 3),
        Text(label, style: Premium.body(context, 11, color: context.colors.textFaint)),
      ],
    );
  }
}

/// `.chart-card` — big current-value header, a range dropdown, and a
/// gradient bar chart underneath.
class _ChartCard extends StatelessWidget {
  final double current;
  final double average;
  final double? goal;
  final List<WeightLog> logs;
  final _Range range;
  final ValueChanged<_Range> onRangeChanged;

  const _ChartCard({
    required this.current,
    required this.average,
    required this.goal,
    required this.logs,
    required this.range,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: Premium.radiusXl,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Premium.heading(context, 22),
                  children: [
                    TextSpan(text: current.toStringAsFixed(1)),
                    TextSpan(text: ' kg', style: Premium.body(context, 12.5, color: context.colors.textSecondary)),
                  ],
                ),
              ),
              PopupMenuButton<_Range>(
                initialValue: range,
                onSelected: onRangeChanged,
                color: context.colors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Premium.radiusMd),
                  side: BorderSide(color: context.colors.border),
                ),
                itemBuilder: (context) => [
                  for (final r in _Range.values)
                    PopupMenuItem(
                      value: r,
                      child: Text(
                        r.longLabel,
                        style: Premium.body(context, 
                          13,
                          color: r == range ? context.colors.accent : context.colors.textPrimary,
                          weight: r == range ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceHigh,
                    border: Border.all(color: context.colors.border),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(range.longLabel, style: Premium.body(context, 12, color: context.colors.textSecondary)),
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more, size: 14, color: context.colors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: _WeightChart(logs: logs, average: average, goal: goal),
          ),
        ],
      ),
    );
  }
}

/// The `.bars` gradient bar chart. Renders one bar per [logs] entry (same
/// data the previous line chart plotted) with dashed reference lines for
/// [average] and [goal] — a like-for-like visual swap, not a data change.
class _WeightChart extends StatelessWidget {
  final List<WeightLog> logs;
  final double average;
  final double? goal;

  const _WeightChart({required this.logs, required this.average, required this.goal});

  @override
  Widget build(BuildContext context) {
    final barGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [context.colors.accent, context.colors.accent2],
    );
    final values = logs.map((l) => l.weight).toList()..addAll([average, ?goal]);
    final minY = values.reduce((a, b) => a < b ? a : b) - 3;
    final maxY = values.reduce((a, b) => a > b ? a : b) + 3;
    final barWidth = (280 / logs.length).clamp(6.0, 26.0);

    return BarChart(
      BarChartData(
        minY: minY,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (logs.length / 4).clamp(1, double.infinity).roundToDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= logs.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.Md().format(logs[i].loggedAt),
                    style: Premium.body(context, 10.5, color: context.colors.textFaint),
                  ),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: average,
              color: context.colors.textFaint,
              strokeWidth: 1.5,
              dashArray: const [6, 4],
            ),
            if (goal != null)
              HorizontalLine(
                y: goal!,
                color: context.colors.success,
                strokeWidth: 1.5,
                dashArray: const [6, 4],
              ),
          ],
        ),
        barGroups: [
          for (var i = 0; i < logs.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: logs[i].weight,
                  gradient: barGradient,
                  width: barWidth,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                    bottomLeft: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// `.celebrate-card` — shown when the active goal has been reached.
class _CelebrateCard extends StatelessWidget {
  final WeightGoal goal;
  final double current;

  const _CelebrateCard({required this.goal, required this.current});

  @override
  Widget build(BuildContext context) {
    final delta = (goal.startWeightKg - current).abs();
    final direction = goal.startWeightKg >= goal.targetWeightKg ? 'down' : 'up';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Color.lerp(context.colors.surface, context.colors.accent, 0.22)!, context.colors.surface]
              : [Color.lerp(Colors.white, context.colors.accent, 0.08)!, Colors.white],
        ),
        borderRadius: BorderRadius.circular(Premium.radiusXxl),
        border: Border.all(color: context.colors.accent.withValues(alpha: isDark ? 0.25 : 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: context.colors.accentGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: context.colors.accentGlowShadow(),
            ),
            child: Icon(Icons.emoji_events, size: 23, color: context.colors.onAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\u{1F389} Goal reached!', style: Premium.heading(context, 14, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'You hit your target weight of ${goal.targetWeightKg.toStringAsFixed(1)} kg '
                  '— ${delta.toStringAsFixed(1)} kg $direction since you started. Amazing consistency.',
                  style: Premium.body(context, 11.5, color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.progress-track` / `.progress-fill` / `.progress-labels`.
class _GoalProgress extends StatelessWidget {
  final WeightGoal goal;
  final double current;

  const _GoalProgress({required this.goal, required this.current});

  @override
  Widget build(BuildContext context) {
    final start = goal.startWeightKg;
    final target = goal.targetWeightKg;
    final totalDelta = (target - start).abs();
    final fraction = totalDelta == 0 ? 1.0 : ((current - start).abs() / totalDelta).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: double.infinity,
            height: 8,
            color: context.colors.surfaceHigh,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  gradient: context.colors.accentGradient,
                  boxShadow: [BoxShadow(color: context.colors.accentGlow, blurRadius: 10)],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Start · ${start.toStringAsFixed(1)} kg', style: Premium.body(context, 11, color: context.colors.textFaint, weight: FontWeight.w600)),
            Text.rich(
              TextSpan(
                style: Premium.body(context, 11, color: context.colors.textFaint, weight: FontWeight.w600),
                children: [
                  const TextSpan(text: 'Now · '),
                  TextSpan(
                    text: '${current.toStringAsFixed(1)} kg',
                    style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Text('Goal · ${target.toStringAsFixed(1)} kg', style: Premium.body(context, 11, color: context.colors.textFaint, weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _GoalTile extends StatelessWidget {
  final WeightGoal goal;
  final double currentWeight;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalTile({
    required this.goal,
    required this.currentWeight,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (currentWeight - goal.targetWeightKg).abs();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        radius: Premium.radiusMd,
        onTap: onEdit,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: goal.achieved
                    ? context.colors.accentGradient
                    : LinearGradient(
                        colors: [context.colors.accentDim, context.colors.accent.withValues(alpha: 0.05)],
                      ),
                borderRadius: BorderRadius.circular(11),
                border: goal.achieved ? null : Border.all(color: context.colors.accent.withValues(alpha: 0.18)),
              ),
              child: Icon(
                goal.achieved ? Icons.emoji_events : Icons.flag_outlined,
                size: 17,
                color: goal.achieved ? context.colors.onAccent : context.colors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${goal.targetWeightKg.toStringAsFixed(1)} kg', style: Premium.heading(context, 14)),
                  const SizedBox(height: 2),
                  Text(
                    goal.achieved
                        ? 'Achieved ${DateFormat.yMMMd().format(goal.achievedAt!)}'
                        : '${remaining.toStringAsFixed(1)} kg to go',
                    style: Premium.body(context, 11.5, color: context.colors.textSecondary),
                  ),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.delete_outline, size: 18, color: context.colors.textFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.log-list` / `.log-row` — newest entry first, with a colored delta
/// arrow versus the previous chronological entry.
class _LogList extends StatelessWidget {
  final List<WeightLog> logs;

  const _LogList({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = logs.length - 1; i >= 0; i--)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LogRow(
              log: logs[i],
              previous: i > 0 ? logs[i - 1] : null,
            ),
          ),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  final WeightLog log;
  final WeightLog? previous;

  const _LogRow({required this.log, required this.previous});

  @override
  Widget build(BuildContext context) {
    final delta = previous != null ? log.weight - previous!.weight : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        gradient: context.colors.cardGradient,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(Premium.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat.MMMd().format(log.loggedAt), style: Premium.body(context, 12.5, color: context.colors.textSecondary, weight: FontWeight.w600)),
          Row(
            children: [
              Text('${log.weight.toStringAsFixed(1)} kg', style: Premium.heading(context, 14, weight: FontWeight.w700)),
              if (delta != null && delta != 0) ...[
                const SizedBox(width: 8),
                Text(
                  delta < 0 ? '↓${delta.abs().toStringAsFixed(1)}' : '↑${delta.toStringAsFixed(1)}',
                  style: Premium.body(context, 
                    11,
                    weight: FontWeight.w700,
                    color: delta < 0 ? context.colors.success : _deltaUpColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
