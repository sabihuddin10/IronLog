import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../core/premium_widgets.dart';
import '../../data/body_profile_store.dart';
import '../../utils/health_formulas.dart';
import 'premium_tool_widgets.dart' show PremiumBmiInline;

class NutrientCalculatorScreen extends StatelessWidget {
  const NutrientCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BodyProfileStore>();
    final bmr = HealthFormulas.bmr(profile.weightKg, profile.heightCm, profile.age, profile.gender);
    final calories = HealthFormulas.tdee(bmr, profile.activityLevel);

    final adaProtein = HealthFormulas.adaProteinRangeGrams(profile.weightKg);
    final cdcProtein = HealthFormulas.cdcProteinRangeGrams(calories);
    final carbs = HealthFormulas.carbRangeGrams(calories);
    final fat = HealthFormulas.fatRangeGrams(calories);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            const _ScHeader(title: 'Nutrient Calculator'),
            const _ScDesc(
              'The Nutrient Calculator estimates the daily amount of dietary nutrients '
              'you require to remain healthy, based on your body profile and activity level.',
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
            _CalorieAllowanceBanner(calories: calories),
            _NutrientSection(
              icon: Icons.egg_outlined,
              title: 'Protein Intake',
              rows: [
                ('ADA · based on your weight', '${adaProtein.$1.toStringAsFixed(0)} - ${adaProtein.$2.toStringAsFixed(0)} g'),
                ('CDC · based on your Calories', '${cdcProtein.$1.toStringAsFixed(0)} - ${cdcProtein.$2.toStringAsFixed(0)} g'),
              ],
              body: 'Based on your weight, the American Dietetic Association (ADA) recommends '
                  'taking at least ${adaProtein.$1.toStringAsFixed(0)} - ${adaProtein.$2.toStringAsFixed(0)} '
                  'grams of protein per day.\n\n'
                  'Based on your conditions, the Centers for Disease Control and Prevention (CDC) '
                  'recommend taking ${cdcProtein.$1.toStringAsFixed(0)} - ${cdcProtein.$2.toStringAsFixed(0)} '
                  'grams of protein per day, which is 10% - 35% of your daily Calorie intake.',
            ),
            _NutrientSection(
              icon: Icons.grain,
              title: 'Carbohydrate Intake',
              rows: [
                ('45% - 65% of daily Calories', '${carbs.$1.toStringAsFixed(0)} - ${carbs.$2.toStringAsFixed(0)} g'),
              ],
              body: 'It is recommended that carbohydrates make up 45% - 65% of your daily '
                  'Calorie intake, which is about ${carbs.$1.toStringAsFixed(0)} - '
                  '${carbs.$2.toStringAsFixed(0)} grams per day.',
            ),
            _NutrientSection(
              icon: Icons.water_drop_outlined,
              title: 'Fat Intake',
              rows: [
                ('20% - 35% of daily Calories', '${fat.$1.toStringAsFixed(0)} - ${fat.$2.toStringAsFixed(0)} g'),
              ],
              body: 'It is recommended that fat make up 20% - 35% of your daily Calorie '
                  'intake, which is about ${fat.$1.toStringAsFixed(0)} - ${fat.$2.toStringAsFixed(0)} '
                  'grams per day.',
            ),
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
        contentPadding: EdgeInsets.only(bottom: 8, top: 4),
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


/// Gradient highlight banner for the total daily calorie allowance
/// (`.result-banner` vocabulary), sitting above the nutrient breakdown.
class _CalorieAllowanceBanner extends StatelessWidget {
  final double calories;
  const _CalorieAllowanceBanner({required this.calories});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 19),
      decoration: BoxDecoration(
        gradient: context.colors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.colors.accentGlowShadow(blur: 26, spread: -12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAILY CALORIE ALLOWANCE',
            style: Premium.body(context, 10, color: context.colors.onAccent.withValues(alpha: 0.65), weight: FontWeight.w700).copyWith(letterSpacing: 0.6),
          ),
          const SizedBox(height: 2),
          Text('${calories.toStringAsFixed(0)} kcal', style: Premium.heading(context, 22, weight: FontWeight.w700, color: context.colors.onAccent)),
        ],
      ),
    );
  }
}

/// One nutrient breakdown card: icon + title, a `.cat-list`-style table of
/// the computed ranges, then the full explanatory copy below.
class _NutrientSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<(String, String)> rows;
  final String body;

  const _NutrientSection({required this.icon, required this.title, required this.rows, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: context.colors.cardGradient,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: Premium.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PremiumIconChip(icon: icon, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Premium.heading(context, 15, weight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 14),
          _CatList(rows: rows),
          const SizedBox(height: 12),
          Text(body, style: Premium.body(context, 12, color: context.colors.textSecondary).copyWith(height: 1.55)),
        ],
      ),
    );
  }
}

/// Bordered list of label/value rows (`.cat-list` / `.cat-row`).
class _CatList extends StatelessWidget {
  final List<(String, String)> rows;
  const _CatList({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                border: i == rows.length - 1 ? null : Border(bottom: BorderSide(color: context.colors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(rows[i].$1, style: Premium.body(context, 12.5, color: context.colors.textSecondary, weight: FontWeight.w500))),
                  const SizedBox(width: 10),
                  Text(
                    rows[i].$2,
                    style: Premium.body(context, 12.5, color: context.colors.accent, weight: FontWeight.w700)
                        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ),
        ],
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
