import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../data/body_profile_store.dart';
import '../../utils/health_formulas.dart';
import 'premium_tool_widgets.dart' show PremiumBmiInline, PremiumCatList, PremiumCatRowData;

enum _Mode { calories, pace, duration }

enum _PaceUnit { kmh, mph, minPerKm }

/// Solves the ACSM walk/run calorie equation in one of three directions,
/// picked via a mode selector rather than a naive "edit any of 4 fields"
/// solver — distance, pace and duration aren't 3 independent variables
/// (distance = pace x duration), so only one mode is ever solving for a
/// truly free unknown at a time.
class WalkCaloriePlannerScreen extends StatefulWidget {
  const WalkCaloriePlannerScreen({super.key});

  @override
  State<WalkCaloriePlannerScreen> createState() => _WalkCaloriePlannerScreenState();
}

class _WalkCaloriePlannerScreenState extends State<WalkCaloriePlannerScreen> {
  _Mode _mode = _Mode.calories;
  _PaceUnit _paceUnit = _PaceUnit.kmh;
  bool _distanceInMiles = false;

  final _distanceController = TextEditingController(text: '3');
  final _durationController = TextEditingController(text: '30');
  final _caloriesController = TextEditingController(text: '200');
  final _paceController = TextEditingController(text: '5');

  @override
  void dispose() {
    _distanceController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _paceController.dispose();
    super.dispose();
  }

  double get _distanceKm {
    final v = double.tryParse(_distanceController.text) ?? 0;
    return _distanceInMiles ? HealthFormulas.milesToKm(v) : v;
  }

  double get _durationMinutes => double.tryParse(_durationController.text) ?? 0;

  double get _targetCalories => double.tryParse(_caloriesController.text) ?? 0;

  double get _paceMetersPerMin {
    final v = double.tryParse(_paceController.text) ?? 0;
    return switch (_paceUnit) {
      _PaceUnit.kmh => HealthFormulas.kmhToMetersPerMin(v),
      _PaceUnit.mph => HealthFormulas.mphToMetersPerMin(v),
      _PaceUnit.minPerKm => HealthFormulas.paceMinPerKmToMetersPerMin(v),
    };
  }

  String _formatPace(double metersPerMin) => switch (_paceUnit) {
        _PaceUnit.kmh => '${HealthFormulas.metersPerMinToKmh(metersPerMin).toStringAsFixed(1)} km/h',
        _PaceUnit.mph => '${HealthFormulas.metersPerMinToMph(metersPerMin).toStringAsFixed(1)} mph',
        _PaceUnit.minPerKm =>
          '${HealthFormulas.metersPerMinToPaceMinPerKm(metersPerMin).toStringAsFixed(1)} min/km',
      };

  String _formatDistance(double km) => _distanceInMiles
      ? '${HealthFormulas.kmToMiles(km).toStringAsFixed(2)} mi'
      : '${km.toStringAsFixed(2)} km';

  void _setDistanceUnit(bool miles) {
    if (miles == _distanceInMiles) return;
    final currentKm = _distanceKm;
    setState(() {
      _distanceInMiles = miles;
      final display = miles ? HealthFormulas.kmToMiles(currentKm) : currentKm;
      _distanceController.text = display.toStringAsFixed(2);
    });
  }

  void _setPaceUnit(_PaceUnit unit) {
    if (unit == _paceUnit) return;
    final currentMetersPerMin = _paceMetersPerMin;
    setState(() {
      _paceUnit = unit;
      final display = switch (unit) {
        _PaceUnit.kmh => HealthFormulas.metersPerMinToKmh(currentMetersPerMin),
        _PaceUnit.mph => HealthFormulas.metersPerMinToMph(currentMetersPerMin),
        _PaceUnit.minPerKm => HealthFormulas.metersPerMinToPaceMinPerKm(currentMetersPerMin),
      };
      _paceController.text = display.toStringAsFixed(1);
    });
  }

