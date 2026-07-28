import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../core/premium_widgets.dart';
import 'age_calculator_screen.dart';
import 'bmi_calculator_screen.dart';
import 'bmr_calculator_screen.dart';
import 'calorie_calculator_screen.dart';
import 'ideal_weight_calculator_screen.dart';
import 'nutrient_calculator_screen.dart';
import 'walk_calorie_planner_screen.dart';
import 'walk_run_tracker_screen.dart';
import 'water_intake_calculator_screen.dart';
import 'weight_tracker_screen.dart';

class _ToolItem {
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  const _ToolItem(this.label, this.icon, this.builder);
}

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static final _tools = <_ToolItem>[
    _ToolItem('BMI', Icons.monitor_weight_outlined, (_) => const BmiCalculatorScreen()),
    _ToolItem('BMR', Icons.local_fire_department_outlined, (_) => const BmrCalculatorScreen()),
    _ToolItem('Ideal Weight', Icons.fitness_center, (_) => const IdealWeightCalculatorScreen()),
    _ToolItem('Water Intake', Icons.water_drop_outlined, (_) => const WaterIntakeCalculatorScreen()),
    _ToolItem('Calories', Icons.local_dining_outlined, (_) => const CalorieCalculatorScreen()),
    _ToolItem('Nutrients', Icons.set_meal_outlined, (_) => const NutrientCalculatorScreen()),
    _ToolItem('Age', Icons.cake_outlined, (_) => const AgeCalculatorScreen()),
    _ToolItem('Weight Tracker', Icons.show_chart, (_) => const WeightTrackerScreen()),
    _ToolItem('Walk/Run', Icons.directions_walk, (_) => const WalkRunTrackerScreen()),
    _ToolItem('Walk Planner', Icons.calculate_outlined, (_) => const WalkCaloriePlannerScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text('Health Tools', style: Premium.heading(context, 23)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 13,
                  crossAxisSpacing: 13,
                  mainAxisExtent: 140,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tool = _tools[index];
                    return PremiumCard(
                      padding: const EdgeInsets.symmetric(vertical: 23, horizontal: 14),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: tool.builder)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PremiumIconChip(icon: tool.icon, size: 46),
                          const SizedBox(height: 12),
                          Text(
                            tool.label,
                            textAlign: TextAlign.center,
                            style: Premium.body(context, 13, color: context.colors.textPrimary, weight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _tools.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
