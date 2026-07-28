import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../data/body_profile_store.dart';
import '../../../utils/health_formulas.dart';
import 'profile_form_widgets.dart';

/// Compact, always-on-screen summary of the user's saved body profile (BMI +
/// category + one-line advice), reusing the same [HealthFormulas.bmi] math
/// as `bmi_calculator_screen.dart`. Dropped into other calculator screens
/// (Walk Planner, BMR, Calorie, Nutrient, ...) right after the
/// weight/height/age fields, so the profile that's about to drive that
/// screen's own calculation is visible first, not just silently read.
class BmiSummaryCard extends StatelessWidget {
  final BodyProfileStore profile;

  const BmiSummaryCard({required this.profile, super.key});

  @override
  Widget build(BuildContext context) {
    final result = HealthFormulas.bmi(
      profile.weightKg,
      profile.heightCm,
      profile.gender,
      profile.age,
      true,
    );
    final category = HealthFormulas.bmiCategoryLabel(result.bmi);

    return ResultBanner(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BMI  ${result.bmi.toStringAsFixed(1)}  ·  $category'),
              Text('${profile.weightKg.toStringAsFixed(1)} kg'),
            ],
          ),
          SizedBox(height: context.scale(4)),
          Text(
            HealthFormulas.bmiAdvice(result.bmi),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
