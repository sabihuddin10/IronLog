import '../models/dashboard_stats.dart';
import '../models/workout.dart';
import 'weight_repository.dart';

/// Derived data, not a stored source of truth — computed client-side from
/// the workouts/weightLogs collections rather than a separate Firestore doc.
/// [workouts] is passed in by the caller (from `WorkoutsStore`) rather than
/// fetched here, so this stays in sync with whatever the rest of the app is
/// currently showing instead of holding its own separate, independently
/// stale copy.
class DashboardRepository {
  final WeightRepository _weightRepository;

  DashboardRepository({WeightRepository? weightRepository}) : _weightRepository = weightRepository ?? WeightRepository();

  /// Current (ending today or yesterday) and best-ever consecutive-day
  /// workout streaks, both computed from the same set of workout dates.
  (int current, int best) _streaks(List<Workout> workouts) {
    final days = workouts.map((w) {
      final d = w.startedAt.toLocal();
      return DateTime(d.year, d.month, d.day);
    }).toSet().toList()
      ..sort();
    if (days.isEmpty) return (0, 0);

    var best = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      run = days[i].difference(days[i - 1]).inDays == 1 ? run + 1 : 1;
      if (run > best) best = run;
    }

    final daySet = days.toSet();
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    if (!daySet.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
    var current = 0;
    while (daySet.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return (current, best);
  }

  Future<DashboardStats> fetch(List<Workout> workouts) async {
    final weightLogs = await _weightRepository.list();
    final (current, best) = _streaks(workouts);

    return DashboardStats(
      totalWorkouts: workouts.length,
      lastWorkout: workouts.isNotEmpty ? workouts.first : null,
      latestWeight: weightLogs.isNotEmpty ? weightLogs.first : null,
      workoutsThisWeek: workouts.where((w) {
        return DateTime.now().difference(w.startedAt).inDays <= 7;
      }).length,
      currentStreakDays: current,
      bestStreakDays: best,
    );
  }
}
