import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_config.dart';
import '../data/local_collection_store.dart';
import '../models/weight_goal.dart';

class WeightGoalRepository {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('weightGoals');

  LocalCollectionStore<WeightGoal> get _local => LocalCollectionStore<WeightGoal>(
        key: 'local_weightGoals_$_uid',
        toJson: (g) => g.toJson(),
        fromJson: WeightGoal.fromJson,
        idOf: (g) => g.id,
      );

  Future<List<WeightGoal>> list() async {
    final goals = AppConfig.storeOnCloud
        ? (await _collection.get()).docs.map((d) => WeightGoal.fromJson(d.data())).toList()
        : await _local.list();
    goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return goals;
  }

  Future<WeightGoal> create({required double targetWeightKg, required double startWeightKg}) async {
    final id = AppConfig.storeOnCloud ? _collection.doc().id : 'wg-${DateTime.now().microsecondsSinceEpoch}';
    final goal = WeightGoal(
      id: id,
      targetWeightKg: targetWeightKg,
      startWeightKg: startWeightKg,
      createdAt: DateTime.now(),
    );
    if (AppConfig.storeOnCloud) {
      await _collection.doc(id).set(goal.toJson());
    } else {
      await _local.add(goal);
    }
    return goal;
  }

  Future<WeightGoal> _mutate(String id, WeightGoal Function(WeightGoal) update) async {
    final current = AppConfig.storeOnCloud
        ? WeightGoal.fromJson((await _collection.doc(id).get()).data()!)
        : (await _local.get(id))!;
    final updated = update(current);
    if (AppConfig.storeOnCloud) {
      await _collection.doc(id).set(updated.toJson());
    } else {
      await _local.replace(updated);
    }
    return updated;
  }

  Future<WeightGoal> update(String id, {required double targetWeightKg}) =>
      _mutate(id, (goal) => goal.copyWith(targetWeightKg: targetWeightKg, clearAchievedAt: true));

  Future<WeightGoal> markAchieved(String id, DateTime achievedAt) =>
      _mutate(id, (goal) => goal.copyWith(achievedAt: achievedAt));

  Future<void> delete(String id) async {
    if (AppConfig.storeOnCloud) {
      await _collection.doc(id).delete();
    } else {
      await _local.remove(id);
    }
  }

  /// Inserts or overwrites a goal by its own id — used by CSV import to
  /// restore a full [WeightGoal] as-is. Unlike [update]/[markAchieved],
  /// this doesn't route through [_mutate] (which expects the record to
  /// already exist) — it writes the given object directly, insert-or-replace.
  Future<void> upsert(WeightGoal goal) async {
    if (AppConfig.storeOnCloud) {
      await _collection.doc(goal.id).set(goal.toJson());
    } else {
      await _local.replace(goal);
    }
  }
}
