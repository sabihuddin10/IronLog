import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/exercise.dart';
import '../models/walk_session.dart';
import '../models/weight_goal.dart';
import '../models/weight_log.dart';
import '../models/workout.dart';
import '../models/workout_template.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/walk_session_repository.dart';
import '../repositories/weight_goal_repository.dart';
import '../repositories/weight_repository.dart';
import '../repositories/workout_repository.dart';
import '../repositories/workout_template_repository.dart';
import 'body_profile_store.dart';

/// How many of each record type a CSV import actually applied — shown to
/// the user afterward so "Imported data" isn't just a blind claim.
class CsvImportSummary {
  final int workouts;
  final int walkSessions;
  final int weightLogs;
  final int weightGoals;
  final int templates;
  final int exercises;
  final bool profileRestored;

  const CsvImportSummary({
    this.workouts = 0,
    this.walkSessions = 0,
    this.weightLogs = 0,
    this.weightGoals = 0,
    this.templates = 0,
    this.exercises = 0,
    this.profileRestored = false,
  });

  int get total => workouts + walkSessions + weightLogs + weightGoals + templates + exercises + (profileRestored ? 1 : 0);
}

/// Backs up (and restores) everything a user has stored in the app as a
/// single CSV file. Each row is `[type, id, summary, data]`: `type`
/// discriminates which repository the row belongs to, `summary` is a
/// human-readable label purely for someone skimming the file in a
/// spreadsheet, and `data` is the record's own `toJson()` output re-encoded
/// as one JSON string. Reusing each model's existing (already-correct)
/// `toJson()`/`fromJson()` this way — rather than hand-flattening nested
/// structures like a workout's exercises/sets into normalized CSV
/// columns — keeps this a faithful, lossless round trip; the primary use
/// case is "back everything up, restore it later" (device migration, data
/// loss recovery), not spreadsheet analysis.
class CsvBackupService {
  final WorkoutRepository workoutRepository;
  final WalkSessionRepository walkSessionRepository;
  final WeightRepository weightRepository;
  final WeightGoalRepository weightGoalRepository;
  final WorkoutTemplateRepository templateRepository;
  final ExerciseRepository exerciseRepository;
  final BodyProfileStore profileStore;

  const CsvBackupService({
    required this.workoutRepository,
    required this.walkSessionRepository,
    required this.weightRepository,
    required this.weightGoalRepository,
    required this.templateRepository,
    required this.exerciseRepository,
    required this.profileStore,
  });

  Future<String> buildCsv() async {
    final workouts = await workoutRepository.list();
    final walks = await walkSessionRepository.list();
    final weights = await weightRepository.list();
    final goals = await weightGoalRepository.list();
    final templates = await templateRepository.list();
    final exercises = (await exerciseRepository.list()).where((e) => e.isCustom).toList();

    final dateFmt = DateFormat.yMMMd();
    final rows = <List<dynamic>>[
      ['type', 'id', 'summary', 'data'],
      for (final w in workouts)
        ['workout', w.id, '${w.name} — ${dateFmt.format(w.startedAt.toLocal())}', jsonEncode(w.toJson())],
      for (final s in walks)
        ['walk_session', s.id, 'Walk — ${dateFmt.format(s.startedAt.toLocal())}', jsonEncode(s.toJson())],
      for (final l in weights)
        [
          'weight_log',
          l.id,
          '${l.weight}${l.unit} — ${dateFmt.format(l.loggedAt.toLocal())}',
          jsonEncode(l.toJson()),
        ],
      for (final g in goals)
        ['weight_goal', g.id, 'Goal: ${g.targetWeightKg}kg', jsonEncode(g.toJson())],
      for (final t in templates) ['workout_template', t.id, 'Preset: ${t.name}', jsonEncode(t.toJson())],
      for (final e in exercises) ['exercise', e.id, 'Exercise: ${e.name}', jsonEncode(e.toJson())],
      ['profile', 'profile', 'Body profile', jsonEncode(profileStore.toJson())],
    ];
    return const CsvEncoder().convert(rows);
  }

  /// Writes [buildCsv]'s output to a timestamped file in the temp
  /// directory, ready to hand to `share_plus` — writing to a shareable temp
  /// file (rather than a public storage location) avoids needing any
  /// storage permission.
  Future<File> exportToFile() async {
    final csv = await buildCsv();
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/ironlog_backup_$stamp.csv');
    return file.writeAsString(csv);
  }

  /// Parses a CSV previously produced by [buildCsv] and upserts every row
  /// into the matching repository. One malformed row (missing column, bad
  /// JSON — this is a user-supplied file, possibly hand-edited) is skipped
  /// rather than aborting the whole import.
  Future<CsvImportSummary> importCsv(String csvText) async {
    final rows = const CsvDecoder().convert(csvText);
    var workouts = 0, walks = 0, weightLogs = 0, goals = 0, templates = 0, exercises = 0;
    var profileRestored = false;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 4) continue;
      try {
        final type = row[0] as String;
        final data = jsonDecode(row[3] as String) as Map<String, dynamic>;
        switch (type) {
          case 'workout':
            await workoutRepository.update(Workout.fromJson(data));
            workouts++;
          case 'walk_session':
            await walkSessionRepository.upsert(WalkSession.fromJson(data));
            walks++;
          case 'weight_log':
            await weightRepository.upsert(WeightLog.fromJson(data));
            weightLogs++;
          case 'weight_goal':
            await weightGoalRepository.upsert(WeightGoal.fromJson(data));
            goals++;
          case 'workout_template':
            await templateRepository.upsert(WorkoutTemplate.fromJson(data));
            templates++;
          case 'exercise':
            final exercise = Exercise.fromJson(data);
            if (exercise.isCustom) {
              await exerciseRepository.upsert(exercise);
              exercises++;
            }
          case 'profile':
            profileStore.applyJson(data);
            profileRestored = true;
        }
      } catch (_) {
        // Skip this row; keep importing the rest of the file.
      }
    }

    return CsvImportSummary(
      workouts: workouts,
      walkSessions: walks,
      weightLogs: weightLogs,
      weightGoals: goals,
      templates: templates,
      exercises: exercises,
      profileRestored: profileRestored,
    );
  }
}
