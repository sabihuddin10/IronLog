import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../data/body_profile_store.dart';
import '../../utils/health_formulas.dart';
import 'premium_tool_widgets.dart' show PremiumBmiInline;

class CalorieCalculatorScreen extends StatelessWidget {
  const CalorieCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BodyProfileStore>();
    final bmr = HealthFormulas.bmr(profile.weightKg, profile.heightCm, profile.age, profile.gender);
    final maintain = HealthFormulas.tdee(bmr, profile.activityLevel);

    final rows = <(String, double)>[
      ('to maintain your weight.', 0),
      ('to lose 0.5 kg per week.', -500),
      ('to lose 1 kg per week.', -1000),
      ('to gain 0.5 kg per week.', 500),
      ('to gain 1 kg per week.', 1000),
    ];

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const _ScHeader(title: 'Calorie Calculator'),
            const _ScDesc(
              'Based on your age, height, gender and activity level, this calorie '
              'calculator will estimate the number of calories you need to eat on a '
              'daily basis to maintain, gain or lose weight.',
            ),
            _AgeGenderField(profile: profile),
            _WeightRow(profile: profile),
            _HeightRow(profile: profile),
            PremiumBmiInline(profile: profile),
            _SelectRow(
              label: 'Activity',
              child: _SelectBox<ActivityLevel>(
                value: profile.activityLevel,
                items: ActivityLevel.values,
                label: (a) => a.label,
                onChanged: (v) {
                  if (v != null) profile.setActivityLevel(v);
                },
              ),
            ),
            for (final row in rows) _GoalCard(value: maintain + row.$2, suffix: row.$1),
            const SizedBox(height: 9),
            _CustomGoalCard(maintainCalories: maintain),
          ],
        ),
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

/// Label + tappable select box row (`.select-row`).
class _SelectRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _SelectRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Premium.body(context, 13.5, color: context.colors.textPrimary, weight: FontWeight.w600)),
          const SizedBox(width: 12),
          Flexible(child: child),
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
        contentPadding: const EdgeInsets.only(bottom: 8, top: 4),
        border: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.borderStrong, width: 1.5)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.borderStrong, width: 1.5)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colors.accent, width: 1.5)),
      ),
    );
  }
}

/// Circular icon toggle (`.pill-btn`), used for the gender switch.
class _PillCircle extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _PillCircle({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: active ? context.colors.accentGradient : null,
          color: active ? null : context.colors.surfaceHigh,
          border: active ? null : Border.all(color: context.colors.border),
          boxShadow: active ? context.colors.accentGlowShadow(blur: 12, spread: -4) : null,
        ),
        child: Icon(icon, size: 15, color: active ? context.colors.onAccent : context.colors.textFaint),
      ),
    );
  }
}

class _GenderPills extends StatelessWidget {
  final Gender value;
  final ValueChanged<Gender> onChanged;
  const _GenderPills({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PillCircle(icon: Icons.male, active: value == Gender.male, onTap: () => onChanged(Gender.male)),
        const SizedBox(width: 8),
        _PillCircle(icon: Icons.female, active: value == Gender.female, onTap: () => onChanged(Gender.female)),
      ],
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

/// Generic select-box trigger wrapping a native [DropdownButton] — keeps the
/// existing dropdown-menu mechanism, only restyles the tappable trigger.
class _SelectBox<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;
  final double maxWidth;

  const _SelectBox({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    this.maxWidth = 190,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 16, color: context.colors.textFaint),
          dropdownColor: context.colors.cardBackground,
          selectedItemBuilder: (context) => items
              .map(
                (it) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label(it),
                    overflow: TextOverflow.ellipsis,
                    style: Premium.body(context, 12.5, color: context.colors.textSecondary, weight: FontWeight.w500),
                  ),
                ),
              )
              .toList(),
          items: items
              .map((it) => DropdownMenuItem(value: it, child: Text(label(it), style: Premium.body(context, 13, color: context.colors.textPrimary))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Full-width gradient goal card (`.goal-card`) — presentational only, no
/// selection state exists for these preset rows in the original screen.
class _GoalCard extends StatelessWidget {
  final double value;
  final String suffix;
  const _GoalCard({required this.value, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
      decoration: BoxDecoration(
        gradient: context.colors.accentGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: context.colors.accentGlowShadow(blur: 20, spread: -12),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${value.toStringAsFixed(0)} ', style: Premium.heading(context, 14, weight: FontWeight.w700, color: context.colors.onAccent)),
            TextSpan(
              text: 'kcal/day $suffix',
              style: Premium.heading(context, 12.5, weight: FontWeight.w500, color: context.colors.onAccent.withValues(alpha: 0.8)),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Two-way segmented switch (`.segmented`), e.g. Lose / Gain.
class _Segmented2 extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final bool isLeft;
  final ValueChanged<bool> onSelect;
  const _Segmented2({required this.leftLabel, required this.rightLabel, required this.isLeft, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: context.colors.surfaceHigh, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(context, leftLabel, isLeft, () => onSelect(true)),
          _seg(context, rightLabel, !isLeft, () => onSelect(false)),
        ],
      ),
    );
  }

  Widget _seg(BuildContext context, String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? context.colors.accentGradient : null,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(label, style: Premium.body(context, 12.5, color: active ? context.colors.onAccent : context.colors.textSecondary, weight: FontWeight.w700)),
      ),
    );
  }
}

/// One row inside a `.convert-card` (`.convert-field`).
class _ConvertField extends StatelessWidget {
  final String tag;
  final TextEditingController controller;
  final String? unit;
  final ValueChanged<String>? onChanged;
  const _ConvertField({required this.tag, required this.controller, this.unit, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surfaceHigh,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(width: 34, child: Text(tag.toUpperCase(), style: Premium.body(context, 10.5, color: context.colors.textFaint, weight: FontWeight.w700))),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: onChanged,
              style: Premium.body(context, 16, color: context.colors.textPrimary, weight: FontWeight.w700),
              cursorColor: context.colors.accent,
              decoration: const InputDecoration(isDense: true, filled: false, border: InputBorder.none, contentPadding: EdgeInsets.zero),
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 8),
            Text(unit!, style: Premium.body(context, 11.5, color: context.colors.textSecondary, weight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.colors.accentDim, context.colors.accent2.withValues(alpha: 0.1)],
          ),
          border: Border.all(color: context.colors.accent.withValues(alpha: 0.28)),
          boxShadow: context.colors.accentGlowShadow(blur: 12, spread: -6),
        ),
        child: Icon(Icons.swap_vert, size: 16, color: context.colors.accent),
      ),
    );
  }
}

