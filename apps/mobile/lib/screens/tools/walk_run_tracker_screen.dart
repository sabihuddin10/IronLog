import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../core/premium_widgets.dart';
import '../../data/body_profile_store.dart';
import '../../models/walk_session.dart';
import '../../repositories/walk_session_repository.dart';
import '../../utils/health_formulas.dart';
import 'walk_foreground_task.dart';
import 'walk_history_screen.dart';
import 'walk_session_models.dart';

enum _ViewState { preStart, live, unavailable }

class WalkRunTrackerScreen extends StatefulWidget {
  const WalkRunTrackerScreen({super.key});

  @override
  State<WalkRunTrackerScreen> createState() => _WalkRunTrackerScreenState();
}

class _WalkRunTrackerScreenState extends State<WalkRunTrackerScreen> {
  _ViewState _viewState = _ViewState.preStart;
  ActiveWalkSession? _session;
  DateTime? _startedAt;
  double _strideLengthMeters = 0;
  double _weightKg = 0;
  double _bmrValue = 0;
  Timer? _ticker;
  StreamSubscription<AccelerometerEvent>? _stepSub;
  bool _saving = false;
  bool _paused = false;
  late Future<List<WalkSession>> _historyFuture;

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_handleTaskData);
    _historyFuture = context.read<WalkSessionRepository>().list();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_handleTaskData);
    _ticker?.cancel();
    _stepSub?.cancel();
    super.dispose();
  }

  void _handleTaskData(Object data) {
    if (!mounted) return;
    if (data == WalkNotificationActions.togglePause) {
      _togglePause();
    } else if (data == WalkNotificationActions.stop) {
      _finish();
    }
  }

  String get _notificationText {
    final session = _session;
    if (session == null) return '';
    final distanceKm = session.distanceMeters(_strideLengthMeters) / 1000;
    return '$_durationLabel · ${session.steps} steps · ${distanceKm.toStringAsFixed(2)} km';
  }

  Future<void> _startForegroundNotification() async {
    // Android-only feature (no web platform implementation); the in-app
    // tracker still works fine on web, just without the notification.
    if (kIsWeb) return;

    var permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      permission = await FlutterForegroundTask.requestNotificationPermission();
    }
    if (permission != NotificationPermission.granted) return;

    await FlutterForegroundTask.startService(
      serviceTypes: const [ForegroundServiceTypes.health],
      notificationTitle: 'Walking',
      notificationText: _notificationText,
      notificationButtons: const [
        NotificationButton(id: WalkNotificationActions.togglePause, text: 'Pause'),
        NotificationButton(id: WalkNotificationActions.stop, text: 'Stop'),
      ],
      callback: startWalkForegroundTask,
    );
  }

  String get _durationLabel {
    final d = _session?.stopwatch.elapsed ?? Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _liveCalories {
    final session = _session;
    if (session == null) return 0;
    final elapsedMinutes = session.stopwatch.elapsed.inMilliseconds / 60000;
    if (elapsedMinutes <= 0) return 0;
    final speedMetersPerMin = session.distanceMeters(_strideLengthMeters) / elapsedMinutes;
    return HealthFormulas.totalWalkKcal(
      weightKg: _weightKg,
      speedMetersPerMin: speedMetersPerMin,
      durationMinutes: elapsedMinutes,
      bmrValue: _bmrValue,
    );
  }

  void _togglePause() {
    final session = _session;
    if (session == null) return;
    if (_paused) {
      _stepSub?.resume();
      session.stopwatch.start();
    } else {
      _stepSub?.pause();
      session.stopwatch.stop();
    }
    setState(() => _paused = !_paused);
    if (!kIsWeb) {
      FlutterForegroundTask.updateService(
        notificationText: _notificationText,
        notificationButtons: [
          NotificationButton(id: WalkNotificationActions.togglePause, text: _paused ? 'Resume' : 'Pause'),
          const NotificationButton(id: WalkNotificationActions.stop, text: 'Stop'),
        ],
      );
    }
  }

  void _startTracking() {
    final profile = context.read<BodyProfileStore>();
    _strideLengthMeters = profile.heightCm * 0.415 / 100;
    _weightKg = profile.weightKg;
    _bmrValue = HealthFormulas.bmr(profile.weightKg, profile.heightCm, profile.age, profile.gender);
    _startedAt = DateTime.now();
    final session = ActiveWalkSession()..stopwatch.start();
    _session = session;

    try {
      _stepSub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
        (event) {
          if (!mounted) return;
          setState(() => session.addAccelerometerSample(event.x, event.y, event.z));
        },
        onError: (_) {
          if (!mounted) return;
          _ticker?.cancel();
          if (!kIsWeb) FlutterForegroundTask.stopService();
          setState(() => _viewState = _ViewState.unavailable);
        },
      );
    } catch (_) {
      setState(() => _viewState = _ViewState.unavailable);
      return;
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (!kIsWeb) FlutterForegroundTask.updateService(notificationText: _notificationText);
    });
    setState(() => _viewState = _ViewState.live);
    _startForegroundNotification();
  }

  Future<void> _finish() async {
    final session = _session;
    final startedAt = _startedAt;
    if (session == null || startedAt == null) return;

    final calories = _liveCalories;
    setState(() => _saving = true);
    _stepSub?.cancel();
    _ticker?.cancel();
    if (!kIsWeb) FlutterForegroundTask.stopService();
    try {
      await context.read<WalkSessionRepository>().create(
            steps: session.steps,
            distanceMeters: session.distanceMeters(_strideLengthMeters),
            duration: session.stopwatch.elapsed,
            startedAt: startedAt,
            strideLengthMeters: _strideLengthMeters,
            calories: calories,
          );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.cardBackground,
        title: const Text('Discard this session?'),
        content: const Text('Your steps, distance and time so far will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep going')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Discard')),
        ],
      ),
    );
    if (discard == true && mounted) {
      _stepSub?.cancel();
      _ticker?.cancel();
      if (!kIsWeb) FlutterForegroundTask.stopService();
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_viewState) {
      case _ViewState.preStart:
        return _buildPreStart(context);
      case _ViewState.live:
        return _buildLive(context);
      case _ViewState.unavailable:
        return _buildUnavailable(context);
    }
  }

  /// `#screen-walkrun` — decorative route card, a "last session" hero +
  /// stat grid (repurposing the mockup's static preview numbers to show the
  /// most recently completed session, since this screen has no live data
  /// before a session starts), the historical chart, and the gradient
  /// "Start" CTA.
  Widget _buildPreStart(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _WrHeader(
              onBack: () => Navigator.of(context).maybePop(),
              onHistory: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WalkHistoryScreen()),
              ),
            ),
            const SizedBox(height: 18),
            const _RouteMapCard(),
            const SizedBox(height: 22),
            FutureBuilder<List<WalkSession>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: context.colors.accent)),
                  );
                }
                final sessions = snapshot.data ?? const <WalkSession>[];
                final last = sessions.isNotEmpty ? sessions.first : null;
                return Column(
                  children: [
                    _LastSessionSummary(session: last),
                    const SizedBox(height: 28),
                    PremiumCard(
                      radius: Premium.radiusXl,
                      padding: const EdgeInsets.all(18),
                      child: WalkHistoryChartSection(sessions: sessions),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PremiumIconChip(icon: Icons.directions_walk),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Track steps, distance and pace', style: Premium.heading(context, 14.5, weight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(
                        "Uses your phone's motion sensor to detect steps — no GPS required.",
                        style: Premium.body(context, 12, color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _StartRunButton(onTap: _startTracking),
          ],
        ),
      ),
    );
  }

  /// `#screen-walkrun-active` — giant live timer, a pause/finish header, and
  /// the 4-up stat strip. All values below are read straight off the same
  /// [ActiveWalkSession]/[HealthFormulas] calls the previous Material UI used
  /// — only the presentation changed.
  Widget _buildLive(BuildContext context) {
    final session = _session!;
    final speedKmh = session.speedMps(_strideLengthMeters) * 3.6;
    final distanceKm = session.distanceMeters(_strideLengthMeters) / 1000;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _WkHeader(
                paused: _paused,
                saving: _saving,
                onBack: _confirmDiscard,
                onTogglePause: _saving ? null : _togglePause,
                onFinish: _saving ? null : _finish,
              ),
              Text(
                _durationLabel,
                textAlign: TextAlign.center,
                style: Premium.heading(context, 50, weight: FontWeight.w600).copyWith(height: 1.1),
              ),
              if (_paused) ...[
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'PAUSED',
                    style: Premium.body(context, 11, color: context.colors.danger, weight: FontWeight.w700),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _StatsStrip(
                steps: '${session.steps}',
                distance: '${distanceKm.toStringAsFixed(2)} km',
                speed: '${speedKmh.toStringAsFixed(1)} km/h',
                calories: '${_liveCalories.toStringAsFixed(0)} kcal',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// No direct mockup equivalent for a sensor-unavailable state; styled with
  /// the same icon-chip / heading / bordered-button vocabulary used
  /// elsewhere in the redesign.
  Widget _buildUnavailable(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _UnavailableMessage(onGoBack: () => Navigator.of(context).pop(false)),
          ),
        ),
      ),
    );
  }
}

