import 'package:flutter/material.dart';
import 'profile_form_widgets.dart';

enum _Goal { lose, gain }

enum _Period {
  hour(1 / 24, 'hour'),
  day(1, 'day'),
  week(7, 'week'),
  month(30.44, 'month'),
  year(365.25, 'year');

  const _Period(this.days, this.label);
  final double days;
  final String label;
}

/// Two-way linked goal-rate <-> calories converter: editing the weight-change
/// rate (or its period) recomputes the daily calorie target, and editing the
/// calorie target recomputes the equivalent rate, at a fixed 7000 kcal/kg
/// (matches the 500/1000 kcal preset rows above, which imply the same rate).
class WeightGoalConverter extends StatefulWidget {
  final double maintainCalories;
  const WeightGoalConverter({required this.maintainCalories, super.key});

  @override
  State<WeightGoalConverter> createState() => _WeightGoalConverterState();
}

class _WeightGoalConverterState extends State<WeightGoalConverter> {
  static const _kcalPerKg = 7000.0;

  _Goal _goal = _Goal.lose;
  _Period _period = _Period.week;
  final _rateController = TextEditingController(text: '0.5');
  final _caloriesController = TextEditingController();
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _syncCaloriesFromRate();
  }

  @override
  void didUpdateWidget(covariant WeightGoalConverter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maintainCalories != widget.maintainCalories) {
      _syncCaloriesFromRate();
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _syncCaloriesFromRate() {
    final rate = double.tryParse(_rateController.text) ?? 0;
    final sign = _goal == _Goal.lose ? -1 : 1;
    final dailyDelta = sign * rate * _kcalPerKg / _period.days;
    _updating = true;
    _caloriesController.text = (widget.maintainCalories + dailyDelta).round().toString();
    _updating = false;
  }

  void _syncRateFromCalories() {
    final calories = double.tryParse(_caloriesController.text);
    if (calories == null) return;
    final dailyDelta = calories - widget.maintainCalories;
    final rate = dailyDelta.abs() * _period.days / _kcalPerKg;
    // Hour/day rates are tiny in kg; show more decimals so they don't round to 0.
    final decimals = _period.days < 1 ? 4 : (_period.days == 1 ? 3 : 2);
    _updating = true;
    _rateController.text = rate.toStringAsFixed(decimals);
    _updating = false;
    setState(() => _goal = dailyDelta <= 0 ? _Goal.lose : _Goal.gain);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Custom goal', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              _TextPill(
                label: 'Lose',
                selected: _goal == _Goal.lose,
                onTap: () => setState(() {
                  _goal = _Goal.lose;
                  _syncCaloriesFromRate();
                }),
              ),
              const SizedBox(width: 6),
              _TextPill(
                label: 'Gain',
                selected: _goal == _Goal.gain,
                onTap: () => setState(() {
                  _goal = _Goal.gain;
                  _syncCaloriesFromRate();
                }),
              ),
              const Spacer(),
              const Text('per'),
              DropdownButton<_Period>(
                value: _period,
                underline: const SizedBox.shrink(),
                items: _Period.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(' ${p.label}')))
                    .toList(),
                onChanged: (p) {
                  if (p == null) return;
                  setState(() => _period = p);
                  _syncCaloriesFromRate();
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: UnderlineNumberField(
                  controller: _rateController,
                  onChanged: (_) {
                    if (_updating) return;
                    _syncCaloriesFromRate();
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('kg'),
            ],
          ),
          const SizedBox(height: 4),
          const Icon(Icons.swap_vert, size: 20),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('='),
              const SizedBox(width: 8),
              Expanded(
                child: UnderlineNumberField(
                  controller: _caloriesController,
                  onChanged: (_) {
                    if (_updating) return;
                    _syncRateFromCalories();
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('kcal/day'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TextPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