// ---- Age / Weight / Height field rows (own local controllers) ----

class _AgeGenderField extends StatefulWidget {
  final BodyProfileStore profile;
  const _AgeGenderField({required this.profile});

  @override
  State<_AgeGenderField> createState() => _AgeGenderFieldState();
}

class _AgeGenderFieldState extends State<_AgeGenderField> {
  late final TextEditingController _controller = TextEditingController(text: '${widget.profile.age}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FieldRow(
      label: 'Age',
      input: _UnderlineInput(
        controller: _controller,
        onChanged: (v) {
          final age = int.tryParse(v);
          if (age != null) widget.profile.setAge(age);
        },
      ),
      trailing: _GenderPills(value: widget.profile.gender, onChanged: widget.profile.setGender),
    );
  }
}

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

class _HeightRow extends StatefulWidget {
  final BodyProfileStore profile;
  const _HeightRow({required this.profile});

  @override
  State<_HeightRow> createState() => _HeightRowState();
}

class _HeightRowState extends State<_HeightRow> {
  late final TextEditingController _cmController = TextEditingController(text: widget.profile.heightCm.toStringAsFixed(0));
  late final TextEditingController _ftController = TextEditingController(text: '${widget.profile.heightFeet}');
  late final TextEditingController _inController =
      TextEditingController(text: widget.profile.heightRemainderInches.toStringAsFixed(0));

  @override
  void dispose() {
    _cmController.dispose();
    _ftController.dispose();
    _inController.dispose();
    super.dispose();
  }

  void _applyFtIn() {
    final ft = int.tryParse(_ftController.text) ?? 0;
    final inch = double.tryParse(_inController.text) ?? 0;
    widget.profile.setHeightFtIn(ft, inch);
  }

  @override
  Widget build(BuildContext context) {
    final ft = widget.profile.heightInFt;
    return _FieldRow(
      label: 'Height',
      input: ft
          ? Row(
              children: [
                Expanded(child: _UnderlineInput(controller: _ftController, onChanged: (_) => _applyFtIn())),
                const SizedBox(width: 8),
                Expanded(child: _UnderlineInput(controller: _inController, onChanged: (_) => _applyFtIn())),
              ],
            )
          : _UnderlineInput(
              controller: _cmController,
              onChanged: (v) {
                final cm = double.tryParse(v);
                if (cm != null) widget.profile.setHeightCm(cm);
              },
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitPill(
            label: 'CM',
            active: !ft,
            onTap: () {
              widget.profile.toggleHeightUnit(false);
              setState(() => _cmController.text = widget.profile.heightCm.toStringAsFixed(0));
            },
          ),
          const SizedBox(width: 6),
          _UnitPill(
            label: 'FT',
            active: ft,
            onTap: () {
              widget.profile.toggleHeightUnit(true);
              setState(() {
                _ftController.text = '${widget.profile.heightFeet}';
                _inController.text = widget.profile.heightRemainderInches.toStringAsFixed(0);
              });
            },
          ),
        ],
      ),
    );
  }
}

// ---- Custom goal converter (rate <-> calories, unchanged math) ----

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
class _CustomGoalCard extends StatefulWidget {
  final double maintainCalories;
  const _CustomGoalCard({required this.maintainCalories});

  @override
  State<_CustomGoalCard> createState() => _CustomGoalCardState();
}

class _CustomGoalCardState extends State<_CustomGoalCard> {
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
  void didUpdateWidget(covariant _CustomGoalCard oldWidget) {
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
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: context.colors.cardGradient,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: Premium.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOM GOAL',
            style: Premium.body(context, 11, color: context.colors.textFaint, weight: FontWeight.w700).copyWith(letterSpacing: 0.6),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Segmented2(
                leftLabel: 'Lose',
                rightLabel: 'Gain',
                isLeft: _goal == _Goal.lose,
                onSelect: (left) => setState(() {
                  _goal = left ? _Goal.lose : _Goal.gain;
                  _syncCaloriesFromRate();
                }),
              ),
              _SelectBox<_Period>(
                value: _period,
                items: _Period.values,
                label: (p) => 'per ${p.label}',
                maxWidth: 110,
                onChanged: (p) {
                  if (p == null) return;
                  setState(() => _period = p);
                  _syncCaloriesFromRate();
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ConvertField(
            tag: 'Goal',
            controller: _rateController,
            unit: 'kg',
            onChanged: (_) {
              if (_updating) return;
              _syncCaloriesFromRate();
              setState(() {});
            },
          ),
          const _SwapButton(),
          _ConvertField(
            tag: '=',
            controller: _caloriesController,
            unit: 'kcal/day',
            onChanged: (_) {
              if (_updating) return;
              _syncRateFromCalories();
            },
          ),
        ],
      ),
    );
  }
}
