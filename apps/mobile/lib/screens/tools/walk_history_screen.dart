import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../models/walk_session.dart';
import '../../repositories/walk_session_repository.dart';

enum _Range { twoW, oneM, threeM, sixM, oneY, all }

extension on _Range {
  String get label => switch (this) {
        _Range.twoW => '2W',
        _Range.oneM => '1M',
        _Range.threeM => '3M',
        _Range.sixM => '6M',
        _Range.oneY => '1Y',
        _Range.all => 'ALL',
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

enum _Metric { steps, distance, calories }

extension on _Metric {
  String get label => switch (this) {
        _Metric.steps => 'Steps',
        _Metric.distance => 'Distance',
        _Metric.calories => 'Calories',
      };

  double valueOf(WalkSession s) => switch (this) {
        _Metric.steps => s.steps.toDouble(),
        _Metric.distance => s.distanceKm,
        _Metric.calories => s.calories,
      };
}

/// Summary stats + date-range chips + metric-picker + trend chart for past
/// walk/run sessions. Shown both at the top of the Walk/Run tracker's
/// pre-start screen (so it's the first thing visible, not hidden behind
/// navigation) and inside [WalkHistoryScreen] above the full records list.
class WalkHistoryChartSection extends StatefulWidget {
  final List<WalkSession> sessions;

  const WalkHistoryChartSection({required this.sessions, super.key});

  @override
  State<WalkHistoryChartSection> createState() => _WalkHistoryChartSectionState();
}

class _WalkHistoryChartSectionState extends State<WalkHistoryChartSection> {
  _Range _range = _Range.oneM;
  _Metric _metric = _Metric.steps;

  @override
  Widget build(BuildContext context) {
    if (widget.sessions.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.scale(24)),
        child: const Center(child: Text('No walk/run sessions logged yet.')),
      );
    }

    final allSessions = <WalkSession>[...widget.sessions]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final days = _range.days;
    final sessions = days == null
        ? allSessions
        : allSessions.where((s) => DateTime.now().difference(s.startedAt).inDays <= days).toList();
    final effective = sessions.isEmpty ? allSessions : sessions;

    final totalSteps = effective.fold<int>(0, (sum, s) => sum + s.steps);
    final totalDistanceKm = effective.fold<double>(0, (sum, s) => sum + s.distanceKm);
    final totalCalories = effective.fold<double>(0, (sum, s) => sum + s.calories);
    final compact = context.isCompactWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryStat(label: 'Sessions', value: '${effective.length}'),
            _SummaryStat(label: 'Distance', value: '${totalDistanceKm.toStringAsFixed(1)} km'),
            _SummaryStat(label: 'Calories', value: totalCalories.toStringAsFixed(0)),
            _SummaryStat(label: 'Steps', value: '$totalSteps'),
          ],
        ),
        SizedBox(height: context.scale(16)),
        Wrap(
          spacing: context.scale(8),
          runSpacing: context.scale(4),
          children: [
            for (final r in _Range.values)
              ChoiceChip(
                label: Text(r.label),
                selected: _range == r,
                onSelected: (_) => setState(() => _range = r),
              ),
          ],
        ),
        SizedBox(height: context.scale(12)),
        SegmentedButton<_Metric>(
          style: ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: context.scale(compact ? 4 : 12))),
            textStyle: WidgetStatePropertyAll(TextStyle(fontSize: context.scale(compact ? 12 : 14))),
          ),
          segments: [
            for (final m in _Metric.values) ButtonSegment(value: m, label: Text(m.label)),
          ],
          selected: {_metric},
          onSelectionChanged: (s) => setState(() => _metric = s.first),
        ),
        SizedBox(height: context.scale(24)),
        SizedBox(
          height: context.scale(220),
          child: _WalkChart(sessions: effective, metric: _metric),
        ),
      ],
    );
  }
}

class WalkHistoryScreen extends StatefulWidget {
  const WalkHistoryScreen({super.key});

  @override
  State<WalkHistoryScreen> createState() => _WalkHistoryScreenState();
}

class _WalkHistoryScreenState extends State<WalkHistoryScreen> {
  late Future<List<WalkSession>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<WalkSessionRepository>().list();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Walk/Run History')),
      body: FutureBuilder<List<WalkSession>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data ?? const [];
          final sorted = <WalkSession>[...sessions]..sort((a, b) => b.startedAt.compareTo(a.startedAt));

          return ListView(
            padding: EdgeInsets.all(context.scale(16)),
            children: [
              WalkHistoryChartSection(sessions: sessions),
              if (sorted.isNotEmpty) ...[
                SizedBox(height: context.scale(24)),
                Text('Records', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: context.scale(8)),
                for (final s in sorted)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.directions_walk),
                    title: Text(
                      '${s.steps} steps · ${s.distanceKm.toStringAsFixed(2)} km · ${s.calories.toStringAsFixed(0)} kcal',
                    ),
                    subtitle: Text(DateFormat.yMMMd().add_jm().format(s.startedAt)),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: context.scale(Theme.of(context).textTheme.titleMedium?.fontSize ?? 16),
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _WalkChart extends StatelessWidget {
  final List<WalkSession> sessions;
  final _Metric metric;

  const _WalkChart({required this.sessions, required this.metric});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = <FlSpot>[
      for (var i = 0; i < sessions.length; i++) FlSpot(i.toDouble(), metric.valueOf(sessions[i])),
    ];
    final values = spots.map((s) => s.y).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY,
        gridData: const FlGridData(drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (sessions.length / 4).clamp(1, double.infinity).roundToDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= sessions.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat.Md().format(sessions[i].startedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 44),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: scheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
