class WeightGoal {
  final String id;
  final double targetWeightKg;
  final double startWeightKg;
  final DateTime createdAt;
  final DateTime? achievedAt;

  bool get achieved => achievedAt != null;

  /// True once [currentWeightKg] has crossed [targetWeightKg] in the
  /// direction implied by [startWeightKg] (losing vs. gaining weight).
  bool isMetBy(double currentWeightKg) {
    return startWeightKg >= targetWeightKg
        ? currentWeightKg <= targetWeightKg
        : currentWeightKg >= targetWeightKg;
  }

  WeightGoal({
    required this.id,
    required this.targetWeightKg,
    required this.startWeightKg,
    required this.createdAt,
    this.achievedAt,
  });

  factory WeightGoal.fromJson(Map<String, dynamic> json) => WeightGoal(
        id: json['id'] as String,
        targetWeightKg: (json['targetWeightKg'] as num).toDouble(),
        startWeightKg: (json['startWeightKg'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        achievedAt: json['achievedAt'] != null ? DateTime.parse(json['achievedAt'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetWeightKg': targetWeightKg,
        'startWeightKg': startWeightKg,
        'createdAt': createdAt.toIso8601String(),
        'achievedAt': achievedAt?.toIso8601String(),
      };

  WeightGoal copyWith({double? targetWeightKg, DateTime? achievedAt, bool clearAchievedAt = false}) {
    return WeightGoal(
      id: id,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      startWeightKg: startWeightKg,
      createdAt: createdAt,
      achievedAt: clearAchievedAt ? null : (achievedAt ?? this.achievedAt),
    );
  }
}
