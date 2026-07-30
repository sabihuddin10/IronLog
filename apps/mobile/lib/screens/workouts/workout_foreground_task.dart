import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Button ids used by the workout-logging notification, shared between the
/// screen (which builds the notification) and the task handler (which
/// reports which button was pressed). Mirrors
/// `screens/tools/walk_foreground_task.dart`'s pattern for the Walk/Run
/// tracker.
class WorkoutNotificationActions {
  WorkoutNotificationActions._();

  static const finish = 'finish';
}

/// Entry point for the background isolate that keeps an in-progress workout
/// alive (and the notification visible/controllable) while the app is
/// backgrounded. Must be a top-level function per flutter_foreground_task's
/// requirements.
@pragma('vm:entry-point')
void startWorkoutForegroundTask() {
  FlutterForegroundTask.setTaskHandler(_WorkoutTaskHandler());
}

/// Runs in the background isolate. Doesn't track anything itself — that
/// still happens in the main isolate — this only keeps the process alive
/// and relays notification button taps back to the main isolate.
class _WorkoutTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    // Relay to main so it can persist the workout — it owns all the
    // exercise/set data (see active_workout_session.dart) which nothing
    // here has access to. But don't leave the notification stuck forever
    // if the main isolate isn't around to process this (app backgrounded,
    // not just the workout screen closed): stop the service directly too,
    // matching the walk/run tracker's Stop button — see
    // `walk_foreground_task.dart` for why that relay-only approach wasn't
    // reliable. If main *is* listening, `ActiveWorkoutSession.finish()`
    // saves and calls `stopService()` itself, which safely no-ops here
    // since the service is already stopped by then.
    FlutterForegroundTask.sendDataToMain(id);
    FlutterForegroundTask.stopService();
  }
}
