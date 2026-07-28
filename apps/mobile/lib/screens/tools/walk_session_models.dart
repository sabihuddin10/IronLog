import 'dart:math' show sqrt;

/// Live in-progress walk/run session. Detects steps in real time from raw
/// accelerometer samples via threshold/peak detection, rather than relying
/// on the OS's cumulative step-counter sensor — that sensor is
/// hardware-batched and can lag many seconds behind an actual step, which
/// reads as "not counting" to the user.
///
/// Uses the raw TYPE_ACCELEROMETER sensor (present on every phone — it's
/// what drives screen auto-rotate) rather than the synthesized
/// TYPE_LINEAR_ACCELERATION virtual sensor, which some devices don't
/// implement. Because raw readings include gravity (~9.8 m/s^2 along
/// whichever axis is "down"), gravity is tracked and subtracted with a slow
/// moving average rather than assumed to already be removed.
class ActiveWalkSession {
  static const double _stepThreshold = 1.2;
  static const double _resetThreshold = _stepThreshold * 0.6;
  static const double _lowPassAlpha = 0.3;
  static const double _gravityAlpha = 0.08;
  static const Duration _minStepInterval = Duration(milliseconds: 300);

  final Stopwatch stopwatch = Stopwatch();

  int _steps = 0;
  double? _gravityEstimate;
  double _filteredDeviation = 0;
  bool _armed = true;
  Duration? _lastStepElapsed;

  int get steps => _steps;

  /// Feed each raw sample from accelerometerEventStream() here. [at]
  /// overrides the elapsed-time reference used for step debouncing — only
  /// meant for tests; production calls always use the running stopwatch.
  void addAccelerometerSample(double x, double y, double z, {Duration? at}) {
    final magnitude = sqrt(x * x + y * y + z * z);
    _gravityEstimate = _gravityEstimate == null
        ? magnitude
        : _gravityAlpha * magnitude + (1 - _gravityAlpha) * _gravityEstimate!;
    final deviation = (magnitude - _gravityEstimate!).abs();
    _filteredDeviation = _lowPassAlpha * deviation + (1 - _lowPassAlpha) * _filteredDeviation;

    if (_armed && _filteredDeviation > _stepThreshold) {
      final elapsed = at ?? stopwatch.elapsed;
      if (_lastStepElapsed == null || elapsed - _lastStepElapsed! >= _minStepInterval) {
        _steps++;
        _lastStepElapsed = elapsed;
      }
      _armed = false;
    } else if (_filteredDeviation < _resetThreshold) {
      _armed = true;
    }
  }

  double distanceMeters(double strideLengthMeters) => _steps * strideLengthMeters;

  double speedMps(double strideLengthMeters) {
    final elapsedSeconds = stopwatch.elapsed.inMilliseconds / 1000;
    if (elapsedSeconds <= 0) return 0.0;
    return distanceMeters(strideLengthMeters) / elapsedSeconds;
  }
}
