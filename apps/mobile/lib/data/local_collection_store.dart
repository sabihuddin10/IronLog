import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic per-collection local store — the on-device counterpart to a
/// Firestore collection, used by each repository when
/// `AppConfig.storeOnCloud` is false. Backed by a Hive box named [key],
/// with one entry per record (keyed by the record's own id via [idOf]) —
/// `add`/`replace`/`remove` are real per-record writes, not a
/// read-the-whole-collection → decode → mutate → re-encode →
/// rewrite-everything round trip against a single JSON blob (which is what
/// this store used to do against SharedPreferences; that got slower and
/// heavier with every record as history accumulated). Hive also works on
/// web (IndexedDB-backed), which this app needs since it runs both as an
/// Android build and a web build — `sqflite` doesn't.
class LocalCollectionStore<T> {
  final String key;
  final Map<String, dynamic> Function(T) toJson;
  final T Function(Map<String, dynamic>) fromJson;
  final String Function(T) idOf;

  LocalCollectionStore({
    required this.key,
    required this.toJson,
    required this.fromJson,
    required this.idOf,
  });

  static final Set<String> _migrated = {};
  static final Map<String, Future<void>> _migrating = {};

  Future<Box<Map>> _box() async {
    await _ensureMigrated();
    return Hive.isBoxOpen(key) ? Hive.box<Map>(key) : Hive.openBox<Map>(key);
  }

  /// One-time import of this collection's pre-Hive data — a single
  /// JSON-encoded list that used to live under this same [key] in
  /// SharedPreferences — into the new Hive box, then clears the old entry.
  /// Without this, everyone's existing local-only history would silently
  /// vanish the first time they open the app after this storage engine
  /// switch. Memoized per [key] for the life of the app so it's only
  /// checked once, not on every store call.
  Future<void> _ensureMigrated() {
    if (_migrated.contains(key)) return Future.value();
    return _migrating[key] ??= _migrate().whenComplete(() {
      _migrated.add(key);
      _migrating.remove(key);
    });
  }

  Future<void> _migrate() async {
    final box = Hive.isBoxOpen(key) ? Hive.box<Map>(key) : await Hive.openBox<Map>(key);
    if (box.isNotEmpty) return; // already on Hive (or genuinely started empty)

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return;

    try {
      final items = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      for (final item in items) {
        final id = item['id'];
        if (id is String) await box.put(id, item);
      }
    } catch (_) {
      // Corrupt legacy blob — nothing sensible to migrate from it.
    }
    await prefs.remove(key);
  }

  Future<List<T>> list() async {
    final box = await _box();
    return box.values.map((raw) => fromJson(_deepMapCast(raw))).toList();
  }

  Future<void> add(T item) async {
    final box = await _box();
    await box.put(idOf(item), toJson(item));
  }

  /// Replaces the item sharing [item]'s id, or adds it if none exists —
  /// `Box.put` is an upsert by key already.
  Future<void> replace(T item) async {
    final box = await _box();
    await box.put(idOf(item), toJson(item));
  }

  Future<void> remove(String id) async {
    final box = await _box();
    await box.delete(id);
  }

  Future<T?> get(String id) async {
    final box = await _box();
    final raw = box.get(id);
    return raw == null ? null : fromJson(_deepMapCast(raw));
  }

  /// Hive hands back nested maps/lists typed as `Map<dynamic, dynamic>` /
  /// `List<dynamic>` even though they were written from a
  /// `Map<String, dynamic>`. Every model's `fromJson` does
  /// `as Map<String, dynamic>` casts on nested objects (a workout's
  /// exercises, a preset's sets, ...), which throws on a raw
  /// `Map<dynamic, dynamic>` despite its keys genuinely all being Strings —
  /// deep-copying into properly-typed maps here means no model file needs
  /// to know or care which storage engine wrote the data.
  static Map<String, dynamic> _deepMapCast(Map raw) =>
      raw.map((k, v) => MapEntry(k as String, _deepCastValue(v)));

  static dynamic _deepCastValue(dynamic value) {
    if (value is Map) return _deepMapCast(value);
    if (value is List) return value.map(_deepCastValue).toList();
    return value;
  }
}
