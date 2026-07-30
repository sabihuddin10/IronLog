import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_config.dart';
import '../data/local_collection_store.dart';
import '../models/weight_log.dart';

class WeightRepository {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('weightLogs');

  LocalCollectionStore<WeightLog> get _local => LocalCollectionStore<WeightLog>(
        key: 'local_weightLogs_$_uid',
        toJson: (w) => w.toJson(),
        fromJson: WeightLog.fromJson,
        idOf: (w) => w.id,
      );

  Future<List<WeightLog>> list() async {
    final logs = AppConfig.storeOnCloud
        ? (await _collection.get()).docs.map((d) => WeightLog.fromJson(d.data())).toList()
        : await _local.list();
    logs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return logs;
  }

  Future<WeightLog> create({
    required double weight,
    required String unit,
    required DateTime loggedAt,
    String? notes,
  }) async {
    final id = AppConfig.storeOnCloud ? _collection.doc().id : 'wt-${DateTime.now().microsecondsSinceEpoch}';
    final log = WeightLog(
      id: id,
      weight: weight,
      unit: unit,
      loggedAt: loggedAt,
      notes: notes,
    );
    if (AppConfig.storeOnCloud) {
      await _collection.doc(id).set(log.toJson());
    } else {
      await _local.add(log);
    }
    return log;
  }

  /// Inserts or overwrites a log by its own id — used by CSV import to
  /// restore a full [WeightLog] as-is (original id/timestamp), unlike
  /// [create] which always mints a new id.
  Future<void> upsert(WeightLog log) async {
    if (AppConfig.storeOnCloud) {
      await _collection.doc(log.id).set(log.toJson());
    } else {
      await _local.replace(log);
    }
  }
}
