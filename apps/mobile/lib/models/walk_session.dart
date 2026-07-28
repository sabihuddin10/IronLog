class WalkSession {
  final String id;
  final int steps;
  final double distanceMeters;
  final Duration duration;
  final DateTime startedAt;
  final DateTime completedAt;
  final double strideLengthMeters;
  final double calories;

  WalkSession({
    required this.id,
    required this.steps,
    required this.distanceMeters,
    required this.duration,
    required this.startedAt,
    required this.completedAt,
    required this.strideLengthMeters,
    required this.calories,
  });

  factory WalkSession.fromJson(Map<String, dynamic> json) => WalkSession(
        id: json['id'] as String,
        steps: json['steps'] as int,
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
        duration: Duration(seconds: json['durationSeconds'] as int),
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: DateTime.parse(json['completedAt'] as String),
        strideLengthMeters: (json['strideLengthMeters'] as num).toDouble(),
        calories: (json['calories'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'steps': steps,
        'distanceMeters': distanceMeters,
        'durationSeconds': duration.inSeconds,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'strideLengthMeters': strideLengthMeters,
        'calories': calories,
      };

  double get distanceKm => distanceMeters / 1000;

  double get averageSpeedMps =>
      duration.inSeconds > 0 ? distanceMeters / duration.inSeconds : 0.0;

  double get paceMinPerKm =>
      distanceKm > 0 ? (duration.inSeconds / 60) / distanceKm : 0.0;
}