/// `.wr-header` — down-chevron chip, centered title, and a second chip
/// (repurposed as the "all records" shortcut the previous AppBar exposed via
/// an action icon).
class _WrHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onHistory;

  const _WrHeader({required this.onBack, required this.onHistory});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ChevButton(icon: Icons.keyboard_arrow_down, onTap: onBack),
        Expanded(
          child: Center(child: Text('Walk/Run', style: Premium.heading(context, 19))),
        ),
        _ChevButton(icon: Icons.list_alt, onTap: onHistory, tooltip: 'All records'),
      ],
    );
  }
}

/// `.wk-header` — down-chevron chip, title, pause/resume chip, and the
/// gradient "Finish" pill (swapped for a spinner while [saving]).
class _WkHeader extends StatelessWidget {
  final bool paused;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback? onTogglePause;
  final VoidCallback? onFinish;

  const _WkHeader({
    required this.paused,
    required this.saving,
    required this.onBack,
    required this.onTogglePause,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Row(
        children: [
          _ChevButton(icon: Icons.keyboard_arrow_down, onTap: onBack),
          const SizedBox(width: 10),
          Expanded(child: Text('Walk / Run', style: Premium.heading(context, 19))),
          _ChevButton(icon: paused ? Icons.play_arrow : Icons.pause, onTap: onTogglePause),
          const SizedBox(width: 8),
          saving
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.accent),
                  ),
                )
              : PremiumGradientButton(label: 'Finish', onTap: onFinish),
        ],
      ),
    );
  }
}

