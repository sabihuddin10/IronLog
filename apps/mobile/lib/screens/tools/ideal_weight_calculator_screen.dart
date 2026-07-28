import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../data/body_profile_store.dart';
import '../../utils/health_formulas.dart';
import 'premium_tool_widgets.dart';

class IdealWeightCalculatorScreen extends StatefulWidget {
  const IdealWeightCalculatorScreen({super.key});

  @override
  State<IdealWeightCalculatorScreen> createState() => _IdealWeightCalculatorScreenState();
}

class _IdealWeightCalculatorScreenState extends State<IdealWeightCalculatorScreen> {
  bool _lbs = false;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<BodyProfileStore>();
    final formulas = HealthFormulas.idealWeightFormulas(profile.heightCm, profile.gender);
    final who = HealthFormulas.whoRange(profile.heightCm);

    String fmt(double kg) {
      final v = _lbs ? kg * 2.2046226218 : kg;
      return v.toStringAsFixed(1);
    }

    final unit = _lbs ? 'lbs' : 'kg';

    return ToolScreenScaffold(
      title: 'Ideal Weight Calculator',
      description: const PremiumScDesc(
        spans: [
          TextSpan(
            text: "Ideal Weight is dependent on one's body type (height, age), healthy weight is commonly determined "
                "by measuring body mass index or BMI.",
          ),
        ],
      ),
      children: [
        PremiumAgeGenderField(profile: profile),
        PremiumHeightField(profile: profile),
        PremiumBmiInline(profile: profile),
        Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Row(
            children: [
              Text('Unit', style: Premium.body(context, 13.5, weight: FontWeight.w600, color: context.colors.textPrimary)),
              const Spacer(),
              PremiumUnitPill(label: 'KG', selected: !_lbs, onTap: () => setState(() => _lbs = false)),
              const SizedBox(width: 6),
              PremiumUnitPill(label: 'LBS', selected: _lbs, onTap: () => setState(() => _lbs = true)),
            ],
          ),
        ),
        PremiumResultBannerCentered(
          value: '${fmt(who.$1)} – ${fmt(who.$2)} $unit',
          subtitle: 'healthy range for your height (WHO)',
        ),
        PremiumCatList(
          rows: [
            for (final entry in formulas.entries.where((e) => e.key != 'WHO'))
              PremiumCatRowData(label: entry.key.replaceAll(' Formula', ''), value: '${fmt(entry.value)} $unit'),
          ],
        ),
        const PremiumInfoBanner(
          text: 'Note: Formula based methods are applicable for adults age 18+ and height above 5ft/152cm. '
              'WHO method is applicable for age 2+.',
        ),
      ],
    );
  }
}
