import 'package:flutter/material.dart';
import '../../../utils/health_formulas.dart';
import 'profile_form_widgets.dart';

/// Two-way linked target-BMI <-> target-weight converter at a fixed height:
/// editing the target BMI recomputes the weight needed to hit it, and
/// editing the target weight recomputes the BMI it implies.
class BmiWeightConverter extends StatefulWidget {
  final double heightCm;
  final bool useNewFormula;
  final double initialBmi;

  const BmiWeightConverter({
    required this.heightCm,
    required this.useNewFormula,
    required this.initialBmi,
    super.key,
  });

  @override
  State<BmiWeightConverter> createState() => _BmiWeightConverterState();
}

class _BmiWeightConverterState extends State<BmiWeightConverter> {
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
  void didUpdateWidget(covariant BmiWeightConverter oldWidget) {
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
          Text('Target BMI ↔ weight', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('BMI'),
              const SizedBox(width: 8),
              Expanded(
                child: UnderlineNumberField(
                  controller: _bmiController,
                  onChanged: (_) {
                    if (_updating) return;
                    _syncWeightFromBmi();
                    setState(() {});
                  },
                ),
              ),
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
                  controller: _weightController,
                  onChanged: (_) {
                    if (_updating) return;
                    _syncBmiFromWeight();
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('kg'),
            ],
          ),
        ],
      ),
    );
  }
}
