import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/premium_theme.dart';
import '../../data/body_profile_store.dart';
import '../../utils/health_formulas.dart';
import 'premium_tool_widgets.dart';

class BmiCalculatorScreen extends StatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  State<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends State<BmiCalculatorScreen> {
  bool _useNewFormula = true;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BodyProfileStore>();
    final result = HealthFormulas.bmi(
      profile.weightKg,
      profile.heightCm,
      profile.gender,
      profile.age,
      _useNewFormula,
    );
    final category = HealthFormulas.bmiCategoryLabel(result.bmi);

    return ToolScreenScaffold(
      title: 'BMI Calculator',
      description: const PremiumScDesc(
        spans: [
          TextSpan(text: 'Body mass index (BMI) is a measure of body fat based on your weight in relation to your height.\n'),
          TextSpan(text: 'Standard Formula: ', style: TextStyle(color: Premium.textFaint, fontWeight: FontWeight.w600)),
          TextSpan(text: 'Traditional method.\n'),
          TextSpan(text: 'New Formula: ', style: TextStyle(color: Premium.textFaint, fontWeight: FontWeight.w600)),
          TextSpan(text: 'More accurate recent method.'),
        ],
      ),
      children: [
        PremiumAgeGenderField(profile: profile),
        PremiumWeightField(profile: profile),
        PremiumHeightField(profile: profile),
        PremiumSelectRow(
          label: 'BMI Method',
          value: _useNewFormula ? 'New formula' : 'Standard formula',
          onTap: () async {
            final choice = await showPremiumPicker<bool>(
              context: context,
              title: 'BMI Method',
              options: const [false, true],
              labelOf: (v) => v ? 'New formula' : 'Standard formula',
              selected: _useNewFormula,
            );
            if (choice != null) setState(() => _useNewFormula = choice);
          },
        ),
        PremiumResultBannerPair(
          leftLabel: 'BMI',
          leftValue: result.bmi.toStringAsFixed(1),
          rightLabel: 'Fat%',
          rightValue: result.bodyFatPercent.toStringAsFixed(1),
        ),
        PremiumCatList(
          rows: [
            for (final c in HealthFormulas.bmiCategories)
              PremiumCatRowData(label: c.$1, value: _rangeLabel(c.$2, c.$3), active: c.$1 == category),
          ],
        ),
        PremiumInfoBanner(text: HealthFormulas.bmiAdvice(result.bmi)),
        _BmiWeightConverter(
          heightCm: profile.heightCm,
          useNewFormula: _useNewFormula,
          initialBmi: result.bmi,
        ),
      ],
    );
  }

  String _rangeLabel(double low, double high) {
    if (low == double.negativeInfinity) return '< $high';
    if (high == double.infinity) return '$low +';
    return '$low - $high';
  }
}

/// Two-way linked target-BMI <-> target-weight converter at a fixed height:
/// editing the target BMI recomputes the weight needed to hit it, and
/// editing the target weight recomputes the BMI it implies. Same math as the
/// original `BmiWeightConverter` widget, restyled to match the `.convert-card`
/// spec.
class _BmiWeightConverter extends StatefulWidget {
  final double heightCm;
  final bool useNewFormula;
  final double initialBmi;

  const _BmiWeightConverter({
    required this.heightCm,
    required this.useNewFormula,
    required this.initialBmi,
  });

  @override
  State<_BmiWeightConverter> createState() => _BmiWeightConverterState();
}

class _BmiWeightConverterState extends State<_BmiWeightConverter> {
  final _bmiController = TextEditingController();
  final _weightController = TextEditingController();
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _bmiController.text = widget.initialBmi.toStringAsFixed(1);
    _syncWeightFromBmi();
  }

  @override
  void didUpdateWidget(covariant _BmiWeightConverter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.heightCm != widget.heightCm || oldWidget.useNewFormula != widget.useNewFormula) {
      // Height or formula changed: keep the target BMI fixed, recompute the weight for it.
      _syncWeightFromBmi();
    }
  }

  @override
  void dispose() {
    _bmiController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  double _weightForBmi(double bmiValue) => widget.useNewFormula
      ? HealthFormulas.weightForBmiNew(bmiValue, widget.heightCm)
      : HealthFormulas.weightForBmiStandard(bmiValue, widget.heightCm);

  double _bmiForWeight(double weightKg) => widget.useNewFormula
      ? HealthFormulas.bmiNew(weightKg, widget.heightCm)
      : HealthFormulas.bmiStandard(weightKg, widget.heightCm);

  void _syncWeightFromBmi() {
    final bmiValue = double.tryParse(_bmiController.text) ?? 0;
    _updating = true;
    _weightController.text = _weightForBmi(bmiValue).toStringAsFixed(1);
    _updating = false;
  }

  void _syncBmiFromWeight() {
    final weightKg = double.tryParse(_weightController.text);
    if (weightKg == null) return;
    _updating = true;
    _bmiController.text = _bmiForWeight(weightKg).toStringAsFixed(1);
    _updating = false;
  }

  @override
  Widget build(BuildContext context) {
    return PremiumConvertCard(
      label: 'Target BMI ↔ weight',
      children: [
        PremiumConvertField(
          tag: 'BMI',
          controller: _bmiController,
          onChanged: (_) {
            if (_updating) return;
            _syncWeightFromBmi();
            setState(() {});
          },
        ),
        const PremiumConvertSwapIcon(),
        PremiumConvertField(
          tag: '=',
          controller: _weightController,
          unit: 'kg',
          onChanged: (_) {
            if (_updating) return;
            _syncBmiFromWeight();
            setState(() {});
          },
        ),
      ],
    );
  }
}
