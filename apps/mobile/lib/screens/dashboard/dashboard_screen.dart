import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_state.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../core/premium_widgets.dart';
import '../../core/responsive.dart';
import '../../models/dashboard_stats.dart';
import '../../repositories/dashboard_repository.dart';
import '../workouts/active_workout_session.dart';
import '../workouts/log_workout_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardStats> _future;
  late final ActiveWorkoutSession _session;
  bool _sessionWasActive = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<DashboardRepository>().fetch();
    _session = context.read<ActiveWorkoutSession>();
    _sessionWasActive = _session.isActive;
    _session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  // The dashboard tab stays alive (never disposed) in RootScreen's
  // IndexedStack, so it won't naturally refetch when a workout is logged
  // from another tab. ActiveWorkoutSession.finish() calls notifyListeners()
  // right after saving, so refreshing on the active -> inactive transition
  // keeps stats current without the user having to pull-to-refresh.
  void _onSessionChanged() {
    if (_sessionWasActive && !_session.isActive) _refresh();
    _sessionWasActive = _session.isActive;
  }

  void _refresh() {
    setState(() => _future = context.read<DashboardRepository>().fetch());
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthState>().user?.email ?? '';
    final name = email.isEmpty ? '?' : email.split('@').first;
    final session = context.watch<ActiveWorkoutSession>();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: context.colors.accent,
          backgroundColor: context.colors.cardBackground,
          child: FutureBuilder<DashboardStats>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: context.colors.accent,
                  ),
                );
              }

              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: context.colors.textFaint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Could not load dashboard data.',
                      textAlign: TextAlign.center,
                      style: Premium.heading(context, context.scale(16)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Premium.body(context, context.scale(12)),
                    ),
                  ],
                );
              }

              final stats = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OVERVIEW',
                            style: Premium.body(
                              context,
                              context.scale(11),
                              weight: FontWeight.w600,
                              color: context.colors.textFaint,
                            ).copyWith(letterSpacing: 1.1),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dashboard',
                            style: Premium.heading(context, context.scale(27)),
                          ),
                        ],
                      ),
                      Container(
                        width: context.scale(36),
                        height: context.scale(36),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: context.colors.accentGradient,
                          border: Border.all(
                            color: context.colors.borderStrong,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: Premium.heading(
                            context,
                            context.scale(14),
                            color: context.colors.onAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _StreakHero(
                    current: stats.currentStreakDays,
                    best: stats.bestStreakDays,
                  ),
                  const SizedBox(height: 11),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.bolt_outlined,
                            value: '${stats.totalWorkouts}',
                            sub: 'Total workouts',
                            trend: stats.workoutsThisWeek > 0
                                ? '↑ new this week'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.calendar_today_outlined,
                            value: '${stats.workoutsThisWeek}',
                            sub: 'This week',
                            trend: stats.workoutsThisWeek > 0
                                ? '↑ on pace'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.monitor_weight_outlined,
                            value: stats.latestWeight != null
                                ? '${stats.latestWeight!.weight} ${stats.latestWeight!.unit}'
                                : 'Not logged',
                            valueMuted: stats.latestWeight == null,
                            sub: 'Latest weight',
                            cta: stats.latestWeight == null
                                ? 'Log now →'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.history,
                            value: stats.lastWorkout?.name ?? '—',
                            valueFontSize: 17,
                            sub: 'Last workout',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _WeeklyGoalRing(
                    sessionsThisWeek: stats.workoutsThisWeek,
                    target: 4,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Continue where you left off',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Premium.heading(context, context.scale(16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'See all',
                        style: Premium.body(
                          context,
                          context.scale(12),
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (session.isActive || stats.lastWorkout != null)
                    _LastWorkoutCard(
                      workoutName: session.isActive ? session.nameController.text : stats.lastWorkout!.name,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StreakHero extends StatefulWidget {
  final int current;
  final int best;

  const _StreakHero({required this.current, required this.best});

  @override
  State<_StreakHero> createState() => _StreakHeroState();
}

class _StreakHeroState extends State<_StreakHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.widthScale;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 18),
      decoration: BoxDecoration(
        // Wash tinted by the active accent pair rather than a fixed hue, so
        // the card follows whichever combo/custom accent is selected — dark:
        // glow bleeding from the flame corner into the surface; light: pale
        // accent-tinted wash (a literal dark-mode corner color blended into a
        // light surface, the old unconditional gradient, produced a dark
        // smudge in light mode).
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    context.colors.surface,
                    context.colors.accent,
                    0.22,
                  )!,
                  context.colors.surface,
                ],
                stops: const [0, 0.55],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(Colors.white, context.colors.accent, 0.08)!,
                  Color.lerp(Colors.white, context.colors.accent2, 0.08)!,
                ],
              ),
        borderRadius: BorderRadius.circular(Premium.radiusXxl),
        border: Border.all(
          color: isDark
              ? context.colors.accent.withValues(alpha: 0.16)
              : const Color(0x0F101814),
        ),
        boxShadow: isDark
            ? Premium.cardShadow
            : const [
                BoxShadow(
                  color: Color(0x1F101814),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: -14,
                ),
              ],
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.06).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 46 * scale,
              height: 46 * scale,
              decoration: BoxDecoration(
                gradient: context.colors.accentGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: context.colors.accentGlowShadow(
                  blur: 16,
                  spread: -4,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.local_fire_department,
                color: context.colors.onAccent,
                size: 22 * scale,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT STREAK',
                  style: Premium.body(
                    context,
                    11 * scale,
                    weight: FontWeight.w600,
                    color: context.colors.textFaint,
                  ).copyWith(letterSpacing: 0.8),
                ),
                const SizedBox(height: 3),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: Premium.heading(context, 19 * scale),
                    children: [
                      TextSpan(
                        text: '${widget.current} days',
                        style: TextStyle(color: context.colors.accent),
                      ),
                      TextSpan(
                        text: ' · best is ${widget.best}',
                        style: Premium.heading(context, 19 * scale),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final double valueFontSize;
  final bool valueMuted;
  final String sub;
  final String? trend;
  final String? cta;

  const _StatTile({
    required this.icon,
    required this.value,
    this.valueFontSize = 24,
    this.valueMuted = false,
    required this.sub,
    this.trend,
    this.cta,
  });

  @override
  Widget build(BuildContext context) {
    final scale = context.widthScale;
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PremiumIconChip(icon: icon, size: 30 * scale),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: valueMuted
                    ? Premium.body(
                        context,
                        14 * scale,
                        weight: FontWeight.w500,
                        color: context.colors.textFaint,
                      )
                    : Premium.heading(context, valueFontSize * scale),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Premium.body(
              context,
              12 * scale,
              color: context.colors.textSecondary,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 6),
            Text(
              trend!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Premium.body(
                context,
                10.5 * scale,
                weight: FontWeight.w600,
                color: context.colors.success,
              ),
            ),
          ],
          if (cta != null) ...[
            const SizedBox(height: 6),
            Text(
              cta!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Premium.body(
                context,
                12 * scale,
                weight: FontWeight.w600,
                color: context.colors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyGoalRing extends StatefulWidget {
  final int sessionsThisWeek;
  final int target;

  const _WeeklyGoalRing({required this.sessionsThisWeek, required this.target});

  @override
  State<_WeeklyGoalRing> createState() => _WeeklyGoalRingState();
}

class _WeeklyGoalRingState extends State<_WeeklyGoalRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final ratio = widget.target <= 0
        ? 0.0
        : (widget.sessionsThisWeek / widget.target).clamp(0, 1).toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _progress = Tween(
      begin: 0.0,
      end: ratio,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.widthScale;
    final ringSize = 60 * scale;
    return Container(
      margin: const EdgeInsets.only(top: 0, bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
      decoration: BoxDecoration(
        gradient: context.colors.elevatedGradient,
        borderRadius: BorderRadius.circular(Premium.radiusXxl),
        border: Border.all(color: context.colors.borderStrong),
        boxShadow: Premium.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly goal',
                  style: Premium.body(
                    context,
                    12 * scale,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: Premium.heading(context, 21 * scale),
                    children: [
                      TextSpan(text: '${widget.sessionsThisWeek} '),
                      TextSpan(
                        text: '/ ${widget.target} sessions',
                        style: Premium.body(
                          context,
                          13 * scale,
                          color: context.colors.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: AnimatedBuilder(
              animation: _progress,
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(ringSize, ringSize),
                    painter: _RingPainter(
                      progress: _progress.value,
                      accent: context.colors.accent,
                      accent2: context.colors.accent2,
                    ),
                  ),
                  Text(
                    '${(_progress.value * 100).round()}%',
                    style: Premium.heading(context, 12.5 * scale),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final Color accent2;

  _RingPainter({
    required this.progress,
    required this.accent,
    required this.accent2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 6) / 2;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, track);

    final gradient = SweepGradient(
      startAngle: -1.5708,
      endAngle: -1.5708 + 6.2832,
      colors: [accent, accent2],
      transform: const GradientRotation(-1.5708),
    );
    final progressPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      6.2832 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accent != accent ||
      oldDelegate.accent2 != accent2;
}

class _LastWorkoutCard extends StatelessWidget {
  final String workoutName;

  const _LastWorkoutCard({required this.workoutName});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<ActiveWorkoutSession>();
    final scale = context.widthScale;
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      radius: Premium.radiusLg,
      onTap: () async {
        if (!session.isActive) {
          await session.start(context.read(), isLiveSession: true);
        }
        if (context.mounted) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LogWorkoutScreen()));
        }
      },
      child: Row(
        children: [
          Container(
            width: 42 * scale,
            height: 42 * scale,
            decoration: BoxDecoration(
              gradient: context.colors.accentGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: context.colors.accentGlowShadow(blur: 12, spread: -4),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.bolt,
              color: context.colors.onAccent,
              size: 19 * scale,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workoutName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Premium.heading(context, 14.5 * scale),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to resume',
                  style: Premium.body(
                    context,
                    12 * scale,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.textFaint),
        ],
      ),
    );
  }
}
