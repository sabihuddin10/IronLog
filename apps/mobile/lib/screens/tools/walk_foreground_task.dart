import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../utils/health_formulas.dart';
import 'walk_session_models.dart';

/// Button ids used by the walk-tracking notification, shared between the
/// screen (which builds the notification) and the task handler (which
/// reports which button was pressed).
class WalkNotificationActions {
  WalkNotificationActions._();

  static const togglePause = 'toggle_pause';
  static const stop = 'stop';
}

/// Message keys for Dart-isolate communication between the tracker screen
/// (main isolate) and [_WalkTaskHandler] (foreground task isolate). Sent as
/// plain `Map<String, dynamic>` since the isolate port only carries values
/// that survive `SendPort.send` — no custom classes.
///
/// Session-start config is deliberately *not* sent this way (see
/// [WalkTaskConfig]) — `sendDataToTask` right after `startService()` resolves
/// races the native side's background-engine setup: `ForegroundService`'s
/// `task` field (the wrapper that relays `onReceiveData` calls into the
/// background engine) isn't necessarily assigned yet at that instant, and a
/// message sent before it is gets silently dropped (`task?.invokeMethod(...)`
/// — null-safe, no error, no retry). `onStart` doesn't have that race since
/// it's the engine's own first lifecycle callback.
class WalkTaskMessage {
  WalkTaskMessage._();

  // Main -> task commands, via `FlutterForegroundTask.sendDataToTask`.
  static const cmdPause = 'pause';
  static const cmdResume = 'resume';
  static const cmdFinish = 'finish';
  static const cmdDiscard = 'discard';

  // Task -> main updates, via `FlutterForegroundTask.sendDataToMain`.
  static const typeStats = 'stats';
  static const typeFinalStats = 'finalStats';
}

/// Keys for passing session-start config to the task isolate via
/// `FlutterForegroundTask.saveData`/`getData` (SharedPreferences-backed,
/// readable from either isolate/engine in this process) instead of
/// `sendDataToTask` — see [WalkTaskMessage] for why.
class WalkTaskConfig {
  WalkTaskConfig._();

  static const strideLengthMeters = 'walkStrideLengthMeters';
  static const weightKg = 'walkWeightKg';
  static const bmrValue = 'walkBmrValue';
}

/// Entry point for the background isolate that keeps the walk session alive
/// (and the notification visible/controllable) while the app is
/// backgrounded. Must be a top-level function per flutter_foreground_task's
/// requirements.
@pragma('vm:entry-point')
void startWalkForegroundTask() {
  FlutterForegroundTask.setTaskHandler(_WalkTaskHandler());
}

