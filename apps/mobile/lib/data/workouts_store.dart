import 'package:flutter/foundation.dart';

import '../models/workout.dart';
import '../repositories/workout_repository.dart';

/// Single in-memory source of truth for the signed-in user's saved
/// workouts, shared via Provider so every screen that lists/counts/charts
/// workouts ([ProfileScreen], [WorkoutsScreen], `DashboardScreen`) reflects
/// a create/edit/delete performed from any ONE of them immediately — no
/// manual pull-to-refresh needed.
///
/// Each of those screens used to hold its own `Future<List<Workout>>`,
/// fetched once in `initState`. Because `RootScreen` keeps every tab alive
/// in an `IndexedStack`, a delete on the Workouts tab never invalidated the
/// Profile tab's already-resolved Future, so it kept showing the deleted
/// workout until something happened to trigger its own separate refetch
/// (backgrounding a live session, pull-to-refresh, ...). Routing every
/// mutation through this one store instead means there's only ever one
/// in-memory copy of the list, and every screen watching it rebuilds the
/// instant that copy changes, regardless of which screen made the change.
class WorkoutsStore extends ChangeNotifier {
  final WorkoutRepository _repository;

  WorkoutsStore(this._repository);

  List<Workout> _workouts = [];
  bool _loaded = false;
  Object? _error;
  Future<void>? _loading;

  /// Most-recent-first, same order [WorkoutRepository.list] returns.
  List<Workout> get workouts => _workouts;
  bool get isLoaded => _loaded;

  /// Set when the last load attempt failed (network/Firestore error) —
  /// screens can check this to show a friendly message instead of an empty
  /// list. Cleared by the next successful load.
  Object? get error => _error;

  /// Loads once; safe to call from every screen's `initState` — later
  /// callers just await the same in-flight (or already-resolved) load
  /// instead of re-fetching. Never throws — a failed fetch is recorded in
  /// [error] and surfaced via [notifyListeners] instead, since most callers
  /// fire this off without awaiting it.
  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  /// Forces a full reload from the repository — used for pull-to-refresh
  /// and after a bulk mutation this store didn't itself perform (a CSV
  /// import writes straight to the repository, bypassing this store's own
  /// create/update/delete methods).
  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      _workouts = await _repository.list();
      _loaded = true;
      _error = null;
    } catch (e) {
      _error = e;
    } finally {
      _loading = null;
      notifyListeners();
    }
  }

  /// Clears the in-memory list without refetching — called on sign-out (or
  /// switching accounts without an app restart) so the next screen that
  /// asks doesn't briefly show the previous user's workouts.
  void reset() {
    _workouts = [];
    _loaded = false;
    _error = null;
    notifyListeners();
  }

  Future<Workout> create({
    required String name,
    required List<WorkoutExercise> exercises,
    required DateTime startedAt,
    double restKcal = 0,
  }) async {
    final workout = await _repository.create(
      name: name,
      exercises: exercises,
      startedAt: startedAt,
      restKcal: restKcal,
    );
    _workouts = [workout, ..._workouts]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    _loaded = true;
    notifyListeners();
    return workout;
  }

  Future<void> update(Workout workout) async {
    await _repository.update(workout);
    _workouts = [
      for (final w in _workouts) if (w.id == workout.id) workout else w,
    ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    _workouts = _workouts.where((w) => w.id != id).toList();
    notifyListeners();
  }
}
