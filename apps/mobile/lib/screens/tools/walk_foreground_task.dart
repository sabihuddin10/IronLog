import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Button ids used by the walk-tracking notification, shared between the
/// screen (which builds the notification) and the task handler (which
/// reports which button was pressed).
class WalkNotificationActions {
  WalkNotificationActions._();

  static const togglePause = 'toggle_pause';
  static const stop = 'stop';
}

/// Entry point for the background isolate that keeps the walk session alive
/// (and the notification visible/controllable) while the app is
/// backgrounded. Must be a top-level function per flutter_foreground_task's
/// requirements.
@pragma('vm:entry-point')
void startWalkForegroundTask() {
  FlutterForegroundTask.setTaskHandler(_WalkTaskHandler());
}

/// Runs in the background isolate. Doesn't do any step-counting itself —
/// that still happens in the main isolate via the accelerometer stream —
/// this only keeps the process alive and relays notification button taps
/// back to the main isolate.
class _WalkTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.sendDataToMain(id);
  }
}