/// Runs the actual step-detection pipeline inside the foreground service's
/// own engine/isolate, rather than just keeping the process alive while the
/// main isolate does the sensing (as this used to work, and as
/// `workout_foreground_task.dart`'s equivalent still does).
///
/// `flutter_foreground_task`'s Android implementation spins up a full second
/// `FlutterEngine` for the task (see the package's `ForegroundTask.kt` —
/// it constructs `FlutterEngine(context)` and runs the Dart callback through
/// it), not a bare isolate, so plugins like `sensors_plus` are registered
/// and work here exactly as they do in the main isolate. That engine runs
/// under the same OS foreground-service exemption from Doze/background CPU
/// throttling that keeps the notification alive — sampling in the main
/// isolate was subject to that throttling once the screen locked, which
/// could silently drop accelerometer samples (and therefore steps).
/// `FlutterForegroundTask.updateService`/`stopService` calls made from
/// either engine's plugin instance resolve to the same singleton Android
/// `Service` via `Intent`, so calling them from here works the same as
/// calling them from the main isolate.
///
/// Persistence still happens on the main isolate: it owns the
/// `WalkSessionRepository` (Provider-injected, Firestore/local-store), and
/// is the only side that calls `FlutterForegroundTask.stopService()` in
/// response to a user action — this handler only reports final stats back
/// via [WalkTaskMessage.typeFinalStats] for the main isolate to persist.
class _WalkTaskHandler extends TaskHandler {
  ActiveWalkSession? _session;
  StreamSubscription<AccelerometerEvent>? _sub;
  double _strideLengthMeters = 0;
  double _weightKg = 0;
  double _bmrValue = 0;
  bool _paused = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final strideLengthMeters = await FlutterForegroundTask.getData<double>(key: WalkTaskConfig.strideLengthMeters);
    final weightKg = await FlutterForegroundTask.getData<double>(key: WalkTaskConfig.weightKg);
    final bmrValue = await FlutterForegroundTask.getData<double>(key: WalkTaskConfig.bmrValue);
    _start(
      strideLengthMeters: strideLengthMeters ?? 0,
      weightKg: weightKg ?? 0,
      bmrValue: bmrValue ?? 0,
    );
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    switch (data['cmd']) {
      case WalkTaskMessage.cmdPause:
        _setPaused(true);
      case WalkTaskMessage.cmdResume:
        _setPaused(false);
      case WalkTaskMessage.cmdFinish:
        _sendStats(WalkTaskMessage.typeFinalStats);
        _stopListening();
      case WalkTaskMessage.cmdDiscard:
        _stopListening();
    }
  }

  void _start({required double strideLengthMeters, required double weightKg, required double bmrValue}) {
    _strideLengthMeters = strideLengthMeters;
    _weightKg = weightKg;
    _bmrValue = bmrValue;
    _paused = false;

    final session = ActiveWalkSession()..stopwatch.start();
    _session = session;
    _sub = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
      (event) => session.addAccelerometerSample(event.x, event.y, event.z),
    );
  }

  void _setPaused(bool paused) {
    final session = _session;
    if (session == null || _paused == paused) return;
    _paused = paused;
    if (paused) {
      _sub?.pause();
      session.stopwatch.stop();
    } else {
      _sub?.resume();
      session.stopwatch.start();
    }
    _sendStats(WalkTaskMessage.typeStats);
  }

  void _stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  double get _liveCalories {
    final session = _session;
    if (session == null) return 0;
    final elapsedMinutes = session.stopwatch.elapsed.inMilliseconds / 60000;
    if (elapsedMinutes <= 0) return 0;
    final speedMetersPerMin = session.distanceMeters(_strideLengthMeters) / elapsedMinutes;
    return HealthFormulas.totalWalkKcal(
      weightKg: _weightKg,
      speedMetersPerMin: speedMetersPerMin,
      durationMinutes: elapsedMinutes,
      bmrValue: _bmrValue,
    );
  }

  void _sendStats(String type) {
    final session = _session;
    if (session == null) return;
    FlutterForegroundTask.sendDataToMain({
      'type': type,
      'steps': session.steps,
      'distanceMeters': session.distanceMeters(_strideLengthMeters),
      'elapsedMs': session.stopwatch.elapsed.inMilliseconds,
      'calories': _liveCalories,
      'paused': _paused,
    });
    if (type == WalkTaskMessage.typeStats) {
      final distanceKm = session.distanceMeters(_strideLengthMeters) / 1000;
      FlutterForegroundTask.updateService(
        notificationText:
            '${_durationLabel(session.stopwatch.elapsed)} · ${session.steps} steps · ${distanceKm.toStringAsFixed(2)} km',
      );
    }
  }

  String _durationLabel(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void onRepeatEvent(DateTime timestamp) => _sendStats(WalkTaskMessage.typeStats);

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _stopListening();
  }

  @override
  void onNotificationButtonPressed(String id) {
    // Pause/resume is handled locally so the accelerometer subscription and
    // notification text update immediately, but it's still relayed to the
    // main isolate too so its UI (pause icon, PopScope state) stays in
    // sync. Stop is relayed only — finishing has to happen on the main
    // isolate, which owns the `WalkSessionRepository` write and the actual
    // `FlutterForegroundTask.stopService()` call.
    if (id == WalkNotificationActions.togglePause) {
      _setPaused(!_paused);
    }
    FlutterForegroundTask.sendDataToMain(id);
  }
}
