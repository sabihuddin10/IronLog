class WeightLog {
  final String id;
  final double weight;
  final String unit;
  final DateTime loggedAt;
  final String? notes;

  WeightLog({
    required this.id,
    required this.weight,
    required this.unit,
    required this.loggedAt,
    this.notes,
  });

  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog(
        id: json['id'] as String,
        weight: (json['weight'] as num).toDouble(),
        unit: json['unit'] as String,
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'weight': weight,
        'unit': unit,
        'loggedAt': loggedAt.toIso8601String(),
        'notes': notes,
      };
}
