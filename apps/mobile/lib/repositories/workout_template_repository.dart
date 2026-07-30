import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_config.dart';
import '../data/local_collection_store.dart';
import '../models/workout_template.dart';

class WorkoutTemplateRepository {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('workout_templates');

  LocalCollectionStore<WorkoutTemplate> get _local => LocalCollectionStore<WorkoutTemplate>(
        key: 'local_workout_templates_$_uid',
        toJson: (t) => t.toJson(),
        fromJson: WorkoutTemplate.fromJson,
        idOf: (t) => t.id,
      );

  Future<List<WorkoutTemplate>> list() async {
    return AppConfig.storeOnCloud
        ? (await _collection.get()).docs.map((d) => WorkoutTemplate.fromJson(d.data())).toList()
        : await _local.list();
  }

  Future<WorkoutTemplate> create({required String name, required List<TemplateExercise> exercises}) async {
    final id = AppConfig.storeOnCloud ? _collection.doc().id : 'wt-${DateTime.now().microsecondsSinceEpoch}';
    final template = WorkoutTemplate(id: id, name: name, exercises: exercises);
    if (AppConfig.storeOnCloud) {
      await _collection.doc(id).set(template.toJson());
    } else {
      await _local.add(template);
    }
    return template;
  }

  Future<void> delete(String id) async {
    if (AppConfig.storeOnCloud) {
      await _collection.doc(id).delete();
    } else {
      await _local.remove(id);
    }
  }

  /// Inserts or overwrites a preset by its own id — used by CSV import to
  /// restore a full [WorkoutTemplate] as-is, unlike [create] which always
  /// mints a new id.
  Future<void> upsert(WorkoutTemplate template) async {
    if (AppConfig.storeOnCloud) {
      await _collection.doc(template.id).set(template.toJson());
    } else {
      await _local.replace(template);
    }
  }
}
