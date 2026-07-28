import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic per-key JSON-list local store — the on-device counterpart to a
/// Firestore collection, used by each repository when
/// `AppConfig.storeOnCloud` is false. Stores the same `toJson()` shape a
/// repository would otherwise write to Firestore, as a single JSON-encoded
/// list under [key] in [SharedPreferences].
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

  Future<List<T>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    final docs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return docs.map(fromJson).toList();
  }

  Future<void> add(T item) async {
    final items = await list();
    items.add(item);
    await _save(items);
  }

  /// Replaces the item sharing [item]'s id, or appends it if none exists.
  Future<void> replace(T item) async {
    final items = await list();
    final index = items.indexWhere((e) => idOf(e) == idOf(item));
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }
    await _save(items);
  }

  Future<void> remove(String id) async {
    final items = await list();
    items.removeWhere((e) => idOf(e) == id);
    await _save(items);
  }

  Future<T?> get(String id) async {
    for (final item in await list()) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  Future<void> _save(List<T> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items.map(toJson).toList()));
  }
}
