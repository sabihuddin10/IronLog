import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_config.dart';
import '../data/local_collection_store.dart';
import '../models/walk_session.dart';

class WalkSessionRepository {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('walkSessions');

  LocalCollectionStore<WalkSession> get _local => LocalCollectionStore<WalkSession>(
        key: 'local_walkSessions_$_uid',
        toJson: (w) => w.toJson(),
        fromJson: WalkSession.fromJson,
        idOf: (w) => w.id,
      );

  Future<List<WalkSession>> list() async {
    final sessions = AppConfig.storeOnCloud
        ? (await _collection.get()).docs.map((d) => WalkSession.fromJson(d.data())).toList()
        : await _local.list();
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }

  Future<WalkSession> create({
    required int steps,
    required double distanceMeters,
    required Duration duration,
    required DateTime startedAt,
    required double strideLengthMeters,
    required double calories,
  }) async {
    final id = AppConfig.storeOnCloud ? _collection.doc().id : 'ws-${DateTime.now().microsecondsSinceEpoch}';
    final session = WalkSession(
      id: id,
      steps: steps,
      distanceMeters: distanceMeters,
      duration: duration,
      startedAt: startedAt,
      completedAt: DateTime.now(),
      strideLengthMeters: strideLengthMeters,
      calories: calories,
    );
    if (AppConfig.storeOnCloud) {
      await _collection.doc(id).set(session.toJson());
    } else {
      await _local.add(session);
    }
    return session;
  }

  Future<void> delete(String id) async {
    if (AppConfig.storeOnCloud) {
      await _collection.doc(id).delete();
    } else {
      await _local.remove(id);
    }
  }

  /// Inserts or overwrites a session by its own id — used by CSV import to
  /// restore a full [WalkSession] as-is (original id, original timestamps),
  /// unlike [create] which always mints a new id and stamps `completedAt`
  /// as now.
  Future<void> upsert(WalkSession session) async {
    if (AppConfig.storeOnCloud) {
      await _collection.doc(session.id).set(session.toJson());
    } else {
      await _local.replace(session);
    }
  }
}
