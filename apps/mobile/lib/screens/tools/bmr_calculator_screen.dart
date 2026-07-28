import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/body_profile_store.dart';
import '../../utils/health_formulas.dart';
import 'premium_tool_widgets.dart';

class BmrCalculatorScreen extends StatelessWidget {
  const BmrCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BodyProfileStore>();
    final bmr = HealthFormulas.bmr(profile.weightKg, profile.heightCm, profile.age, profile.gender);
    final tdee = HealthFormulas.tdee(bmr, profile.activityLevel);

    return ToolScreenScaffold(
      title: 'BMR Calculator',
      description: const PremiumScDesc(
        spans: [
          TextSpan(
            text: "Your BMR (Basal Metabolic Rate) is an estimate of how many calories you'd burn if you were to do "
                "nothing but rest for 24 hours. It represents the minimum amount of energy needed to keep your body "
                "functioning, including breathing and keeping your heart beating.",
          ),
        ],
      ),
      children: [
        PremiumAgeGenderField(profile: profile),
        PremiumWeightField(profile: profile),
        PremiumHeightField(profile: profile),
        PremiumBmiInline(profile: profile),
        PremiumSelectRow(
          label: 'Activity',
          value: profile.activityLevel.label,
          onTap: () async {
            final choice = await showPremiumPicker<ActivityLevel>(
              context: context,
              title: 'Activity level',
              options: ActivityLevel.values,
              labelOf: (a) => a.label,
              selected: profile.activityLevel,
            );
            if (choice != null) profile.setActivityLevel(choice);
          },
        ),
        PremiumResultBannerCentered(
          value: '${bmr.toStringAsFixed(0)} kcal/day',
          subtitle: 'energy burned at complete rest',
        ),
        PremiumCatList(
          rows: [
            PremiumCatRowData(label: 'Mifflin-St Jeor', value: '${bmr.toStringAsFixed(0)} kcal', active: true),
          ],
        ),
        const PremiumInfoBanner(
          text: 'Mifflin-St Jeor is the formula most recommended by dietitians today — it\'s used above as your default estimate.',
        ),
        PremiumResultBannerCentered(
          value: '${tdee.toStringAsFixed(0)} kcal/day',
          subtitle: 'TDEE — estimated daily calories burned at your activity level',
        ),
      ],
    );
  }
}
