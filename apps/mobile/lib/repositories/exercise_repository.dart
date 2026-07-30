import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_config.dart';
import '../data/local_collection_store.dart';
import '../data/mock_store.dart';
import '../models/exercise.dart';

/// The built-in exercise library (with per-muscle engagement percentages)
/// stays a bundled static asset loaded into [MockStore] — see
/// `assets/data/exercises.json` — since it's shared reference data, not
/// per-user content, regardless of [AppConfig.storeOnCloud]. Only custom,
/// user-created exercises switch between Firestore and local storage.
class ExerciseRepository {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('exercises');

  LocalCollectionStore<Exercise> get _local => LocalCollectionStore<Exercise>(
        key: 'local_exercises_$_uid',
        toJson: (e) => e.toJson(),
        fromJson: Exercise.fromJson,
        idOf: (e) => e.id,
      );

  Future<List<Exercise>> list() async {
    final custom = AppConfig.storeOnCloud
        ? (await _collection.get()).docs.map((d) => Exercise.fromJson(d.data())).toList()
        : await _local.list();
    return [...MockStore.instance.exercises, ...custom];
  }

  Future<Exercise> create({
    required String name,
    required String muscleGroup,
    String? equipment,
  }) async {
    final id = AppConfig.storeOnCloud ? _collection.doc().id : 'ex-custom-${DateTime.now().microsecondsSinceEpoch}';
    final exercise = Exercise(
      id: id,
      ownerId: _uid,
      name: name,
      muscleGroup: muscleGroup,
      equipment: equipment,
      isCustom: true,
    );
    if (AppConfig.storeOnCloud) {
      await _collection.doc(id).set(exercise.toJson());
    } else {
      await _local.add(exercise);
    }
    return exercise;
  }

  /// Inserts or overwrites a custom exercise by its own id — used by CSV
  /// import to restore a full [Exercise] as-is. Silently no-ops for
  /// built-in exercises (`isCustom == false`): those are bundled reference
  /// data from `assets/data/exercises.json`, not per-user content, and must
  /// never be written to the custom collection.
  Future<void> upsert(Exercise exercise) async {
    if (!exercise.isCustom) return;
    if (AppConfig.storeOnCloud) {
      await _collection.doc(exercise.id).set(exercise.toJson());
    } else {
      await _local.replace(exercise);
    }
  }
}
