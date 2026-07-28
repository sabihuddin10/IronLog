import 'weight_log.dart';
import 'workout.dart';

class DashboardStats {
  final int totalWorkouts;
  final Workout? lastWorkout;
  final WeightLog? latestWeight;
  final int workoutsThisWeek;

  /// Consecutive days (ending today or yesterday) with at least one workout.
  final int currentStreakDays;

  /// Longest [currentStreakDays] has ever been, across all workout history.
  final int bestStreakDays;

  DashboardStats({
    required this.totalWorkouts,
    required this.lastWorkout,
    required this.latestWeight,
    required this.workoutsThisWeek,
    required this.currentStreakDays,
    required this.bestStreakDays,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        totalWorkouts: json['totalWorkouts'] as int,
        lastWorkout: json['lastWorkout'] != null
            ? Workout.fromJson(json['lastWorkout'] as Map<String, dynamic>)
            : null,
        latestWeight: json['latestWeight'] != null
            ? WeightLog.fromJson(json['latestWeight'] as Map<String, dynamic>)
            : null,
        workoutsThisWeek: json['workoutsThisWeek'] as int,
        currentStreakDays: json['currentStreakDays'] as int? ?? 0,
        bestStreakDays: json['bestStreakDays'] as int? ?? 0,
      );
}
