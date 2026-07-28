import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/premium_theme.dart';
import '../../core/premium_widgets.dart';
import '../../core/responsive.dart';
import '../../models/workout.dart';
import '../../models/workout_template.dart';
import '../../repositories/workout_repository.dart';
import '../../repositories/workout_template_repository.dart';
import 'active_workout_session.dart';
import 'log_workout_screen.dart';
import 'preset_builder_screen.dart';
import 'workout_detail_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  late Future<List<Workout>> _future;
  late Future<List<WorkoutTemplate>> _templatesFuture;
  late final ActiveWorkoutSession _session;
  bool _sessionWasActive = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadTemplates();
    _session = context.read<ActiveWorkoutSession>();
    _sessionWasActive = _session.isActive;
    _session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  // This tab stays alive (never disposed) in RootScreen's IndexedStack, so
  // finishing a workout from another tab wouldn't otherwise refetch it.
  void _onSessionChanged() {
    if (_sessionWasActive && !_session.isActive) _refresh();
    _sessionWasActive = _session.isActive;
  }

  void _load() {
    _future = context.read<WorkoutRepository>().list();
  }

  void _loadTemplates() {
    _templatesFuture = context.read<WorkoutTemplateRepository>().list();
  }

  Future<void> _refresh() async {
    setState(() {
      _load();
      _loadTemplates();
    });
    await Future.wait([_future, _templatesFuture]);
  }

  Future<void> _createPreset() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const PresetBuilderScreen()));
    if (created == true) setState(_loadTemplates);
  }

  Future<void> _deletePreset(WorkoutTemplate template) async {
    final repository = context.read<WorkoutTemplateRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.cardBackground,
        title: Text('Delete "${template.name}"?', style: Premium.heading(context, 16)),
        content: Text(
          'This preset will be removed. It won\'t affect any workouts already logged.',
          style: Premium.body(context, 13, color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: Premium.body(context, 13, weight: FontWeight.w600, color: context.colors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF6B5C), foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await repository.delete(template.id);
    if (mounted) setState(_loadTemplates);
  }

  /// Asks whether the workout about to be logged is happening right now
  /// (real-time tracked) or already happened (backfilled) — see
  /// [ActiveWorkoutSession.isLiveSession]. Returns null if the user backs out.
  Future<bool?> _chooseLiveOrPast() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.cardBackground,
        title: Text('Log a workout', style: Premium.heading(context, 17)),
        content: Text(
          'Are you working out right now, or logging one you already did?',
          style: Premium.body(context, 13.5, color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Past workout', style: Premium.body(context, 13, weight: FontWeight.w600, color: context.colors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.accent, foregroundColor: context.colors.onAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Live workout', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _startLogging({WorkoutTemplate? template}) async {
    final session = context.read<ActiveWorkoutSession>();
    var isLive = true;
    if (!session.isActive) {
      final choice = await _chooseLiveOrPast();
      if (choice == null) return;
      isLive = choice;
    }
    if (!mounted) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LogWorkoutScreen(isLiveSession: isLive, template: template)),
    );
    if (created == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: context.colors.accent,
          backgroundColor: context.colors.cardBackground,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR TRAINING',
                        style: Premium.body(context, context.scale(11), weight: FontWeight.w600, color: context.colors.textFaint)
                            .copyWith(letterSpacing: 1.1),
                      ),
                      const SizedBox(height: 2),
                      Text('Workouts', style: Premium.heading(context, context.scale(27))),
                    ],
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(context.scale(20)),
                      onTap: _startLogging,
                      child: Container(
                        width: context.scale(44),
                        height: context.scale(44),
                        decoration: BoxDecoration(
                          gradient: context.colors.accentGradient,
                          shape: BoxShape.circle,
                          boxShadow: context.colors.accentGlowShadow(),
                        ),
                        child: Icon(Icons.add, color: context.colors.onAccent, size: context.scale(24)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text('Presets', style: Premium.heading(context, 15)),
              const SizedBox(height: 10),
              SizedBox(
                height: 108,
                child: FutureBuilder<List<WorkoutTemplate>>(
                  future: _templatesFuture,
                  builder: (context, snapshot) {
                    final templates = snapshot.data ?? [];
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final t in templates)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _PresetCard(
                              template: t,
                              onTap: () => _startLogging(template: t),
                              onDelete: () => _deletePreset(t),
                            ),
                          ),
                        _NewPresetCard(onTap: _createPreset),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Consumer<ActiveWorkoutSession>(
                builder: (context, session, _) {
                  if (!session.isActive) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: PremiumCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () async {
                        final created = await Navigator.of(
                          context,
                        ).push<bool>(MaterialPageRoute(builder: (_) => const LogWorkoutScreen()));
                        if (created == true) _refresh();
                      },
                      child: Row(
                        children: [
                          const LivePulseDot(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Workout in progress', style: Premium.heading(context, 14.5)),
                                const SizedBox(height: 2),
                                Text(
                                  '${session.durationLabel} · ${session.completedSetCount} sets',
                                  style: Premium.body(context, 12, color: context.colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: context.colors.textFaint),
                        ],
                      ),
                    ),
                  );
                },
              ),
              PremiumGradientButton(label: 'Log workout', icon: Icons.add, onTap: _startLogging),
              const SizedBox(height: 22),
              FutureBuilder<List<Workout>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator(color: context.colors.accent)),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off, size: 48, color: context.colors.textFaint),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load workouts.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: Premium.body(context, 12.5, color: context.colors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  final workouts = snapshot.data ?? [];
                  if (workouts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(Icons.fitness_center, size: 44, color: context.colors.textFaint),
                          const SizedBox(height: 14),
                          Text('No workouts logged yet.', style: Premium.body(context, 13, color: context.colors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final w in workouts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _WorkoutRow(
                            workout: w,
                            onTap: () => Navigator.of(
                              context,
                            ).push(MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: w))),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.last-workout`-style row: gradient icon chip, title/meta, mini-stats,
/// trailing chevron.
class _WorkoutRow extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const _WorkoutRow({required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: context.colors.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: context.colors.accentGlowShadow(blur: 12, spread: -4),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.fitness_center, color: context.colors.onAccent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Premium.heading(context, 14.5, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat.yMMMd().add_jm().format(workout.startedAt.toLocal()),
                      style: Premium.body(context, 12, color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: context.colors.textFaint),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                label: 'Duration',
                value: workout.duration.inMinutes > 0 ? '${workout.duration.inMinutes}m' : '-',
              ),
              _MiniStat(label: 'Volume', value: '${workout.totalVolume.toStringAsFixed(0)}kg'),
              _MiniStat(label: 'Sets', value: '${workout.totalSets}'),
            ],
          ),
        ],
      ),
    );
  }
}

/// A saved preset — tap to start a session pre-loaded with its exercises
/// and set counts; the small close button deletes it.
class _PresetCard extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PresetCard({required this.template, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final count = template.exercises.length;
    return SizedBox(
      width: 158,
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const PremiumIconChip(icon: Icons.fitness_center, size: 28),
                const Spacer(),
                InkWell(
                  onTap: onDelete,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(Icons.close, size: 14, color: context.colors.textFaint),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              template.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Premium.heading(context, 13.5, weight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text(
              '$count exercise${count == 1 ? '' : 's'}',
              style: Premium.body(context, 11.5, color: context.colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trailing card in the presets row — opens the preset builder.
class _NewPresetCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NewPresetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Premium.radiusLg),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.accent.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(Premium.radiusLg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 20, color: context.colors.accent),
                const SizedBox(height: 6),
                Text('New preset', style: Premium.body(context, 12, weight: FontWeight.w600, color: context.colors.accent)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Premium.heading(context, 14, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label, style: Premium.body(context, 11, color: context.colors.textFaint)),
        ],
      ),
    );
  }
}
