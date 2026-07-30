/// Distinguishes how a set is logged. Strength sets (lifting) are load ×
/// reps; cardio sets (treadmill, bike, rower, jump rope...) are duration +
/// distance instead — there's no "weight" being lifted.
enum SetKind { strength, cardio }

class WorkoutSet {
  final int setNumber;
  final SetKind kind;

  /// Strength-only: loaded weight (kg) and rep count. Null for cardio sets.
  final double? weight;
  final int? reps;

  /// Cardio-only: elapsed time and distance covered. Null for strength sets.
  final int? durationSeconds;
  final double? distanceMeters;

  final bool isWarmup;

  WorkoutSet({
    required this.setNumber,
    this.kind = SetKind.strength,
    this.weight,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
    this.isWarmup = false,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
        setNumber: json['setNumber'] as int,
        kind: json['kind'] == 'cardio' ? SetKind.cardio : SetKind.strength,
        weight: (json['weight'] as num?)?.toDouble(),
        reps: json['reps'] as int?,
        durationSeconds: json['durationSeconds'] as int?,
        distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
        isWarmup: json['isWarmup'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'setNumber': setNumber,
        'kind': kind.name,
        'weight': weight,
        'reps': reps,
        'durationSeconds': durationSeconds,
        'distanceMeters': distanceMeters,
        'isWarmup': isWarmup,
        'isPersonalRecord': false,
      };
}

class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final int order;
  final List<WorkoutSet> sets;

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.order,
    required this.sets,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) => WorkoutExercise(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        order: json['order'] as int,
        sets: (json['sets'] as List)
            .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'order': order,
        'sets': sets.map((s) => s.toJson()).toList(),
      };
}

class Workout {
  final String id;
  final String name;
  final List<WorkoutExercise> exercises;
  final DateTime startedAt;
  final DateTime? completedAt;

  /// Resting-metabolism calorie contribution for this workout, resolved
  /// once at save time (live stopwatch time, or a synthetic backfill/rest
  /// estimate — see [HealthFormulas.workoutKcal]) rather than recomputed
  /// from [duration] on every view. Older saved workouts predate this field
  /// and default to 0.
  final double restKcal;

  Workout({
    required this.id,
    required this.name,
    required this.exercises,
    required this.startedAt,
    required this.completedAt,
    this.restKcal = 0,
  });

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: json['id'] as String,
        name: json['name'] as String,
        exercises: (json['exercises'] as List)
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        restKcal: (json['restKcal'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'restKcal': restKcal,
      };

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  /// Strength-only tonnage; cardio sets have no weight/reps to contribute.
  double get totalVolume => exercises.fold(
        0.0,
        (sum, e) => sum + e.sets.fold(0.0, (s, set) => s + (set.weight ?? 0) * (set.reps ?? 0)),
      );

  Duration get duration =>
      completedAt != null ? completedAt!.difference(startedAt) : Duration.zero;

  /// '-' only when there's truly no completion time recorded; workouts under
  /// a minute show seconds instead of rounding down to a misleading '-'.
  String get durationLabel {
    if (completedAt == null) return '-';
    final d = duration;
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    if (d.inSeconds > 0) return '${d.inSeconds}s';
    return '-';
  }
}
