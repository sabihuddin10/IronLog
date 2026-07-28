class MuscleEngagement {
  final String muscle;
  final int percentage;

  MuscleEngagement({required this.muscle, required this.percentage});

  factory MuscleEngagement.fromJson(Map<String, dynamic> json) => MuscleEngagement(
        muscle: json['muscle'] as String,
        percentage: json['percentage'] as int,
      );

  Map<String, dynamic> toJson() => {'muscle': muscle, 'percentage': percentage};
}

class Exercise {
  final String id;
  final String? ownerId;
  final String name;
  final String muscleGroup;
  final String? equipment;
  final bool isCustom;
  final List<MuscleEngagement> muscles;

  Exercise({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.isCustom,
    this.muscles = const [],
  });

  /// Primary (highest-percentage) muscle engagement, if any.
  MuscleEngagement? get primaryMuscle {
    if (muscles.isEmpty) return null;
    return muscles.reduce((a, b) => a.percentage >= b.percentage ? a : b);
  }

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        ownerId: json['ownerId'] as String?,
        name: json['name'] as String,
        muscleGroup: json['muscleGroup'] as String? ?? json['category'] as String,
        equipment: json['equipment'] as String?,
        isCustom: json['isCustom'] as bool? ?? false,
        muscles: (json['muscles'] as List?)
                ?.map((m) => MuscleEngagement.fromJson(m as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'name': name,
        'muscleGroup': muscleGroup,
        'equipment': equipment,
        'isCustom': isCustom,
        'muscles': muscles.map((m) => m.toJson()).toList(),
      };

  factory Exercise.fromLibraryJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        ownerId: null,
        name: json['name'] as String,
        muscleGroup: json['category'] as String,
        equipment: json['equipment'] as String?,
        isCustom: false,
        muscles: (json['muscles'] as List)
            .map((m) => MuscleEngagement.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

const List<String> muscleGroups = [
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'legs',
  'glutes',
  'core',
  'cardio',
  'full_body',
];