  String _bmiRangeLabel(double low, double high) {
    if (low == double.negativeInfinity) return '< $high';
    if (high == double.infinity) return '$low +';
    return '$low - $high';
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BodyProfileStore>();
    final bmrValue = HealthFormulas.bmr(profile.weightKg, profile.heightCm, profile.age, profile.gender);

    String resultMain;
    String resultSub;
    double currentSpeedMetersPerMin;
    switch (_mode) {
      case _Mode.calories:
        final speed = _durationMinutes > 0 ? _distanceKm * 1000 / _durationMinutes : 0.0;
        currentSpeedMetersPerMin = speed;
        final kcal = HealthFormulas.totalWalkKcal(
          weightKg: profile.weightKg,
          speedMetersPerMin: speed,
          durationMinutes: _durationMinutes,
          bmrValue: bmrValue,
        );
        resultMain = '${kcal.toStringAsFixed(0)} kcal burned';
        resultSub = 'at a pace of ${_formatPace(speed)}';
      case _Mode.pace:
        final speed = HealthFormulas.speedForKcalTarget(
          weightKg: profile.weightKg,
          durationMinutes: _durationMinutes,
          bmrValue: bmrValue,
          targetKcal: _targetCalories,
        );
        currentSpeedMetersPerMin = speed;
        final distanceKm = speed * _durationMinutes / 1000;
        resultMain = 'Walk/run at ${_formatPace(speed)}';
        resultSub = 'covering ${_formatDistance(distanceKm)}';
      case _Mode.duration:
        final speed = _paceMetersPerMin;
        currentSpeedMetersPerMin = speed;
        final duration = HealthFormulas.durationMinutesForKcalTarget(
          weightKg: profile.weightKg,
          speedMetersPerMin: speed,
          bmrValue: bmrValue,
          targetKcal: _targetCalories,
        );
        final distanceKm = speed * duration / 1000;
        resultMain = '${duration.toStringAsFixed(0)} minutes needed';
        resultSub = 'covering ${_formatDistance(distanceKm)}';
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const _ScHeader(title: 'Walk Planner'),
            const _ScDesc(
              'Estimate calories burned, pace, or time for your walk or run. Uses your '
              'weight, height, age and gender for a more accurate estimate.',
            ),
            _Segmented3(mode: _mode, onChanged: (m) => setState(() => _mode = m)),
            _WeightRow(profile: profile),
            PremiumBmiInline(profile: profile),
            PremiumCatList(
              rows: [
                for (final c in HealthFormulas.bmiCategories)
                  PremiumCatRowData(
                    label: c.$1,
                    value: _bmiRangeLabel(c.$2, c.$3),
                    active: c.$1 == HealthFormulas.bmiCategoryLabel(
                      HealthFormulas.bmi(profile.weightKg, profile.heightCm, profile.gender, profile.age, true).bmi,
                    ),
                  ),
              ],
            ),
            // Distance is a free input only in "calories" mode; in the other two
            // modes it's a derived output shown in the result banner instead.
            if (_mode == _Mode.calories)
              _FieldRow(
                label: 'Distance',
                input: _UnderlineInput(controller: _distanceController, onChanged: (_) => setState(() {})),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _UnitPill(label: 'KM', active: !_distanceInMiles, onTap: () => _setDistanceUnit(false)),
                    const SizedBox(width: 6),
                    _UnitPill(label: 'MI', active: _distanceInMiles, onTap: () => _setDistanceUnit(true)),
                  ],
                ),
              ),
            // Pace is a free input only in "duration" mode; in the other two
            // modes it's derived (an output in "pace" mode, or used to compute
            // speed from distance/duration in "calories" mode).
            if (_mode == _Mode.duration) ...[
              _FieldRow(
                label: 'Pace',
                input: _UnderlineInput(controller: _paceController, onChanged: (_) => setState(() {})),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 22, top: 2),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _UnitPill(
                        label: 'KM/H',
                        active: _paceUnit == _PaceUnit.kmh,
                        onTap: () => _setPaceUnit(_PaceUnit.kmh),
                      ),
                      _UnitPill(
                        label: 'MPH',
                        active: _paceUnit == _PaceUnit.mph,
                        onTap: () => _setPaceUnit(_PaceUnit.mph),
                      ),
                      _UnitPill(
                        label: '/KM',
                        active: _paceUnit == _PaceUnit.minPerKm,
                        onTap: () => _setPaceUnit(_PaceUnit.minPerKm),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // Duration is a free input in "calories" and "pace" modes; in
            // "duration" mode it's the value being solved for.
            if (_mode == _Mode.calories || _mode == _Mode.pace)
              _FieldRow(
                label: 'Duration',
                input: _UnderlineInput(controller: _durationController, onChanged: (_) => setState(() {})),
                trailing: Text('min', style: Premium.body(context, 13, color: context.colors.textFaint, weight: FontWeight.w500)),
              ),
            // Target calories is a free input in "pace" and "duration" modes;
            // in "calories" mode it's the value being solved for.
            if (_mode == _Mode.pace || _mode == _Mode.duration)
              _FieldRow(
                label: 'Target',
                input: _UnderlineInput(controller: _caloriesController, onChanged: (_) => setState(() {})),
                trailing: Text('kcal', style: Premium.body(context, 13, color: context.colors.textFaint, weight: FontWeight.w500)),
              ),
            _ResultBanner(main: resultMain, sub: resultSub),
            const SizedBox(height: 8),
            Text('Calories vs. pace', style: Premium.body(context, 12, color: context.colors.textSecondary, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: _CaloriePaceCurve(
                weightKg: profile.weightKg,
                bmrValue: bmrValue,
                currentSpeedMetersPerMin: currentSpeedMetersPerMin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live, formula-driven curve of calories burned per hour across a range of
/// paces at the current weight/BMR — no stored data, just the same
/// [HealthFormulas.totalWalkKcal] equation the calculator above uses,
/// evaluated at each point. The current input is highlighted so the user can
/// see where they sit on the curve, not just read a single number.
class _CaloriePaceCurve extends StatelessWidget {
  final double weightKg;
  final double bmrValue;
  final double currentSpeedMetersPerMin;

  const _CaloriePaceCurve({
    required this.weightKg,
    required this.bmrValue,
    required this.currentSpeedMetersPerMin,
  });

  static const _minKmh = 1.0;
  static const _maxKmh = 12.0;

  double _kcalPerHourAt(double kmh) {
    final speed = HealthFormulas.kmhToMetersPerMin(kmh);
    return HealthFormulas.totalWalkKcal(
      weightKg: weightKg,
      speedMetersPerMin: speed,
      durationMinutes: 60,
      bmrValue: bmrValue,
    );
  }

  @override
  Widget build(BuildContext context) {
    const steps = 22;
    final spots = <FlSpot>[
      for (var i = 0; i <= steps; i++)
        FlSpot(
          _minKmh + (_maxKmh - _minKmh) * i / steps,
          _kcalPerHourAt(_minKmh + (_maxKmh - _minKmh) * i / steps),
        ),
    ];

    final currentKmh = HealthFormulas.metersPerMinToKmh(currentSpeedMetersPerMin).clamp(_minKmh, _maxKmh);
    final currentKcal = _kcalPerHourAt(currentKmh);
    final axisLabelStyle = Premium.body(context, 9.5, color: context.colors.textFaint, weight: FontWeight.w600);

    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        gridData: const FlGridData(drawVerticalLine: false, drawHorizontalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 2,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(value.toStringAsFixed(0), style: axisLabelStyle),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: axisLabelStyle),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: context.colors.accentGradient,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
        extraLinesData: ExtraLinesData(
          verticalLines: [
            VerticalLine(x: currentKmh, color: context.colors.danger.withValues(alpha: 0.55), strokeWidth: 1.5, dashArray: [4, 4]),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => context.colors.cardBackground,
            tooltipRoundedRadius: 12,
            tooltipBorder: BorderSide(color: context.colors.accent.withValues(alpha: 0.3), width: 1),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            tooltipMargin: 12,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) => touchedSpots
                .map(
                  (spot) => LineTooltipItem(
                    '${spot.y.round()} kcal',
                    TextStyle(color: context.colors.accent, fontWeight: FontWeight.w700, fontSize: 13),
                    children: [
                      TextSpan(
                        text: '\nat ${spot.x.toStringAsFixed(1)} km/h',
                        style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.w500, fontSize: 11),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
        showingTooltipIndicators: [
          ShowingTooltipIndicators([
            LineBarSpot(
              LineChartBarData(spots: spots, color: context.colors.accent),
              0,
              FlSpot(currentKmh, currentKcal),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Shared sub-screen header — back chevron + title (`.sc-header`).
class _ScHeader extends StatelessWidget {
  final String title;
  const _ScHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.colors.cardBackground,
                border: Border.all(color: context.colors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back, size: 16, color: context.colors.textSecondary),
            ),
          ),
          const SizedBox(width: 14),
          Text(title, style: Premium.heading(context, 19)),
        ],
      ),
    );
  }
}

/// Descriptive paragraph under the header (`.sc-desc`).
class _ScDesc extends StatelessWidget {
  final String text;
  const _ScDesc(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Text(text, style: Premium.body(context, 12.5, color: context.colors.textSecondary).copyWith(height: 1.6)),
    );
  }
}

/// Label + input + trailing pill group (`.field-row`).
class _FieldRow extends StatelessWidget {
  final String label;
  final Widget input;
  final Widget? trailing;
  const _FieldRow({required this.label, required this.input, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 64, child: Text(label, style: Premium.body(context, 13.5, color: context.colors.textPrimary, weight: FontWeight.w600))),
          const SizedBox(width: 14),
          Expanded(child: input),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

/// Underlined numeric input (`.field-row input.underline`).
class _UnderlineInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  const _UnderlineInput({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: Premium.body(context, 16, color: context.colors.textPrimary, weight: FontWeight.w600),
      cursorColor: context.colors.accent,
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: EdgeInsets.only(bottom: 8, top: 4),
        border: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.borderStrong, width: 1.5)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.borderStrong, width: 1.5)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.accent, width: 1.5)),
      ),
    );
  }
}

/// Pill-shaped unit toggle (`.unit-pill`).
class _UnitPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _UnitPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? context.colors.accentGradient : null,
          color: active ? null : context.colors.surfaceHigh,
          border: active ? null : Border.all(color: context.colors.border),
          borderRadius: BorderRadius.circular(20),
          boxShadow: active ? context.colors.accentGlowShadow(blur: 12, spread: -4) : null,
        ),
        child: Text(label, style: Premium.body(context, 10.5, color: active ? context.colors.onAccent : context.colors.textFaint, weight: FontWeight.w700)),
      ),
    );
  }
}

