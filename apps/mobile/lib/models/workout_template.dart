/// A single set's target values within a [TemplateExercise] — captured
/// while building the preset (weight/reps typed in to preview the estimated
/// time/calories, see `PresetBuilderScreen`) and pre-filled when a session
/// is started from this preset, ready to adjust on the day rather than
/// starting from a blank box every time.
class TemplateSet {
  final bool isWarmup;

  /// Strength-only target: loaded weight (kg) and rep count. Null for cardio sets.
  final double? weight;
  final int? reps;

  /// Cardio-only target: elapsed time and distance. Null for strength sets.
  final int? durationSeconds;
  final double? distanceMeters;

  TemplateSet({
    this.isWarmup = false,
    this.weight,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
  });

  factory TemplateSet.fromJson(Map<String, dynamic> json) => TemplateSet(
        isWarmup: json['isWarmup'] as bool? ?? false,
        weight: (json['weight'] as num?)?.toDouble(),
        reps: json['reps'] as int?,
        durationSeconds: json['durationSeconds'] as int?,
        distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'isWarmup': isWarmup,
        'weight': weight,
        'reps': reps,
        'durationSeconds': durationSeconds,
        'distanceMeters': distanceMeters,
      };
}

/// A single exercise slot within a [WorkoutTemplate] — the exercise plus its
/// target sets.
class TemplateExercise {
  final String exerciseId;
  final String exerciseName;
  final bool isCardio;
  final List<TemplateSet> sets;

  TemplateExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.isCardio = false,
    required this.sets,
  });

  factory TemplateExercise.fromJson(Map<String, dynamic> json) => TemplateExercise(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        isCardio: json['isCardio'] as bool? ?? false,
        sets: (json['sets'] as List).map((s) => TemplateSet.fromJson(s as Map<String, dynamic>)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'isCardio': isCardio,
        'sets': sets.map((s) => s.toJson()).toList(),
      };
}

/// A saved, reusable workout skeleton ("preset") — a name plus an ordered
/// list of exercises with target sets. Starting a session from one
/// pre-populates [ActiveWorkoutSession.exercises] via
/// [ActiveExercise.fromTemplate], pre-filling each set's target weight/reps
/// (or cardio duration/distance) — still fully editable, ready to fill in
/// while training.
class WorkoutTemplate {
  final String id;
  final String name;
  final List<TemplateExercise> exercises;

  WorkoutTemplate({required this.id, required this.name, required this.exercises});

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) => WorkoutTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        exercises: (json['exercises'] as List)
            .map((e) => TemplateExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}
