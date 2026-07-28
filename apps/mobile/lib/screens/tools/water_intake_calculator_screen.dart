import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../data/body_profile_store.dart';
import '../../utils/health_formulas.dart';
import 'premium_tool_widgets.dart';

class WaterIntakeCalculatorScreen extends StatelessWidget {
  const WaterIntakeCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BodyProfileStore>();
    final (oz, liters) = HealthFormulas.waterIntake(profile.weightKg);

    // Purely presentational glass count derived from the (unchanged) liters
    // calculation — ~250ml per glass — clamped to a sane display range.
    var glasses = (liters / 0.25).round();
    if (glasses < 1) glasses = 1;
    if (glasses > 30) glasses = 30;

    return ToolScreenScaffold(
      title: 'Water Intake Calculator',
      description: const PremiumScDesc(
        spans: [
          TextSpan(text: 'Estimate your daily water needs based on your body weight.'),
        ],
      ),
      children: [
        PremiumWeightField(profile: profile),
        PremiumBmiInline(profile: profile),
        PremiumResultBannerCentered(
          value: '${liters.toStringAsFixed(2)} L / day',
          subtitle: '≈ ${oz.toStringAsFixed(0)} oz · $glasses glasses',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '$glasses glasses recommended per day',
            style: Premium.body(context, 12, weight: FontWeight.w600, color: context.colors.textSecondary),
          ),
        ),
        PremiumWaterGlasses(total: glasses, filled: 0),
      ],
    );
  }
}