/// Equal-width 3-way tab switcher (`.segmented3`) — Cal / Pace / Time.
class _Segmented3 extends StatelessWidget {
  final _Mode mode;
  final ValueChanged<_Mode> onChanged;
  const _Segmented3({required this.mode, required this.onChanged});

  static const _entries = [
    (_Mode.calories, 'Cal'),
    (_Mode.pace, 'Pace'),
    (_Mode.duration, 'Time'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: context.colors.surfaceHigh, borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: [
          for (final e in _entries)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(e.$1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: mode == e.$1 ? context.colors.accentGradient : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    e.$2,
                    textAlign: TextAlign.center,
                    style: Premium.body(context, 12, color: mode == e.$1 ? context.colors.onAccent : context.colors.textSecondary, weight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Centered/stacked gradient result banner (`.result-banner.centered`).
class _ResultBanner extends StatelessWidget {
  final String main;
  final String sub;
  const _ResultBanner({required this.main, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 19),
      decoration: BoxDecoration(
        gradient: context.colors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.accentGlowShadow(blur: 26, spread: -12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(main, style: Premium.heading(context, 20, weight: FontWeight.w700, color: context.colors.onAccent)),
          const SizedBox(height: 4),
          Text(sub, style: Premium.body(context, 11.5, color: context.colors.onAccent.withValues(alpha: 0.75), weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ---- Weight field row (own local controller) ----

class _WeightRow extends StatefulWidget {
  final BodyProfileStore profile;
  const _WeightRow({required this.profile});

  @override
  State<_WeightRow> createState() => _WeightRowState();
}

class _WeightRowState extends State<_WeightRow> {
  late final TextEditingController _controller = TextEditingController(
    text: (widget.profile.weightInLbs ? widget.profile.weightLbs : widget.profile.weightKg).toStringAsFixed(1),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    final value = widget.profile.weightInLbs ? widget.profile.weightLbs : widget.profile.weightKg;
    _controller.text = value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return _FieldRow(
      label: 'Weight',
      input: _UnderlineInput(
        controller: _controller,
        onChanged: (v) {
          final value = double.tryParse(v);
          if (value == null) return;
          if (widget.profile.weightInLbs) {
            widget.profile.setWeightLbs(value);
          } else {
            widget.profile.setWeightKg(value);
          }
        },
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitPill(
            label: 'KG',
            active: !widget.profile.weightInLbs,
            onTap: () {
              widget.profile.toggleWeightUnit(false);
              setState(_refresh);
            },
          ),
          const SizedBox(width: 6),
          _UnitPill(
            label: 'LBS',
            active: widget.profile.weightInLbs,
            onTap: () {
              widget.profile.toggleWeightUnit(true);
              setState(_refresh);
            },
          ),
        ],
      ),
    );
  }
}