/// Shared 30x30 `surface-2` chip used by both header variants above —
/// `.wk-header .chev` / `.icon-btn`.
class _ChevButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const _ChevButton({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: context.colors.cardBackground,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: context.colors.textSecondary),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// `.map-card` — a decorative route/step visual (this tracker uses the
/// phone's accelerometer for step detection, not GPS, so the badge text is
/// adapted from the mockup's "GPS locked" to reflect that honestly).
class _RouteMapCard extends StatelessWidget {
  const _RouteMapCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: context.colors.cardGradient,
        borderRadius: BorderRadius.circular(Premium.radiusXxl),
        border: Border.all(color: context.colors.border),
        boxShadow: Premium.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            left: -24,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [context.colors.accent2.withValues(alpha: 0.14), context.colors.accent2.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _RoutePainter(accent: context.colors.accent, accent2: context.colors.accent2),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.colors.onAccent.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: context.colors.borderStrong),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_walk, size: 12, color: context.colors.textSecondary),
                  const SizedBox(width: 6),
                  Text('Step-based tracking', style: Premium.body(context, 10.5, color: context.colors.textSecondary, weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a stylized, dashed, gradient route line approximating the
/// mockup's SVG `<path>` — purely decorative, no data binding.
class _RoutePainter extends CustomPainter {
  final Color accent;
  final Color accent2;

  _RoutePainter({required this.accent, required this.accent2});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 340;
    final sy = size.height / 180;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    final path = Path()
      ..moveTo(p(20, 150).dx, p(20, 150).dy)
      ..cubicTo(p(60, 120).dx, p(60, 120).dy, p(80, 160).dx, p(80, 160).dy, p(120, 130).dx, p(120, 130).dy)
      ..cubicTo(p(160, 100).dx, p(160, 100).dy, p(190, 60).dx, p(190, 60).dy, p(230, 90).dx, p(230, 90).dy)
      ..cubicTo(p(265, 118).dx, p(265, 118).dy, p(300, 40).dx, p(300, 40).dy, p(320, 30).dx, p(320, 30).dy);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(colors: [accent2, accent]).createShader(Offset.zero & size);

    const dashWidth = 6.0;
    const dashGap = 9.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashGap;
      }
    }

    canvas.drawCircle(p(20, 150), 4, Paint()..color = accent2);
    canvas.drawCircle(p(320, 30), 5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.accent2 != accent2;
}

/// `.wr-hero` + `.wr-grid` — repurposed to summarize the most recently
/// completed session (there is no "current" distance/pace before a session
/// starts, unlike the mockup's static preview numbers).
class _LastSessionSummary extends StatelessWidget {
  final WalkSession? session;

  const _LastSessionSummary({required this.session});

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String _formatPace(double paceMinPerKm) {
    if (paceMinPerKm <= 0 || !paceMinPerKm.isFinite) return '--';
    final totalSeconds = (paceMinPerKm * 60).round();
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    final s = session;
    if (s == null) {
      return Column(
        children: [
          Text('READY WHEN YOU ARE', style: Premium.body(context, 11, color: context.colors.textFaint, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('No sessions logged yet', style: Premium.heading(context, 18)),
        ],
      );
    }

    return Column(
      children: [
        Text('LAST SESSION · DISTANCE', style: Premium.body(context, 11, color: context.colors.textFaint, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            style: Premium.heading(context, 46, color: context.colors.accent),
            children: [
              TextSpan(text: s.distanceKm.toStringAsFixed(2)),
              TextSpan(text: ' km', style: Premium.body(context, 15, color: context.colors.textSecondary, weight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _WrStat(value: _formatDuration(s.duration), label: 'Duration')),
            const SizedBox(width: 10),
            Expanded(child: _WrStat(value: _formatPace(s.paceMinPerKm), label: 'Avg pace')),
            const SizedBox(width: 10),
            Expanded(child: _WrStat(value: s.calories.toStringAsFixed(0), label: 'Calories')),
          ],
        ),
      ],
    );
  }
}

/// `.wr-stat`.
class _WrStat extends StatelessWidget {
  final String value;
  final String label;

  const _WrStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: BoxDecoration(
        gradient: context.colors.cardGradient,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(value, style: Premium.heading(context, 16, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: Premium.body(context, 9, color: context.colors.textFaint, weight: FontWeight.w600).copyWith(letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

/// `.wr-start` — full-width gradient CTA. Labeled "Start Walk/Run" rather
/// than the mockup's literal "Start Run" since this tracker has no separate
/// walk/run mode — one session type covers both (see [HealthFormulas]'s
/// speed-based walk/run auto-selection).
class _StartRunButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartRunButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: context.colors.accentGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: context.colors.accentGlowShadow(blur: 26, spread: -10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, size: 18, color: context.colors.onAccent),
              const SizedBox(width: 8),
              Text('Start Walk/Run', style: Premium.heading(context, 15, weight: FontWeight.w700, color: context.colors.onAccent)),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.stat-strip` — 4-up steps/distance/speed/calories readout with hairline
/// dividers between cells.
class _StatsStrip extends StatelessWidget {
  final String steps;
  final String distance;
  final String speed;
  final String calories;

  const _StatsStrip({
    required this.steps,
    required this.distance,
    required this.speed,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: Premium.radiusLg,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      child: Row(
        children: [
          Expanded(child: _StripStat(value: steps, label: 'Steps')),
          _divider(context),
          Expanded(child: _StripStat(value: distance, label: 'Distance')),
          _divider(context),
          Expanded(child: _StripStat(value: speed, label: 'Speed')),
          _divider(context),
          Expanded(child: _StripStat(value: calories, label: 'Calories')),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Container(width: 1, height: 28, color: context.colors.border);
}

class _StripStat extends StatelessWidget {
  final String value;
  final String label;

  const _StripStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: Premium.heading(context, 16, weight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: Premium.body(context, 9, color: context.colors.textFaint, weight: FontWeight.w600).copyWith(letterSpacing: 0.5),
        ),
      ],
    );
  }
}

/// Sensor-unavailable empty state — icon chip, message, bordered "Go back"
/// button. No mockup equivalent exists for this state.
class _UnavailableMessage extends StatelessWidget {
  final VoidCallback onGoBack;

  const _UnavailableMessage({required this.onGoBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [context.colors.accentDim, context.colors.accent.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colors.accent.withValues(alpha: 0.18)),
          ),
          child: Icon(Icons.sensors_off, size: 30, color: context.colors.accent),
        ),
        const SizedBox(height: 18),
        Text(
          'Step sensor unavailable on this device.',
          textAlign: TextAlign.center,
          style: Premium.heading(context, 15, weight: FontWeight.w600),
        ),
        const SizedBox(height: 22),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onGoBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.cardBackground,
                border: Border.all(color: context.colors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('Go back', style: Premium.body(context, 13, color: context.colors.textPrimary, weight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}
