import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_config.dart';
import '../data/local_collection_store.dart';
import '../models/workout.dart';

class WorkoutRepository {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('workouts');

  LocalCollectionStore<Workout> get _local => LocalCollectionStore<Workout>(
        key: 'local_workouts_$_uid',
        toJson: (w) => w.toJson(),
        fromJson: Workout.fromJson,
        idOf: (w) => w.id,
      );

  Future<List<Workout>> list() async {
    final workouts = AppConfig.storeOnCloud
        ? (await _collection.get()).docs.map((d) => Workout.fromJson(d.data())).toList()
        : await _local.list();
    workouts.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return workouts;
  }

  Future<Workout> create({
    required String name,
    required List<WorkoutExercise> exercises,
    required DateTime startedAt,
    double restKcal = 0,
  }) async {
    final id = AppConfig.storeOnCloud ? _collection.doc().id : 'w-${DateTime.now().microsecondsSinceEpoch}';
    final workout = Workout(
      id: id,
      name: name,
      exercises: exercises,
      startedAt: startedAt,
      completedAt: DateTime.now(),
      restKcal: restKcal,
    );
    if (AppConfig.storeOnCloud) {
      await _collection.doc(id).set(workout.toJson());
    } else {
      await _local.add(workout);
    }
    return workout;
  }

  Future<void> update(Workout workout) async {
    if (AppConfig.storeOnCloud) {
      await _collection.doc(workout.id).set(workout.toJson());
    } else {
      await _local.replace(workout);
    }
  }

  Future<void> delete(String id) async {
    if (AppConfig.storeOnCloud) {
      await _collection.doc(id).delete();
    } else {
      await _local.remove(id);
    }
  }
}
