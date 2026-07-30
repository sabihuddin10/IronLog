import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
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
  final String key;
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  const _ToolItem(this.key, this.label, this.icon, this.builder);
}

class _ToolCategory {
  final String label;
  final List<_ToolItem> tools;
  const _ToolCategory(this.label, this.tools);
}

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  static final _categories = <_ToolCategory>[
    _ToolCategory('Body', [
      _ToolItem(
        'bmi',
        'BMI',
        Icons.monitor_weight_outlined,
        (_) => const BmiCalculatorScreen(),
      ),
      _ToolItem(
        'bmr',
        'BMR',
        Icons.local_fire_department_outlined,
        (_) => const BmrCalculatorScreen(),
      ),
      _ToolItem(
        'idealWeight',
        'Ideal Weight',
        Icons.fitness_center,
        (_) => const IdealWeightCalculatorScreen(),
      ),
      _ToolItem(
        'age',
        'Age',
        Icons.cake_outlined,
        (_) => const AgeCalculatorScreen(),
      ),
    ]),
    _ToolCategory('Fuel', [
      _ToolItem(
        'waterIntake',
        'Water Intake',
        Icons.water_drop_outlined,
        (_) => const WaterIntakeCalculatorScreen(),
      ),
      _ToolItem(
        'calories',
        'Calories',
        Icons.local_dining_outlined,
        (_) => const CalorieCalculatorScreen(),
      ),
      _ToolItem(
        'nutrients',
        'Nutrients',
        Icons.set_meal_outlined,
        (_) => const NutrientCalculatorScreen(),
      ),
      _ToolItem(
        'weightTracker',
        'Weight Tracker',
        Icons.show_chart,
        (_) => const WeightTrackerScreen(),
      ),
    ]),
    _ToolCategory('Movement', [
      _ToolItem(
        'walkRun',
        'Walk/Run',
        Icons.directions_walk,
        (_) => const WalkRunTrackerScreen(),
      ),
      _ToolItem(
        'walkPlanner',
        'Walk Planner',
        Icons.calculate_outlined,
        (_) => const WalkCaloriePlannerScreen(),
      ),
    ]),
  ];

  static const _boxName = 'tool_usage';

  Map<String, int> _lastOpened = {};

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<Box<int>> _usageBox() async => Hive.isBoxOpen(_boxName)
      ? Hive.box<int>(_boxName)
      : Hive.openBox<int>(_boxName);

  Future<void> _loadUsage() async {
    final box = await _usageBox();
    if (!mounted) return;
    setState(
      () => _lastOpened = box.toMap().map((k, v) => MapEntry(k as String, v)),
    );
  }

  Future<void> _open(_ToolItem tool) async {
    final now = DateTime.now();
    final box = await _usageBox();
    await box.put(tool.key, now.millisecondsSinceEpoch);
    if (!mounted) return;
    setState(
      () =>
          _lastOpened = {..._lastOpened, tool.key: now.millisecondsSinceEpoch},
    );
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: tool.builder));
  }

  @override
  Widget build(BuildContext context) {
    final total = _categories.fold<int>(0, (sum, c) => sum + c.tools.length);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Health Tools', style: Premium.heading(context, 23)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '$total total',
                        style: Premium.body(
                          context,
                          12.5,
                          color: context.colors.textFaint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final category in _categories) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: _SectionDivider(label: category.label),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    mainAxisExtent: 106,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tool = category.tools[index];
                    return _ToolCard(tool: tool, onTap: () => _open(tool));
                  }, childCount: category.tools.length),
                ),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
          ],
        ),
      ),
    );
  }
}

/// A small-caps section label with a hairline rule trailing off to the right
/// — separates the tool grid into Body / Fuel / Movement groups.
class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: Premium.body(
            context,
            11,
            color: context.colors.textFaint,
            weight: FontWeight.w700,
          ).copyWith(letterSpacing: 1.1),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: context.colors.border, height: 1)),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final _ToolItem tool;
  final VoidCallback onTap;

  const _ToolCard({required this.tool, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: colors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: Premium.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: CustomPaint(
                painter: _GradientRingPainter(
                  gradient: colors.accentGradient,
                  strokeWidth: 2,
                ),
                child: Center(
                  child: Icon(tool.icon, size: 22, color: colors.accent),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tool.label,
              textAlign: TextAlign.center,
              style: Premium.body(
                context,
                12.5,
                color: colors.textPrimary,
                weight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a fully closed circular ring stroked with a gradient shader — used
/// as a purely decorative frame behind each tool card's icon (no progress
/// semantics, identical on every card).
class _GradientRingPainter extends CustomPainter {
  final Gradient gradient;
  final double strokeWidth;

  const _GradientRingPainter({
    required this.gradient,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = gradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(
      size.center(Offset.zero),
      (size.shortestSide - strokeWidth) / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) =>
      oldDelegate.gradient != gradient ||
      oldDelegate.strokeWidth != strokeWidth;
}
