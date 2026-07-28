import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/exercise.dart';

/// Bundled built-in exercise library (assets/data/exercises.json) — shared
/// reference data, not per-user content, so it stays a static in-memory
/// asset rather than living in Firestore. Every other collection (workouts,
/// weight logs, weight goals, walk sessions, custom exercises) is
/// Firestore-backed — see lib/repositories/.
class MockStore {
  MockStore._internal();

  static final MockStore instance = MockStore._internal();

  final List<Exercise> exercises = [];

  bool _exercisesLoaded = false;

  /// Loads the exercise library (with per-muscle engagement percentages)
  /// from assets/data/exercises.json. Call once before first use, e.g. in
  /// main() before runApp.
  Future<void> loadExercises() async {
    if (_exercisesLoaded) return;
    final raw = await rootBundle.loadString('assets/data/exercises.json');
    final list = jsonDecode(raw) as List;
    exercises.addAll(list.map((e) => Exercise.fromLibraryJson(e as Map<String, dynamic>)));
    _exercisesLoaded = true;
  }
}
